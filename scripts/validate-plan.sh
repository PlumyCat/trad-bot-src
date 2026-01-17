#!/bin/bash
# =============================================================================
# validate-plan.sh - Verify Azure Function App uses Flex Consumption plan
# =============================================================================
#
# Purpose: Check if an Azure Function App uses the Flex Consumption plan
#          to avoid using the deprecated Consumption plan
#
# Usage: ./validate-plan.sh <function_app_name> <resource_group>
#
# Parameters:
#   function_app_name - Name of the Azure Function App
#   resource_group    - Name of the resource group containing the Function App
#
# Exit codes:
#   0 - Success (Flex Consumption plan)
#   1 - Error (wrong plan, not found, or other error)
#
# Example:
#   ./validate-plan.sh tradbot-client rg-tradbot-client
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
    echo "Usage: $0 <function_app_name> <resource_group>"
    echo ""
    echo "Parameters:"
    echo "  function_app_name - Name of the Azure Function App"
    echo "  resource_group    - Name of the resource group"
    echo ""
    echo "Example:"
    echo "  $0 tradbot-client rg-tradbot-client"
    echo ""
    echo "Exit codes:"
    echo "  0 - Flex Consumption plan - OK"
    echo "  1 - Wrong plan or Function App not found - ERROR"
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

check_function_app_exists() {
    local function_app_name=$1
    local resource_group=$2

    if ! az functionapp show \
        --name "$function_app_name" \
        --resource-group "$resource_group" &> /dev/null; then
        return 1
    fi
    return 0
}

get_function_app_plan_info() {
    local function_app_name=$1
    local resource_group=$2

    # Get the Function App details including SKU and kind
    az functionapp show \
        --name "$function_app_name" \
        --resource-group "$resource_group" \
        --query "{kind:kind, sku:sku.name, tier:sku.tier}" -o json 2>/dev/null
}

is_flex_consumption() {
    local function_app_name=$1
    local resource_group=$2

    # Check if the Function App is Flex Consumption
    # Flex Consumption apps have kind containing "functionapp,linux" and sku "FlexConsumption" or "FC1"
    local sku
    sku=$(az functionapp show \
        --name "$function_app_name" \
        --resource-group "$resource_group" \
        --query "sku.name" -o tsv 2>/dev/null)

    local kind
    kind=$(az functionapp show \
        --name "$function_app_name" \
        --resource-group "$resource_group" \
        --query "kind" -o tsv 2>/dev/null)

    # Flex Consumption typically has FC1 SKU or FlexConsumption
    if [[ "$sku" == "FC1" ]] || [[ "$sku" == "FlexConsumption" ]]; then
        echo "flex"
        return 0
    fi

    # Check if it's Dynamic (Consumption plan - deprecated)
    if [[ "$sku" == "Y1" ]] || [[ "$sku" == "Dynamic" ]]; then
        echo "consumption"
        return 0
    fi

    # Other plans (Premium, Dedicated, etc.)
    echo "$sku"
    return 0
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

    local function_app_name=$1
    local resource_group=$2

    print_header "VALIDATE FUNCTION APP PLAN"

    echo -e "  Function App: ${BOLD}$function_app_name${NC}"
    echo -e "  Resource Group: ${BOLD}$resource_group${NC}"
    echo ""

    # Pre-flight checks
    echo -n "  Checking Azure CLI... "
    check_azure_cli
    echo -e "${GREEN}OK${NC}"

    echo -n "  Checking Azure login... "
    check_azure_login
    echo -e "${GREEN}OK${NC}"

    # Check if Function App exists
    echo -n "  Checking if Function App exists... "
    if ! check_function_app_exists "$function_app_name" "$resource_group"; then
        echo -e "${RED}NOT FOUND${NC}"
        echo ""
        print_error "Function App '$function_app_name' not found in resource group '$resource_group'"
        echo ""
        echo "  Possible causes:"
        echo "    - Wrong Function App name"
        echo "    - Wrong resource group"
        echo "    - Function App not yet created"
        echo ""
        echo "  To list existing Function Apps:"
        echo "    az functionapp list \\"
        echo "      --query \"[].{Nom:name, RG:resourceGroup}\" -o table"
        echo ""
        exit 1
    fi
    echo -e "${GREEN}FOUND${NC}"

    # Get and validate plan type
    echo -n "  Checking plan type... "
    local plan_type
    plan_type=$(is_flex_consumption "$function_app_name" "$resource_group")

    echo -e "${BOLD}$plan_type${NC}"
    echo ""

    # Evaluate plan type
    case "$plan_type" in
        "flex"|"FC1"|"FlexConsumption")
            echo "════════════════════════════════════════════════════════════════════════"
            print_success "Plan is Flex Consumption - Correct!"
            echo "════════════════════════════════════════════════════════════════════════"
            echo ""
            echo "  The Function App uses the recommended plan:"
            echo "    - Flex Consumption (FC1)"
            echo "    - Pay-per-execution model"
            echo "    - Supported by Microsoft"
            echo ""
            exit 0
            ;;
        "consumption"|"Y1"|"Dynamic")
            echo "════════════════════════════════════════════════════════════════════════"
            print_error "Plan is Consumption (DEPRECATED) - WARNING!"
            echo "════════════════════════════════════════════════════════════════════════"
            echo ""
            print_warning "This plan is DEPRECATED by Microsoft!"
            echo ""
            echo "  The simple Consumption plan will be phased out."
            echo "  You should migrate to Flex Consumption."
            echo ""
            echo "  ${BOLD}Action required: Delete and recreate with Flex Consumption${NC}"
            echo ""
            echo "    # Delete the Function App"
            echo "    az functionapp delete \\"
            echo "      --name $function_app_name \\"
            echo "      --resource-group $resource_group"
            echo ""
            echo "    # Recreate with Flex Consumption"
            echo "    az functionapp create \\"
            echo "      --name $function_app_name \\"
            echo "      --resource-group $resource_group \\"
            echo "      --storage-account \$STORAGE_NAME \\"
            echo "      --flexconsumption-location francecentral \\"
            echo "      --runtime python --runtime-version 3.11"
            echo ""
            echo "    # Then redeploy the code"
            echo "    func azure functionapp publish $function_app_name --python"
            echo ""
            exit 1
            ;;
        *)
            echo "════════════════════════════════════════════════════════════════════════"
            print_warning "Plan type: $plan_type"
            echo "════════════════════════════════════════════════════════════════════════"
            echo ""
            echo "  This is not the recommended Flex Consumption plan."
            echo "  Current plan: $plan_type"
            echo ""
            echo "  For this project, Flex Consumption is recommended:"
            echo "    - Pay-per-execution (cost-effective)"
            echo "    - Modern, supported by Microsoft"
            echo "    - Required for new deployments"
            echo ""
            echo "  Consider migrating to Flex Consumption if appropriate."
            echo ""
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
