# System Architecture: trad-bot-src

**Date:** 2026-01-16
**Architect:** Eric
**Version:** 1.0
**Project Type:** Documentation / Deployment Instructions
**Project Level:** 2 (Medium - 5-15 stories)
**Status:** Draft

---

## Document Overview

This document defines the architecture for improving the trad-bot-src deployment system. Unlike traditional software architecture, this project focuses on:
- **CLAUDE.md** document structure and guardrails
- **Validation scripts** for pre-deployment checks
- **Deployment reports** format and templates
- **File organization** for security and clarity

**Related Documents:**
- Product Requirements Document: `docs/prd-trad-bot-src-2026-01-16.md`
- Product Brief: `docs/product-brief-trad-bot-src-2026-01-16.md`

---

## Executive Summary

The architecture prioritizes **security first** (no credential persistence), followed by **usability** (beginner-friendly instructions) and **consistency** (single deployment path). The solution consists of four main components:

1. **CLAUDE.md Overhaul** - Restructured with strict ALWAYS/NEVER guardrails
2. **Validation Scripts** - Bash scripts for pre-deployment checks
3. **Deployment Reports** - Credential-free documentation for clients folder
4. **File Organization** - Secure directory structure with proper .gitignore

---

## Architectural Drivers

These NFRs heavily influence architectural decisions:

| Priority | Driver | NFR | Architectural Impact |
|----------|--------|-----|---------------------|
| 1 | **Security** | NFR-001, NFR-002 | No credentials in files, session-only display, credential-free reports |
| 2 | **Usability** | NFR-003, NFR-004 | Step-by-step format, ALWAYS/NEVER rules, copy-paste commands, WHY explanations |
| 3 | **Consistency** | NFR-005 | Single deployment path, no alternatives, enforced order |
| 4 | **Safety** | NFR-006 | Read-only validation scripts, idempotent checks |

---

## System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    trad-bot-src Repository                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │    CLAUDE.md     │    │     scripts/     │                   │
│  │  (Instructions)  │    │  (Validation)    │                   │
│  │                  │    │                  │                   │
│  │  - Critical Rules│    │  - check-all.sh  │                   │
│  │  - Phase 0/1/2   │    │  - validate-sku  │                   │
│  │  - Credentials   │    │  - validate-plan │                   │
│  │  - Report Gen    │    │                  │                   │
│  └──────────────────┘    └──────────────────┘                   │
│                                                                  │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │    clients/      │    │     docs/        │                   │
│  │  (GITIGNORED)    │    │  (Public docs)   │                   │
│  │                  │    │                  │                   │
│  │  - Reports only  │    │  - PRD           │                   │
│  │  - NO credentials│    │  - Architecture  │                   │
│  │                  │    │  - Product Brief │                   │
│  └──────────────────┘    └──────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

         │                          │
         ▼                          ▼
┌─────────────────────┐    ┌─────────────────────┐
│  OpenCode Container │    │   Azure CLI (az)    │
│  - Reads CLAUDE.md  │    │  - Executes commands│
│  - Follows rules    │    │  - Creates resources│
│  - Generates report │    │  - Returns creds    │
└─────────────────────┘    └─────────────────────┘
```

### Architectural Pattern

**Pattern:** Document-Driven Deployment Automation

**Rationale:**
The primary "system" is an AI assistant (OpenCode/Claude) that reads CLAUDE.md and executes Azure CLI commands. The architecture focuses on making the instructions unambiguous and foolproof through:
- Explicit guardrails (ALWAYS/NEVER)
- Pre-deployment validation
- Credential isolation (session-only)
- Consistent process flow

---

## Component 1: CLAUDE.md Structure

### New Document Organization

```
CLAUDE.md
├── 🚨 CRITICAL RULES (TOP - First thing AI reads)
│   ├── ALWAYS Rules
│   ├── NEVER Rules
│   └── Security Warning
│
├── 🔑 CREDENTIALS SECTION (Clear distinction)
│   ├── Function App Credentials (for Power Platform)
│   ├── Blob Storage Credentials (for file upload)
│   └── ⚠️ NOT Translator Credentials
│
├── 📋 DEPLOYMENT PHASES
│   ├── Phase 0: Entra ID App
│   ├── Phase 1: Azure Backend
│   └── Phase 2: Power Platform
│
├── ✅ VALIDATION COMMANDS (Inline)
│   ├── Check existing resources
│   ├── Verify SKU is F0
│   └── Verify plan is Flex Consumption
│
├── 📄 DEPLOYMENT REPORT TEMPLATE
│   └── Template with NO credentials
│
└── 📖 REFERENCE
    ├── Environment variables
    ├── Permissions
    └── Troubleshooting
