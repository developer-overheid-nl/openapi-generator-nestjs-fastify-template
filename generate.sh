#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT=""
OUTPUT=""
NAME="generated-api"
VERSION="1.0.0"
NEST_VERSION="11.0.0"
TS_VERSION="5.9.3"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      INPUT="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT="$2"
      shift 2
      ;;
    --name|--npm-name)
      NAME="$2"
      shift 2
      ;;
    --version|--npm-version)
      VERSION="$2"
      shift 2
      ;;
    --nest-version)
      NEST_VERSION="$2"
      shift 2
      ;;
    --ts-version)
      TS_VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Usage: $0 -i tools.openapi.yaml -o ./tools-api --name tools-api" >&2
  exit 2
fi

npx @openapitools/openapi-generator-cli generate \
  -i "$INPUT" \
  -g typescript-nestjs-server \
  -o "$OUTPUT" \
  -t "$TEMPLATE_DIR" \
  -c "$TEMPLATE_DIR/generator-config.yaml" \
  --additional-properties="npmName=$NAME,npmVersion=$VERSION,nestVersion=$NEST_VERSION,tsVersion=$TS_VERSION"

mkdir -p "$OUTPUT/api"
cp "$INPUT" "$OUTPUT/api/openapi.yaml"
