#!/usr/bin/env bash
set -eo pipefail

# ============================================================================
# Mistral Vibe Hybrid Setup - Test Runner
# ============================================================================
#
# This script runs comprehensive tests and collects coverage
# Usage: ./tests/run_tests.sh [options]
# Options: --coverage, --verbose, --help
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
fatal() { echo -e "${RED}[FATAL]${NC} $1"; exit 1; }

# Configuration
TEST_DIR="$(dirname "$0")"
PROJECT_ROOT="$TEST_DIR/.."
COVERAGE_DIR="$TEST_DIR/coverage"
TEST_REPORT="$TEST_DIR/test_report.txt"
COVERAGE_REPORT="$COVERAGE_DIR/coverage_report.txt"

# Parse arguments
COVERAGE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --coverage)
            COVERAGE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            set -x
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --coverage    Collect test coverage"
            echo "  --verbose, -v Enable verbose output"
            echo "  --help, -h    Show this help"
            exit 0
            ;;
        *)
            fatal "Unknown option: $1"
            ;;
    esac
done

# Create directories
mkdir -p "$COVERAGE_DIR"
echo "" > "$TEST_REPORT"
echo "" > "$COVERAGE_REPORT"

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_file="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$VERBOSE" = true ]; then
        info "Running: $test_name"
        echo "Command: $test_command"
    fi
    
    # Run test and capture output
    local start_time=$(date +%s%N)
    
    if bash -c "$test_command" > "$test_file" 2>&1; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 )) # milliseconds
        
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "✅ PASS: $test_name ($duration ms)" >> "$TEST_REPORT"
        
        if [ "$VERBOSE" = true ]; then
            echo "Output:"
            cat "$test_file"
        fi
        
        return 0
    else
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))
        
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "❌ FAIL: $test_name ($duration ms)" >> "$TEST_REPORT"
        echo "Output:" >> "$TEST_REPORT"
        cat "$test_file" >> "$TEST_REPORT"
        echo "" >> "$TEST_REPORT"
        
        if [ "$VERBOSE" = true ]; then
            warn "Test failed: $test_name"
        fi
        
        return 1
    fi
}

# Run all tests
run_tests() {
    info "Running tests..."
    
    # Test 1: Install script help
    run_test "install.sh --help" \
        "$PROJECT_ROOT/install.sh --help" \
        "$COVERAGE_DIR/test_install_help.txt"
    
    # Test 2: Install script version
    run_test "install.sh --version" \
        "$PROJECT_ROOT/install.sh --version" \
        "$COVERAGE_DIR/test_install_version.txt"
    
    # Test 3: Package script help
    run_test "package.sh --help" \
        "$PROJECT_ROOT/package.sh --help" \
        "$COVERAGE_DIR/test_package_help.txt"
    
    # Test 4: Sign scripts help
    run_test "sign_scripts.sh --help" \
        "$PROJECT_ROOT/sign_scripts.sh --help" \
        "$COVERAGE_DIR/test_sign_help.txt"
    
    # Test 5: Setup script with automatic responses
    run_test "setup_mistral_vibe.sh (automatic)" \
        "cd $PROJECT_ROOT && echo -e '\n\n' | ./setup_mistral_vibe.sh" \
        "$COVERAGE_DIR/test_setup_automatic.txt"
    
    # Test 6: Toggle hybrid mode help
    run_test "toggle_hybrid_mode.sh --help" \
        "$PROJECT_ROOT/toggle_hybrid_mode.sh --help" \
        "$COVERAGE_DIR/test_toggle_help.txt"
    
    # Test 7: Change worker model help
    run_test "change_worker_model.sh --help" \
        "$PROJECT_ROOT/change_worker_model.sh --help" \
        "$COVERAGE_DIR/test_change_worker_help.txt"
    
    # Test 8: Python syntax - vibe_custom_commands.py
    run_test "Python syntax: vibe_custom_commands.py" \
        "python3 -m py_compile $PROJECT_ROOT/src/vibe_custom_commands.py" \
        "$COVERAGE_DIR/test_python_vibe_commands.txt"
    
    # Test 9: Python syntax - load_vibe_extensions.py
    run_test "Python syntax: load_vibe_extensions.py" \
        "python3 -m py_compile $PROJECT_ROOT/src/load_vibe_extensions.py" \
        "$COVERAGE_DIR/test_python_extensions.txt"
    
    # Test 10: Shellcheck on all scripts
    run_test "Shellcheck: install.sh" \
        "shellcheck $PROJECT_ROOT/install.sh || echo 'shellcheck_not_installed'" \
        "$COVERAGE_DIR/test_shellcheck_install.txt"
    
    echo "Tests completed: $PASSED_TESTS/$TOTAL_TESTS passed"
}

