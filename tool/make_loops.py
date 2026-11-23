"""Recorta un loop de cada tema de arte/musica/ y lo pasa a OGG.

    python3 tool/make_loops.py

Para cada tema:
1. Calcula el tempo (pulsos por minuto) y dónde caen los compases (4 pulsos).
2. Prueba cortes que empiezan y terminan al comienzo de un compás y duran
   entre MIN_LEN y MAX_LEN segundos. Elige el que mejor empalma: lo que suena
   justo después del final se tiene que parecer a lo que suena al principio.
3. Une el final con el principio con un fundido cruzado corto (XFADE).
4. Exporta a assets/music/<nombre>.ogg (Vorbis, 96 kbps).

Necesita: python3-numpy, python3-scipy y ffmpeg.
"""

import subprocess
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'arte/musica'
DST = ROOT / 'assets/music'

RATE = 44100
MIN_LEN = 40.0  # Segundos.
MAX_LEN = 60.0
XFADE = 0.2  # Segundos de fundido cruzado en la unión.
BITRATE = '96k'

# nombre en assets → (archivo en arte/musica, desde qué segundo puede
# empezar el loop).
TRACKS = {
    'intro': ('Walking_for_Gramonia.mp3', 11.0),
    'final': ('Tales_at_Twilight.mp3', 0.0),
    'aventura': ('Path_Through_the_Ferns.mp3', 0.0),
    'tension': ('Across_The_Dragon_Peaks.mp3', 0.0),
}

# Análisis.
HOP = 512
WIN = 2048


def decode(path: Path) -> np.ndarray:
    """Audio estéreo en float32, forma (muestras, 2)."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le',
         '-ac', '2', '-ar', str(RATE), '-'],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).copy()


def spectrogram(mono: np.ndarray) -> np.ndarray:
    """Magnitudes en escala logarítmica, una fila por cuadro de HOP."""
    window = np.hanning(WIN).astype(np.float32)
    frames = 1 + (len(mono) - WIN) // HOP
    idx = np.arange(WIN)[None, :] + HOP * np.arange(frames)[:, None]
    spec = np.abs(np.fft.rfft(mono[idx] * window, axis=1))
    # Juntar las frecuencias en 48 bandas logarítmicas (más robusto).
    freqs = np.fft.rfftfreq(WIN, 1 / RATE)
    edges = np.geomspace(40, 12000, 49)
    bands = np.stack(
        [spec[:, (freqs >= lo) & (freqs < hi)].sum(axis=1)
         for lo, hi in zip(edges[:-1], edges[1:])],
        axis=1,
    )
    return np.log1p(bands)


def onsets(spec: np.ndarray) -> np.ndarray:
    flux = np.maximum(0, np.diff(spec, axis=0)).sum(axis=1)
    flux = np.concatenate([[0], flux])
    return flux - flux.mean()


def tempo_and_beats(env: np.ndarray) -> tuple[float, np.ndarray]:
    """Período del pulso (en cuadros) y cuadros donde caen los pulsos."""
    fps = RATE / HOP
    ac = np.correlate(env, env, mode='full')[len(env) - 1:]
    lags = np.arange(len(ac))
    bpm = 60 * fps / np.maximum(lags, 1)
    ok = (bpm >= 60) & (bpm <= 180)
    # Leve preferencia por tempos cerca de 110 (evita duplicar o partir).
    weight = np.exp(-0.5 * (np.log2(bpm / 110) / 1.0) ** 2)
    period = lags[ok][np.argmax((ac * weight)[ok])]
    # Afinar el período con precisión de fracción de cuadro.
    best, best_score = float(period), -np.inf
    for p in np.linspace(period - 1, period + 1, 81):
        for phase in np.linspace(0, p, 40, endpoint=False):
            pos = np.arange(phase, len(env) - 1, p).astype(int)
            score = env[pos].sum()
            if score > best_score:
                best, best_score, best_phase = p, score, phase
    beats = np.arange(best_phase, len(env) - 1, best)
    return best, beats


def downbeats(env: np.ndarray, beats: np.ndarray) -> np.ndarray:
    """De cada 4 pulsos, el que más se marca es el comienzo del compás."""
    idx = beats.astype(int)
    scores = [env[idx[k::4]].mean() for k in range(4)]
    return beats[int(np.argmax(scores))::4]


def similarity(spec: np.ndarray, a: int, b: int, length: int) -> float:
    """Cuánto se parecen dos tramos del espectrograma (1 = iguales)."""
    x, y = spec[a:a + length].ravel(), spec[b:b + length].ravel()
    if len(x) != len(y) or len(x) == 0:
        return -1.0
    return float(np.dot(x, y) / (np.linalg.norm(x) * np.linalg.norm(y)))


def best_loop(audio: np.ndarray, min_start: float) -> dict:
    mono = audio.mean(axis=1)
    spec = spectrogram(mono)
    env = onsets(spec)
    period, beats = tempo_and_beats(env)
    bars = downbeats(env, beats)
    fps = RATE / HOP
    compare = int(2.0 * fps)  # Se comparan 2 segundos.

    starts = [b for b in bars if min_start - 0.05 <= b / fps <= min_start + 12]
    if min_start > 0:
        # Si se pidió un segundo exacto, el compás más cercano a ese segundo.
        starts = starts[:1]
    best = None
    for s in starts:
        for e in bars:
            length = (e - s) / fps
            if not MIN_LEN <= length <= MAX_LEN:
                continue
            if int(e) + compare >= len(spec):
                continue
            score = similarity(spec, int(s), int(e), compare)
            # Lo de justo antes del final y del principio, también.
            score += 0.5 * similarity(
                spec, int(s) - compare // 2, int(e) - compare // 2,
                compare // 2,
            ) if s > compare else 0
            if best is None or score > best['score']:
                best = {'start': s / fps, 'end': e / fps, 'score': score}
    if best is None:
        raise SystemExit('No encontré un loop de la duración pedida.')
    best['bpm'] = 60 * fps / period
    return best


def render(audio: np.ndarray, start: float, end: float) -> np.ndarray:
    """El loop: de start a end, y lo que sigue a end fundido en el inicio."""
    s, e, n = int(start * RATE), int(end * RATE), int(XFADE * RATE)
    loop = audio[s:e].copy()
    t = np.linspace(0, np.pi / 2, n, dtype=np.float32)[:, None]
    tail = audio[e:e + n]
    loop[:n] = loop[:n] * np.sin(t) + tail * np.cos(t)
    return loop


def encode(loop: np.ndarray, dst: Path) -> None:
    subprocess.run(
        ['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(RATE),
         '-ac', '2', '-i', '-', '-c:a', 'libvorbis', '-b:a', BITRATE,
         str(dst)],
        input=loop.astype(np.float32).tobytes(), check=True,
    )


def main() -> None:
    only = set(sys.argv[1:])  # Opcional: solo estos nombres.
    DST.mkdir(parents=True, exist_ok=True)
    for name, (file, min_start) in TRACKS.items():
        if only and name not in only:
            continue
        audio = decode(SRC / file)
        loop = best_loop(audio, min_start)
        dst = DST / f'{name}.ogg'
        encode(render(audio, loop['start'], loop['end']), dst)
        print(
            f'{dst.relative_to(ROOT)}: {file}, {loop["bpm"]:.0f} pulsos/min, '
            f'de {loop["start"]:.2f} s a {loop["end"]:.2f} s '
            f'({loop["end"] - loop["start"]:.1f} s), '
            f'parecido {loop["score"]:.3f}, {dst.stat().st_size // 1024} KB'
        )


if __name__ == '__main__':
    main()