```

### Critical Rules Section Design

**Location:** TOP of CLAUDE.md (first section after title)

**Format:**
```markdown
## 🚨 CRITICAL RULES - READ FIRST

### ✅ ALWAYS DO:
| Rule | Command/Action | WHY |
|------|----------------|-----|
| Use Flex Consumption | `--sku "FlexConsumption"` | Simple Consumption is deprecated |
| Use F0 for Translator | `--sku F0` | Free tier, S1 costs $35/month |
| Login with tenant | `az login --tenant <id>` | Required for delegated access |
| Use func publish | `func azure functionapp publish` | Consistent deployment |
| Check resources first | See validation commands | Avoid duplicates |

### ❌ NEVER DO:
| Rule | Why This Breaks Things |
|------|------------------------|
| NEVER use S1 SKU | Costs $35/month unnecessary |
| NEVER use zip deploy | Inconsistent with func publish |
| NEVER modify WEBSITE_* vars | Breaks deployment, requires rebuild |
| NEVER store credentials | Security risk, session-only |
| NEVER give Translator creds to Power Platform | Wrong credentials! |
```

### Credentials Section Design

**FR-006, FR-007, FR-012 Implementation:**

```markdown
## 🔑 CREDENTIALS FOR POWER PLATFORM

⚠️ **IMPORTANT:** These are FUNCTION APP credentials, NOT Translator credentials!

### What Power Platform Needs:

| Credential | What It Is | How to Get It |
|------------|-----------|---------------|
| Function URL | `https://{name}.azurewebsites.net/api` | `az functionapp show` |
| Function Key | API key for the function | `az functionapp keys list` |
| Container Name | `doc-to-trad` | Fixed value |
| Storage Key | Blob storage access key | `az storage account keys list` |

### Display Commands (Run at end of Phase 1):

```bash
# Get Function credentials (NOT Translator!)
FUNCTION_URL=$(az functionapp show --name $FUNC_NAME --resource-group $RG --query defaultHostName -o tsv)
FUNCTION_KEY=$(az functionapp keys list --name $FUNC_NAME --resource-group $RG --query functionKeys.default -o tsv)

echo "════════════════════════════════════════"
echo "  CREDENTIALS FOR POWER PLATFORM"
echo "════════════════════════════════════════"
echo ""
echo "  Function URL: https://$FUNCTION_URL/api"
echo "  Function Key: $FUNCTION_KEY"
echo ""
echo "  Container:    doc-to-trad"
echo "  Storage Key:  $STORAGE_KEY"
echo ""
echo "════════════════════════════════════════"
```

⚠️ **These credentials are displayed ONLY during this session.**
⚠️ **Do NOT save them to any file.**
```

---

## Component 2: Validation Scripts

### Script Organization

```
scripts/
├── check-all.sh          # Master validation script
├── check-resources.sh    # List existing resources (FR-009)
├── validate-sku.sh       # Verify F0 SKU (FR-010)
└── validate-plan.sh      # Verify Flex Consumption (FR-011)
```

### Script: check-all.sh (Master)

**Purpose:** Run all validations before deployment

```bash
#!/bin/bash
# check-all.sh - Pre-deployment validation
# Usage: ./scripts/check-all.sh

echo "🔍 Running pre-deployment validation..."
echo ""

# Check 1: List existing resources
echo "═══ EXISTING RESOURCES ═══"
./scripts/check-resources.sh
echo ""

# Check 2: Validate Translator SKU
echo "═══ TRANSLATOR SKU CHECK ═══"
./scripts/validate-sku.sh
echo ""

