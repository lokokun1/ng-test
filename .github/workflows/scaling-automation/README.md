# EKS Scaling Automation (FinOps Lambda Trigger)

## 1. Overview
This repository contains a **manual, self-service GitHub Actions workflow** that triggers **environment scaling actions** by invoking the `finops-resource-scheduler` AWS Lambda.

---
## important notice 
(the env vars stays persistent also if you redeploy the eks nodes, but if you redeploy lambda it resets)

## 2. Technology Stack
| Component | Role |
|----------|------|
| GitHub Actions (`workflow_dispatch`) | Manual trigger & orchestration |
| GitHub OIDC + IAM Roles | Secure authentication (no long-lived AWS keys) |
| AWS Lambda (`finops-resource-scheduler`) | Executes the “start/stop” scaling logic in the target account |
| Python (`find_cred.py`) | Maps environment → AWS Account ID |
| AWS CLI + `jq` | Reads/updates Lambda environment variables + invokes Lambda |
| AWS Region | `il-central-1` |

---

## 3. Execution Flow
1. **Manual Trigger** – user selects:
   - `environment` (INT/DEV/STG/PRD)
   - `action` (`start` / `stop`)
   - optional `start_behavior` (START override)
   - optional `stop_behavior` (STOP override)
2. **Account Mapping** – `find_cred.py` maps the environment to the target AWS Account ID.
3. **Authentication**
   - Assume Infra role (in the infra account)  
   - Chain into the Execution role (in the target environment account)
4. **Optional Configuration Updates**
   - If `start_behavior != None` → updates Lambda env var `START_COUNT`
   - If `stop_behavior != None` → updates Lambda env var `STOP_COUNT`
5. **Invoke Lambda**
   - Sends payload: `{"action": "start"}` or `{"action": "stop"}`
   - Saves output to `response.json`

---
## 3.5 FIND_CRED.PY 

It stores the cicd roles as secrets, and during execution it takes the relevent env and translates it into output it as the automation can work with. 
it stores the accounts in this pattern 
under **ENV_ACCOUNT_MAPPING**
and the json looks like this 

```json
{
   "INT": "arn:aws:iam::####dev-cicd-account####:role/wl-cicd-build-codebuild-role-##int-account##",
   "DEV": "arn:aws:iam::####dev-cicd-account####:role/wl-cicd-build-codebuild-role-##dev-account##",
   "STG": "arn:aws:iam::####prod-cicd-account####:role/wl-cicd-build-codebuild-role-##stg-account##",
   "PRD": "arn:aws:iam::####prod-cicd-account####:role/wl-cicd-build-codebuild-role-##prod-account##"
}
```

## 4. Usage

### 4.1 Trigger the workflow
Go to **Actions → “EKS Scaler” → Run workflow** and choose:

#### Inputs
| Input | Required | Description | Options |
|------|----------|-------------|---------|
| `environment` | Yes | Target environment | `INT`, `DEV`, `STG`, `PRD` |
| `action` | Yes | What to run now | `start`, `stop` |
| `nodes_count` | Yes | Override START capacity (no change if `None`) | `None`, `2`, `4`, `6`, `8`, `10` |
| `stop_behavior` | Yes | Override STOP capacity (no change if `None`) | `None`, `2`, `4`, `6`, `8`, `10` |

### 4.2 What actually changes?
- If you select `nodes_count` (not `None`), the workflow updates:
  - `START_COUNT` in the Lambda environment variables, 
- If you select `stop_behavior` (not `None`), the workflow updates:
  - `STOP_COUNT` in the Lambda environment variables
- Then it invokes the Lambda with `start`/`stop`.

> Notes:
> - This is an **operational control** path (immediate effect), not an IaC change.
> - The real scaling behavior still lives inside `finops-resource-scheduler`.

---

## 5. Implementation Details

### 5.1 Credential Mapping — `find_cred.py`
- Reads `ENV_ACCOUNT_MAPPING` from GitHub Secrets (exported to `ENV_MAPPING_SECRET`)
- Outputs the resolved `account_id` for later steps.

### 5.2 AWS Authentication (OIDC)
The workflow uses two role assumptions:
1. **Infra role** (fixed infra account, includes account-id suffix in role name)
2. **Execution role** (target environment account), using `role-chaining: true`

### 5.3 Updating Lambda Env Vars (optional)
The workflow:
1. Pulls current env vars:
   - `aws lambda get-function-configuration --query 'Environment.Variables'`
2. Uses `jq` to merge a single key override:
   - `START_COUNT` or `STOP_COUNT`
3. Pushes the merged env vars back:
   - `aws lambda update-function-configuration --environment file://...`

### 5.4 Invoking the Lambda
Invokes:
- `finops-resource-scheduler`
- payload: `{"action":"start"}` or `{"action":"stop"}`
- writes output into `response.json`

---

## 6. Requirements & Assumptions
- The GitHub runner image/environment includes:
  - `aws` CLI
  - `jq`
  - `python3`
- The target Lambda exists in the target account:
  - Function name: `finops-resource-scheduler`
- IAM roles allow:
  - `lambda:GetFunctionConfiguration`
  - `lambda:UpdateFunctionConfiguration`
  - `lambda:InvokeFunction`

---

## Maintainer
Dar Ravina
