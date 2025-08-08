#!/bin/bash

echo "🔑 Setting up API secrets for Zero email application..."
echo ""

echo "✅ OpenAI API key already configured!"
echo ""

echo "📋 Remaining required API keys:"
echo "1. BETTER_AUTH_SECRET (generate a secure random string)"
echo "2. GOOGLE_CLIENT_ID (from Google Cloud Console)"
echo "3. GOOGLE_CLIENT_SECRET (from Google Cloud Console)"
echo "4. RESEND_API_KEY (from Resend Dashboard)"
echo "5. PERPLEXITY_API_KEY (from Perplexity API)"
echo "6. AUTUMN_SECRET_KEY (generate a secure random string)"
echo ""

echo "🚀 Let's set them up one by one..."
echo ""

# Generate secure random strings for secrets
echo "🔐 Generating secure secrets..."
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
AUTUMN_SECRET_KEY=$(openssl rand -base64 32)

echo "Generated BETTER_AUTH_SECRET: $BETTER_AUTH_SECRET"
echo "Generated AUTUMN_SECRET_KEY: $AUTUMN_SECRET_KEY"
echo ""

echo "📝 Setting up generated secrets..."
echo "Setting BETTER_AUTH_SECRET..."
echo "$BETTER_AUTH_SECRET" | wrangler secret put BETTER_AUTH_SECRET --env production

echo "Setting AUTUMN_SECRET_KEY..."
echo "$AUTUMN_SECRET_KEY" | wrangler secret put AUTUMN_SECRET_KEY --env production

echo ""
echo "✅ Generated secrets configured!"
echo ""
echo "📋 Next steps:"
echo "1. Get Google OAuth credentials from: https://console.cloud.google.com/"
echo "2. Get Resend API key from: https://resend.com/"
echo "3. Get Perplexity API key from: https://www.perplexity.ai/"
echo ""
echo "Then run these commands:"
echo "wrangler secret put GOOGLE_CLIENT_ID --env production"
echo "wrangler secret put GOOGLE_CLIENT_SECRET --env production"
echo "wrangler secret put RESEND_API_KEY --env production"
echo "wrangler secret put PERPLEXITY_API_KEY --env production"
echo ""
echo "🎯 After setting all secrets, your Zero email app will be fully functional!" 