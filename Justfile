# List all commands
default:
    @just --list

# Recompile local dependencies (after changes to path deps)
@compile-deps:
    mix deps.compile --force >/dev/null
    mix compile --force >/dev/null

# Run all tests
test: compile-deps
    mix test

# Run only tests affected by recent changes (faster)
test-stale: compile-deps
    mix test --stale

# Run all quality checks (compiler, formatter, credo, tests, coverage)
check: compile-deps
    mix check

# Print uncovered lines in file:line format
coverage-gaps: compile-deps
    #!/usr/bin/env bash
    mix coveralls.json > /dev/null 2>&1
    cat cover/excoveralls.json | jq -r '.source_files[] | select((.coverage | map(select(. == 0)) | length) > 0) | .name as $name | .coverage | to_entries | map(select(.value == 0) | "\($name):\(.key + 1)") | .[]'

# Generate and open HTML coverage report
coverage-html: compile-deps
    mix coveralls.html
    open cover/excoveralls.html

# Run linter
lint:
    mix credo --strict

# Format code
format:
    mix format

# Pre-commit gate: run by the global TDD commit-msg hook
pre-commit: check

# Pre-push gate: enforce 100% code coverage before pushing
pre-push: compile-deps
    mix coveralls
