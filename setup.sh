#!/bin/bash

# Pulse iOS App Setup Script
# This script helps you set up the configuration files for the Pulse app

set -e

echo "🎯 Pulse iOS App Setup"
echo "======================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Config directory exists
if [ ! -d "Config" ]; then
    echo -e "${RED}Error: Config directory not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo "📋 Step 1: Setting up Supabase configuration"
echo "--------------------------------------------"

if [ -f "Config/Supabase.plist" ]; then
    echo -e "${YELLOW}Supabase.plist already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping Supabase configuration"
    else
        cp Config/Supabase.plist.template Config/Supabase.plist
        echo -e "${GREEN}✓ Created Config/Supabase.plist${NC}"
    fi
else
    cp Config/Supabase.plist.template Config/Supabase.plist
    echo -e "${GREEN}✓ Created Config/Supabase.plist${NC}"
fi

echo ""
echo "📋 Step 2: Setting up PostHog configuration"
echo "-------------------------------------------"

if [ -f "Config/PostHog.plist" ]; then
    echo -e "${YELLOW}PostHog.plist already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping PostHog configuration"
    else
        cp Config/PostHog.plist.template Config/PostHog.plist
        echo -e "${GREEN}✓ Created Config/PostHog.plist${NC}"
    fi
else
    cp Config/PostHog.plist.template Config/PostHog.plist
    echo -e "${GREEN}✓ Created Config/PostHog.plist${NC}"
fi

echo ""
echo "📝 Next Steps:"
echo "-------------"
echo ""
echo "1. Create a Supabase project at https://supabase.com"
echo "   - Go to Settings → API"
echo "   - Copy your Project URL and anon key"
echo "   - Edit Config/Supabase.plist with your credentials"
echo ""
echo "2. Run the SQL migrations from PULSE_MVP_PLAN.md section 4"
echo "   - Go to SQL Editor in Supabase dashboard"
echo "   - Copy and run all migration scripts"
echo ""
echo "3. Create a PostHog project at https://posthog.com"
echo "   - Go to Project Settings"
echo "   - Copy your Project API Key"
echo "   - Edit Config/PostHog.plist with your key"
echo ""
echo "4. Install dependencies via Xcode:"
echo "   - Open project in Xcode"
echo "   - File → Add Packages..."
echo "   - Add: https://github.com/supabase/supabase-swift"
echo "   - Add: https://github.com/PostHog/posthog-ios"
echo ""
echo "5. Build and run the app!"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "For more details, see:"
echo "  - PULSE_MVP_PLAN.md for complete architecture"
echo "  - Pulse/README.md for project overview"
echo "  - Config/README.md for configuration details"