# Check 3: Validate Function Plan
echo "═══ FUNCTION PLAN CHECK ═══"
./scripts/validate-plan.sh
echo ""

echo "✅ Validation complete. Review above for any warnings."
```

### Script: check-resources.sh (FR-009)

**Purpose:** Read-only list of existing resources

```bash
#!/bin/bash
# check-resources.sh - List existing Azure resources
# This script is READ-ONLY and has no side effects

echo "📋 Existing Translators:"
az cognitiveservices account list \
  --query "[?kind=='TextTranslation'].{Name:name, SKU:sku.name, RG:resourceGroup}" \
  -o table

echo ""
echo "📋 Existing Storage Accounts:"
az storage account list \
  --query "[].{Name:name, RG:resourceGroup}" \
  -o table

echo ""
echo "📋 Existing Function Apps:"
az functionapp list \
  --query "[].{Name:name, RG:resourceGroup}" \
  -o table
```

### Script: validate-sku.sh (FR-010)

**Purpose:** Verify Translator uses F0 SKU

```bash
#!/bin/bash
# validate-sku.sh - Verify Translator SKU is F0
# Warns if S1 (paid) SKU detected

S1_COUNT=$(az cognitiveservices account list \
  --query "[?kind=='TextTranslation' && sku.name=='S1'] | length(@)" \
  -o tsv)

if [ "$S1_COUNT" -gt 0 ]; then
  echo "⚠️ WARNING: Found $S1_COUNT Translator(s) with S1 (PAID) SKU!"
  echo "   S1 costs ~$35/month. Consider using F0 (free) instead."
  az cognitiveservices account list \
    --query "[?kind=='TextTranslation' && sku.name=='S1'].{Name:name, RG:resourceGroup}" \
    -o table
else
  echo "✅ All Translators use F0 (free) SKU"
fi
```

### Script: validate-plan.sh (FR-011)

**Purpose:** Verify Function App uses Flex Consumption

```bash
#!/bin/bash
# validate-plan.sh - Verify Function App plan type
# Warns if not using Flex Consumption

# Note: This requires knowing the function app name
# Run with: ./validate-plan.sh <function-app-name> <resource-group>

FUNC_NAME=$1
RG=$2

if [ -z "$FUNC_NAME" ] || [ -z "$RG" ]; then
  echo "Usage: ./validate-plan.sh <function-app-name> <resource-group>"
  exit 1
fi

