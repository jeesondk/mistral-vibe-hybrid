#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Mistral Vibe Hybrid Setup - Shell Script Test Runner
# ============================================================================
#
# Runs behavioral tests against project shell scripts.
# Usage: ./tests/run_tests.sh [--verbose] [--help]
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

TOTAL=0
PASSED=0
FAILED=0
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=true; shift ;;
        --coverage)   shift ;;  # accepted for backwards compat, no-op
        --help|-h)
            echo "Usage: $0 [--verbose] [--help]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

pass() {
    PASSED=$((PASSED + 1))
    TOTAL=$((TOTAL + 1))
    echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
    echo -e "  ${RED}✗${NC} $1"
    if [[ -n "${2:-}" ]]; then
        echo -e "    ${YELLOW}→ $2${NC}"
    fi
}

section() {
    echo ""
    echo -e "${YELLOW}$1${NC}"
}

# Helper: run a command and check exit code
expect_success() {
    local desc="$1"; shift
    local output
    if output=$("$@" 2>&1); then
        if [[ "$VERBOSE" == true ]]; then
            echo "    output: $output"
        fi
        pass "$desc"
    else
        fail "$desc" "exit code $?, output: ${output:0:200}"
    fi
}

expect_failure() {
    local desc="$1"; shift
    local output
    if output=$("$@" 2>&1); then
        fail "$desc" "expected failure but got success"
    else
        if [[ "$VERBOSE" == true ]]; then
            echo "    output: $output"
        fi
        pass "$desc"
    fi
}

expect_output_contains() {
    local desc="$1"
    local pattern="$2"
    shift 2
    local output
    output=$("$@" 2>&1) || true
    if echo "$output" | grep -qi "$pattern"; then
        pass "$desc"
    else
        fail "$desc" "output did not contain '$pattern'"
    fi
}

# ============================================================================
# Shell syntax validation
# ============================================================================
section "Shell syntax validation (bash -n)"

for script in install.sh setup_mistral_vibe.sh start_llm_server.sh \
              change_worker_model.sh toggle_hybrid_mode.sh sign_scripts.sh \
              package.sh setup_uv.sh; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        expect_success "syntax: $script" bash -n "$PROJECT_ROOT/$script"
    else
        fail "syntax: $script" "file not found"
    fi
done

# ============================================================================
# Shellcheck (if available)
# ============================================================================
section "Shellcheck analysis"

if command -v shellcheck &>/dev/null; then
    for script in install.sh setup_mistral_vibe.sh start_llm_server.sh \
                  change_worker_model.sh toggle_hybrid_mode.sh; do
        if [[ -f "$PROJECT_ROOT/$script" ]]; then
            expect_success "shellcheck: $script" \
                shellcheck -S warning "$PROJECT_ROOT/$script"
        fi
    done
else
    echo -e "  ${YELLOW}⚠ shellcheck not installed, skipping${NC}"
fi

# ============================================================================
# install.sh behavioral tests
# ============================================================================
section "install.sh"

expect_success   "shows help with --help" "$PROJECT_ROOT/install.sh" --help
expect_success   "shows help with -h"     "$PROJECT_ROOT/install.sh" -h
expect_success   "shows version with --version" "$PROJECT_ROOT/install.sh" --version
expect_success   "shows version with -v"  "$PROJECT_ROOT/install.sh" -v
expect_output_contains "help includes usage info" "usage" \
    "$PROJECT_ROOT/install.sh" --help
expect_output_contains "version includes version number" "1\." \
    "$PROJECT_ROOT/install.sh" --version

# ============================================================================
# toggle_hybrid_mode.sh behavioral tests
# ============================================================================
section "toggle_hybrid_mode.sh"

expect_success "no-args shows usage/status" "$PROJECT_ROOT/toggle_hybrid_mode.sh"
expect_output_contains "no-args mentions hybrid or single" "hybrid\|single\|mode" \
    "$PROJECT_ROOT/toggle_hybrid_mode.sh"
expect_failure "rejects invalid command" "$PROJECT_ROOT/toggle_hybrid_mode.sh" invalidcmd123

# Test with a temp config dir
TEMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME"' EXIT
mkdir -p "$TEMP_HOME/.config/mistral_vibe/agents"

# Create a minimal config.json so toggle can read it
cat > "$TEMP_HOME/.config/mistral_vibe/config.json" << 'CONF'
{
  "providers": {
    "mistral-api": { "model": "devstral-medium-latest" },
    "local-llm": { "model": "mistral-3b" }
  }
}
CONF

expect_output_contains "status detects mode" "hybrid\|single\|mode" \
    env HOME="$TEMP_HOME" "$PROJECT_ROOT/toggle_hybrid_mode.sh" status

# ============================================================================
# change_worker_model.sh behavioral tests
# ============================================================================
section "change_worker_model.sh"

# --list with no models dir should handle gracefully
EMPTY_HOME="$(mktemp -d)"
mkdir -p "$EMPTY_HOME/.config/mistral_vibe"
expect_output_contains "--list mentions models" "model\|no\|found\|available" \
    env HOME="$EMPTY_HOME" "$PROJECT_ROOT/change_worker_model.sh" --list
rm -rf "$EMPTY_HOME"

# --list with a models dir containing fake gguf files
MODELS_HOME="$(mktemp -d)"
mkdir -p "$MODELS_HOME/models"
touch "$MODELS_HOME/models/test-model-1.gguf"
touch "$MODELS_HOME/models/test-model-2.gguf"
expect_output_contains "--list shows model files" "test-model" \
    env HOME="$MODELS_HOME" "$PROJECT_ROOT/change_worker_model.sh" --list
rm -rf "$MODELS_HOME"

# ============================================================================
# start_llm_server.sh behavioral tests
# ============================================================================
section "start_llm_server.sh"

expect_success "shows help with --help" "$PROJECT_ROOT/start_llm_server.sh" --help
expect_output_contains "help lists backends" "vllm\|llamacpp\|ollama" \
    "$PROJECT_ROOT/start_llm_server.sh" --help

# ============================================================================
# package.sh behavioral tests
# ============================================================================
section "package.sh"

expect_success "shows help with --help" "$PROJECT_ROOT/package.sh" --help
expect_output_contains "help mentions tar or zip" "tar\|zip\|package" \
    "$PROJECT_ROOT/package.sh" --help

# ============================================================================
# sign_scripts.sh behavioral tests
# ============================================================================
section "sign_scripts.sh"

expect_success "shows help with --help" "$PROJECT_ROOT/sign_scripts.sh" --help

# ============================================================================
# vibe-extended wrapper
# ============================================================================
section "vibe-extended"

expect_success "syntax: vibe-extended" bash -n "$PROJECT_ROOT/vibe-extended"

# ============================================================================
# Python syntax validation
# ============================================================================
section "Python syntax validation"

for pyfile in src/vibe_custom_commands.py src/load_vibe_extensions.py src/__init__.py; do
    if [[ -f "$PROJECT_ROOT/$pyfile" ]]; then
        expect_success "py_compile: $pyfile" \
            python3 -m py_compile "$PROJECT_ROOT/$pyfile"
    else
        fail "py_compile: $pyfile" "file not found"
    fi
done

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=========================================="
echo "  Results: $PASSED/$TOTAL passed, $FAILED failed"
echo "=========================================="

if [[ "$FAILED" -gt 0 ]]; then
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi

echo -e "${GREEN}All tests passed.${NC}"
