#!/bin/bash
# =============================================================================
# check-resources.sh - List existing Azure resources before deployment
# =============================================================================
#
# Purpose: Display all existing Translators, Storage Accounts, and Function Apps
#          in the current Azure subscription to prevent creating duplicates.
#
# Usage: ./check-resources.sh
#
# Requirements:
#   - Azure CLI (az) must be installed
#   - Must be logged in to Azure (az login)
#   - Subscription must be selected (az account set --subscription)
#
# Output: Tables showing existing resources with key information
#
# Exit codes:
#   0 - Success (resources listed)
#   1 - Error (not logged in or no subscription selected)
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${YELLOW}${BOLD}▶ $1${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# =============================================================================
# Pre-Flight Checks
# =============================================================================

check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI (az) is not installed or not in PATH"
        echo "  Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
}

check_azure_login() {
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure"
        echo ""
        echo "  Please run:"
        echo "    az login --tenant <TENANT_ID>"
        echo ""
        exit 1
    fi
}

check_subscription() {
    local sub_name
    sub_name=$(az account show --query "name" -o tsv 2>/dev/null)
    local sub_id
    sub_id=$(az account show --query "id" -o tsv 2>/dev/null)

    if [[ -z "$sub_name" ]] || [[ -z "$sub_id" ]]; then
        print_error "No subscription selected"
        echo ""
        echo "  Please run:"
        echo "    az account list -o table"
        echo "    az account set --subscription <SUBSCRIPTION_ID>"
        echo ""
        exit 1
    fi

    echo -e "  Subscription: ${BOLD}$sub_name${NC}"
    echo -e "  ID:           $sub_id"
}

# =============================================================================
# Resource Listing Functions
# =============================================================================

list_translators() {
    print_section "Azure Translator (Cognitive Services - TextTranslation)"

    local result
    result=$(az cognitiveservices account list \
        --query "[?kind=='TextTranslation'].{Nom:name, SKU:sku.name, ResourceGroup:resourceGroup, Region:location}" \
        -o table 2>/dev/null)

    if [[ -z "$result" ]] || [[ "$result" == *"[]"* ]] || [[ $(echo "$result" | wc -l) -le 1 ]]; then
        print_info "No Translator found in this subscription"
        echo ""
        echo "  To create one (F0 = free):"
        echo "    az cognitiveservices account create \\"
        echo "      --name translator-\$CLIENT_NAME \\"
        echo "      --resource-group \$RESOURCE_GROUP \\"
        echo "      --kind TextTranslation \\"
        echo "      --sku F0 \\"
        echo "      --location francecentral --yes"
    else
        echo "$result"
        echo ""
        # Check for S1 SKU and warn
        if echo "$result" | grep -q "S1"; then
            print_warning "S1 SKU detected! This costs ~35\$/month"
            echo "  Consider migrating to F0 (free) if possible"
        fi
        # Check for F0 and inform
        if echo "$result" | grep -q "F0"; then
            print_success "F0 SKU found - this is the FREE tier (recommended)"
        fi
    fi
}

list_storage_accounts() {
    print_section "Storage Accounts"

    local result
    result=$(az storage account list \
        --query "[].{Nom:name, ResourceGroup:resourceGroup, Region:location, Kind:kind}" \
        -o table 2>/dev/null)

    if [[ -z "$result" ]] || [[ "$result" == *"[]"* ]] || [[ $(echo "$result" | wc -l) -le 1 ]]; then
        print_info "No Storage Account found in this subscription"
        echo ""
        echo "  To create one:"
        echo "    az storage account create \\"
        echo "      --name storage\$CLIENT_NAME \\"
        echo "      --resource-group \$RESOURCE_GROUP \\"
        echo "      --location francecentral \\"
        echo "      --sku Standard_LRS"
    else
        echo "$result"
    fi
}

list_function_apps() {
    print_section "Function Apps"

    local result
    result=$(az functionapp list \
        --query "[].{Nom:name, ResourceGroup:resourceGroup, Region:location, State:state}" \
        -o table 2>/dev/null)

    if [[ -z "$result" ]] || [[ "$result" == *"[]"* ]] || [[ $(echo "$result" | wc -l) -le 1 ]]; then
        print_info "No Function App found in this subscription"
        echo ""
        echo "  To create one (Flex Consumption):"
        echo "    az functionapp create \\"
        echo "      --name tradbot-\$CLIENT_NAME \\"
        echo "      --resource-group \$RESOURCE_GROUP \\"
        echo "      --storage-account \$STORAGE_NAME \\"
        echo "      --flexconsumption-location francecentral \\"
        echo "      --runtime python --runtime-version 3.11"
    else
        echo "$result"
        echo ""
        # Count function apps
        local count
        count=$(echo "$result" | tail -n +3 | wc -l)
        print_info "Found $count Function App(s)"
    fi
}

list_resource_groups() {
    print_section "Resource Groups"

    local result
    result=$(az group list \
        --query "[].{Nom:name, Region:location}" \
        -o table 2>/dev/null)

    if [[ -z "$result" ]] || [[ "$result" == *"[]"* ]] || [[ $(echo "$result" | wc -l) -le 1 ]]; then
        print_info "No Resource Group found in this subscription"
    else
        echo "$result"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_header "CHECK AZURE RESOURCES - Pre-Deployment Verification"

    echo -e "${BOLD}This script lists existing resources to prevent duplicates.${NC}"
    echo "It is READ-ONLY and does not create or modify any resources."
    echo ""

    # Pre-flight checks
    print_section "Pre-Flight Checks"

    echo -n "  Checking Azure CLI... "
    check_azure_cli
    echo -e "${GREEN}OK${NC}"

    echo -n "  Checking Azure login... "
    check_azure_login
    echo -e "${GREEN}OK${NC}"

    echo -n "  Checking subscription... "
    echo -e "${GREEN}OK${NC}"
    check_subscription

    # List resources
    list_resource_groups
    list_translators
    list_storage_accounts
    list_function_apps

    # Summary
    print_header "Summary"

    echo "  Review the resources above before creating new ones."
    echo ""
    echo "  Key reminders:"
    echo "    - Reuse existing Translator F0 if available (free tier)"
    echo "    - Never use Translator S1 unless explicitly requested"
    echo "    - Use Flex Consumption for Function Apps"
    echo "    - Create dedicated Resource Group per client: rg-tradbot-{client}"
    echo ""
    print_success "Resource check complete"
    echo ""
}

# Run main function
main "$@"
