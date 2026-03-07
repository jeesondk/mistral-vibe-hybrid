#!/usr/bin/env bash
set -eo pipefail

# ============================================================================
# Python 3.12 Migration Test Script
# ============================================================================
#
# This script tests that the Python 3.12 migration was successful
# It checks all configuration files and settings
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
success() { echo -e "${BLUE}[SUCCESS]${NC} $1"; }

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local test_name="$1"
    local test_command="$2"
    local expected="$3"
    
    info "Testing: $test_name"
    
    if bash -c "$test_command" 2>/dev/null | grep -q "$expected"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        success "✅ PASS: $test_name"
        return 0
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        fail "❌ FAIL: $test_name"
        return 1
    fi
}

# Main test function
main() {
    echo ""
    echo "${BLUE}=========================================="
    echo "  Python 3.12 Migration Test"
    echo "==========================================${NC}"
    echo ""
    
    # Test 1: Python version file
    run_test "Python version file" \
        "cat .python-version" \
        "3.12"
    
    # Test 2: CI workflow Python version
    run_test "CI workflow Python version" \
        "grep 'python-version' .github/workflows/ci.yml" \
        "3.12"
    
    # Test 3: Release workflow Python version
    run_test "Release workflow Python version" \
        "grep 'python-version' .github/workflows/release.yml" \
        "3.12"
    
    # Test 4: pyproject.toml Python requirement
    run_test "pyproject.toml Python requirement" \
        "grep 'requires-python' pyproject.toml" \
        "3.12"
    
    # Test 5: mypy Python version
    run_test "mypy Python version" \
        "grep 'python_version' pyproject.toml | head -1" \
        "3.12"
    
    # Test 6: black Python version
    run_test "black Python version" \
        "grep 'target-version' pyproject.toml" \
        "py312"
    
    # Test 7: setup_uv.sh default version
    run_test "setup_uv.sh default version" \
        "grep 'PYTHON_VERSION=' setup_uv.sh | grep '3.12'" \
        "3.12"
    
    # Test 8: UV guide version
    run_test "UV guide version" \
        "grep '3.12' docs/UV_GUIDE.md" \
        "3.12"
    
    # Test 9: CI/CD guide version
    run_test "CI/CD guide version" \
        "grep 'Set up Python 3.12' docs/CI_CD_GUIDE.md" \
        "3.12"
    
    echo ""
    echo "=========================================="
    echo "  Test Results"
    echo "=========================================="
    echo "Total:   $TOTAL_TESTS tests"
    echo "Passed:  $PASSED_TESTS tests"
    echo "Failed:  $FAILED_TESTS tests"
    echo ""
    
    if [ "$FAILED_TESTS" -gt 0 ]; then
        fail "Some tests failed. Python 3.12 migration may be incomplete."
    fi
    
    # Calculate success rate
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        SUCCESS_RATE=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
        success "Migration complete: $SUCCESS_RATE% success rate"
    fi
    
    echo ""
    echo "All Python 3.12 migration tests passed! ✅"
}

# Run main function
main "$@"
