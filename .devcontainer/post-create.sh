#!/usr/bin/env bash
# Se corre una vez al crear el contenedor (postCreateCommand).
set -euo pipefail

# Los volúmenes se montan como root: se los damos al usuario vscode.
sudo chown -R vscode:vscode \
  /home/vscode/.gradle /home/vscode/.pub-cache /home/vscode/.claude /home/vscode/.android

# Clave de debug: la app instalada en el celular está firmada con ella.
# Si el volumen está vacío (primera vez), se restaura la copia del proyecto
# para que el celular acepte las actualizaciones sin desinstalar la app.
backup=".devcontainer/android-keys/debug.keystore"
if [ ! -f /home/vscode/.android/debug.keystore ] && [ -f "$backup" ]; then
  cp "$backup" /home/vscode/.android/debug.keystore
  echo "Clave de debug restaurada desde $backup"
fi

flutter --version
if [ -f pubspec.yaml ]; then flutter pub get; fi
