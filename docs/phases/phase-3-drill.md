# Phase 3 drill: break the deploy path

The plan for the seven steps in the Phase 3 brief, prepared on 26 November 2026 so each step is run against a prediction written down first. For every step: the fault, how it is planted, what should happen and which control does it, the evidence to keep, what Alex does, what the step is expected to reveal, and how it is cleaned up. The results go under each step as it is run, and the whole becomes the Phase 3 entry in `docs/learning-log.md`.

Two things were changed before the drill rather than by it, because reading the workflow found them and the cost of finding them live was production broken: the rollback now returns traffic to the revision recorded before the Bicep step, not before the rollout, since a template change (an environment variable) makes the Bicep step create a revision of its own that carries the fault; and the Checkov scan is a hard failure with the two known false positives accepted in a baseline, as ADR 0019 said Phase 3 would make it. Both are in the drill's preparation pull request, and both are faults the drill would otherwise have found at steps 2 and 4. Preparing step 4 also found that the brief's chosen fault is one the scanner cannot see, so the step plants two.

**Rules for the drill.** Every planted fault lives on a branch named `drill/phase3-<step>`. Nothing merges to `main` except step 2's switch and its revert, both through the ordinary gates. Production is deliberately unhealthy for a few minutes in step 2; Alex picks the time. Agents plant and observe; Alex approves, merges, and does the one hand change in step 6.

## Step 1. Unapproved production deploy

**Fault.** An attempt to reach production without Alex's approval.

**How.** Three attempts, because three controls stand in the way and each is worth seeing refuse on its own.

1. The ordinary case, already observed on runs 15, 16, 18, 22 and 23: a merge to `main` deploys staging and the production job waits. Evidence: those runs, each with "Waiting for review" on the production job for hours until Alex acted.
2. A `Deploy` run dispatched by hand from a branch other than `main`. Expected: the `images` job's provenance condition is false, so the job is skipped and nothing after it runs (ADR 0021, 20 October amendment). Evidence: the run's job list, every job skipped.
3. A workflow on the drill branch that tries two things without the `production` environment's approval: a job that signs in to Azure with the production deploy identity's client id but no `environment:` line, and a job that declares `environment: production` from a non-`main` branch. Expected: the first fails at sign-in with `AADSTS700213`, because the federated credential's subject names the `production` environment and the job presents none; the second never starts, because the environment's deployment branch policy allows `main` only. Evidence: the two job logs.

**Alex.** Nothing; that is the point.

**Expected to reveal.** Nothing new if all three refuse. If attempt 3's second job runs, the branch policy is not set and Alex sets it.

**Clean up.** Delete the branch. No pull request is opened for attempt 3; the workflow runs from the branch.

## Step 2. Failed smoke test, automatic rollback

**Fault.** A deploy whose API reports unhealthy in production only.

**How.** The preparation pull request added `Health:ForceUnhealthy`, a configuration switch read by a health check named `forced`: when true, `/api/health` answers 503 Unhealthy while `/api/health/live`, which the probes ask, stays 200. It is a Bicep parameter, false in both environments. The drill pull request sets it true in `infra/parameters/production.bicepparam` only, with a description that says it is the drill, and merges through the ordinary gates.

**Expected.** Staging deploys and passes its smoke test and suites (its parameter is false). Alex approves at G4. In production the Bicep step creates a revision carrying the environment variable, with the images already running; because traffic follows the latest revision, production starts answering 503 on `/api/health` at that moment, and the web app shows "unhealthy". The rollout creates the next revision with the new images; it reports healthy, because the probes ask the liveness endpoint; the smoke test asks `/api/health`, gets 503, retries for three minutes and fails. The rollback runs: traffic shifts to the revision recorded before the Bicep step, both apps return to their previous images, the failed revision is deactivated, the run is red with a summary that says so. The web app works again within seconds of the shift; the whole unhealthy window is about four minutes.

