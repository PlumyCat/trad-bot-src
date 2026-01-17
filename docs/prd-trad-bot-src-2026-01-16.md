# Product Requirements Document: trad-bot-src

**Date:** 2026-01-16
**Author:** Eric
**Version:** 1.0
**Project Type:** API / Backend Service
**Project Level:** 2 (Medium - 5-15 stories)
**Status:** Draft

---

## Document Overview

This Product Requirements Document (PRD) defines the functional and non-functional requirements for the trad-bot-src deployment improvement project. It serves as the source of truth for what will be built and provides traceability from requirements through implementation.

**Related Documents:**
- Product Brief: `docs/product-brief-trad-bot-src-2026-01-16.md`

---

## Executive Summary

This project improves the deployment automation for an Azure Function-based translation service integrated with Microsoft Copilot Studio. The goal is to make the deployment process foolproof for Be-Cloud technicians with limited Azure experience by rewriting CLAUDE.md instructions with strict guardrails, adding validation scripts, and ensuring correct credentials are provided.

**Key Problems Addressed:**
- Wrong Azure Function plan selection (must be Flex Consumption)
- Wrong Translator SKU selection (must be F0, not S1)
- Incorrect Azure login method
- Inconsistent deployment methods
- Wrong credentials provided (Function vs Translator)
- Missing Blob container credentials
- Accidental modification of auto-created variables

---

## Product Goals

### Business Objectives

- **Zero deployment errors:** Eliminate mistakes caused by unclear instructions
- **Enable non-experts to deploy:** Any Be-Cloud technician can deploy successfully without Azure knowledge
- **Prevent cost overruns:** Ensure F0 (free) Translator SKU is always used
- **Secure credential handling:** No credentials stored outside current session

### Success Metrics

| Metric | Target |
|--------|--------|
| Deployment success rate | 100% |
| Deployments requiring intervention | 0 |
| Wrong SKU selections | 0 |
| Wrong plan type selections | 0 |
| Credential leaks | 0 |

---

## Functional Requirements

Functional Requirements (FRs) define **what** the system does - specific features and behaviors.

Each requirement includes:
- **ID**: Unique identifier (FR-001, FR-002, etc.)
- **Priority**: Must Have / Should Have / Could Have (MoSCoW)
- **Description**: What the system should do
- **Acceptance Criteria**: How to verify it's complete

---

### FR-001: Enforce Flex Consumption Plan

**Priority:** Must Have

**Description:**
CLAUDE.md must enforce use of Azure Function Flex Consumption plan only. The simple Consumption plan is being deprecated and must never be used.

**Acceptance Criteria:**
- [ ] Instructions explicitly state "ALWAYS use Flex Consumption plan"
- [ ] Instructions explicitly state "NEVER use simple Consumption plan"
- [ ] Reason documented (deprecation by Microsoft)
- [ ] Correct az command provided for Flex Consumption

**Dependencies:** None

---

### FR-002: Enforce F0 Translator SKU

**Priority:** Must Have

**Description:**
CLAUDE.md must enforce use of F0 (free) SKU for Azure Translator. Using S1 costs $35/month and is unnecessary for this use case.

**Acceptance Criteria:**
- [ ] Instructions explicitly state "ALWAYS use --sku F0"
- [ ] Instructions explicitly state "NEVER use S1 (costs $35/month)"
- [ ] Require check for existing F0 Translator before creating new one
- [ ] Provide command to list existing Translators with SKU

**Dependencies:** FR-008 (resource check)

---

### FR-003: Enforce Correct Azure Login

**Priority:** Must Have

**Description:**
CLAUDE.md must enforce `az login --tenant <tenantid>` for delegated access to client tenants. Other login methods do not work with Be-Cloud's partner access model.

**Acceptance Criteria:**
- [ ] Instructions state "ONLY use az login --tenant <tenantid>"
- [ ] Explains why (delegated partner access requires tenant specification)
- [ ] Provides example command with placeholder

