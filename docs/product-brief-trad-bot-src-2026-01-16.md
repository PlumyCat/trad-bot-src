# Product Brief: trad-bot-src

**Date:** 2026-01-16
**Author:** Eric
**Version:** 1.0
**Project Type:** API / Backend Service
**Project Level:** 2 (Medium - 5-15 stories)

---

## Executive Summary

An Azure Function-based translation service integrated with Microsoft Copilot Studio bot, enabling document translation while preserving original formatting. The solution is deployed automatically via a container running OpenCode, which pulls this repository and displays a browser-based deployment procedure for the Power Platform solution containing the Copilot Studio bot. The goal is to make this deployment process foolproof for technicians with limited Azure experience.

---

## Problem Statement

### The Problem

Technicians deploying the translation solution frequently make errors during Azure deployment:

- **Wrong Azure Function plan:** Using deprecated simple Consumption plan instead of required Flex Consumption plan
- **Accidental variable modification:** Modifying auto-created Azure environment variables, which breaks deployments and requires complete rebuilds
- **Costly SKU selection:** Using expensive S1 SKU for Azure Translator instead of free F0 tier (costing +$35/month per deployment)
- **Inconsistent deployment methods:** Mixing `func azure functionapp publish` and zip deploy methods
- **Incorrect Azure login:** Not using `az login --tenant <tenantid>` for delegated access to client tenants

### Why Now?

The deployment bot needs to be shared with colleagues at Be-Cloud who lack Azure expertise. Without clear, foolproof instructions embedded in the CLAUDE.md file, they risk breaking deployments and incurring unnecessary costs for clients.

### Impact if Unsolved

- Broken deployments requiring complete rebuilds
- Additional monthly costs ($35/month per deployment with wrong S1 SKU)
- Inability to scale deployment process to less technical team members
- Lost time troubleshooting avoidable errors
- Reduced confidence in the deployment system

---

## Target Audience

### Primary Users

**Be-Cloud Technicians**
- Role: Internal technical support staff
- Azure Experience: Beginner level
- Context: Using OpenCode in a container to deploy translation bot to client Azure tenants
- Key need: Clear, error-proof deployment instructions

### Secondary Users

**Client End-Users**
- Role: Employees at Be-Cloud clients
- Interaction: Use the Copilot Studio translation bot through Teams/Power Platform
- Key need: Working translation service that preserves document formatting

### User Needs

1. **Foolproof deployment instructions** that prevent common errors
2. **Validation checks** that catch mistakes before they cause damage
3. **Consistent, repeatable process** that works the same way every time

---

## Solution Overview

### Proposed Solution

Improve the deployment automation by:
1. Rewriting CLAUDE.md with stricter, clearer instructions and explicit guardrails
2. Adding validation scripts that check configuration before deployment
3. Updating the browser-based documentation at localhost:5545/procedure
4. Implementing error prevention mechanisms that stop wrong commands

### Key Features

- **Improved CLAUDE.md Instructions**
  - Explicit rules: ALWAYS use Flex Consumption, NEVER use S1 SKU
  - Mandatory verification steps before resource creation
  - Single deployment method enforcement (func publish only)
  - Correct Azure login command for delegated access

- **Automated Validation Scripts**
  - Pre-deployment checks for existing resources
  - SKU verification (F0 only for Translator)
  - Plan type verification (Flex Consumption only)
  - Variable protection (never modify auto-created vars)

- **Step-by-Step Guided Deployment**
  - Clear phase separation (Phase 0, 1, 2)
  - Browser-based procedure with visual guidance
  - Checkpoint confirmations at critical steps

- **Error Prevention Guardrails**
  - Explicit "NEVER do X" instructions
  - Pre-flight checks before destructive operations
  - Warnings for common mistake patterns

### Value Proposition

Enable any Be-Cloud technician to successfully deploy the translation bot to client Azure tenants without Azure expertise, without errors, and without incurring unnecessary costs.

---

## Business Objectives

### Goals

- **Zero deployment errors:** Eliminate mistakes caused by unclear instructions
- **Enable non-experts to deploy:** Any Be-Cloud technician can deploy successfully without Azure knowledge
- **Prevent cost overruns:** Ensure F0 (free) Translator SKU is always used

