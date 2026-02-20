#!/bin/bash

# ============================================================
#  swaggerToPdf.sh
#  Converts a Swagger/OpenAPI JSON spec to a PDF document
#  Usage: ./swaggerToPdf.sh <swagger-json-url> [output-filename]
# ============================================================

set -euo pipefail

# ── Colours ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Defaults ─────────────────────────────────────────────────
DEFAULT_URL="https://xyz.com/swagger/v1/swagger.json"
SWAGGER_URL="${1:-$DEFAULT_URL}"
OUTPUT_PDF="${2:-api-docs.pdf}"
SWAGGER_JSON="./swagger.json"
HTML_FILE="./index.html"
WORK_DIR="$(pwd)"

# ── Helpers ──────────────────────────────────────────────────
log_info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

print_banner() {
  echo -e "${BOLD}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║       Swagger → PDF Generator        ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${NC}"
}

cleanup() {
  log_info "Cleaning up temporary files..."
  rm -f "$SWAGGER_JSON" "$HTML_FILE"
  # Remove other openapi-generator artifacts
  rm -f .openapi-generator-ignore 2>/dev/null || true
  rm -rf .openapi-generator 2>/dev/null || true
  log_success "Cleanup complete."
}

check_dependencies() {
  log_info "Checking dependencies..."
  for cmd in curl docker; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "'$cmd' is not installed or not in PATH."
    fi
  done
  if ! docker info &>/dev/null; then
    log_error "Docker daemon is not running."
  fi
  log_success "All dependencies found."
}

# ── Main ─────────────────────────────────────────────────────
print_banner

check_dependencies

# Step 1 — Download Swagger JSON
echo
log_info "Step 1/3 — Downloading Swagger spec from:"
echo -e "           ${CYAN}${SWAGGER_URL}${NC}"

curl -sf --max-time 30 "$SWAGGER_URL" -o "$SWAGGER_JSON" \
  || log_error "Failed to download Swagger JSON. Check the URL and network access."

if [ ! -s "$SWAGGER_JSON" ]; then
  log_error "Downloaded file is empty. The URL may not return a valid JSON spec."
fi

log_success "Swagger JSON saved → ${SWAGGER_JSON}"

# Step 2 — Generate HTML from Swagger JSON
echo
log_info "Step 2/3 — Generating HTML documentation..."

docker run --rm \
  -v "${WORK_DIR}:/local" \
  openapitools/openapi-generator-cli generate \
    -i /local/swagger.json \
    -g html \
    -o /local \
    --skip-validate-spec \
  2>&1 | grep -E "(ERROR|WARN|Successfully)" || true

if [ ! -f "$HTML_FILE" ]; then
  log_error "HTML generation failed. 'index.html' not found."
fi

log_success "HTML documentation generated → ${HTML_FILE}"

# Step 3 — Convert HTML to PDF using headless Chromium
echo
log_info "Step 3/3 — Converting HTML to PDF..."

docker run --rm \
  -v "${WORK_DIR}:/output" \
  zenika/alpine-chrome:with-node \
  chromium-browser --headless --no-sandbox \
    --print-to-pdf="/output/${OUTPUT_PDF}" \
    "file:///output/index.html" \
  2>&1 | grep -v "^$" || true

if [ ! -f "./${OUTPUT_PDF}" ]; then
  log_error "PDF generation failed. Output file not found."
fi

log_success "PDF generated → ${WORK_DIR}/${OUTPUT_PDF}"

# Cleanup temp files
echo
cleanup

# Done
echo
echo -e "${BOLD}${GREEN}  ✔ Done!${NC} Your API documentation is ready:"
echo -e "  📄 ${BOLD}${WORK_DIR}/${OUTPUT_PDF}${NC}"
echo
