# Sprint Plan: trad-bot-src

**Date:** 2026-01-16
**Scrum Master:** Eric
**Project Level:** 2 (Medium)
**Total Stories:** 13
**Total Points:** 36
**Planned Sprints:** 2

---

## Executive Summary

This sprint plan breaks down the deployment automation improvement project into 13 user stories across 2 sprints. The goal is to make the Azure Function deployment process foolproof for Be-Cloud technicians with limited Azure experience.

**Key Metrics:**
- Total Stories: 13
- Total Points: 36
- Sprints: 2
- Team Capacity: 30 points per sprint
- Target Completion: 4 weeks

---

## Story Inventory

### EPIC-001: CLAUDE.md Instruction Overhaul (22 points)

---

### STORY-001: Add Critical Rules Section at Top

**Epic:** EPIC-001 - CLAUDE.md Instruction Overhaul
**Priority:** Must Have
**Points:** 5

**User Story:**
As a Be-Cloud technician
I want ALWAYS/NEVER rules clearly visible at the top of CLAUDE.md
So that I never make critical deployment errors

**Acceptance Criteria:**
- [ ] ALWAYS rules section at document top
- [ ] "ALWAYS use Flex Consumption plan" with reason (deprecation)
- [ ] "ALWAYS use --sku F0" with cost warning ($35/month)
- [ ] "ALWAYS use az login --tenant <tenantid>" with reason (delegated access)
- [ ] "ALWAYS use func azure functionapp publish" only
- [ ] NEVER rules section with explicit prohibitions
- [ ] Visual formatting (bold, emoji, colors in markdown)

**Technical Notes:**
Restructure CLAUDE.md to put critical rules at the very top, before any deployment phases. Use clear visual hierarchy.

**Dependencies:** None

**FRs Addressed:** FR-001, FR-002, FR-003, FR-004

---

### STORY-002: Add Protected Variables Documentation

**Epic:** EPIC-001 - CLAUDE.md Instruction Overhaul
**Priority:** Must Have
**Points:** 2

**User Story:**
As a Be-Cloud technician
I want a clear list of auto-created Azure variables I must never modify
So that I don't accidentally break deployments requiring full rebuilds

**Acceptance Criteria:**
- [ ] List of auto-created variables (WEBSITE_*, AzureWebJobsStorage, etc.)
- [ ] Clear "NEVER modify" warning
- [ ] Explanation of consequences (full rebuild required)
- [ ] List of variables that CAN be modified (custom app settings)
- [ ] Example of safe vs unsafe modifications

**Technical Notes:**
Add this as a subsection within the critical rules or as a dedicated callout box.

**Dependencies:** STORY-001

**FRs Addressed:** FR-005

---

### STORY-003: Create Pre-Deployment Resource Check Section

**Epic:** EPIC-001 - CLAUDE.md Instruction Overhaul
**Priority:** Must Have
**Points:** 3

**User Story:**
As a Be-Cloud technician
I want mandatory resource check commands before creating any resources
So that I don't create duplicate resources or miss existing F0 Translators

**Acceptance Criteria:**
- [ ] Mandatory step labeled "BEFORE creating any resource"
- [ ] az command to list existing Translators with SKU
- [ ] az command to list existing Storage Accounts
- [ ] az command to list existing Function Apps
- [ ] Instructions to reuse existing F0 Translator if found
- [ ] Clear guidance on when to create vs reuse

**Technical Notes:**
This section should be placed at the start of Phase 1, before any resource creation.

**Dependencies:** None

**FRs Addressed:** FR-008

---

### STORY-004: Create Credentials for Power Platform Section

**Epic:** EPIC-001 - CLAUDE.md Instruction Overhaul
**Priority:** Must Have
**Points:** 3

**User Story:**
As a Be-Cloud technician
I want a clear section showing which credentials to provide to Power Platform
So that I give the correct credentials (Function App, not Translator)

