#!/bin/bash

# PARADIGMSOL3S Gemini CLI Setup Script
# This script sets up Google's Gemini AI CLI tools for the monorepo

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/gemini-setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Create logs directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/logs"

echo "==========================================="
echo "PARADIGMSOL3S Gemini CLI Setup Script"
echo "==========================================="
log_info "Starting Gemini CLI setup process..."

# Check if Python is installed
check_python() {
    log_info "Checking Python installation..."
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        log_success "Python3 found: $PYTHON_VERSION"
        return 0
    elif command -v python &> /dev/null; then
        PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
        log_success "Python found: $PYTHON_VERSION"
        return 0
    else
        log_error "Python is not installed. Please install Python 3.8 or higher."
        return 1
    fi
}

# Check if pip is installed
check_pip() {
    log_info "Checking pip installation..."
    if command -v pip3 &> /dev/null; then
        PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $2}')
        log_success "pip3 found: $PIP_VERSION"
        return 0
    elif command -v pip &> /dev/null; then
        PIP_VERSION=$(pip --version 2>&1 | awk '{print $2}')
        log_success "pip found: $PIP_VERSION"
        return 0
    else
        log_error "pip is not installed. Please install pip."
        return 1
    fi
}

# Install Google Generative AI SDK
install_gemini_sdk() {
    log_info "Installing Google Generative AI SDK..."
    
    if command -v pip3 &> /dev/null; then
        pip3 install --user google-generativeai
    else
        pip install --user google-generativeai
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Google Generative AI SDK installed successfully"
    else
        log_error "Failed to install Google Generative AI SDK"
        return 1
    fi
}

# Install additional AI/ML dependencies
install_ai_dependencies() {
    log_info "Installing additional AI/ML dependencies..."
    
    REQUIREMENTS="
openai
requests
jsonschema
pyyaml
click
colorama
tqdm
"
    
    echo "$REQUIREMENTS" > "$PROJECT_ROOT/requirements-ai.txt"
    
    if command -v pip3 &> /dev/null; then
        pip3 install --user -r "$PROJECT_ROOT/requirements-ai.txt"
    else
        pip install --user -r "$PROJECT_ROOT/requirements-ai.txt"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Additional AI dependencies installed successfully"
    else
        log_error "Failed to install additional AI dependencies"
        return 1
    fi
}

# Create Gemini configuration directory
setup_config_dir() {
    log_info "Setting up configuration directory..."
    
    CONFIG_DIR="$HOME/.config/paradigmsol3s-gemini"
    mkdir -p "$CONFIG_DIR"
    
    # Create sample configuration file
    cat > "$CONFIG_DIR/config.yaml" << EOF
# PARADIGMSOL3S Gemini AI Configuration
api:
  gemini_api_key: ""
  openai_api_key: ""
  model_preferences:
    primary: "gemini-pro"
    fallback: "gpt-3.5-turbo"

settings:
  max_tokens: 4000
  temperature: 0.7
  top_p: 0.9
  
logging:
  level: "INFO"
  file: "$PROJECT_ROOT/logs/gemini-cli.log"
  
projects:
  paradigmsol3s:
    path: "$PROJECT_ROOT"
    context: "Decentralized footwear innovation platform"
EOF

    log_success "Configuration directory created at: $CONFIG_DIR"
}

# Create Gemini CLI wrapper script
create_cli_wrapper() {
    log_info "Creating Gemini CLI wrapper script..."
    
    CLI_SCRIPT="$PROJECT_ROOT/scripts/gemini-cli.py"
    
    cat > "$CLI_SCRIPT" << 'EOF'
#!/usr/bin/env python3
"""
PARADIGMSOL3S Gemini CLI Tool
A command-line interface for Google's Gemini AI integration
"""

import os
import sys
import yaml
import json
import click
import logging
from pathlib import Path

try:
    import google.generativeai as genai
except ImportError:
    print("Error: google-generativeai not installed. Run: pip install google-generativeai")
    sys.exit(1)

# Configuration
CONFIG_DIR = Path.home() / ".config" / "paradigmsol3s-gemini"
CONFIG_FILE = CONFIG_DIR / "config.yaml"

def load_config():
    """Load configuration from YAML file"""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, 'r') as f:
            return yaml.safe_load(f)
    return {}

def setup_logging(config):
    """Setup logging based on configuration"""
    log_level = config.get('logging', {}).get('level', 'INFO')
    log_file = config.get('logging', {}).get('file', 'gemini-cli.log')
    
    logging.basicConfig(
        level=getattr(logging, log_level),
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler(sys.stdout)
        ]
    )

