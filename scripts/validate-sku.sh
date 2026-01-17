#!/bin/bash
# =============================================================================
# validate-sku.sh - Verify Azure Translator SKU is F0 (free)
# =============================================================================
#
# Purpose: Check if an Azure Translator resource uses the free F0 SKU
#          to avoid unexpected costs from S1 ($35/month)
#
# Usage: ./validate-sku.sh <translator_name> <resource_group>
#
# Parameters:
#   translator_name  - Name of the Azure Translator resource
#   resource_group   - Name of the resource group containing the Translator
#
# Exit codes:
#   0 - Success (SKU is F0)
#   1 - Error (SKU is S1, not found, or other error)
#
# Example:
#   ./validate-sku.sh translator-client rg-tradbot-client
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

print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

usage() {
    echo ""
    echo "Usage: $0 <translator_name> <resource_group>"
    echo ""
    echo "Parameters:"
    echo "  translator_name  - Name of the Azure Translator resource"
    echo "  resource_group   - Name of the resource group"
    echo ""
    echo "Example:"
    echo "  $0 translator-client rg-tradbot-client"
    echo ""
    echo "Exit codes:"
    echo "  0 - SKU is F0 (free tier) - OK"
    echo "  1 - SKU is S1 (paid) or resource not found - ERROR"
    echo ""
    exit 1
}

# =============================================================================
# Validation Functions
# =============================================================================

check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI (az) is not installed or not in PATH"
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

check_translator_exists() {
    local translator_name=$1
    local resource_group=$2

    if ! az cognitiveservices account show \
        --name "$translator_name" \
        --resource-group "$resource_group" &> /dev/null; then
        return 1
    fi
    return 0
}

get_translator_sku() {
    local translator_name=$1
    local resource_group=$2

    az cognitiveservices account show \
        --name "$translator_name" \
        --resource-group "$resource_group" \
        --query "sku.name" -o tsv 2>/dev/null
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Check parameters
    if [[ $# -ne 2 ]]; then
        print_error "Missing required parameters"
        usage
    fi

    local translator_name=$1
    local resource_group=$2

    print_header "VALIDATE TRANSLATOR SKU"

    echo -e "  Translator: ${BOLD}$translator_name${NC}"
    echo -e "  Resource Group: ${BOLD}$resource_group${NC}"
    echo ""

    # Pre-flight checks
    echo -n "  Checking Azure CLI... "
    check_azure_cli
    echo -e "${GREEN}OK${NC}"

    echo -n "  Checking Azure login... "
    check_azure_login
    echo -e "${GREEN}OK${NC}"

    # Check if Translator exists
    echo -n "  Checking if Translator exists... "
    if ! check_translator_exists "$translator_name" "$resource_group"; then
        echo -e "${RED}NOT FOUND${NC}"
        echo ""
        print_error "Translator '$translator_name' not found in resource group '$resource_group'"
        echo ""
        echo "  Possible causes:"
        echo "    - Wrong Translator name"
        echo "    - Wrong resource group"
        echo "    - Translator not yet created"
        echo ""
        echo "  To list existing Translators:"
        echo "    az cognitiveservices account list \\"
        echo "      --query \"[?kind=='TextTranslation'].{Nom:name, RG:resourceGroup}\" -o table"
        echo ""
        exit 1
    fi
    echo -e "${GREEN}FOUND${NC}"

    # Get and validate SKU
    echo -n "  Checking SKU... "
    local sku
    sku=$(get_translator_sku "$translator_name" "$resource_group")

    if [[ -z "$sku" ]]; then
        echo -e "${RED}UNKNOWN${NC}"
        print_error "Could not determine SKU"
        exit 1
    fi

    echo -e "${BOLD}$sku${NC}"
    echo ""

    # Evaluate SKU
    if [[ "$sku" == "F0" ]]; then
        echo "════════════════════════════════════════════════════════════════════════"
        print_success "SKU is F0 (FREE tier) - Correct!"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
        echo "  The Translator uses the free tier:"
        echo "    - 2 million characters/month included"
        echo "    - No monthly cost"
        echo "    - Recommended for this project"
        echo ""
        exit 0
    elif [[ "$sku" == "S1" ]]; then
        echo "════════════════════════════════════════════════════════════════════════"
        print_error "SKU is S1 (PAID tier) - WARNING!"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
        print_warning "This Translator costs approximately \$35/month!"
        echo ""
        echo "  Unless explicitly requested by the client, you should:"
        echo ""
        echo "  ${BOLD}Option 1: Delete and recreate with F0${NC}"
        echo ""
        echo "    # Delete the S1 Translator"
        echo "    az cognitiveservices account delete \\"
        echo "      --name $translator_name \\"
        echo "      --resource-group $resource_group"
        echo ""
        echo "    # Recreate with F0 (free)"
        echo "    az cognitiveservices account create \\"
        echo "      --name $translator_name \\"
        echo "      --resource-group $resource_group \\"
        echo "      --kind TextTranslation \\"
        echo "      --sku F0 \\"
        echo "      --location francecentral --yes"
        echo ""
        echo "  ${BOLD}Option 2: Keep S1 (only if client explicitly requested)${NC}"
        echo ""
        echo "    Document the client's request in the deployment report."
        echo ""
        exit 1
    else
        echo "════════════════════════════════════════════════════════════════════════"
        print_warning "Unknown SKU: $sku"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
        echo "  Expected: F0 (free) or S1 (paid)"
        echo "  Found: $sku"
        echo ""
        echo "  Please verify the Translator configuration manually."
        echo ""
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
