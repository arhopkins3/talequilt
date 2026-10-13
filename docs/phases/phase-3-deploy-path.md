# Phase 3: Deploy path

**Exit test:** a change reaches production only after Alex approves, and a failed smoke test rolls it back.

## Brief

### What this phase adds

The road from `main` to a running system, built so that the road itself is under the same controls as the code. Azure resources are declared in Bicep under `infra/` and created by the pipeline, never by hand in the portal. GitHub Actions signs in to Azure with OpenID Connect, so no cloud credential is stored anywhere. Every merge to `main` deploys to a staging environment and runs end-to-end tests, a dynamic security scan and accessibility checks against it. Promotion to production waits for Alex's approval on a GitHub environment (gate G4), then runs smoke tests and rolls back automatically if they fail. Runtime secrets live in Key Vault and are read through managed identity. The Checkov scan built in Phase 2 starts doing real work on the Bicep, and the SBOM gets a release to ride on.

### The problem it solves

Phases 1 and 2 proved that nothing broken, vulnerable or leaked can reach `main`. Nothing yet proves that what reaches `main` can run, or that production changes only when a named human says so. Deployment is where most real incidents happen: a hand-edited setting that differs between environments, a credential in a pipeline variable that leaks, a release nobody can roll back at two in the morning. Phase 3 makes deployment a reviewed, repeatable, reversible act with an audit trail: the Bicep diff is in the pull request, the deploy is a workflow run, the approval is recorded on the environment, and the rollback is automatic.

### Terms, defined once

