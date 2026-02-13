# Template Usage Guide

This is a production-ready Elixir project template extracted from real-world use.

## Features Summary

### Quality & Testing
- **Credo**: Strict linting with production-grade rules from 7Mind backend patterns
- **ExCoveralls**: 100% test coverage requirement by default
- **Format checking**: 120-character line length
- **Warnings as errors**: Catch issues early in CI

### CI/CD
- **GitHub Actions**: Complete pipeline with format, lint, compile, test, coverage
- **Matrix testing**: Elixir 1.17, 1.18 on OTP 27
- **Caching**: Dependencies cached for faster builds

### Development
- **Nix support**: Reproducible dev environments with flake.nix
- **Git attributes**: Proper Elixir diff handling

## Quick Start

### Option 1: Using setup.sh (Recommended)

```bash
# Clone or copy template
cp -r ~/dev/projects/_templates/elixir my_project
cd my_project

# Run setup script
./setup.sh my_app MyApp "My application description"

# Install dependencies
mix deps.get

# Verify setup
mix test
mix credo --strict
```

### Option 2: Manual Setup

```bash
# Clone or copy template
cp -r ~/dev/projects/_templates/elixir my_project
cd my_project

# Replace placeholders manually in these files:
# - mix.exs
# - config/config.exs
# - config/test.exs
# - lib/app.ex → lib/my_app.ex
# - test/app_test.exs → test/my_app_test.exs
# - .credo.exs

# Rename files
mv lib/app.ex lib/my_app.ex
mv test/app_test.exs test/my_app_test.exs

# Remove template files
rm setup.sh TEMPLATE_USAGE.md

# Install and verify
mix deps.get
mix test
```

## Placeholders

Replace these in your project:

- `{{app_name}}` - Your app name in snake_case (e.g., `my_api`)
- `{{module_name}}` - Your module name in PascalCase (e.g., `MyApi`)
- `{{description}}` - Project description

The setup.sh script handles all of this automatically.

## Project Structure

```
template/
├── .github/
│   └── workflows/
│       └── ci.yml          # GitHub Actions CI pipeline
├── config/
│   ├── config.exs          # Main config
│   └── test.exs            # Test config
├── lib/
│   └── app.ex              # Main module (rename to {{app_name}}.ex)
├── test/
│   ├── app_test.exs        # Main test (rename to {{app_name}}_test.exs)
│   └── test_helper.exs     # Test setup
├── .credo.exs              # Credo linting config
├── .formatter.exs          # Format config (120 char lines)
├── .gitattributes          # Git attributes for Elixir
├── .gitignore              # Standard Elixir + Nix ignores
├── coveralls.json          # Coverage config (100% required)
├── flake.nix               # Nix development environment
├── LICENSE                 # MIT license template
├── mix.exs                 # Mix project config
├── README.md               # Template README
└── setup.sh                # Automated setup script
```

## Common Workflows

### Development
```bash
# Get dependencies
mix deps.get

# Run tests
mix test

# Run tests with coverage
mix coveralls

# Run linter
mix credo --strict

# Check formatting
mix format --check-formatted

# Auto-format code
mix format
```

### CI/CD Checks
All of these run in CI on push/PR:
1. Format check
2. Credo (strict mode)
3. Compile (warnings as errors)
4. Tests
5. Coverage check

### Customization

#### Adjust Coverage Requirements
Edit `coveralls.json`:
```json
{
  "coverage_options": {
    "minimum_coverage": 90  // Lower from 100
  }
}
```

#### Modify Credo Rules
In `.credo.exs`, move checks between `enabled` and `disabled` lists.

Common adjustments:
- Enable `Credo.Check.Readability.Specs` for typespec enforcement
- Enable `Credo.Check.Readability.StrictModuleLayout` for consistent module structure
- Disable `Credo.Check.Readability.ModuleDoc` if you don't want to require module docs

#### Add Dependencies
Common additions in `mix.exs`:

```elixir
defp deps do
  [
    # Web
    {:plug_cowboy, "~> 2.7"},
    {:bandit, "~> 1.5"},  # Or use Bandit instead of Cowboy

    # Database
    {:ecto_sql, "~> 3.12"},
    {:postgrex, ">= 0.0.0"},

    # JSON
    {:jason, "~> 1.4"},

    # HTTP clients
    {:req, "~> 0.5"},
    {:finch, "~> 0.18"},

    # Testing
    {:bypass, "~> 2.1", only: :test},
    {:mox, "~> 1.1", only: :test},

    # Existing
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:excoveralls, "~> 0.18", only: :test}
  ]
end
```

## Integration with Nix

If using Nix:
```bash
# Enter dev shell
nix develop

# Or use direnv (add to .envrc)
use flake
```

The flake.nix includes Elixir 1.18 and OTP 27.

## Tips

1. **Start with strict quality**: The template has strict checks enabled. It's easier to start strict and relax later than to add strictness to a messy codebase.

2. **100% coverage goal**: The default 100% coverage target is intentional. It's easier to maintain from the start. Lower it only if you have a good reason.

3. **CI pipeline**: The GitHub Actions workflow is comprehensive. You can disable specific steps if needed, but having all checks is valuable.

4. **Module docs**: Credo requires module docs (`@moduledoc`). This is good practice but can be disabled if you prefer.

## Template Philosophy

This template embodies "production-grade from day one":

- **Quality gates**: Formatting, linting, and coverage are not optional
- **Fail fast**: Warnings are errors in CI
- **Strict rules**: Better to start strict and relax than add rigor later
- **Complete testing**: 100% coverage as default sets the right expectation

If you want a more relaxed starting point, adjust `.credo.exs` and `coveralls.json` after setup.

## Resources

- [Elixir Guide](https://elixir-lang.org/getting-started/introduction.html)
- [Mix Documentation](https://hexdocs.pm/mix/)
- [Credo](https://hexdocs.pm/credo/)
- [ExCoveralls](https://hexdocs.pm/excoveralls/)

## Tooling Research

Based on 2026 research, the Elixir ecosystem has several template generation tools:

- **mix_generator/mix_template**: Mix-based templating system
- **Exgen**: EEx-based template generation via Mix archives
- **gen_template_project**: Template system with `mix gen` task

This template uses a simple git-based approach with shell script automation, which is:
- Easy to understand and modify
- No additional tooling required
- Works with any text editor or IDE
- Easy to version control and share

For more advanced templating needs, consider exploring Mix generators or Exgen.