**Evidence.** The run (red, with the rollback step's output and summary); `/api/health` from Alex's browser during the window (503) and after (200); the production API's revision list afterwards, showing traffic on the earlier revision; the Container Apps summary line naming the revisions.

**Alex.** Approves the drill deploy at G4 at a time of his choosing; watches the web app during the window; approves the revert's deploy afterwards.

**Expected to reveal.** That the unhealthy window opens at the Bicep step, before any test runs, whenever the fault is in configuration rather than code. The smoke test and rollback close it, but a company would want the configuration deployed to the new revision at zero traffic first. A candidate for a later phase: deploy the Bicep with traffic pinned to the current revision and shift only after the smoke test, which is the zero-traffic path ADR 0021 kept as a fallback.

**Clean up.** A revert pull request sets the parameter back to false; its deploy goes through staging and G4 and leaves production on the new revision with the switch off. `main` then carries no fault.

## Step 3. Incompatible migration

**Fault.** A migration that renames the `Title` column of `Books` to `Name`, with the code updated to match, which breaks the revision still serving the moment the migration runs and before the new images roll out.

**How.** A pull request on the drill branch with the migration and the matching entity change. Tests pass, because they run the new code against the new schema. It is never merged.

**Expected.** CI is green. Copilot's review and the triage agent may or may not notice; the compatibility rule in ADR 0021 is a review rule, enforced by a human reading the migration. The pull request is closed unmerged with a comment naming the rule.

**Expected to reveal.** That nothing mechanical enforces expand-then-contract. Remediation candidates for the debrief: a CI check that fails on destructive migration operations (`DROP COLUMN`, `RENAME`, `ALTER COLUMN` narrowing) in the generated SQL script unless the pull request carries a `migration/contract-approved` label; or a job in the staging deploy that runs the previous image's integration tests against the migrated schema before the rollout.

**Clean up.** Close the pull request; delete the branch.

## Step 4. Insecure infrastructure

**Fault.** Two, planted one at a time on the storage account, because preparing the step showed they are not the same case.

**How.** (a) `allowBlobPublicAccess: true`, the fault the brief names. (b) `minimumTlsVersion: 'TLS1_0'`. Each a one-line pull request on the drill branch, never merged.

**Expected.** (a) passes the scan. Checkov's Bicep check set has no rule for `allowBlobPublicAccess` (its blob-public-access rule exists for Terraform only; the Bicep rules on a storage account cover HTTPS-only, TLS version, replication, naming, trusted services, container access level, default network rule and public network access, and the last two are skipped in the template with a reason). Rehearsed locally while preparing: the fault scanned clean. (b) fails the scan naming `CKV_AZURE_44`, now a hard failure after the preparation pull request; rehearsed locally against the baseline and seen to fail. `Infrastructure build` passes both, since the Bicep is valid.

**Expected to reveal.** Two things. First, the scanner's coverage has a hole exactly where the brief expected it to catch something; the remediation is a custom Checkov policy (a YAML rule under `.checkov/` that fails a storage account whose `allowBlobPublicAccess` is not false), and a note in ADR 0019 that the Bicep rule set is thinner than the Terraform one. Second, that `Infrastructure scan` and `Infrastructure build` are not among the required checks on `main`, so even (b)'s red check does not disable the merge button. Alex adds both to the ruleset's required checks; that is the one ruleset change Phase 3 asks for, and it is Alex's act.

**Clean up.** Close both pull requests; delete the branches.

## Step 5. Stored credential

**Fault.** A deploy workflow that signs in with a stored client secret instead of OpenID Connect.

**How.** A pull request on the drill branch that changes the `azure/login` step in `deploy-environment.yml` to use `creds: ${{ secrets.AZURE_CREDENTIALS }}` and adds, in a committed file, a fabricated client secret in Entra's format (a test value, not a live one). Never merged.

**Expected.** Push protection may reject the push on the fabricated secret; if it does not (GitHub validates some formats and lets unrecognised ones through, as the Phase 2 drill found), the `Secret scan` check fails and it is required, so the merge button is disabled. The workflow change itself is caught by nothing mechanical: a reviewer reading the diff sees a `creds:` block where the rule says there is none to add.

**Expected to reveal.** That the "no stored cloud credentials" rule is enforced on the secret's value but not on the workflow's shape. Remediation candidate, cheap and in a required check: a line in `eng/check-docs.sh` that fails if any workflow uses `creds:`, `client-secret`, `AZURE_CREDENTIALS` or a `secrets.` reference inside an `azure/login` step.

**Clean up.** Close the pull request; delete the branch. If push protection accepted the fabricated value, it is a known fake and stays in the closed branch's history until the branch is deleted.

## Step 6. Drift

**Fault.** A change made by hand in Azure.

**How.** Two hand changes by Alex, chosen because the Bicep treats them differently. (a) An extra entry on the staging API's ingress allow-list, added in the portal or with `az containerapp ingress access-restriction set`. (b) An extra firewall rule on the staging SQL server, `drill-drift`, allowing a single address. Then `Deploy` run by hand from `main`.

**Expected.** (a) The what-if shows the ingress allow-list changing and the Bicep step puts it back, because the template owns the whole list. (b) The what-if says nothing about the firewall rule and the Bicep step leaves it in place, because the template declares its own rules as child resources and an incremental deployment does not delete children it does not know about. A third thing to read in the same what-if, asked for by the run 16 note: the budget, the one date-dependent resource. The deploy reads the existing budget's start date back before the Bicep step, so the what-if should show the budget unchanged; a change there means the read-back failed and the next deploy would hit the error run 17 hit.

**Expected to reveal.** The second half: hand-made additions survive a deploy when they are separate resources. Remediation candidates for the debrief: a weekly drift job that lists firewall rules and allow-list entries and compares them with the template, opening an issue on a difference; or Azure deployment stacks, which delete what the template stops declaring. Complete-mode deployment is ruled out, because the resource groups also hold the identities the bootstrap created and a complete deployment would delete them.

**Alex.** Makes the two hand changes, runs the deploy, and afterwards deletes the firewall rule by hand, since nothing else will.

**Clean up.** Alex removes the firewall rule. The allow-list entry is removed by the deploy itself.

## Step 7. Clean up

Steps 3, 4 and 5 are pull requests that never merge: close them and delete their branches. Step 1's branch is deleted. Step 2's switch is reverted through the gates and production ends on the newest revision with the switch off. Step 6's firewall rule is deleted by hand. The `zap` issues, if the drill's deploys opened any, are closed by the next clean scan. Then the results under each step are written, the remediations are listed with a decision on each, and the Phase 3 entry goes into the learning log.

## Order and timing

1, 3, 4 and 5 can run on any day and in parallel, since none touches production. 6 needs ten minutes of Alex's time on staging. 2 needs Alex at the keyboard for about twenty minutes, with production unhealthy for about four of them; it goes last, and the revert follows the same day.
