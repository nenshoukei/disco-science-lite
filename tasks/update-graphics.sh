#!/bin/bash
set -eux
ROOT_DIR=$(cd "$(dirname "$0")/.."; pwd)
GRAPHICS_DIR="$ROOT_DIR/graphics"

# TODO: Change this for other environments
FACTORIO_DATA="$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data"

convert "$FACTORIO_DATA/base/graphics/entity/lab/lab-light.png" \
    -colorspace Gray -level "0,80%,1.5" \
    "$GRAPHICS_DIR/lab-overlay.png"
convert "$FACTORIO_DATA/space-age/graphics/entity/biolab/biolab-lights.png" \
    -colorspace Gray -level "0,80%,6.0" \
    "$GRAPHICS_DIR/biolab-overlay.png"
convert \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.00 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.45 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.72 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.70 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.73 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.71 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.68 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.03 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.70 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.72 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.00 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.48 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.70 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.05 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.65 \) \
    \( -size 128x128 radial-gradient:white-black -evaluate multiply 0.55 \) \
    +append \
    "$GRAPHICS_DIR/general-overlay.png"