- **Bicep:** Azure's declarative language for infrastructure. A template describes the resources wanted; a deployment makes reality match. `what-if` shows the difference before applying it, which is the infrastructure equivalent of a diff.
- **OpenID Connect (OIDC) federation:** GitHub Actions presents a short-lived signed token saying "this is run N of workflow W on branch B in repository R", and Azure is configured to trust that exact claim for one identity. No secret is created, stored or rotated.
- **Managed identity:** an identity Azure gives to a resource (a container app, a workflow's federated identity) so it can call other Azure services without a password. Key Vault grants it read on the secrets it needs.
- **Container Apps:** Azure's serverless container host. Each deploy creates a new *revision*; traffic can be split or shifted between revisions, which is what makes rollback a one-line call.
- **GitHub environment:** a named deployment target with its own secrets, variables and protection rules. A *required reviewer* on the `production` environment is what turns a workflow step into gate G4.
- **Smoke test:** a handful of requests against the deployed system that prove it is alive and wired correctly, run in the first minute after a deploy, as distinct from the full end-to-end suite run on staging.
- **DAST (dynamic application security testing):** scanning the running application rather than its source. OWASP ZAP's baseline scan requests pages and reports missing headers, insecure cookies and the like.

### Alternatives

ADR 0007 (hosting shape) is proposed and names the options with idle-cost estimates; this phase prices them from the calculator and accepts the ADR. The survey below carries the remaining decisions; each becomes an ADR or an amendment.

### At company scale

A platform team owns a landing zone (networking, policy, monitoring, identity) and product teams deploy into it from templates they do not edit. Infrastructure changes go through the same pull request gates as code, with policy-as-code (Azure Policy, Checkov or similar) blocking non-compliant resources before they exist. Environments are many (dev, test, staging, pre-production, production), approvals are tied to change tickets, and deployment windows and freeze periods are enforced by the pipeline. Rollback is a tested runbook, not a hope. Cost is tagged and charged back; a budget alert is a page, not an email.

## Decide

To be settled in the Phase 3 survey. Each question carries a recommendation.

1. **Compute shape.** Confirm ADR 0007's first option: Container Apps (consumption) for the API and the worker, Static Web Apps for the React build, Azure SQL serverless with auto-pause, Storage for blobs and queues, Key Vault, Log Analytics. Recommendation: confirm, then price it; the alternatives are kept in the ADR.
2. **Environments.** (a) Staging and production, both from the same Bicep with a parameter file each, in two resource groups; (b) production only, with the end-to-end tests run against a temporary deployment. Recommendation: (a). The exit test needs somewhere for a bad deploy to fail before Alex sees it, and two environments from one template is the pattern worth learning.
3. **Public exposure before sign-in.** ADR 0008 forbids a public hostname for the API or the web app until sign-in exists in Phase 5. (a) Restrict the API's ingress to an IP allow-list and protect the web app's routes with Static Web Apps' built-in authentication (GitHub provider, invited users only), as a stopgap; (b) bring Google sign-in forward into this phase; (c) deploy only the API and worker, with internal ingress, and leave the web app undeployed until Phase 5. Recommendation: (a). It keeps the phase about deployment, satisfies ADR 0008's intent, and is removed in Phase 5. Changes to it are never classed as small.
4. **Pipeline identity.** (a) A user-assigned managed identity per environment with a federated credential for this repository and that environment, holding Contributor on its resource group only; (b) one app registration with a client secret in GitHub. Recommendation: (a). It is CLAUDE.md rule 8 made concrete, and the two identities mean the staging workflow cannot touch production.
5. **Database migrations.** (a) The API applies EF Core migrations at startup; (b) the pipeline runs a migration bundle against the environment's database before the new revision takes traffic. Recommendation: (b), with one rule that makes (b) safe: every migration must be compatible with the revision still serving, so a column or table is added in one release and only removed in a later one once nothing reads it (expand first, contract later). The migration runs while the old revision is live and a traffic shift does not undo it, so without that rule a rename or a drop would break both the running revision and the rollback. Database recovery is a separate path, point-in-time restore from Azure SQL's automatic backups, rehearsed in the drill and never implied by a traffic shift.
6. **Rollback.** (a) On a failed production smoke test, the workflow shifts traffic back to the previous Container Apps revision and marks the run failed; (b) redeploy the previous image. Recommendation: (a). Revisions make it seconds rather than minutes, and the previous revision is already warm. Rollback moves traffic only; it leaves the database as the migration left it, which is why decision 5 requires that migration to be compatible with the previous revision.
7. **Tests on staging.** Playwright end-to-end (the health and books pages), an OWASP ZAP baseline scan, and accessibility checks with axe through Playwright, all required before promotion is offered; production gets the smoke test only. Recommendation: all three on staging from the start, with the suites small and the thresholds explicit.
8. **Budget.** An Azure budget with alerts at £10 and £20 a month, staging scaled to zero between runs, SQL auto-pause on both environments. Recommendation: as stated; the price is in the accepted ADR 0007 and on the Console.

## Build

Four pull requests, each reviewable in one sitting.

1. **Infrastructure.** Bicep for one environment (parameterised), a `what-if` step in CI that posts the plan on the pull request, Checkov now scanning real files, and a documented one-time bootstrap script (resource groups, the two managed identities and their federated credentials) that Alex runs once from his own session, recorded in the ADR, because the pipeline cannot create the identity it signs in with.
2. **Staging deploy.** A `Deploy` workflow on push to `main`: sign in with OIDC, deploy the Bicep, build and push the two container images, run the migration bundle, deploy the revision, deploy the web app. The `staging` environment exists with no protection rule.
3. **Verify and promote.** Playwright, ZAP and axe against staging, then the `production` job behind the `production` environment with Alex as required reviewer (G4), the smoke test, and the automatic traffic shift back on failure. The Console shows the two environments and the gate.
4. **Accept and price.** ADR 0007 accepted with calculator prices and the first month's actual bill when it exists, the budget alerts, the operating model's stage 5 and 6 rows marked enforced, and the learning log entry after the drill.

### One-time settings (Alex applies)

| Setting | Why | When |
| --- | --- | --- |
| Azure subscription and the bootstrap script | The identities the pipeline signs in with must exist before the pipeline runs | Pull request 1 |
| GitHub environments `staging` and `production`; Alex as required reviewer on `production` | G4 | Pull request 3 |
| Budget alerts to Alex's email | Cost guardrail | Pull request 4 |

## Break it: the drill

1. **Unapproved production deploy.** Merge a change and do nothing. Expected: staging deploys and passes; the production job waits on the `production` environment and nothing reaches it.
2. **Failed smoke test.** Merge a change whose health endpoint returns 500 behind a flag only production sets. Expected: staging passes, Alex approves, the smoke test fails, traffic shifts back to the previous revision, the run is red, and the site still works on the old revision. The change is then reverted by a pull request through the same gates, so `main` and production agree again.
3. **Incompatible migration.** A pull request whose migration drops a column the current revision still reads. Expected: review holds it on the compatibility rule from decision 5; it is closed unmerged. If a company needed proof rather than review, staging would show it: the old revision errors the moment the migration runs, before promotion is offered.
4. **Insecure infrastructure.** A pull request that sets a storage account to allow public blob access. Expected: Checkov fails the pull request naming the rule; `what-if` shows the change.
5. **Stored credential.** A pull request that adds a client secret to a workflow's environment block. Expected: push protection or the secret scan stops it, and the review notes that the deploy workflow has no secret to add.
6. **Drift.** Change a setting by hand in the portal, then redeploy. Expected: `what-if` reports the drift and the deploy puts it back.
7. **Clean up.** Steps 3, 4 and 5 are pull requests that never merge: close them. Steps 1 and 2 have to reach `main` for the deploy workflow to run, so step 1's change is harmless by design and step 2's is reverted by a pull request through the same gates. Step 6 leaves nothing behind. Production ends on the revision it started on, and `main` carries no deliberate fault.

## Carried in from Phase 2

- Public exposure is forbidden before sign-in (ADR 0008); decision 3 above is the stopgap.
- Checkov has run on an empty `infra/` since Phase 2 and reports without blocking; this phase decides whether `Infrastructure scan` becomes required.
- The SBOM is produced on every run but attached to nothing; this phase attaches it to the release that deploys.
- Dependabot now proposes Actions bumps for the deploy workflow too; the pin check applies to it like any other.
- The Pages workflow is the only deploy so far and already waits for CI; the application deploy follows the same rule.

## Debrief

Written in `docs/learning-log.md` after the drill.
