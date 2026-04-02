#!/bin/bash

# PARADIGMSOL3S ChatGPT Setup Script
# This script sets up OpenAI ChatGPT API access for the monorepo

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/chatgpt-setup.log"

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
echo "PARADIGMSOL3S ChatGPT Setup Script"
echo "==========================================="
log_info "Starting ChatGPT setup process..."

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

# Install OpenAI SDK
install_openai_sdk() {
    log_info "Installing OpenAI SDK..."
    
    if command -v pip3 &> /dev/null; then
        pip3 install --user openai
    else
        pip install --user openai
    fi
    
    if [ $? -eq 0 ]; then
        log_success "OpenAI SDK installed successfully"
    else
        log_error "Failed to install OpenAI SDK"
        return 1
    fi
}

# Setup environment variables
setup_environment() {
    log_info "Setting up environment variables..."
    
    ENV_FILE="$PROJECT_ROOT/.env"
    
    if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
        log_info "Created .env file at $ENV_FILE"
    fi
    
    # Check if OPENAI_API_KEY is already set
    if grep -q "OPENAI_API_KEY" "$ENV_FILE"; then
        log_warning "OPENAI_API_KEY already exists in .env file"
    else
        echo "# OpenAI API Key for ChatGPT access" >> "$ENV_FILE"
        echo "OPENAI_API_KEY=your_openai_api_key_here" >> "$ENV_FILE"
        log_info "Added OPENAI_API_KEY placeholder to .env file"
        log_warning "Please replace 'your_openai_api_key_here' with your actual OpenAI API key"
    fi
    
    log_success "Environment setup completed"
}

# Create a sample ChatGPT integration script
create_sample_script() {
    log_info "Creating sample ChatGPT integration script..."
    
    SAMPLE_SCRIPT="$PROJECT_ROOT/scripts/chatgpt_example.py"
    
    cat > "$SAMPLE_SCRIPT" << 'EOF'
#!/usr/bin/env python3
"""
PARADIGMSOL3S ChatGPT Integration Example
This script demonstrates how to connect to ChatGPT via OpenAI API
"""

import os
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

def chat_with_gpt(prompt, model="gpt-3.5-turbo"):
    """
    Send a prompt to ChatGPT and get a response
    """
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are a helpful assistant for PARADIGMSOL3S, the House of Soles decentralized footwear innovation project."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1000,
            temperature=0.7
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    # Example usage
    prompt = "Explain how blockchain can revolutionize the footwear industry."
    response = chat_with_gpt(prompt)
    print(f"ChatGPT Response: {response}")
EOF
    
    chmod +x "$SAMPLE_SCRIPT"
    log_success "Created sample ChatGPT script at $SAMPLE_SCRIPT"
}

# Main execution
main() {
    log_info "Running ChatGPT setup checks..."
    
    check_python || exit 1
    check_pip || exit 1
    
    install_openai_sdk || exit 1
    
    # Install python-dotenv for .env support
    log_info "Installing python-dotenv..."
    if command -v pip3 &> /dev/null; then
        pip3 install --user python-dotenv
    else
        pip install --user python-dotenv
    fi
    
    setup_environment || exit 1
    create_sample_script || exit 1
    
    log_success "ChatGPT setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Get your OpenAI API key from https://platform.openai.com/api-keys"
    echo "2. Replace 'your_openai_api_key_here' in .env with your actual API key"
    echo "3. Run the sample script: python3 scripts/chatgpt_example.py"
    echo "4. Integrate ChatGPT into your House of Soles x Aether applications"
}

main "$@"