@click.group()
@click.pass_context
def cli(ctx):
    """PARADIGMSOL3S Gemini CLI Tool"""
    ctx.ensure_object(dict)
    config = load_config()
    ctx.obj['config'] = config
    setup_logging(config)

@cli.command()
@click.argument('prompt')
@click.option('--model', default=None, help='AI model to use')
@click.option('--temperature', default=None, type=float, help='Temperature setting')
@click.option('--output', '-o', help='Output file')
@click.pass_context
def generate(ctx, prompt, model, temperature, output):
    """Generate AI response for a given prompt"""
    config = ctx.obj['config']
    
    # Configure API key
    api_key = config.get('api', {}).get('gemini_api_key') or os.getenv('GEMINI_API_KEY')
    if not api_key:
        click.echo("Error: Gemini API key not configured. Set GEMINI_API_KEY environment variable.")
        return
    
    genai.configure(api_key=api_key)
    
    # Set model
    model_name = model or config.get('api', {}).get('model_preferences', {}).get('primary', 'gemini-pro')
    model = genai.GenerativeModel(model_name)
    
    # Set temperature
    temp = temperature or config.get('settings', {}).get('temperature', 0.7)
    
    try:
        response = model.generate_content(prompt)
        result = response.text
        
        if output:
            with open(output, 'w') as f:
                f.write(result)
            click.echo(f"Response saved to: {output}")
        else:
            click.echo(result)
            
    except Exception as e:
        logging.error(f"Error generating response: {e}")
        click.echo(f"Error: {e}")

@cli.command()
@click.pass_context
def config_show(ctx):
    """Show current configuration"""
    config = ctx.obj['config']
    click.echo(json.dumps(config, indent=2))

@cli.command()
@click.option('--key', required=True, help='Configuration key to set')
@click.option('--value', required=True, help='Configuration value to set')
def config_set(key, value):
    """Set configuration value"""
    click.echo(f"Setting {key} = {value}")
    # Implementation for setting config values

if __name__ == '__main__':
    cli()
EOF

    chmod +x "$CLI_SCRIPT"
    log_success "Gemini CLI wrapper created at: $CLI_SCRIPT"
}

# Create usage documentation
create_documentation() {
    log_info "Creating documentation..."
    
    DOC_FILE="$PROJECT_ROOT/docs/gemini-cli-usage.md"
    mkdir -p "$PROJECT_ROOT/docs"
    
    cat > "$DOC_FILE" << 'EOF'
# Gemini CLI Usage Guide

## Setup

1. Run the setup script: `./scripts/gemini-cli-setup.sh`
2. Set your API key: `export GEMINI_API_KEY="your-api-key-here"`
3. Test the installation: `python3 ./scripts/gemini-cli.py --help`

## Configuration

Configuration file location: `~/.config/paradigmsol3s-gemini/config.yaml`

## Usage Examples

### Generate AI response
```bash
python3 ./scripts/gemini-cli.py generate "Explain blockchain technology for footwear"
```

### Save response to file
```bash
python3 ./scripts/gemini-cli.py generate "Write a smart contract for shoe authenticity" -o contract.md
```

### Use specific model
```bash
python3 ./scripts/gemini-cli.py generate "Design NFT metadata structure" --model gemini-pro
```

### Show configuration
```bash
python3 ./scripts/gemini-cli.py config-show
```

## Environment Variables

- `GEMINI_API_KEY`: Your Google Gemini API key
- `OPENAI_API_KEY`: Your OpenAI API key (fallback)

## Integration with Workflows

The Gemini CLI is integrated with the repository's GitHub Actions workflows for:
- Automated code review
- Documentation generation
- Architecture suggestions
- Security analysis
EOF

    log_success "Documentation created at: $DOC_FILE"
}

# Main setup function
main() {
    log_info "Starting PARADIGMSOL3S Gemini CLI setup..."
    
    # Check prerequisites
    check_python || exit 1
    check_pip || exit 1
    
    # Install dependencies
    install_gemini_sdk || exit 1
    install_ai_dependencies || exit 1
    
    # Setup configuration and scripts
    setup_config_dir
    create_cli_wrapper
    create_documentation
    
    echo
    log_success "Gemini CLI setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Set your API key: export GEMINI_API_KEY='your-api-key-here'"
    echo "2. Test installation: python3 ./scripts/gemini-cli.py --help"
    echo "3. Read documentation: cat docs/gemini-cli-usage.md"
    echo
    log_info "Setup process finished."
}

# Run main function
main "$@"
