# Client Simulator CD --- Repository Dispatch Workflow

This folder contains the Continuous Delivery (CD) workflow that
automates updating the **Client Simulator** ECS task definitions across
all environments (`dev`, `stg`, `prd`) using a GitHub → Terragrunt Pull
Request--driven deployment model.

The workflow is triggered **remotely** from the application repository
(Capenabelment) after a new Docker image is built and pushed to AWS ECR.\
The workflow in this repository (Cap-infra-repo) updates the Terragrunt
configuration with the new image tag and creates pull requests for each
environment.

------------------------------------------------------------------------

# 📌 Overview

This workflow enables a secure, automated mechanism for pushing new
versions of the Client Simulator application into the IaC repository.\
Instead of deploying manually, it:

1.  Receives an `image_tag` from Capenabelment
2.  Updates the `image = "<tag>"` field inside the relevant
    `terragrunt.hcl` files\
3.  Creates **three pull requests** --- one for each environment
4.  Deployment happens only **after manual merge**, preserving security
    controls

This provides: - Safer version promotion
- Clear visibility of changes
- Full IaC compliance (Terragrunt triggers apply after merge)
- A deterministic release process

------------------------------------------------------------------------

# 🚀 CD Architecture Flow

### 1. Capenabelment --- Application Code

-   Builds Docker image
-   Pushes to ECR
-   Extracts `IMAGE_TAG`
-   Sends a **repository_dispatch** event:

``` json
{
  "event_type": "deploy-simulator",
  "client_payload": {
    "image_tag": "<IMAGE_TAG>"
  }
}
```

### 2. Cap-infra-repo --- Infrastructure & Terragrunt

This repo listens for that dispatch using:

``` yaml
on:
  repository_dispatch:
    types: [ deploy-simulator ]
```

When triggered, it executes: - `simulator-dispatch-cd.yaml` (GitHub
Actions workflow) - `simulator-dispatch-cd.py` (automation logic)

Together, they: - Install necessary tools (Python, GitHub CLI) -
Authenticate via GitHub App - Modify Terragrunt files - Create PRs for
`dev`, `stg`, and `prd`

------------------------------------------------------------------------

# 📂 Directory Structure

    .github/workflows/
        simulator-dispatch-cd.yaml
    .github/workflows/simulator-cicd/
        simulator-dispatch-cd.py
    products/
        anan-magen/
            il-central-1/
                dev/
                stg/
                prd/
                    client-simulator/
                        ecs-task-def/
                            terragrunt.hcl

------------------------------------------------------------------------

# ⚙️ How the GitHub Workflow Works

### 1. Trigger (repository_dispatch)

Triggered externally by Capenabelment with event type `deploy-simulator`.

### 2. Environment Setup

-   Python\
-   GitHub CLI\
-   Git config\
-   AWS region + Terragrunt version

### 3. Authentication

Uses GitHub App via:

``` yaml
actions/create-github-app-token@v1
```

This token allows: - Creating branches - Pushing updates - Opening pull
requests

### 4. Image Tag Verification

Ensures the payload contains:

``` yaml
github.event.client_payload.image_tag
```

### 5. Checkout & Execution


``` bash
python simulator-dispatch-cd.py --ImageTag <tag>
```

------------------------------------------------------------------------

# 🐍 Python Script Logic (simulator-dispatch-cd.py)

The script performs the core automation steps:

### 1. Iterates Over Environments

    env = ["prd", "stg", "dev"]

### 2. For Each Environment

Modifies:

    products/anan-magen/il-central-1/<env>/client-simulator/ecs-task-def/terragrunt.hcl

### 3. Updates the `image = "<tag>"` Line

Locates the first occurrence of:

    image = "<old-tag>"

and replaces its value with the new tag.

### 4. Creates a Branch

Example branch format:

    <IMAGE_TAG>-stg-20250107150322

### 5. Commits & Pushes the Change

    git add <file>
    git commit -m "update task def, env:<env> tag:<ImageTag>"
    git push origin <branch>

### 6. Automatically Opens a Pull Request

Uses the GitHub CLI:

    gh pr create --title ... --body ... --base main --head <branch>

### 7. Returns to main Branch

Ensures subsequent env updates use a clean base.

------------------------------------------------------------------------

# 🔐 Required Secrets

The workflow depends on the following GitHub Actions secrets:

  Secret Name         Purpose
  ------------------- ---------------------------------------
  `APP_ID`            GitHub App ID used for authentication
  `APP_PRIVATE_KEY`   Private key for the GitHub App

------------------------------------------------------------------------

# 📌 Important Notes

-   Terragrunt deployment **does not** run automatically --- PR merges
    trigger it manually (security requirement).\
-   The workflow aborts if a target `terragrunt.hcl` file cannot be
    found.\
-   All branch names are unique due to timestamp + tag.\
-   Only Capenabelment should trigger this workflow via `repository_dispatch`.\
-   GitHub App token must have `contents: write` and
    `pull-requests: write`.

------------------------------------------------------------------------


**Maintainer: Dar Ravina**