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

CODEGEN_INPUT="$INPUT"
TEMP_CODEGEN_INPUT=""
cleanup() {
  if [[ -n "$TEMP_CODEGEN_INPUT" && -f "$TEMP_CODEGEN_INPUT" ]]; then
    rm -f "$TEMP_CODEGEN_INPUT"
  fi
}
trap cleanup EXIT

if command -v node >/dev/null 2>&1; then
  TEMP_CODEGEN_INPUT="$(mktemp "${TMPDIR:-/tmp}/openapi-codegen-input.XXXXXX")"
  if node - "$INPUT" "$TEMP_CODEGEN_INPUT" <<'NODE'
const { readFileSync, writeFileSync } = require("node:fs");

const input = process.argv[2];
const output = process.argv[3];
const document = JSON.parse(readFileSync(input, "utf8"));
const methods = new Set(["get", "put", "post", "delete", "options", "head", "patch", "trace"]);

for (const pathItem of Object.values(document.paths ?? {})) {
  if (!pathItem || typeof pathItem !== "object") continue;
  for (const [method, operation] of Object.entries(pathItem)) {
    if (!methods.has(method) || !operation || typeof operation !== "object") continue;
    if (Array.isArray(operation.tags) && operation.tags.length > 1) {
      operation.tags = [operation.tags[0]];
    }
  }
}

writeFileSync(output, `${JSON.stringify(document, null, 2)}\n`);
NODE
  then
    CODEGEN_INPUT="$TEMP_CODEGEN_INPUT"
  else
    echo "Warning: could not normalize operation tags for code generation; using original input." >&2
    rm -f "$TEMP_CODEGEN_INPUT"
    TEMP_CODEGEN_INPUT=""
  fi
fi

npx @openapitools/openapi-generator-cli generate \
  -i "$CODEGEN_INPUT" \
  -g typescript-nestjs-server \
  -o "$OUTPUT" \
  -t "$TEMPLATE_DIR" \
  -c "$TEMPLATE_DIR/generator-config.yaml" \
  --additional-properties="npmName=$NAME,npmVersion=$VERSION,nestVersion=$NEST_VERSION,tsVersion=$TS_VERSION"

mkdir -p "$OUTPUT/api"
cp "$INPUT" "$OUTPUT/api/openapi.yaml"