**Dependencies:** None

---

### FR-004: Enforce Single Deployment Method

**Priority:** Must Have

**Description:**
CLAUDE.md must enforce `func azure functionapp publish` as the only deployment method. Zip deploy must never be used to ensure consistency.

**Acceptance Criteria:**
- [ ] Instructions state "ONLY use func azure functionapp publish"
- [ ] Instructions state "NEVER use zip deploy"
- [ ] Provides complete publish command with parameters

**Dependencies:** None

---

### FR-005: Protect Auto-Created Variables

**Priority:** Must Have

**Description:**
CLAUDE.md must prohibit modification of auto-created Azure environment variables. Modifying these variables breaks deployments and requires complete rebuilds.

**Acceptance Criteria:**
- [ ] Instructions state "NEVER modify auto-created Azure variables"
- [ ] Lists which variables are auto-created (WEBSITE_*, AzureWebJobsStorage, etc.)
- [ ] Explains consequence (requires full rebuild if modified)
- [ ] Specifies which variables CAN be modified (custom app settings only)

**Dependencies:** None

---

### FR-006: Provide Correct Function App Credentials

**Priority:** Must Have

**Description:**
CLAUDE.md must provide Function App URL and key for Power Platform configuration, NOT the Translator credentials. These are distinct and must not be confused.

**Acceptance Criteria:**
- [ ] Clear section titled "Credentials for Power Platform"
- [ ] Shows Function URL format: `https://{function-name}.azurewebsites.net/api`
- [ ] Shows Function Key (functionKeys.default)
- [ ] Explicitly differentiates from Translator credentials
- [ ] Provides az commands to retrieve these credentials

**Dependencies:** None

---

### FR-007: Provide Blob Container Credentials

**Priority:** Must Have

**Description:**
CLAUDE.md must provide Blob storage credentials (container name and storage key) for Power Platform solution file upload.

**Acceptance Criteria:**
- [ ] Shows Container name: `doc-to-trad`
- [ ] Shows Storage Key retrieval command
- [ ] Explains purpose (file upload for Power Platform processing)
- [ ] Included in "Credentials for Power Platform" section

**Dependencies:** FR-006

---

### FR-008: Pre-Deployment Resource Check

**Priority:** Must Have

**Description:**
CLAUDE.md must require checking existing resources before creating new ones to avoid duplicates and reuse existing F0 Translators.

**Acceptance Criteria:**
- [ ] Mandatory step to check for existing Translator (F0)
- [ ] Mandatory step to check for existing Storage Account
- [ ] Mandatory step to check for existing Function App
- [ ] Provides az commands for each check
- [ ] Instructions to reuse existing resources when found

**Dependencies:** None

---

### FR-009: Validation Script - Check Existing Resources

**Priority:** Should Have

**Description:**
Create a validation script that lists existing Azure resources before deployment to help technicians make informed decisions.

**Acceptance Criteria:**
- [ ] Script lists existing Translators with SKU
- [ ] Script lists existing Storage Accounts
- [ ] Script lists existing Function Apps
- [ ] Output is clear and formatted for easy reading
- [ ] Script is read-only (no side effects)

**Dependencies:** None

---

### FR-010: Validation Script - Verify Correct SKU

**Priority:** Should Have

**Description:**
Create a validation script to verify F0 SKU is used for Azure Translator, with warning if S1 is detected.

**Acceptance Criteria:**
- [ ] Checks if Translator exists
- [ ] Verifies SKU is F0
- [ ] Displays warning if S1 detected
- [ ] Suggests corrective action

**Dependencies:** FR-009

---

### FR-011: Validation Script - Verify Plan Type

**Priority:** Should Have

**Description:**
Create a validation script to verify Azure Function uses Flex Consumption plan.

**Acceptance Criteria:**
- [ ] Checks Function App plan type
- [ ] Verifies Flex Consumption is used
- [ ] Displays warning if wrong plan type detected
- [ ] Suggests corrective action

