# Elixir Project Template

A production-ready Elixir project template with best practices baked in.

## Features

- **Quality tooling**: Credo with strict checks, ExCoveralls for test coverage
- **CI/CD ready**: GitHub Actions workflow with formatting, linting, tests, and coverage
- **100% test coverage**: Configured with strict coverage requirements
- **Modern Elixir**: Set up for Elixir 1.17+ and OTP 27
- **Nix support**: Includes flake.nix for reproducible development environments

## Quick Start

```bash
# Clone template
git clone ~/dev/projects/_templates/elixir my_project
cd my_project

# Replace placeholders
./setup.sh my_app MyApp "My App Description"

# Or manually replace:
# - {{app_name}} → your_app (snake_case)
# - {{module_name}} → YourApp (PascalCase)
# - {{description}} → Your project description
```

## What's Included

### Configuration Files
- `.credo.exs` - Production-grade linting rules
- `.formatter.exs` - Code formatting (120 char line length)
- `coveralls.json` - 100% test coverage requirement
- `.gitignore` - Standard Elixir + Nix ignores

### CI/CD
- `.github/workflows/ci.yml` - Complete CI pipeline
  - Format checking
  - Credo linting (strict mode)
  - Compilation with warnings-as-errors
  - Test execution
  - Coverage reporting

### Project Structure
```
├── .github/workflows/
│   └── ci.yml
├── config/
│   ├── config.exs
│   └── test.exs
├── lib/
│   └── {{app_name}}.ex
├── test/
│   ├── {{app_name}}_test.exs
│   └── test_helper.exs
├── .credo.exs
├── .formatter.exs
├── .gitignore
├── coveralls.json
├── mix.exs
└── flake.nix
```

## Template Setup Script

The `setup.sh` script automates placeholder replacement:

```bash
./setup.sh <app_name> <ModuleName> "Description"
```

Example:
```bash
./setup.sh my_api MyApi "A REST API service"
```

## Manual Setup

If you prefer manual setup:

1. Replace `{{app_name}}` with your app name (snake_case)
2. Replace `{{module_name}}` with your module name (PascalCase)
3. Replace `{{description}}` with your project description
4. Update dependencies in `mix.exs` as needed
5. Remove template README and create your own

Files to update:
- `mix.exs`
- `lib/{{app_name}}.ex` (rename file)
- `test/{{app_name}}_test.exs` (rename file)
- `config/config.exs` (if using app-specific config)

## After Setup

```bash
# Get dependencies
mix deps.get

# Run tests
mix test

# Run linting
mix credo --strict

# Check formatting
mix format --check-formatted

# Run coverage
mix coveralls
```

## CI/CD

The template includes a GitHub Actions workflow that runs on push and PR:
- Format checking
- Credo linting (strict mode)
- Compilation with warnings-as-errors
- Tests
- Coverage reporting

## Customization

### Adjust Coverage Requirements

Edit `coveralls.json`:
```json
{
  "coverage_options": {
    "minimum_coverage": 90  // Change from 100
  }
}
```

### Modify Credo Rules

Edit `.credo.exs` to enable/disable specific checks in the `enabled` or `disabled` lists.

### Add Dependencies

Common additions:
```elixir
# Web framework
{:plug_cowboy, "~> 2.7"},

# Database
{:ecto_sql, "~> 3.12"},
{:postgrex, ">= 0.0.0"},

# JSON
{:jason, "~> 1.4"}
```

## License

This template is provided as-is for use in your projects.
