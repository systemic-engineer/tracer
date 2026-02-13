# Changelog

All notable changes to this template will be documented in this file.

## [0.1.0] - 2026-02-13

### Added
- Initial template creation
- Production-grade Credo configuration from 7Mind backend patterns
- ExCoveralls with 100% coverage requirement
- GitHub Actions CI pipeline with:
  - Format checking
  - Credo linting (strict mode)
  - Compilation with warnings-as-errors
  - Test execution
  - Coverage reporting
  - Matrix testing (Elixir 1.17, 1.18 on OTP 27)
- Automated setup.sh script for quick project initialization
- Nix flake for reproducible development environments
- Comprehensive documentation:
  - README.md - Quick start guide
  - TEMPLATE_USAGE.md - Detailed usage instructions
  - Inline comments in all config files

### Configuration Files
- `.credo.exs` - Strict linting with 95+ enabled checks
- `.formatter.exs` - 120-character line length
- `coveralls.json` - 100% coverage minimum
- `.gitignore` - Standard Elixir + Nix ignores
- `.gitattributes` - Proper Elixir diff handling
- `flake.nix` - Nix development shell

### Features
- Template placeholder system ({{app_name}}, {{module_name}}, {{description}})
- Automated file renaming in setup script
- Production-ready from day one philosophy
- Comprehensive quality gates in CI

### Template Structure
```
elixir/
├── .github/workflows/ci.yml
├── config/
│   ├── config.exs
│   └── test.exs
├── lib/app.ex
├── test/
│   ├── app_test.exs
│   └── test_helper.exs
├── Configuration files (.credo.exs, .formatter.exs, etc.)
├── Documentation (README.md, TEMPLATE_USAGE.md)
└── setup.sh
```

### Research
Evaluated Elixir template generation tools:
- mix_generator/mix_template
- Exgen
- gen_template_project

Chose simple git-based approach for:
- Simplicity and transparency
- No additional tooling dependencies
- Easy customization
- Universal compatibility
