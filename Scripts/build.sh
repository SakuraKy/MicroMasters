#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/MicroMasters.xcodeproj"

xcodebuild -project "${PROJECT_PATH}" \
  -scheme MicroMasters \
  -configuration Release \
  build