**Acceptance Criteria:**
- [ ] Section titled "Credentials for Power Platform" (clear, distinct)
- [ ] Function URL format: `https://{function-name}.azurewebsites.net/api`
- [ ] Function Key retrieval command
- [ ] Blob Container name: `doc-to-trad`
- [ ] Storage Key retrieval command
- [ ] Explicit note: "These are NOT the Translator credentials"
- [ ] Visual separation from Translator credential section

**Technical Notes:**
Must clearly differentiate Function App credentials from Translator credentials to avoid confusion.

**Dependencies:** None

**FRs Addressed:** FR-006, FR-007

---

### STORY-005: Restructure Phase Documentation

**Epic:** EPIC-001 - CLAUDE.md Instruction Overhaul
**Priority:** Must Have
**Points:** 5

**User Story:**
As a Be-Cloud technician
I want clear visual separation between deployment phases
So that I always know which phase I'm in and what account to use

**Acceptance Criteria:**
- [ ] Phase 0 clearly marked with required account (Admin Global client)
- [ ] Phase 1 clearly marked with required account (Delegated Be-Cloud)
- [ ] Phase 2 clearly marked (Browser only, no az commands)
- [ ] Visual headers/dividers between phases
- [ ] Account type reminder at start of each phase
- [ ] "Phase 2 = Documentation" callout (no az login needed)
- [ ] Numbered steps within each phase

**Technical Notes:**
Review entire CLAUDE.md structure and reorganize for clarity. Ensure consistent formatting throughout.

**Dependencies:** STORY-001, STORY-003, STORY-004

**FRs Addressed:** NFR-003, NFR-005

---

### STORY-006: Add Error Guidance Section

**Epic:** EPIC-001 - CLAUDE.md Instruction Overhaul
**Priority:** Should Have
**Points:** 4

**User Story:**
As a Be-Cloud technician
I want documented solutions for common deployment errors
So that I can fix problems without escalation

**Acceptance Criteria:**
- [ ] Section titled "Common Errors and Solutions"
- [ ] Error: Wrong SKU selected → Solution: Delete and recreate with F0
- [ ] Error: Wrong plan type → Solution: Delete and recreate with Flex Consumption
- [ ] Error: Login failed → Solution: Use az login --tenant
- [ ] Error: Deployment failed → Solution: Check variables not modified
- [ ] Error: Credentials not working → Solution: Verify Function vs Translator creds
- [ ] Each error includes specific corrective command

**Technical Notes:**
Place at end of document or as appendix for reference during troubleshooting.

**Dependencies:** STORY-001

**FRs Addressed:** NFR-004

---

### EPIC-002: Validation Scripts (9 points)

---

### STORY-007: Create check-resources.sh Script

**Epic:** EPIC-002 - Validation Scripts
**Priority:** Should Have
**Points:** 3

**User Story:**
As a Be-Cloud technician
I want a script that lists all existing Azure resources
So that I can see what already exists before deployment

**Acceptance Criteria:**
- [ ] Script named `scripts/check-resources.sh`
- [ ] Lists existing Translators with SKU (table format)
- [ ] Lists existing Storage Accounts with resource group
- [ ] Lists existing Function Apps with resource group
- [ ] Clear, formatted output for easy reading
- [ ] Read-only operation (no side effects)
- [ ] Requires subscription to be set first

**Technical Notes:**
Use `az` CLI commands with `--query` and `-o table` for clean output. Script must be idempotent.

**Dependencies:** None

**FRs Addressed:** FR-009

---

### STORY-008: Create validate-sku.sh Script

**Epic:** EPIC-002 - Validation Scripts
**Priority:** Should Have
**Points:** 2

**User Story:**
As a Be-Cloud technician
I want a script that verifies the Translator SKU is F0
So that I catch wrong SKU selection before it costs money

**Acceptance Criteria:**
- [ ] Script named `scripts/validate-sku.sh`
- [ ] Takes Translator name and resource group as parameters
- [ ] Checks if Translator exists
- [ ] Verifies SKU is F0
- [ ] Displays ✓ if F0, ✗ if S1
- [ ] Shows warning message if S1 detected with cost info
- [ ] Suggests corrective action (delete and recreate)

