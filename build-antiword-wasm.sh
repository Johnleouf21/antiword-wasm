#!/usr/bin/env bash
# Build antiword -> WebAssembly (sortie DocBook XML, encodage UTF-8)
# Produit un fichier unique antiword.js (wasm + ressources embarqués en base64).
#
# Prérequis : git, python3, et emsdk (installé par ce script si absent).
# Testé pour produire un artefact chargeable via @require dans un userscript.

set -euo pipefail
WORK="${PWD}/antiword-wasm-build"
mkdir -p "$WORK" && cd "$WORK"

# ---------------------------------------------------------------- 1. emsdk
if ! command -v emcc >/dev/null 2>&1; then
  if [ ! -d emsdk ]; then
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git
  fi
  cd emsdk
  ./emsdk install latest
  ./emsdk activate latest
  # shellcheck disable=SC1091
  source ./emsdk_env.sh
  cd ..
fi
emcc --version | head -1

# ------------------------------------------------------------- 2. antiword
if [ ! -d antiword ]; then
  git clone --depth 1 https://github.com/grobian/antiword.git
fi
cd antiword

# Ressources STRICTEMENT nécessaires (validé : sans le mapping, antiword refuse
# de convertir et sort l'usage ; fontnames évite un warning sur stderr).
# 4,8 Ko au lieu des 412 Ko du dossier Resources complet.
mkdir -p wasmres
cp Resources/UTF-8.txt Resources/fontnames wasmres/

# ------------------------------------------------------------- 3. compile
# Liste des sources = celle du Makefile.Linux (52 fichiers).
SRCS=$(sed -n '/^OBJS/,/^$/p' Makefile.Linux | tr -d '\\' \
       | tr -s ' \t\n' '\n' | grep '\.o$' | sed 's/\.o/.c/' | tr '\n' ' ')

emcc $SRCS \
  -O2 \
  -DNDEBUG \
  -DGLOBAL_ANTIWORD_DIR='"/usr/share/antiword"' \
  -Wno-everything \
  --embed-file wasmres/UTF-8.txt@/usr/share/antiword/UTF-8.txt \
  --embed-file wasmres/fontnames@/usr/share/antiword/fontnames \
  -sINVOKE_RUN=0 \
  -sEXIT_RUNTIME=0 \
  -sFORCE_FILESYSTEM=1 \
  -sALLOW_MEMORY_GROWTH=1 \
  -sMODULARIZE=1 \
  -sEXPORT_NAME=createAntiword \
  -sEXPORTED_RUNTIME_METHODS=callMain,FS \
  -sSINGLE_FILE=1 \
  -sENVIRONMENT=web \
  -o ../antiword.js

cd ..
ls -lh antiword.js
echo
echo "OK -> $WORK/antiword.js"
echo "Héberge ce fichier (CDN, Vercel...) et pointe le @require du userscript dessus."
echo "Il ne contient AUCUNE donnée patient : juste le binaire + les tables de charset."
