#!/bin/bash

# Zero Email Deployment Script for Cloudflare Workers
# This script automates the deployment process

set -e

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --server   Deploy only the server"
    echo "  -m, --mail     Deploy only the mail app"
    echo "  -v, --verify   Verify deployment after completion"
    echo ""
    echo "Examples:"
    echo "  $0              # Deploy everything"
    echo "  $0 --server     # Deploy only server"
    echo "  $0 --mail       # Deploy only mail app"
    echo "  $0 --verify     # Deploy and verify"
    echo ""
    echo "For troubleshooting, check the logs at: ~/.wrangler/logs/"
}

# Parse command line arguments
DEPLOY_SERVER=true
DEPLOY_MAIL=true
VERIFY_DEPLOYMENT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--server)
            DEPLOY_MAIL=false
            shift
            ;;
        -m|--mail)
            DEPLOY_SERVER=false
            shift
            ;;
        -v|--verify)
            VERIFY_DEPLOYMENT=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

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
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. Deployment status will be limited."
        print_status "Install jq for better deployment status reporting:"
        print_status "  macOS: brew install jq"
        print_status "  Ubuntu/Debian: sudo apt-get install jq"
        print_status "  CentOS/RHEL: sudo yum install jq"
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

# Show build configuration
show_build_config() {
    print_status "Current build configuration:"
    echo ""
    
    if [ -f "apps/mail/vite.config.ts" ]; then
        echo "Vite configuration:"
        echo "  - File: apps/mail/vite.config.ts"
        echo "  - Status: Found"
        echo ""
    fi
    
    if [ -f "apps/mail/wrangler.jsonc" ]; then
        echo "Wrangler configuration:"
        echo "  - File: apps/mail/wrangler.jsonc"
        echo "  - Status: Found"
        echo ""
        
        # Show wrangler config details
        print_status "Wrangler configuration details:"
        cd apps/mail
        wrangler config 2>/dev/null || echo "  - Unable to show wrangler config"
        cd ../..
        echo ""
    fi
    
    if [ -f "apps/mail/package.json" ]; then
        echo "Package configuration:"
        echo "  - File: apps/mail/package.json"
        echo "  - Build script: $(grep -o '"build": "[^"]*"' apps/mail/package.json | cut -d'"' -f4)"
        echo ""
    fi
}

# Build applications
build_applications() {
    print_status "Building applications..."
    
    # Show current build configuration
    show_build_config
    
    # Build mail application (React Router app)
    print_status "Building mail application..."
    cd apps/mail
    if ! pnpm build; then
        print_error "Failed to build mail application"
        exit 1
    fi
    cd ../..
    
    # Server doesn't need a build step for Cloudflare Workers
    print_status "Server application is ready for deployment (no build needed for Cloudflare Workers)"
    
    print_success "Applications prepared for deployment"
}

# Deploy to Cloudflare
deploy_to_cloudflare() {
    print_status "Deploying to Cloudflare Workers..."
    
    # Deploy server if requested
    if [ "$DEPLOY_SERVER" = true ]; then
        print_status "Deploying server application..."
        cd apps/server
        if ! wrangler deploy; then
            print_error "Failed to deploy server application"
            exit 1
        fi
        cd ../..
        print_success "Server deployed successfully"
    else
        print_status "Skipping server deployment"
    fi
    
    # Deploy mail application if requested
    if [ "$DEPLOY_MAIL" = true ]; then
        print_status "Deploying mail application..."
        cd apps/mail
        if ! wrangler deploy; then
            print_error "Failed to deploy mail application"
            if [ "$DEPLOY_SERVER" = true ]; then
                print_warning "Server was deployed successfully, but mail app failed"
                print_status "You may need to manually deploy the mail app or check the build output"
            fi
            exit 1
        fi
        cd ../..
        print_success "Mail app deployed successfully"
    else
        print_status "Skipping mail app deployment"
    fi
    
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
        wrangler secret put "$secret" --name "$secret_value"
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

# Check Wrangler configuration
check_wrangler_config() {
    print_status "Checking Wrangler configuration..."
    
    # Check server wrangler config
    if [ ! -f "apps/server/wrangler.jsonc" ]; then
        print_error "Server wrangler.jsonc not found"
        exit 1
    fi
    
    # Check mail wrangler config
    if [ ! -f "apps/mail/wrangler.jsonc" ]; then
        print_error "Mail wrangler.jsonc not found"
        exit 1
    fi
    
    print_success "Wrangler configuration files found"
}

# Troubleshooting function
troubleshoot_deployment() {
    print_status "Troubleshooting deployment issues..."
    echo ""
    echo "Common issues and solutions:"
    echo ""
    echo "1. Wrangler configuration error:"
    echo "   - Make sure your wrangler.jsonc files are properly configured"
    echo "   - Check that environment variables are set in your build tool (Vite)"
    echo "   - Don't use --env flag in wrangler deploy when using redirected configs"
    echo ""
    echo "2. Build failures:"
    echo "   - Check that all dependencies are installed: pnpm install"
    echo "   - Verify your .env file has all required variables"
    echo "   - Check for TypeScript compilation errors"
    echo ""
    echo "3. Build output issues:"
    echo "   - Verify your Vite configuration includes @cloudflare/vite-plugin"
    echo "   - Check that your build script in package.json is correct"
    echo "   - Ensure your wrangler.jsonc points to the correct build output"
    echo "   - React Router builds to build/client/, not dist/"
    echo ""
    echo "4. Authentication issues:"
    echo "   - Run: wrangler login"
    echo "   - Verify your Cloudflare account ID is correct"
    echo ""
    echo "5. Environment variable issues:"
    echo "   - Run: pnpm nizzy sync"
    echo "   - Check that your .env file exists and has correct values"
    echo ""
    echo "6. Cloudflare Workers specific issues:"
    echo "   - Make sure your Vite config uses @cloudflare/vite-plugin"
    echo "   - Check that your wrangler.jsonc has the correct entry point"
    echo "   - Verify your build output directory matches wrangler.jsonc"
    echo ""
    print_status "For more help, check the Wrangler logs at: ~/.wrangler/logs/"
}

# Check Cloudflare Workers compatibility
check_workers_compatibility() {
    print_status "Checking Cloudflare Workers compatibility..."
    
    # Check if the build output contains the necessary files for Cloudflare Workers
    if [ -d "apps/mail/build" ]; then
        echo "Build output found in apps/mail/build/"
        
        # Check for client build
        if [ -d "apps/mail/build/client" ]; then
            echo "✓ Client build found"
            
            # Check for essential client files
            if [ -f "apps/mail/build/client/index.html" ]; then
                echo "✓ index.html found"
            else
                print_warning "index.html not found in client build"
            fi
        else
            print_warning "Client build directory not found"
        fi
        
        # Check for server build (Cloudflare Workers)
        if [ -d "apps/mail/build/server" ]; then
            echo "✓ Server build found"
            
            # Check for essential server files
            if [ -f "apps/mail/build/server/index.js" ]; then
                echo "✓ Server index.js found"
            else
                print_warning "Server index.js not found"
            fi
        else
            print_warning "Server build directory not found - this may cause deployment issues"
        fi
        
        # Check for wrangler-specific files
        if [ -f "apps/mail/build/.wrangler/deploy/config.json" ]; then
            echo "✓ Wrangler deployment config found"
        else
            print_warning "Wrangler deployment config not found - build may not be configured for Cloudflare Workers"
        fi
    else
        print_error "Build output directory not found"
        return 1
    fi
    
    echo ""
    print_success "Cloudflare Workers compatibility check completed"
}

# Verify build output
verify_build_output() {
    print_status "Verifying build output..."
    
    # Check mail app build output - React Router creates build/client and build/server
    if [ ! -d "apps/mail/build" ]; then
        print_error "Mail app build output not found. Build may have failed."
        exit 1
    fi
    
    # Show build output structure for debugging
    print_status "Build output structure:"
    ls -la apps/mail/build/
    echo ""
    
    # Check for essential build files in the client directory
    if [ ! -d "apps/mail/build/client" ]; then
        print_error "Mail app client build output not found. Build may be incomplete."
        exit 1
    fi
    
    # Show client build output structure
    print_status "Client build output structure:"
    ls -la apps/mail/build/client/ | head -10
    echo ""
    
    # Check for essential build files
    if [ ! -f "apps/mail/build/client/index.html" ]; then
        print_error "Mail app index.html not found. Build may be incomplete."
        exit 1
    fi
    
    # Check Cloudflare Workers compatibility
    check_workers_compatibility
    
    print_success "Build output verified"
}

# Check Wrangler authentication
check_wrangler_auth() {
    print_status "Checking Wrangler authentication..."
    
    if ! wrangler whoami &> /dev/null; then
        print_error "Not logged into Wrangler. Please run: wrangler login"
        print_status "This will open your browser to authenticate with Cloudflare"
        exit 1
    fi
    
    print_success "Wrangler authentication verified"
}

# Diagnose build configuration issues
diagnose_build_issues() {
    print_status "Diagnosing build configuration issues..."
    echo ""
    
    # Check Vite configuration
    if [ -f "apps/mail/vite.config.ts" ]; then
        echo "Vite configuration analysis:"
        
        # Check for Cloudflare plugin
        if grep -q "@cloudflare/vite-plugin" "apps/mail/vite.config.ts"; then
            echo "✓ @cloudflare/vite-plugin found"
        else
            echo "✗ @cloudflare/vite-plugin NOT found - this is required for Cloudflare Workers"
            echo "  Add: import { cloudflare } from '@cloudflare/vite-plugin';"
            echo "  And: cloudflare() to your plugins array"
        fi
        
        # Check for React Router plugin
        if grep -q "@react-router/dev/vite" "apps/mail/vite.config.ts"; then
            echo "✓ @react-router/dev/vite plugin found"
        else
            echo "✗ @react-router/dev/vite plugin NOT found"
        fi
        
        # Check for build configuration
        if grep -q "ssr:" "apps/mail/vite.config.ts"; then
            echo "✓ SSR configuration found"
        else
            echo "✗ SSR configuration not found - this may cause issues"
        fi
        
        echo ""
    fi
    
    # Check package.json
    if [ -f "apps/mail/package.json" ]; then
        echo "Package.json analysis:"
        
        # Check build script
        if grep -q '"build":' "apps/mail/package.json"; then
            echo "✓ Build script found"
            echo "  Build script: $(grep -o '"build": "[^"]*"' apps/mail/package.json | cut -d'"' -f4)"
        else
            echo "✗ Build script not found"
        fi
        
        # Check for required dependencies
        if grep -q "@cloudflare/vite-plugin" "apps/mail/package.json"; then
            echo "✓ @cloudflare/vite-plugin dependency found"
        else
            echo "✗ @cloudflare/vite-plugin dependency NOT found"
            echo "  Install with: pnpm add -D @cloudflare/vite-plugin"
        fi
        
        echo ""
    fi
    
    # Check wrangler configuration
    if [ -f "apps/mail/wrangler.jsonc" ]; then
        echo "Wrangler configuration analysis:"
        
        # Check for entry point
        if grep -q "entry" "apps/mail/wrangler.jsonc"; then
            echo "✓ Entry point configured"
        else
            echo "✗ Entry point not configured"
        fi
        
        # Check for build output directory
        if grep -q "build" "apps/mail/wrangler.jsonc"; then
            echo "✓ Build output directory configured"
        else
            echo "✗ Build output directory not configured"
        fi
        
        echo ""
    fi
    
    print_status "Build configuration diagnosis completed"
}

# Manual deployment instructions
manual_deployment_instructions() {
    print_status "Manual deployment instructions:"
    echo ""
    echo "If automated deployment fails, you can deploy manually:"
    echo ""
    echo "1. Deploy server:"
    echo "   cd apps/server"
    echo "   wrangler deploy"
    echo "   cd ../.."
    echo ""
    echo "2. Deploy mail app:"
    echo "   cd apps/mail"
    echo "   wrangler deploy"
    echo "   cd ../.."
    echo ""
    echo "3. Check deployment status:"
    echo "   wrangler deployments list"
    echo ""
    echo "4. If build issues persist, try:"
    echo "   cd apps/mail"
    echo "   pnpm clean"
    echo "   pnpm install"
    echo "   pnpm build"
    echo "   cd ../.."
    echo ""
    print_status "For more help, run: ./deploy.sh --help"
}

# Check deployment status
check_deployment_status() {
    print_status "Checking deployment status..."
    
    echo ""
    echo "Current deployments:"
    echo ""
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        print_warning "jq not available, showing basic deployment status"
        
        # Check server deployment status
        if [ "$DEPLOY_SERVER" = true ]; then
            print_status "Server deployment status:"
            cd apps/server
            wrangler deployments list --format pretty 2>/dev/null || echo "  - Unable to fetch server deployment status"
            cd ../..
        fi
        
        # Check mail app deployment status
        if [ "$DEPLOY_MAIL" = true ]; then
            print_status "Mail app deployment status:"
            cd apps/mail
            wrangler deployments list --format pretty 2>/dev/null || echo "  - Unable to fetch mail app deployment status"
            cd ../..
        fi
    else
        # Check server deployment status with jq
        if [ "$DEPLOY_SERVER" = true ]; then
            print_status "Server deployment status:"
            cd apps/server
            wrangler deployments list --format json | jq -r '.[0] | "  - ID: \(.id)\n    Status: \(.status)\n    Created: \(.created_on)"' 2>/dev/null || echo "  - Unable to fetch server deployment status"
            cd ../..
        fi
        
        # Check mail app deployment status with jq
        if [ "$DEPLOY_MAIL" = true ]; then
            print_status "Mail app deployment status:"
            cd apps/mail
            wrangler deployments list --format json | jq -r '.[0] | "  - ID: \(.id)\n    Status: \(.status)\n    Created: \(.created_on)"' 2>/dev/null || echo "  - Unable to fetch mail app deployment status"
            cd ../..
        fi
    fi
    
    echo ""
}

# Check build configuration
check_build_config() {
    print_status "Checking build configuration..."
    
    # Check if the mail app has the necessary configuration files
    if [ ! -f "apps/mail/wrangler.jsonc" ]; then
        print_error "wrangler.jsonc not found in mail app. This is required for Cloudflare Workers deployment."
        exit 1
    fi
    
    # Check if the build is configured for Cloudflare Workers
    if [ ! -f "apps/mail/vite.config.ts" ]; then
        print_error "vite.config.ts not found in mail app. This is required for the build configuration."
        exit 1
    fi
    
    print_success "Build configuration verified"
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
    check_wrangler_config
    check_wrangler_auth
    check_build_config
    install_dependencies
    sync_env
    
    # Only build if deploying mail app
    if [ "$DEPLOY_MAIL" = true ]; then
        build_applications
        verify_build_output
    fi
    
    deploy_to_cloudflare
    
    # Check deployment status
    check_deployment_status
    
    # Verify deployment if requested
    if [ "$VERIFY_DEPLOYMENT" = true ]; then
        verify_deployment
    fi
    
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

# Error handler
error_handler() {
    print_error "Deployment failed!"
    echo ""
    
    # If we're in the build or verification phase, run diagnostics
    if [ -d "apps/mail/build" ] || [ -f "apps/mail/package.json" ]; then
        diagnose_build_issues
        echo ""
    fi
    
    troubleshoot_deployment
    echo ""
    manual_deployment_instructions
    exit 1
}

# Set error handler
trap error_handler ERR

# Run main function
main "$@" 