### Success Metrics

| Metric | Target |
|--------|--------|
| Deployment success rate | 100% |
| Deployments requiring intervention | 0 |
| Wrong SKU selections | 0 |
| Wrong plan type selections | 0 |

### Business Value

- **Cost savings:** Prevent $35/month per client from wrong SKU selection
- **Time savings:** Eliminate hours spent troubleshooting broken deployments
- **Scalability:** Enable more team members to perform deployments
- **Client satisfaction:** Reliable, consistent service delivery

---

## Scope

### In Scope

- Improve CLAUDE.md with stricter deployment instructions
- Add validation scripts for pre-deployment checks
- Update documentation site (localhost:5545/procedure)
- Add explicit guardrails and "NEVER do X" rules
- Implement verification steps before resource creation

### Out of Scope

- Modifying the Copilot Studio bot itself
- Adding new translation features or capabilities
- Multi-language support for documentation
- Refactoring the Azure Functions translation code
- Changes to the Power Platform solution package

### Future Considerations

- Automated testing of deployment process
- Rollback procedures for failed deployments
- Dashboard for tracking deployment status across clients
- Integration with Be-Cloud ticketing system

---

## Key Stakeholders

- **Eric (Project Owner)** - High influence. Leading this project, responsible for deployment process quality at Be-Cloud
- **Be-Cloud Technicians** - High influence. Primary users who will execute deployments
- **Be-Cloud Management** - Medium influence. Interested in cost control and service quality
- **Client IT Contacts** - Low influence. May need to provide Azure access or approvals

---

## Constraints and Assumptions

### Constraints

| Constraint | Reason |
|------------|--------|
| Must use Azure Flex Consumption plan | Simple Consumption being deprecated by Microsoft |
| Must use F0 Translator SKU only | Free tier prevents unnecessary costs |
| Must use delegated access (`az login --tenant`) | Only method that works with Be-Cloud's partner access model |
| Must use `func azure functionapp publish` only | Consistent deployment method required |
| Must never modify auto-created Azure variables | Causes deployment failures requiring rebuild |

### Assumptions

- OpenCode is pre-installed and configured in the deployment container
- Container has Azure CLI available
- Technicians have access to Be-Cloud's delegated credentials
- Clients have valid Azure subscriptions accessible via delegation
- Browser is available for viewing localhost:5545/procedure

---

## Success Criteria

- **Primary criterion:** Any Be-Cloud technician can successfully deploy the translation bot to a client tenant without assistance
- Deployment follows exact same process every time
- No deployment failures due to instruction ambiguity
- No unnecessary Azure costs from wrong SKU selection
- Positive feedback from technicians using the improved process

---

## Timeline and Milestones

### Target Launch

**ASAP - Urgent priority**

This is blocking the ability to share deployment responsibilities with the team.

### Key Milestones

1. **Milestone 1:** Audit current CLAUDE.md and identify all error-prone areas
2. **Milestone 2:** Rewrite CLAUDE.md with explicit guardrails
3. **Milestone 3:** Add validation scripts for pre-deployment checks
4. **Milestone 4:** Update documentation site with visual guides
5. **Milestone 5:** Test with a technician who has no prior deployment experience
6. **Milestone 6:** Deploy to first client using new process

---

## Risks and Mitigation

- **Risk:** AI assistant (OpenCode) may still make errors despite improved instructions
  - **Likelihood:** Medium
  - **Mitigation:** Add multiple verification checkpoints; implement "ask before acting" rules for destructive operations; test extensively with edge cases

- **Risk:** Azure deprecation timeline may change
  - **Likelihood:** Low
  - **Mitigation:** Monitor Microsoft announcements; ensure Flex Consumption is already the default

- **Risk:** Technicians may skip verification steps
  - **Likelihood:** Medium
  - **Mitigation:** Make verification mandatory before proceeding; add clear warnings about consequences

---

## Next Steps

1. Create Product Requirements Document (PRD) - `/bmad:prd`
2. Define system architecture - `/bmad:architecture`
3. Plan implementation sprints - `/bmad:sprint-planning`

---

**This document was created using BMAD Method v6 - Phase 1 (Analysis)**

*To continue: Run `/bmad:workflow-status` to see your progress and next recommended workflow.*
