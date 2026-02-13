#!/usr/bin/env bash
# Setup script for Elixir project template
# Usage: ./setup.sh <app_name> <ModuleName> "Description"

set -e

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <app_name> <ModuleName> [description]"
  echo ""
  echo "Example:"
  echo "  $0 my_api MyApi 'A REST API service'"
  echo ""
  exit 1
fi

APP_NAME="$1"
MODULE_NAME="$2"
DESCRIPTION="${3:-An Elixir application}"

echo "Setting up Elixir project..."
echo "  App name: $APP_NAME"
echo "  Module name: $MODULE_NAME"
echo "  Description: $DESCRIPTION"
echo ""

# Validate app_name (should be snake_case)
if ! [[ "$APP_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Error: app_name must be lowercase snake_case (e.g., my_app)"
  exit 1
fi

# Validate module_name (should be PascalCase)
if ! [[ "$MODULE_NAME" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
  echo "Error: ModuleName must be PascalCase (e.g., MyApp)"
  exit 1
fi

# Function to replace placeholders in files
replace_in_file() {
  local file="$1"
  if [ -f "$file" ]; then
    sed -i.bak \
      -e "s/{{app_name}}/$APP_NAME/g" \
      -e "s/{{module_name}}/$MODULE_NAME/g" \
      -e "s/{{description}}/$DESCRIPTION/g" \
      "$file"
    rm "${file}.bak"
    echo "  ✓ Updated $file"
  fi
}

# Replace in all template files
echo "Replacing placeholders..."
replace_in_file "mix.exs"
replace_in_file "config/config.exs"
replace_in_file "config/test.exs"
replace_in_file "lib/app.ex"
replace_in_file "test/app_test.exs"
replace_in_file ".credo.exs"

# Rename files
echo ""
echo "Renaming files..."
if [ -f "lib/app.ex" ]; then
  mv "lib/app.ex" "lib/${APP_NAME}.ex"
  echo "  ✓ Renamed lib/app.ex → lib/${APP_NAME}.ex"
fi

if [ -f "test/app_test.exs" ]; then
  mv "test/app_test.exs" "test/${APP_NAME}_test.exs"
  echo "  ✓ Renamed test/app_test.exs → test/${APP_NAME}_test.exs"
fi

# Clean up
echo ""
echo "Cleaning up..."
rm -f setup.sh
echo "  ✓ Removed setup.sh"

# Initialize git if not already
if [ ! -d ".git" ]; then
  echo ""
  echo "Initializing git repository..."
  git init
  git add .
  git commit -m "Initial commit from template"
  echo "  ✓ Git repository initialized"
fi

echo ""
echo "✨ Project setup complete!"
echo ""
echo "Next steps:"
echo "  1. cd into your project directory"
echo "  2. Run 'mix deps.get' to install dependencies"
echo "  3. Run 'mix test' to verify everything works"
echo "  4. Start coding!"
echo ""
