"""Convierte los dibujos de arte/ a WebP con transparencia para la app.

    python3 tool/convert_art.py

- arte/objetos/<id>.jpeg     -> assets/items/<id>.webp       (256×256)
- arte/personajes/<id>.jpeg  -> assets/characters/<id>.webp  (512×512)

Saca el fondo blanco solo en la zona clara que toca el borde (lo blanco de
adentro del dibujo queda), y deja el brillo de alrededor semitransparente.
Necesita: python3-pil, python3-numpy, python3-scipy y cwebp.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
JOBS = [
    (ROOT / 'arte/objetos', ROOT / 'assets/items', 256),
    (ROOT / 'arte/personajes', ROOT / 'assets/characters', 512),
]
WORK_SIZE = 768  # Se procesa a este tamaño (más rápido que 2048).
LIGHT = 70  # Hasta esta distancia al blanco, un píxel puede ser fondo.
CLEAR = 10  # Hasta esta distancia al blanco, es fondo totalmente transparente.
PADDING = 0.04  # Margen alrededor del dibujo, en proporción del lado.
QUALITY = '82'


def remove_white(img: Image.Image) -> Image.Image:
    rgb = np.asarray(img.convert('RGB'), dtype=np.float32)
    dist = 255.0 - rgb.min(axis=2)  # 0 = blanco puro.

    # Zona clara conectada al borde de la imagen.
    labels, _ = ndimage.label(dist < LIGHT)
    border = np.unique(
        np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])
    )
    border = border[border != 0]
    background = np.isin(labels, border)

    # Rampa suave: blanco -> transparente, cerca del dibujo -> opaco.
    alpha = np.ones(dist.shape, dtype=np.float32)
    ramp = np.clip((dist - CLEAR) / (LIGHT - CLEAR), 0.0, 1.0)
    alpha[background] = ramp[background]

    # Quitar el blanco mezclado: c = a·c' + (1-a)·255.
    safe = np.maximum(alpha, 1e-3)[..., None]
    color = 255.0 - (255.0 - rgb) / safe
    color = np.where(alpha[..., None] > 0, color, 0)
    out = np.dstack([np.clip(color, 0, 255), alpha * 255.0]).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def fit_square(img: Image.Image, size: int) -> Image.Image:
    alpha = np.asarray(img)[..., 3]
    ys, xs = np.nonzero(alpha > 12)
    if len(xs) == 0:
        return img.resize((size, size), Image.LANCZOS)
    box = img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    side = int(max(box.size) * (1 + 2 * PADDING))
    square = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    square.paste(box, ((side - box.width) // 2, (side - box.height) // 2))
    return square.resize((size, size), Image.LANCZOS)


def convert(src: Path, dst: Path, size: int) -> None:
    img = Image.open(src)
    img.thumbnail((WORK_SIZE, WORK_SIZE), Image.LANCZOS)
    result = fit_square(remove_white(img), size)
    with tempfile.NamedTemporaryFile(suffix='.png') as tmp:
        result.save(tmp.name)
        subprocess.run(
            ['cwebp', '-quiet', '-q', QUALITY, '-alpha_q', '90', tmp.name,
             '-o', str(dst)],
            check=True,
        )


def main() -> None:
    only = set(sys.argv[1:])  # Opcional: convertir solo estos id.
    for src_dir, dst_dir, size in JOBS:
        dst_dir.mkdir(parents=True, exist_ok=True)
        for src in sorted(src_dir.glob('*.jp*g')) + sorted(src_dir.glob('*.png')):
            if only and src.stem not in only:
                continue
            dst = dst_dir / f'{src.stem}.webp'
            convert(src, dst, size)
            print(f'{dst.relative_to(ROOT)}  {dst.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main()