**Technical Notes:**
Exit code 0 for F0, exit code 1 for S1 or not found. Can be used in automation.

**Dependencies:** STORY-007

**FRs Addressed:** FR-010

---

### STORY-009: Create validate-plan.sh Script

**Epic:** EPIC-002 - Validation Scripts
**Priority:** Should Have
**Points:** 2

**User Story:**
As a Be-Cloud technician
I want a script that verifies the Function App uses Flex Consumption
So that I catch wrong plan selection before deployment

**Acceptance Criteria:**
- [ ] Script named `scripts/validate-plan.sh`
- [ ] Takes Function App name and resource group as parameters
- [ ] Checks Function App plan type
- [ ] Verifies Flex Consumption is used
- [ ] Displays ✓ if Flex Consumption, ✗ if wrong plan
- [ ] Shows warning if simple Consumption detected (deprecated)
- [ ] Suggests corrective action

**Technical Notes:**
Exit code 0 for Flex Consumption, exit code 1 for wrong plan. Can be used in automation.

**Dependencies:** STORY-007

**FRs Addressed:** FR-011

---

### STORY-010: Create check-all.sh Master Script

**Epic:** EPIC-002 - Validation Scripts
**Priority:** Should Have
**Points:** 2

**User Story:**
As a Be-Cloud technician
I want a single script that runs all validation checks
So that I can verify everything is correct with one command

**Acceptance Criteria:**
- [ ] Script named `scripts/check-all.sh`
- [ ] Runs check-resources.sh
- [ ] Runs validate-sku.sh (if Translator specified)
- [ ] Runs validate-plan.sh (if Function App specified)
- [ ] Shows summary of all checks (passed/failed count)
- [ ] Non-zero exit if any check fails
- [ ] Usage instructions if run without parameters

**Technical Notes:**
Master script that orchestrates all validations. Should be the recommended entry point.

**Dependencies:** STORY-007, STORY-008, STORY-009

**FRs Addressed:** FR-009, FR-010, FR-011, NFR-006

---

### EPIC-003: Deployment Reporting (5 points)

---

### STORY-011: Add Credentials Display at End of Phase 1

**Epic:** EPIC-003 - Deployment Reporting
**Priority:** Must Have
**Points:** 2

**User Story:**
As a Be-Cloud technician
I want all credentials displayed clearly at the end of Phase 1
So that I have everything needed for Power Platform configuration

**Acceptance Criteria:**
- [ ] Display block at end of Phase 1 in CLAUDE.md
- [ ] Shows Function URL and Function Key
- [ ] Shows Container name (doc-to-trad) and Storage Key
- [ ] Formatted with clear visual separation (box/border)
- [ ] Labels clearly identify each credential
- [ ] Copy-paste ready format
- [ ] Message: "Save these for Phase 2"

**Technical Notes:**
This is an echo block in CLAUDE.md showing the format. AI should display this at end of Phase 1.

**Dependencies:** STORY-004

**FRs Addressed:** FR-012

---

### STORY-012: Create Deployment Report Template

**Epic:** EPIC-003 - Deployment Reporting
**Priority:** Must Have
**Points:** 3

**User Story:**
As a Be-Cloud technician
I want a deployment report template for the clients folder
So that I document each deployment without exposing credentials

**Acceptance Criteria:**
- [ ] Template in CLAUDE.md or separate file
- [ ] Report path: `clients/{client-name}/deployment-{date}.md`
- [ ] Contains: deployment date/time, client name, resource names
- [ ] Contains: deployment status (success/failure)
- [ ] Contains: Phase completion checklist
- [ ] Contains NO credentials (API keys, passwords, secrets)
- [ ] Contains NO tenant IDs
- [ ] Instructions in CLAUDE.md to generate report

**Technical Notes:**
Template should be in CLAUDE.md with placeholders. AI fills in during deployment.

**Dependencies:** None

**FRs Addressed:** FR-013, NFR-001, NFR-002

---

### STORY-013: Set Up .gitignore for Credentials

