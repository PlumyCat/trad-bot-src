#!/bin/bash
# =============================================================================
# check-all.sh - Master script to run all validation checks
# =============================================================================
#
# Purpose: Run all pre-deployment validation checks in one command
#          to ensure Azure resources are correctly configured
#
# Usage:
#   ./check-all.sh                                    # List resources only
#   ./check-all.sh -t <translator> -f <function_app> -g <resource_group>
#
# Parameters:
#   -t, --translator    Name of the Azure Translator to validate (optional)
#   -f, --function-app  Name of the Azure Function App to validate (optional)
#   -g, --resource-group Resource group for validation checks (required if -t or -f)
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed
#
# Example:
#   ./check-all.sh
#   ./check-all.sh -t translator-client -f tradbot-client -g rg-tradbot-client
#
# =============================================================================

# Get script directory for relative paths to other scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Counters for summary
CHECKS_RUN=0
CHECKS_PASSED=0
CHECKS_FAILED=0

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

print_section() {
    echo ""
    echo -e "${YELLOW}${BOLD}▶ $1${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
}

usage() {
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Master script to run all pre-deployment validation checks."
    echo ""
    echo "Options:"
    echo "  -t, --translator <name>     Azure Translator name to validate"
    echo "  -f, --function-app <name>   Azure Function App name to validate"
    echo "  -g, --resource-group <name> Resource group (required if -t or -f specified)"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Run check-resources.sh only"
    echo "  $0 -t translator-client -g rg-tradbot-client"
    echo "  $0 -f tradbot-client -g rg-tradbot-client"
    echo "  $0 -t translator-client -f tradbot-client -g rg-tradbot-client"
    echo ""
    echo "Checks performed:"
    echo "  1. check-resources.sh  - List all existing Azure resources (always)"
    echo "  2. validate-sku.sh     - Verify Translator uses F0 SKU (if -t specified)"
    echo "  3. validate-plan.sh    - Verify Function App uses Flex Consumption (if -f specified)"
    echo ""
    echo "Exit codes:"
    echo "  0 - All checks passed"
    echo "  1 - One or more checks failed"
    echo ""
}

# =============================================================================
# Check Functions
# =============================================================================

run_check_resources() {
    print_section "CHECK 1: List Existing Resources"

    if [[ ! -x "$SCRIPT_DIR/check-resources.sh" ]]; then
        print_error "check-resources.sh not found or not executable"
        ((CHECKS_FAILED++))
        return 1
    fi

    ((CHECKS_RUN++))

    if "$SCRIPT_DIR/check-resources.sh"; then
        print_success "Resource check completed"
        ((CHECKS_PASSED++))
        return 0
    else
        print_error "Resource check failed"
        ((CHECKS_FAILED++))
        return 1
    fi
}

run_validate_sku() {
    local translator_name=$1
    local resource_group=$2

    print_section "CHECK 2: Validate Translator SKU"

    if [[ ! -x "$SCRIPT_DIR/validate-sku.sh" ]]; then
        print_error "validate-sku.sh not found or not executable"
        ((CHECKS_FAILED++))
        return 1
    fi

    echo "  Validating: $translator_name in $resource_group"
    echo ""

    ((CHECKS_RUN++))

    if "$SCRIPT_DIR/validate-sku.sh" "$translator_name" "$resource_group"; then
        print_success "SKU validation passed (F0)"
        ((CHECKS_PASSED++))
        return 0
    else
        print_error "SKU validation failed"
        ((CHECKS_FAILED++))
        return 1
    fi
}

run_validate_plan() {
    local function_app_name=$1
    local resource_group=$2

    print_section "CHECK 3: Validate Function App Plan"

    if [[ ! -x "$SCRIPT_DIR/validate-plan.sh" ]]; then
        print_error "validate-plan.sh not found or not executable"
        ((CHECKS_FAILED++))
        return 1
    fi

    echo "  Validating: $function_app_name in $resource_group"
    echo ""

    ((CHECKS_RUN++))

    if "$SCRIPT_DIR/validate-plan.sh" "$function_app_name" "$resource_group"; then
        print_success "Plan validation passed (Flex Consumption)"
        ((CHECKS_PASSED++))
        return 0
    else
        print_error "Plan validation failed"
        ((CHECKS_FAILED++))
        return 1
    fi
}

print_summary() {
    print_header "VALIDATION SUMMARY"

    echo -e "  Total checks run:    ${BOLD}$CHECKS_RUN${NC}"
    echo -e "  Checks passed:       ${GREEN}${BOLD}$CHECKS_PASSED${NC}"
    echo -e "  Checks failed:       ${RED}${BOLD}$CHECKS_FAILED${NC}"
    echo ""

    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo "════════════════════════════════════════════════════════════════════════"
        print_success "ALL CHECKS PASSED!"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
        echo "  Your Azure resources are correctly configured."
        echo "  You can proceed with deployment."
        echo ""
    else
        echo "════════════════════════════════════════════════════════════════════════"
        print_error "$CHECKS_FAILED CHECK(S) FAILED!"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
        echo "  Please review the errors above and fix them before deployment."
        echo ""
        echo "  Common issues:"
        echo "    - Translator using S1 instead of F0 (costs \$35/month)"
        echo "    - Function App using deprecated Consumption plan"
        echo ""
    fi
}

# =============================================================================
# Parse Arguments
# =============================================================================

TRANSLATOR_NAME=""
FUNCTION_APP_NAME=""
RESOURCE_GROUP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--translator)
            TRANSLATOR_NAME="$2"
            shift 2
            ;;
        -f|--function-app)
            FUNCTION_APP_NAME="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# =============================================================================
# Validate Arguments
# =============================================================================

# If translator or function app specified, resource group is required
if [[ -n "$TRANSLATOR_NAME" || -n "$FUNCTION_APP_NAME" ]]; then
    if [[ -z "$RESOURCE_GROUP" ]]; then
        print_error "Resource group (-g) is required when specifying -t or -f"
        usage
        exit 1
    fi
fi

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_header "PRE-DEPLOYMENT VALIDATION - check-all.sh"

    echo -e "  ${BOLD}Configuration:${NC}"
    if [[ -n "$TRANSLATOR_NAME" ]]; then
        echo "    Translator:    $TRANSLATOR_NAME"
    else
        echo "    Translator:    (not specified - skipping SKU check)"
    fi
    if [[ -n "$FUNCTION_APP_NAME" ]]; then
        echo "    Function App:  $FUNCTION_APP_NAME"
    else
        echo "    Function App:  (not specified - skipping plan check)"
    fi
    if [[ -n "$RESOURCE_GROUP" ]]; then
        echo "    Resource Group: $RESOURCE_GROUP"
    fi
    echo ""

    # Always run resource check
    run_check_resources

    # Run SKU validation if translator specified
    if [[ -n "$TRANSLATOR_NAME" ]]; then
        run_validate_sku "$TRANSLATOR_NAME" "$RESOURCE_GROUP"
    fi

    # Run plan validation if function app specified
    if [[ -n "$FUNCTION_APP_NAME" ]]; then
        run_validate_plan "$FUNCTION_APP_NAME" "$RESOURCE_GROUP"
    fi

    # Print summary
    print_summary

    # Exit with appropriate code
    if [[ $CHECKS_FAILED -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

# Run main function
main
