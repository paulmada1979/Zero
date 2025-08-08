#!/bin/bash

# Zero Email Deployment Script for Cloudflare Workers
# This script automates the deployment process

set -e

echo "🚀 Starting Zero Email deployment to Cloudflare Workers..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cloudflare Account ID
CLOUDFLARE_ACCOUNT_ID="5df48107ff73dbb67b96a31d3f9dae80"

# Function to print colored output
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

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v pnpm &> /dev/null; then
        print_error "pnpm is not installed"
        exit 1
    fi
    
    if ! command -v wrangler &> /dev/null; then
        print_error "wrangler is not installed. Install with: npm install -g wrangler"
        exit 1
    fi
    
    print_success "All requirements met"
}

# Set Cloudflare account ID
set_account_id() {
    print_status "Setting Cloudflare account ID: $CLOUDFLARE_ACCOUNT_ID"
    export CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID"
    print_success "Account ID set"
}

# Check if .env file exists
check_env_file() {
    print_status "Checking environment file..."
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found. Please create it with the required variables."
        print_status "You can run 'pnpm nizzy env' to set it up interactively."
        exit 1
    fi
    
    print_success "Environment file found"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    pnpm install
    print_success "Dependencies installed"
}

# Sync environment variables
sync_env() {
    print_status "Syncing environment variables..."
    pnpm nizzy sync
    print_success "Environment variables synced"
}

# Build applications
build_applications() {
    print_status "Building applications..."
    
    # Build mail application (React Router app)
    print_status "Building mail application..."
    cd apps/mail
    pnpm build
    cd ../..
    
    # Server doesn't need a build step for Cloudflare Workers
    print_status "Server application is ready for deployment (no build needed for Cloudflare Workers)"
    
    print_success "Applications prepared for deployment"
}

# Deploy to Cloudflare
deploy_to_cloudflare() {
    print_status "Deploying to Cloudflare Workers..."
    
    # Deploy server first
    print_status "Deploying server application..."
    cd apps/server
    wrangler deploy --env production
    cd ../..
    
    # Deploy mail application
    print_status "Deploying mail application..."
    cd apps/mail
    wrangler deploy --env production
    cd ../..
    
    print_success "Deployment completed"
}

# Set up environment variables in Cloudflare
setup_cloudflare_secrets() {
    print_status "Setting up Cloudflare secrets..."
    
    # List of secrets to set
    secrets=(
        "BETTER_AUTH_SECRET"
        "GOOGLE_CLIENT_ID"
        "GOOGLE_CLIENT_SECRET"
        "RESEND_API_KEY"
        "OPENAI_API_KEY"
        "PERPLEXITY_API_KEY"
        "AUTUMN_SECRET_KEY"
        "TWILIO_ACCOUNT_SID"
        "TWILIO_AUTH_TOKEN"
        "TWILIO_PHONE_NUMBER"
        "COMPOSIO_API_KEY"
    )
    
    for secret in "${secrets[@]}"; do
        print_status "Setting $secret..."
        echo "Please enter the value for $secret:"
        read -s secret_value
        wrangler secret put "$secret" --env production --name "$secret_value"
    done
    
    print_success "Cloudflare secrets configured"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check server health
    print_status "Checking server health..."
    if curl -f -s "https://api.mail.aididit.net/health" > /dev/null; then
        print_success "Server is healthy"
    else
        print_warning "Server health check failed"
    fi
    
    # Check main application
    print_status "Checking main application..."
    if curl -f -s "https://mail.aididit.net" > /dev/null; then
        print_success "Main application is accessible"
    else
        print_warning "Main application check failed"
    fi
    
    print_success "Deployment verification completed"
}

# Main deployment function
main() {
    echo "=========================================="
    echo "Zero Email Cloudflare Workers Deployment"
    echo "=========================================="
    echo ""
    
    check_requirements
    set_account_id
    check_env_file
    install_dependencies
    sync_env
    build_applications
    deploy_to_cloudflare
    
    echo ""
    print_status "Deployment completed! 🎉"
    echo ""
    print_status "Next steps:"
    echo "1. Configure your DNS records in Cloudflare dashboard"
    echo "2. Set up custom domains for your workers"
    echo "3. Run database migrations: cd apps/server && pnpm db:migrate"
    echo "4. Set up environment variables in Cloudflare dashboard"
    echo ""
    print_status "Your application should be available at:"
    echo "- Main app: https://mail.aididit.net"
    echo "- API: https://api.mail.aididit.net"
    echo ""
}

# Run main function
main "$@" 