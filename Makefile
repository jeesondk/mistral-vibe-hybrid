.PHONY: lint format typecheck test test-shell test-python check all

# Run all checks (same as CI)
all: lint typecheck test

# Linting
lint:
	uv run ruff check src/ tests/python/
	uv run ruff format --check src/ tests/python/

# Auto-fix lint and format issues
format:
	uv run ruff check --fix src/ tests/python/
	uv run ruff format src/ tests/python/

# Type checking
typecheck:
	uv run mypy src/ --config-file mypy.ini

# All tests
test: test-shell test-python

# Shell script tests
test-shell:
	./tests/run_tests.sh

# Python tests with coverage
test-python:
	uv run pytest tests/python/ --cov=src --cov-report=term-missing

# Quick check: lint + typecheck (no tests)
check: lint typecheck