**Epic:** EPIC-003 - Deployment Reporting
**Priority:** Must Have
**Points:** 1

**User Story:**
As a Be-Cloud technician
I want .gitignore configured to exclude credential files
So that I never accidentally commit sensitive data

**Acceptance Criteria:**
- [ ] .gitignore exists in repository root
- [ ] Excludes any .env files
- [ ] Excludes any credentials.* files
- [ ] Excludes any *secret* files
- [ ] Excludes any *.key files
- [ ] Does NOT exclude clients/ folder (reports are safe)
- [ ] Documented in CLAUDE.md

**Technical Notes:**
Verify existing .gitignore and add patterns if missing. This is a safety net.

**Dependencies:** None

**FRs Addressed:** NFR-001

---

## Sprint Allocation

### Sprint 1 (Weeks 1-2) - 27/30 points (90% utilization)

**Goal:** Complete CLAUDE.md overhaul with all critical rules, credential sections, and phase restructuring

**Stories:**

| Story | Title | Points | Priority |
|-------|-------|--------|----------|
| STORY-001 | Add Critical Rules Section at Top | 5 | Must Have |
| STORY-002 | Add Protected Variables Documentation | 2 | Must Have |
| STORY-003 | Create Pre-Deployment Resource Check Section | 3 | Must Have |
| STORY-004 | Create Credentials for Power Platform Section | 3 | Must Have |
| STORY-005 | Restructure Phase Documentation | 5 | Must Have |
| STORY-011 | Add Credentials Display at End of Phase 1 | 2 | Must Have |
| STORY-012 | Create Deployment Report Template | 3 | Must Have |
| STORY-013 | Set Up .gitignore for Credentials | 1 | Must Have |
| STORY-006 | Add Error Guidance Section | 3* | Should Have |

**Total:** 27 points / 30 capacity

*Note: STORY-006 reduced to 3 points to fit sprint; remaining work moved to Sprint 2 buffer*

**Sprint 1 Deliverables:**
- ✓ CLAUDE.md fully restructured with critical rules
- ✓ All credential sections complete
- ✓ Deployment report template ready
- ✓ .gitignore configured

**Risks:**
- CLAUDE.md restructuring may reveal additional clarity issues
- Mitigation: Leave 3-point buffer for adjustments

**Dependencies:**
- None external; stories have internal dependencies managed by order

---

### Sprint 2 (Weeks 3-4) - 9/30 points (30% utilization)

**Goal:** Implement validation scripts for additional safety net

**Stories:**

| Story | Title | Points | Priority |
|-------|-------|--------|----------|
| STORY-007 | Create check-resources.sh Script | 3 | Should Have |
| STORY-008 | Create validate-sku.sh Script | 2 | Should Have |
| STORY-009 | Create validate-plan.sh Script | 2 | Should Have |
| STORY-010 | Create check-all.sh Master Script | 2 | Should Have |

**Total:** 9 points / 30 capacity

**Sprint 2 Deliverables:**
- ✓ All validation scripts created
- ✓ scripts/ folder with 4 shell scripts
- ✓ Full deployment safety net in place

**Risks:**
- Low utilization provides buffer for Sprint 1 overflow
- Scripts may need adjustment based on actual az CLI output

**Dependencies:**
- Sprint 1 must be complete (CLAUDE.md serves as spec for scripts)

---

## Epic Traceability

| Epic ID | Epic Name | Stories | Total Points | Sprint |
|---------|-----------|---------|--------------|--------|
| EPIC-001 | CLAUDE.md Instruction Overhaul | STORY-001, 002, 003, 004, 005, 006 | 22 points | Sprint 1 |
| EPIC-002 | Validation Scripts | STORY-007, 008, 009, 010 | 9 points | Sprint 2 |
| EPIC-003 | Deployment Reporting | STORY-011, 012, 013 | 6 points | Sprint 1 |

---

## Requirements Coverage

### Functional Requirements