**Dependencies:** FR-009

---

### FR-012: Clear Credentials Display

**Priority:** Must Have

**Description:**
At the end of Phase 1, display all required credentials in a clear, copy-paste ready format for Power Platform configuration.

**Acceptance Criteria:**
- [ ] Shows Function URL and Function Key
- [ ] Shows Container name and Storage Key
- [ ] Formatted clearly with visual separation
- [ ] Labels prevent confusion between credential types
- [ ] Easy to copy-paste

**Dependencies:** FR-006, FR-007

---

### FR-013: Deployment Report Generation

**Priority:** Must Have

**Description:**
Generate a deployment report in the "clients" folder after successful deployment. Report must contain NO credentials for security.

**Acceptance Criteria:**
- [ ] Report created in `clients/{client-name}/` folder
- [ ] Contains deployment date and timestamp
- [ ] Contains client name and resource names created
- [ ] Contains NO credentials (API keys, passwords, secrets)
- [ ] No credentials stored outside current session
- [ ] Template provided in CLAUDE.md

**Dependencies:** None

---

## Non-Functional Requirements

Non-Functional Requirements (NFRs) define **how** the system performs - quality attributes and constraints.

---

### NFR-001: Security - No Credential Persistence

**Priority:** Must Have

**Description:**
Credentials must never be stored outside the current deployment session. This prevents accidental exposure in git commits or shared documents.

**Acceptance Criteria:**
- [ ] No credentials in git commits (verify .gitignore)
- [ ] No credentials in deployment reports
- [ ] Credentials displayed only during active session
- [ ] Clear warning in CLAUDE.md about credential handling
- [ ] No credentials in clients/ folder reports

**Rationale:**
Credentials stored in files could be accidentally committed to git or shared, creating security vulnerabilities for clients.

---

### NFR-002: Security - No Sensitive Data in Reports

**Priority:** Must Have

**Description:**
Deployment reports must contain no sensitive information that could compromise client security.

**Acceptance Criteria:**
- [ ] No API keys, passwords, or secrets
- [ ] No tenant IDs (could identify specific clients)
- [ ] Only deployment metadata (date, resource names, status)
- [ ] Report template enforces this restriction

**Rationale:**
Reports may be shared or stored long-term; they must be safe to share without review.

---

### NFR-003: Usability - Beginner-Friendly Instructions

**Priority:** Must Have

**Description:**
Instructions must be understandable by Be-Cloud technicians with no Azure experience.

**Acceptance Criteria:**
- [ ] Clear step-by-step format with numbered phases
- [ ] Explains WHY for each rule (not just WHAT)
- [ ] No assumed Azure knowledge
- [ ] Copy-paste ready commands
- [ ] Visual separation between phases

**Rationale:**
The primary users are beginners; instructions must guide them without requiring external research.

---

### NFR-004: Usability - Clear Error Messages

**Priority:** Should Have

**Description:**
When something goes wrong, the error message should explain what happened and suggest corrective action.

**Acceptance Criteria:**
- [ ] Errors explain what went wrong
- [ ] Errors suggest specific corrective action
- [ ] Common errors have dedicated guidance in CLAUDE.md
- [ ] Error patterns documented with solutions

**Rationale:**
Beginners need guidance to recover from errors without escalation.

---

### NFR-005: Reliability - Consistent Deployment Process

**Priority:** Must Have

**Description:**
Every deployment must follow the exact same process to ensure predictable outcomes.

**Acceptance Criteria:**
- [ ] Single deployment method enforced (func publish)
- [ ] Single login method enforced (az login --tenant)
- [ ] Same phase order every time (Phase 0 → 1 → 2)
- [ ] No alternative paths or shortcuts
- [ ] No conditional logic that changes the process

**Rationale:**
Consistency reduces errors and makes troubleshooting easier.

---

