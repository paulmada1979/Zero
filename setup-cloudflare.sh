#!/bin/bash

# Cloudflare Resources Setup Script
# This script helps create the necessary Cloudflare resources for Zero email

set -e

echo "🔧 Setting up Cloudflare resources for Zero email..."

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

# Check if wrangler is installed
check_wrangler() {
    if ! command -v wrangler &> /dev/null; then
        print_error "wrangler is not installed. Install with: npm install -g wrangler"
        exit 1
    fi
    print_success "wrangler is installed"
}

# Set Cloudflare account ID
set_account_id() {
    print_status "Setting Cloudflare account ID: $CLOUDFLARE_ACCOUNT_ID"
    export CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID"
    print_success "Account ID set"
}

# Create D1 database
create_d1_database() {
    print_status "Creating D1 database..."
    
    # Check if database already exists
    if wrangler d1 list | grep -q "zero-db"; then
        print_warning "D1 database 'zero-db' already exists"
        return
    fi
    
    # Create database
    output=$(wrangler d1 create zero-db)
    print_success "D1 database created"
    
    # Extract database ID
    db_id=$(echo "$output" | grep -o 'Created database .*' | cut -d' ' -f3)
    print_status "Database ID: $db_id"
    print_status "Please update your wrangler.jsonc with this ID"
}

# Create R2 buckets
create_r2_buckets() {
    print_status "Creating R2 buckets..."
    
    # Check if R2 is enabled
    if ! wrangler r2 bucket list &>/dev/null; then
        print_error "R2 is not enabled in your Cloudflare account"
        print_status "Please enable R2 in your Cloudflare dashboard:"
        echo "1. Go to https://dash.cloudflare.com"
        echo "2. Select your account: Paul@ai-did-it.com's Account"
        echo "3. Go to R2 Object Storage"
        echo "4. Click 'Enable R2'"
        echo "5. Run this script again"
        return
    fi
    
    # Create threads bucket
    if ! wrangler r2 bucket list | grep -q "threads-prod"; then
        wrangler r2 bucket create threads-prod
        print_success "R2 bucket 'threads-prod' created"
    else
        print_warning "R2 bucket 'threads-prod' already exists"
    fi
    
    # Create staging bucket
    if ! wrangler r2 bucket list | grep -q "threads-staging"; then
        wrangler r2 bucket create threads-staging
        print_success "R2 bucket 'threads-staging' created"
    else
        print_warning "R2 bucket 'threads-staging' already exists"
    fi
}

# Create KV namespaces
create_kv_namespaces() {
    print_status "Creating KV namespaces..."
    
    local namespaces=(
        "gmail_history_id"
        "gmail_processing_threads"
        "subscribed_accounts"
        "connection_labels"
        "prompts_storage"
        "gmail_sub_age"
        "snoozed_emails"
    )
    
    for ns in "${namespaces[@]}"; do
        if ! wrangler kv namespace list | grep -q "$ns"; then
            output=$(wrangler kv namespace create "$ns")
            print_success "KV namespace '$ns' created"
            
            # Extract namespace ID
            ns_id=$(echo "$output" | grep -o 'id: .*' | cut -d' ' -f2)
            print_status "Namespace ID for '$ns': $ns_id"
        else
            print_warning "KV namespace '$ns' already exists"
        fi
    done
}

# Create Vectorize indexes
create_vectorize_indexes() {
    print_status "Creating Vectorize indexes..."
    
    # Check if indexes exist
    if ! wrangler vectorize list | grep -q "threads-vector"; then
        wrangler vectorize create threads-vector --dimensions=1536
        print_success "Vectorize index 'threads-vector' created"
    else
        print_warning "Vectorize index 'threads-vector' already exists"
    fi
    
    if ! wrangler vectorize list | grep -q "messages-vector"; then
        wrangler vectorize create messages-vector --dimensions=1536
        print_success "Vectorize index 'messages-vector' created"
    else
        print_warning "Vectorize index 'messages-vector' already exists"
    fi
}

# Create Queues
create_queues() {
    print_status "Creating Queues..."
    
    if ! wrangler queues list | grep -q "thread-queue-prod"; then
        wrangler queues create thread-queue-prod
        print_success "Queue 'thread-queue-prod' created"
    else
        print_warning "Queue 'thread-queue-prod' already exists"
    fi
    
    if ! wrangler queues list | grep -q "subscribe-queue-prod"; then
        wrangler queues create subscribe-queue-prod
        print_success "Queue 'subscribe-queue-prod' created"
    else
        print_warning "Queue 'subscribe-queue-prod' already exists"
    fi
}

# Show next steps
show_next_steps() {
    echo ""
    print_status "Next steps:"
    echo "1. Update your wrangler.jsonc files with the resource IDs shown above"
    echo "2. Run the deployment script: ./deploy.sh"
    echo "3. Configure your domain in Cloudflare dashboard"
    echo "4. Set up environment variables in Cloudflare"
    echo ""
    print_success "Cloudflare resources setup completed!"
}

# Main function
main() {
    echo "=========================================="
    echo "Cloudflare Resources Setup"
    echo "=========================================="
    echo ""
    
    check_wrangler
    set_account_id
    create_d1_database
    create_r2_buckets
    create_kv_namespaces
    create_vectorize_indexes
    create_queues
    show_next_steps
}

# Run main function
main "$@" 