PLAN_KIND=$(az functionapp show --name $FUNC_NAME --resource-group $RG \
  --query "kind" -o tsv 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "⚠️ Function App '$FUNC_NAME' not found in resource group '$RG'"
  exit 1
fi

if [[ "$PLAN_KIND" == *"functionapp"* ]]; then
  echo "✅ Function App '$FUNC_NAME' is configured correctly"
else
  echo "⚠️ WARNING: Function App may not be using correct plan type"
  echo "   Expected: Flex Consumption"
  echo "   Current kind: $PLAN_KIND"
fi
```

---

## Component 3: Deployment Reports

### Report Template Design (FR-013)

**Location:** Generated in `clients/{client-name}/`

**Security Requirements:**
- NO credentials (API keys, passwords, secrets)
- NO tenant IDs (could identify clients)
- Only metadata (dates, resource names, status)

### Report Template

```markdown
# Deployment Report: {CLIENT_NAME}

**Date:** {DEPLOYMENT_DATE}
**Deployed By:** {TECHNICIAN_NAME}
**Status:** ✅ Success

---

## Resources Created

| Resource Type | Name | Resource Group |
|--------------|------|----------------|
| Function App | {func_name} | {rg_name} |
| Storage Account | {storage_name} | {rg_name} |
| Translator | {translator_name} (F0) | {rg_name} |
| Entra ID App | TradBot-OneDrive-{client} | N/A |

---

## Configuration Summary

- **Translation Service:** Azure Translator (F0 - Free tier)
- **Function Plan:** Flex Consumption
- **Deployment Method:** func azure functionapp publish
- **OneDrive Integration:** Enabled

---

## Next Steps for Client

1. Access the bot via Microsoft Teams or Power Platform
2. Upload documents to translate
3. Translated documents saved to OneDrive

---

⚠️ **Note:** This report contains no credentials.
Credentials are provided separately during deployment session.

---

*Generated by trad-bot-src deployment system*
*Report created: {TIMESTAMP}*
```

### Report Generation in CLAUDE.md

```bash
# Generate deployment report (NO credentials!)
CLIENT_NAME="client-name"
REPORT_DIR="clients/$CLIENT_NAME"
mkdir -p "$REPORT_DIR"

cat > "$REPORT_DIR/deployment-report.md" << EOF
# Deployment Report: $CLIENT_NAME

**Date:** $(date +%Y-%m-%d)
**Status:** ✅ Success

## Resources Created

| Resource Type | Name |
|--------------|------|
| Function App | $FUNCTION_APP_NAME |
| Storage Account | $STORAGE_NAME |
| Translator | $TRANSLATOR_NAME (F0) |

---

⚠️ **This report contains NO credentials.**

EOF

echo "📄 Report generated: $REPORT_DIR/deployment-report.md"
```

---

## Component 4: File Organization

### Directory Structure

```
trad-bot-src/
├── CLAUDE.md              # Main deployment instructions
├── .gitignore             # MUST exclude credentials
│
├── scripts/               # Validation scripts
│   ├── check-all.sh
│   ├── check-resources.sh
│   ├── validate-sku.sh
│   └── validate-plan.sh
│
├── clients/               # Deployment reports (GITIGNORED)
│   └── {client-name}/
│       └── deployment-report.md
│
├── docs/                  # BMAD documentation
│   ├── product-brief-*.md
│   ├── prd-*.md
│   └── architecture-*.md
│
├── bmad/                  # BMAD config
│   └── config.yaml
│
├── Solution/              # Power Platform solution
│   └── BotCopilotTraducteur_*.zip
│
└── src/                   # Azure Functions code (existing)
    └── ...
```

### .gitignore Updates

**CRITICAL for NFR-001 (No Credential Persistence):**

```gitignore
# Deployment outputs - NEVER commit
clients/

# Credentials - NEVER commit
*.env
.env.*
credentials.json
secrets.json

# Azure Function local settings
local.settings.json

# Temporary files
*.tmp
*.log
```

---

## NFR Coverage

### NFR-001: Security - No Credential Persistence

**Requirement:** Credentials must never be stored outside the current deployment session.

**Architecture Solution:**
1. **CLAUDE.md** displays credentials with `echo` commands only
2. **No file writes** for credentials
3. **clients/** folder in .gitignore
4. **Deployment reports** explicitly exclude credentials
5. **Clear warnings** in CLAUDE.md about credential handling

**Validation:**
- `grep -r "KEY\|SECRET\|PASSWORD" clients/` should return nothing
- .gitignore verified to exclude clients/

---

### NFR-002: Security - No Sensitive Data in Reports

**Requirement:** Deployment reports must contain no sensitive information.

**Architecture Solution:**
1. **Report template** has no credential placeholders
2. **Template validation** - no fields for keys/secrets
3. **Explicit comment** in reports: "This report contains no credentials"

**Validation:**
- Reports reviewed before commit
- No variables ending in KEY, SECRET, PASSWORD

---

### NFR-003: Usability - Beginner-Friendly Instructions

**Requirement:** Instructions must be understandable by technicians with no Azure experience.

**Architecture Solution:**
1. **Step-by-step format** with numbered phases
2. **WHY column** in rules table explains reasoning
3. **Copy-paste commands** with clear variable names
4. **Visual separation** using markdown headers and boxes
5. **ALWAYS/NEVER tables** - unambiguous rules

**Validation:**
- Test with beginner technician
- No assumed Azure knowledge

---

### NFR-004: Usability - Clear Error Messages

**Requirement:** Error messages should explain what happened and suggest corrective action.

**Architecture Solution:**
1. **Validation scripts** output clear warnings
2. **Common errors section** in CLAUDE.md
3. **Each warning includes** suggestion (e.g., "Consider using F0 instead")

**Validation:**
- Scripts tested with error conditions
- Messages reviewed for clarity

---

### NFR-005: Reliability - Consistent Deployment Process

**Requirement:** Every deployment must follow the exact same process.

**Architecture Solution:**
1. **Single deployment method:** `func azure functionapp publish` only
2. **Single login method:** `az login --tenant` only
3. **Fixed phase order:** Phase 0 → Phase 1 → Phase 2
4. **No conditional paths** or alternatives in instructions

**Validation:**
- CLAUDE.md reviewed for alternative paths
- No "or" options for critical commands

---

### NFR-006: Reliability - Idempotent Resource Checks

**Requirement:** Running resource checks multiple times produces the same result.

**Architecture Solution:**
1. **All scripts are read-only** (only `az ... list` commands)
2. **No resource creation** in validation scripts
3. **Safe to run repeatedly** during troubleshooting

**Validation:**
- Scripts contain no `create`, `update`, `delete` commands
- Multiple runs produce identical output

---

## Security Architecture

### Credential Flow

```
┌─────────────────┐    Session Only    ┌─────────────────┐
│  Azure CLI (az) │ ──────────────────▶│  Terminal Echo  │
│                 │    Credentials     │  (displayed)    │
│  Creates/Gets   │                    │                 │
│  credentials    │                    │  NOT SAVED      │
└─────────────────┘                    └─────────────────┘
                                              │
                                              │ Copy/Paste
                                              ▼
                                       ┌─────────────────┐
                                       │  Power Platform │
                                       │  Configuration  │
                                       │  (in browser)   │
                                       └─────────────────┘
```

### Security Boundaries

| Zone | What's Allowed | What's NOT Allowed |
|------|---------------|-------------------|
| **CLAUDE.md** | Display commands with `echo` | File writes with credentials |
| **scripts/** | Read-only az commands | Create/modify/delete resources |
| **clients/** | Metadata reports | Any credentials |
| **Repository** | Public docs, code | Credentials, secrets, .env files |

### Credential Types and Handling

| Credential | Used For | Displayed | Saved |
|-----------|----------|-----------|-------|
| Function URL | Power Platform | Yes (session) | No |
| Function Key | Power Platform | Yes (session) | No |
| Storage Key | Power Platform | Yes (session) | No |
| Translator Key | Azure Function (env var) | No | In Azure only |
| Client Secret | Entra ID | Yes (session) | No |

---

## Requirements Traceability

### Functional Requirements Coverage

| FR ID | Requirement | Component | Implementation |
|-------|-------------|-----------|----------------|
| FR-001 | Enforce Flex Consumption | CLAUDE.md | ALWAYS rule + command |
| FR-002 | Enforce F0 Translator SKU | CLAUDE.md | ALWAYS rule + validate-sku.sh |
| FR-003 | Enforce Correct Azure Login | CLAUDE.md | ALWAYS rule (az login --tenant) |
| FR-004 | Enforce Single Deployment Method | CLAUDE.md | NEVER rule (no zip deploy) |
| FR-005 | Protect Auto-Created Variables | CLAUDE.md | NEVER rule + variable list |
| FR-006 | Provide Correct Function App Credentials | CLAUDE.md | Credentials section |
| FR-007 | Provide Blob Container Credentials | CLAUDE.md | Credentials section |
| FR-008 | Pre-Deployment Resource Check | CLAUDE.md + scripts | check-resources.sh |
| FR-009 | Validation Script - Check Resources | scripts/ | check-resources.sh |
| FR-010 | Validation Script - Verify SKU | scripts/ | validate-sku.sh |
| FR-011 | Validation Script - Verify Plan | scripts/ | validate-plan.sh |
| FR-012 | Clear Credentials Display | CLAUDE.md | Formatted echo block |
| FR-013 | Deployment Report Generation | CLAUDE.md | Report template |

### Non-Functional Requirements Coverage

| NFR ID | Requirement | Solution | Validation |
|--------|-------------|----------|------------|
| NFR-001 | No Credential Persistence | Session-only display, .gitignore | Grep for credentials |
| NFR-002 | No Sensitive Data in Reports | Credential-free template | Report review |
| NFR-003 | Beginner-Friendly | ALWAYS/NEVER tables, WHY column | User test |
| NFR-004 | Clear Error Messages | Script warnings with suggestions | Error condition test |
| NFR-005 | Consistent Process | Single path, no alternatives | Document review |
| NFR-006 | Idempotent Checks | Read-only scripts | Multiple run test |

---

## Trade-offs & Decision Log

### Decision 1: Inline Commands vs. Separate Scripts

**Choice:** Both approaches

**Trade-off:**
- ✅ Gain: Flexibility, redundancy, clear instructions in CLAUDE.md
- ❌ Lose: Some duplication between CLAUDE.md and scripts

**Rationale:** Beginners benefit from seeing commands inline. Scripts provide additional safety net.

---

### Decision 2: Report Location

**Choice:** clients/ folder (gitignored)

**Trade-off:**
- ✅ Gain: Reports exist locally for reference
- ❌ Lose: Reports not in version control

**Rationale:** Security trumps history. Reports can be regenerated if needed.

---

### Decision 3: French vs. English Documentation

**Choice:** Keep existing French in CLAUDE.md

**Trade-off:**
- ✅ Gain: Consistent with current team language
- ❌ Lose: Not accessible to non-French speakers

**Rationale:** Out of scope per PRD. Focus on content, not translation.

---

## Implementation Guidelines

### CLAUDE.md Rewrite Order

1. **Add Critical Rules section** (TOP) - FR-001 to FR-005
2. **Restructure Credentials section** - FR-006, FR-007, FR-012
3. **Add validation commands** inline - FR-008
4. **Add report template** - FR-013
5. **Add NEVER rules** for auto-created variables - FR-005
6. **Review and test** with beginner technician

### Script Creation Order

1. **check-resources.sh** (FR-009) - Foundation
2. **validate-sku.sh** (FR-010) - Depends on resources
3. **validate-plan.sh** (FR-011) - Depends on resources
4. **check-all.sh** - Master script

### Testing Strategy

1. **CLAUDE.md Review:** Read through as beginner
2. **Script Tests:** Run each script with various conditions
3. **Integration Test:** Full deployment with new instructions
4. **Security Audit:** Verify no credentials in files

---

## Open Issues & Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| AI still makes errors | Medium | High | Multiple checkpoints, ALWAYS/NEVER rules |
| Technician skips validation | Medium | Medium | Make validation mandatory in CLAUDE.md |
| .gitignore not updated | Low | High | Verify during implementation |

---

## Assumptions & Constraints

### Assumptions

- OpenCode reads CLAUDE.md from project root
- Azure CLI is available and authenticated
- Technicians can run bash scripts
- Power Platform configured via browser (not automated)

### Constraints

| Constraint | Source | Impact |
|-----------|--------|--------|
| Flex Consumption only | Microsoft deprecation | FR-001 |
| F0 SKU only | Cost control | FR-002 |
| Delegated access | Be-Cloud partner model | FR-003 |
| No credential storage | Security policy | NFR-001, NFR-002 |

---

## Future Considerations

- **Automated testing** of deployment process
- **Dashboard** for tracking deployments across clients
- **Multi-language** documentation support
- **Rollback** procedures for failed deployments

---

## Approval & Sign-off

**Review Status:**
- [ ] Technical Lead
- [ ] Product Owner (Eric)
- [ ] Security Review (Credentials handling)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Eric | Initial architecture |

---

## Next Steps

### Phase 4: Sprint Planning & Implementation

Run `/bmad:sprint-planning` to:
- Break epics into detailed user stories
- Estimate story complexity
- Plan sprint iterations
- Begin implementation following this architectural blueprint

**Implementation Principles:**
1. Security first - verify no credentials in any files
2. Test with beginner technician before finalizing
3. Follow component order (CLAUDE.md → Scripts → Reports)
4. Validate each FR and NFR as implemented

---

**This document was created using BMAD Method v6 - Phase 3 (Solutioning)**

*To continue: Run `/bmad:workflow-status` to see your progress and next recommended workflow.*