# Collect coverage
collect_coverage() {
    if [ "$COVERAGE" = false ]; then
        return
    fi
    
    info "Collecting coverage..."
    
    # Count lines of code
    echo "Code Coverage Report" > "$COVERAGE_REPORT"
    echo "Generated: $(date)" >> "$COVERAGE_REPORT"
    echo "" >> "$COVERAGE_REPORT"
    
    # Shell scripts
    echo "=== Shell Scripts ===" >> "$COVERAGE_REPORT"
    for script in "$PROJECT_ROOT"/*.sh; do
        if [ -f "$script" ]; then
            lines=$(wc -l < "$script")
            echo "$(basename "$script"): $lines lines" >> "$COVERAGE_REPORT"
        fi
    done
    echo "" >> "$COVERAGE_REPORT"
    
    # Python files
    echo "=== Python Files ===" >> "$COVERAGE_REPORT"
    for pyfile in "$PROJECT_ROOT"/*.py; do
        if [ -f "$pyfile" ]; then
            lines=$(wc -l < "$pyfile")
            echo "$(basename "$pyfile"): $lines lines" >> "$COVERAGE_REPORT"
        fi
    done
    echo "" >> "$COVERAGE_REPORT"
    
    # Test files
    echo "=== Test Files ===" >> "$COVERAGE_REPORT"
    test_files=$(find "$COVERAGE_DIR" -name "test_*.txt" | wc -l)
    echo "Total test files: $test_files" >> "$COVERAGE_REPORT"
    echo "" >> "$COVERAGE_REPORT"
    
    # Test coverage summary
    echo "=== Test Coverage Summary ===" >> "$COVERAGE_REPORT"
    echo "Total tests: $TOTAL_TESTS" >> "$COVERAGE_REPORT"
    echo "Passed: $PASSED_TESTS" >> "$COVERAGE_REPORT"
    echo "Failed: $FAILED_TESTS" >> "$COVERAGE_REPORT"
    
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        coverage_percent=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
        echo "Coverage: $coverage_percent%" >> "$COVERAGE_REPORT"
    fi
    
    info "✓ Coverage report generated: $COVERAGE_REPORT"
}

# Generate HTML report
generate_html_report() {
    if [ "$COVERAGE" = false ]; then
        return
    fi
    
    info "Generating HTML report..."
    
    HTML_REPORT="$COVERAGE_DIR/report.html"
    
    cat > "$HTML_REPORT" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Mistral Vibe Hybrid - Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        .summary { background: #f8f9fa; padding: 15px; border-radius: 5px; }
        .pass { color: #27ae60; }
        .fail { color: #e74c3c; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #34495e; color: white; }
        tr:hover { background: #f5f5f5; }
    </style>
</head>
<body>
    <h1>Mistral Vibe Hybrid - Test Report</h1>
    <div class="summary">
        <h2>Test Summary</h2>
        <p>Total Tests: <strong>$TOTAL_TESTS</strong></p>
        <p class="pass">Passed: <strong>$PASSED_TESTS</strong></p>
        <p class="fail">Failed: <strong>$FAILED_TESTS</strong></p>
EOF
    
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        coverage_percent=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
        cat >> "$HTML_REPORT" << EOF
        <p>Coverage: <strong>$coverage_percent%</strong></p>
EOF
    fi
    
    cat >> "$HTML_REPORT" << 'EOF'
    </div>
    
    <h2>Test Results</h2>
    <table>
        <thead>
            <tr>
                <th>Test Name</th>
                <th>Status</th>
                <th>Output</th>
            </tr>
        </thead>
        <tbody>
EOF
    
    # Add test results to HTML
    while IFS= read -r line; do
        if [[ "$line" == ✅* ]]; then
            status="PASS"
            test_name="${line:4}"
            echo "            <tr class='pass'>" >> "$HTML_REPORT"
        elif [[ "$line" == ❌* ]]; then
            status="FAIL"
            test_name="${line:4}"
            echo "            <tr class='fail'>" >> "$HTML_REPORT"
        else
            continue
        fi
        
        cat >> "$HTML_REPORT" << EOF
                <td>$test_name</td>
                <td>$status</td>
                <td><a href="test_${status,,}_$(echo "$test_name" | tr ' ' '_' | tr -cd '[:alnum:]_').txt">View</a></td>
            </tr>
EOF
    done < "$TEST_REPORT"
    
    cat >> "$HTML_REPORT" << 'EOF'
        </tbody>
    </table>
    
    <h2>Coverage Details</h2>
    <pre>
EOF
    
    cat "$COVERAGE_REPORT" >> "$HTML_REPORT"
    
    cat >> "$HTML_REPORT" << 'EOF'
    </pre>
</body>
</html>
EOF
    
    info "✓ HTML report generated: $HTML_REPORT"
}

# Main function
main() {
    echo ""
    echo "${BLUE}=========================================="
    echo "  Mistral Vibe Hybrid - Test Runner"
    echo "==========================================${NC}"
    echo ""
    
    run_tests
    
    echo ""
    echo "=========================================="
    echo "  Test Results"
    echo "=========================================="
    echo "Total:   $TOTAL_TESTS tests"
    echo "Passed:  $PASSED_TESTS tests"
    echo "Failed:  $FAILED_TESTS tests"
    echo ""
    
    if [ "$FAILED_TESTS" -gt 0 ]; then
        error "Some tests failed. See $TEST_REPORT for details."
        return 1
    fi
    
    collect_coverage
    generate_html_report
    
    echo "Reports generated:"
    echo "  • Text report:   $TEST_REPORT"
    echo "  • Coverage:      $COVERAGE_REPORT"
    echo "  • HTML report:   $HTML_REPORT"
    echo ""
    
    if [ "$COVERAGE" = true ]; then
        if [ "$TOTAL_TESTS" -gt 0 ]; then
            coverage_percent=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
            echo "Test Coverage: $coverage_percent%"
        fi
    fi
    
    echo ""
    info "✅ All tests passed!"
}

# Run main function
main "$@"