### NFR-006: Reliability - Idempotent Resource Checks

**Priority:** Should Have

**Description:**
Running resource checks multiple times produces the same result with no side effects.

**Acceptance Criteria:**
- [ ] Check scripts are read-only
- [ ] No resources created or modified by checks
- [ ] Safe to run repeatedly during troubleshooting
- [ ] No state changes from validation

**Rationale:**
Technicians should be able to run checks multiple times without fear of breaking things.

---

## Epics

Epics are logical groupings of related functionality that will be broken down into user stories during sprint planning (Phase 4).

Each epic maps to multiple functional requirements and will generate 2-10 stories.

---

### EPIC-001: CLAUDE.md Instruction Overhaul

**Description:**
Completely rewrite CLAUDE.md with strict guardrails, explicit rules (ALWAYS/NEVER), and a clear credentials section. This is the core deliverable that addresses all deployment error types.

**Functional Requirements:**
- FR-001: Enforce Flex Consumption Plan
- FR-002: Enforce F0 Translator SKU
- FR-003: Enforce Correct Azure Login
- FR-004: Enforce Single Deployment Method
- FR-005: Protect Auto-Created Variables
- FR-006: Provide Correct Function App Credentials
- FR-007: Provide Blob Container Credentials
- FR-008: Pre-Deployment Resource Check

**Story Count Estimate:** 5-7 stories

**Priority:** Must Have

**Business Value:**
Directly addresses all documented deployment errors. This epic alone could achieve the goal of zero deployment errors.

---

### EPIC-002: Validation Scripts

**Description:**
Create pre-deployment validation scripts that check resources and configuration before deployment begins. These scripts help technicians verify they're set up correctly.

**Functional Requirements:**
- FR-009: Validation Script - Check Existing Resources
- FR-010: Validation Script - Verify Correct SKU
- FR-011: Validation Script - Verify Plan Type

**Story Count Estimate:** 3-4 stories

**Priority:** Should Have

**Business Value:**
Provides additional safety net beyond CLAUDE.md instructions. Catches errors before they cause problems.

---

### EPIC-003: Deployment Reporting

**Description:**
Generate clear credentials display during deployment and create secure deployment reports for the clients folder. Ensures credentials are visible when needed but never persisted.

**Functional Requirements:**
- FR-012: Clear Credentials Display
- FR-013: Deployment Report Generation

**Story Count Estimate:** 2-3 stories

**Priority:** Must Have

**Business Value:**
Ensures technicians have the credentials they need for Power Platform configuration, while maintaining security by never storing credentials.

---

## User Stories (High-Level)

Detailed user stories will be created during sprint planning (Phase 4).

**Preliminary story format:**
> "As a [user type], I want [goal] so that [benefit]."

---

## User Personas

### Primary Persona: Be-Cloud Technician

| Attribute | Description |
|-----------|-------------|
| Role | Internal technical support staff |
| Azure Experience | Beginner - no prior Azure knowledge |
| Context | Using OpenCode in a container to deploy translation bot |
| Key Needs | Clear, error-proof deployment instructions |
| Pain Points | Makes costly mistakes, inconsistent results, no confidence |
| Goals | Successfully deploy to client tenants without help |

### Secondary Persona: Client End-User

| Attribute | Description |
|-----------|-------------|
| Role | Employee at Be-Cloud client company |
| Interaction | Uses Copilot Studio translation bot via Teams/Power Platform |
| Key Needs | Working translation service that preserves document formatting |
| Impact | Beneficiary of successful deployments |

---

## User Flows

### Primary Flow: Complete Deployment

1. Technician starts OpenCode container
2. Container pulls latest trad-bot-src repository
3. Technician initiates deployment with client name
4. **Phase 0:** Create Entra ID App (admin account)
5. **Phase 1:** Deploy Azure resources (delegated account)
6. System displays credentials for Power Platform
7. **Phase 2:** Configure Power Platform (browser)
8. System generates deployment report (no credentials)
9. Deployment complete