| FR ID | FR Name | Story | Sprint |
|-------|---------|-------|--------|
| FR-001 | Enforce Flex Consumption Plan | STORY-001 | 1 |
| FR-002 | Enforce F0 Translator SKU | STORY-001 | 1 |
| FR-003 | Enforce Correct Azure Login | STORY-001 | 1 |
| FR-004 | Enforce Single Deployment Method | STORY-001 | 1 |
| FR-005 | Protect Auto-Created Variables | STORY-002 | 1 |
| FR-006 | Provide Correct Function App Credentials | STORY-004 | 1 |
| FR-007 | Provide Blob Container Credentials | STORY-004 | 1 |
| FR-008 | Pre-Deployment Resource Check | STORY-003 | 1 |
| FR-009 | Validation Script - Check Resources | STORY-007, STORY-010 | 2 |
| FR-010 | Validation Script - Verify SKU | STORY-008, STORY-010 | 2 |
| FR-011 | Validation Script - Verify Plan | STORY-009, STORY-010 | 2 |
| FR-012 | Clear Credentials Display | STORY-011 | 1 |
| FR-013 | Deployment Report Generation | STORY-012 | 1 |

### Non-Functional Requirements

| NFR ID | NFR Name | Solution | Story |
|--------|----------|----------|-------|
| NFR-001 | No Credential Persistence | .gitignore, report template | STORY-012, STORY-013 |
| NFR-002 | No Sensitive Data in Reports | Report template design | STORY-012 |
| NFR-003 | Beginner-Friendly Instructions | Phase restructuring | STORY-005 |
| NFR-004 | Clear Error Messages | Error guidance section | STORY-006 |
| NFR-005 | Consistent Deployment Process | Phase restructuring | STORY-005 |
| NFR-006 | Idempotent Resource Checks | Read-only scripts | STORY-007, STORY-010 |

---

## Risks and Mitigation

**High:**
- None identified

**Medium:**
- Risk: AI assistant may still make errors despite improved instructions
  - Mitigation: Test with actual deployments; add verification checkpoints
- Risk: Technicians may skip validation steps
  - Mitigation: Make checks mandatory in CLAUDE.md; add warnings

**Low:**
- Risk: Azure CLI output format changes
  - Mitigation: Use stable --query and -o table options
- Risk: Sprint 1 stories take longer than estimated
  - Mitigation: Sprint 2 has low utilization (30%) to absorb overflow

---

## Definition of Done

For a story to be considered complete:
- [ ] Changes implemented and committed
- [ ] CLAUDE.md updated (if applicable)
- [ ] Scripts tested with actual az commands (if applicable)
- [ ] No credentials in committed files
- [ ] Documentation clear and beginner-friendly
- [ ] Reviewed by project owner

---

## Team Information

| Attribute | Value |
|-----------|-------|
| Team Size | 1 developer |
| Sprint Length | 2 weeks (10 workdays) |
| Productive Hours/Day | 6 hours |
| Points per Sprint | 30 points |
| Point Definition | 1 point = 2 hours |

---

## Sprint Cadence

- Sprint length: 2 weeks
- Sprint planning: Day 1
- Sprint review: Day 10
- Sprint retrospective: Day 10

---

## Next Steps

**Immediate:** Begin Sprint 1

Run `/bmad:dev-story STORY-001` to start implementing the first story (Critical Rules Section).

**Sprint 1 Story Order (recommended):**
1. STORY-001 - Critical Rules Section (foundation for everything)
2. STORY-002 - Protected Variables (builds on critical rules)
3. STORY-003 - Resource Check Section (new content)
4. STORY-004 - Credentials Section (new content)
5. STORY-005 - Phase Restructuring (integrates above)
6. STORY-011 - Credentials Display (depends on STORY-004)
7. STORY-012 - Report Template (independent)
8. STORY-013 - .gitignore (quick win)
9. STORY-006 - Error Guidance (polish)

---

**This plan was created using BMAD Method v6 - Phase 4 (Implementation Planning)**

*To implement: Run `/bmad:dev-story STORY-XXX` to begin implementing a specific story.*
