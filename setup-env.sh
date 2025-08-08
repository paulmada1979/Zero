#!/bin/bash

# Zero Email Environment Setup Script
# This script helps set up the environment variables for deployment

set -e

echo "🔧 Setting up Zero Email environment variables..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cloudflare Account ID
CLOUDFLARE_ACCOUNT_ID="5df48107ff73dbb67b96a31d3f9dae80"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Generate random secrets
generate_secret() {
    openssl rand -hex 32
}

# Create .env file
create_env_file() {
    print_status "Creating .env file..."
    
    # Generate secrets
    BETTER_AUTH_SECRET=$(generate_secret)
    AUTUMN_SECRET_KEY=$(generate_secret)
    
    cat > .env << EOF
# Application URLs
VITE_PUBLIC_APP_URL=https://mail.aididit.net
VITE_PUBLIC_BACKEND_URL=https://api.mail.aididit.net

# Database (Cloudflare D1)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/zerodotemail"

# Authentication
BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
BETTER_AUTH_URL=https://mail.aididit.net
COOKIE_DOMAIN="mail.aididit.net"

# Google OAuth (Required - You need to fill these)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Redis (Upstash or Cloudflare KV)
REDIS_URL="your_redis_url"
REDIS_TOKEN="your_redis_token"

# Email Service
RESEND_API_KEY=

# AI Services
OPENAI_API_KEY=
PERPLEXITY_API_KEY=
OPENAI_MODEL=gpt-4o
OPENAI_MINI_MODEL=gpt-4o-mini

# AI System Prompt
AI_SYSTEM_PROMPT=""

# Environment
NODE_ENV="production"

# Autumn (for file uploads)
AUTUMN_SECRET_KEY=${AUTUMN_SECRET_KEY}

# Twilio (for voice calls)
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# COMPOSIO Integration
COMPOSIO_API_KEY=ak_LAt1eI1u3Dgq1vo6H3v1

# Cloudflare Account ID
CLOUDFLARE_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID}
EOF

    print_success ".env file created"
    print_warning "Please fill in the required API keys and credentials"
}

# Show next steps
show_next_steps() {
    echo ""
    print_status "Next steps:"
    echo "1. Edit the .env file and fill in your API keys:"
    echo "   - GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET"
    echo "   - RESEND_API_KEY"
    echo "   - OPENAI_API_KEY"
    echo "   - PERPLEXITY_API_KEY"
    echo "   - TWILIO credentials (if using voice features)"
    echo "   - REDIS_URL and REDIS_TOKEN"
    echo ""
    echo "2. Setup Cloudflare resources:"
    echo "   ./setup-cloudflare.sh"
    echo ""
    echo "3. Run the deployment script:"
    echo "   ./deploy.sh"
    echo ""
    print_success "Environment setup completed!"
}

# Main function
main() {
    echo "=========================================="
    echo "Zero Email Environment Setup"
    echo "=========================================="
    echo ""
    
    if [ -f ".env" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Keeping existing .env file"
            show_next_steps
            exit 0
        fi
    fi
    
    create_env_file
    show_next_steps
}

# Run main function
main "$@" 