### Validation Flow: Pre-Deployment Check

1. Technician runs validation script
2. Script checks for existing resources
3. Script verifies SKU and plan types
4. Script displays any warnings
5. Technician proceeds or corrects issues

---

## Dependencies

### Internal Dependencies

- OpenCode container with pre-installed configuration
- Azure CLI available in container
- trad-bot-src repository accessible via git
- Documentation site at localhost:5545

### External Dependencies

- Azure subscription accessible via delegated access
- Client tenant with appropriate permissions
- Microsoft Graph API for Entra ID operations
- Azure Translator API availability
- Power Platform environment

---

## Assumptions

- OpenCode is pre-installed and configured in the deployment container
- Container has Azure CLI available and functional
- Technicians have access to Be-Cloud's delegated credentials
- Clients have valid Azure subscriptions accessible via delegation
- Browser is available for viewing localhost:5545/procedure
- Git access to trad-bot-src repository is available
- Power Platform environments exist for clients

---

## Out of Scope

- Modifying the Copilot Studio bot itself
- Adding new translation features or capabilities
- Multi-language support for documentation
- Refactoring the Azure Functions translation code
- Changes to the Power Platform solution package (.zip)
- Automated testing of the translation function
- Dashboard for deployment tracking
- Integration with ticketing systems

---

## Open Questions

No open questions at this time. All requirements are clear and complete.

---

## Approval & Sign-off

### Stakeholders

- **Eric (Project Owner)** - High influence. Decision maker for all requirements
- **Be-Cloud Technicians** - High influence. Primary users, will validate usability
- **Be-Cloud Management** - Medium influence. Interested in cost control
- **Client IT Contacts** - Low influence. May need to provide access

### Approval Status

- [x] Product Owner (Eric)
- [ ] Engineering Lead
- [ ] Design Lead
- [ ] QA Lead

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Eric | Initial PRD |

---

## Next Steps

### Phase 3: Architecture

Run `/bmad:architecture` to create system architecture based on these requirements.

The architecture will address:
- CLAUDE.md structure and organization
- Validation script design
- Deployment report format
- Credential display formatting

### Phase 4: Sprint Planning

After architecture is complete, run `/bmad:sprint-planning` to:
- Break epics into detailed user stories
- Estimate story complexity
- Plan sprint iterations
- Begin implementation

---

**This document was created using BMAD Method v6 - Phase 2 (Planning)**

*To continue: Run `/bmad:workflow-status` to see your progress and next recommended workflow.*

---

## Appendix A: Requirements Traceability Matrix

| Epic ID | Epic Name | Functional Requirements | Story Count (Est.) |
|---------|-----------|-------------------------|-------------------|
| EPIC-001 | CLAUDE.md Instruction Overhaul | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008 | 5-7 stories |
| EPIC-002 | Validation Scripts | FR-009, FR-010, FR-011 | 3-4 stories |
| EPIC-003 | Deployment Reporting | FR-012, FR-013 | 2-3 stories |

**Total Estimated Stories:** 10-14 stories

---

## Appendix B: Prioritization Details

### Functional Requirements by Priority

| Priority | Count | Requirements |
|----------|-------|--------------|
| Must Have | 10 | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-012, FR-013 |
| Should Have | 3 | FR-009, FR-010, FR-011 |
| Could Have | 0 | - |

### Non-Functional Requirements by Priority

| Priority | Count | Requirements |
|----------|-------|--------------|
| Must Have | 4 | NFR-001, NFR-002, NFR-003, NFR-005 |
| Should Have | 2 | NFR-004, NFR-006 |

### Summary

- **13 Functional Requirements** (10 Must Have, 3 Should Have)
- **6 Non-Functional Requirements** (4 Must Have, 2 Should Have)
- **3 Epics** (2 Must Have, 1 Should Have)
- **10-14 Stories Estimated**
