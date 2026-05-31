# Client Simulator: ECS Management & CD

This repository provides a unified interface for managing the **Client Simulator** ECS service. By combining automated state management with a PR-driven CD pipeline, developers gain full autonomy over their environments without needing deep Infrastructure-as-Code (IaC) expertise.

---

## ECS Automation (State Management)
The **ECS Automation** workflow is a user-dispatched tool that allows you to inspect and modify the running state of the Client Simulator in real-time.

### Key Capabilities:
* **Environment Targeting:** Select between `dev`, `stg`, or `prd`.
* **Application Mode:** Toggle between `Functional` and `Load-Test`.
* **Granular Logging:** Set log levels (`INFO`, `DEBUG`, `TRACE`, `ERROR`) for specific areas.
* **Scaling on Demand:** Choose instance counts: `None`, `1`, `50`, `100`, or `200`.

> [!IMPORTANT]  
> **The "None" Safety Switch** > Selecting **None** for the instance count ensures **no infrastructure changes** are made during the run.  
> * **Unsure of the current scale?** Run the workflow with `None` first. The GitHub Action logs will output the current ECS state so you can verify the configuration before applying changes.

---

## Client Simulator CD (Continuous Delivery)
Our CD pipeline follows a **GitOps approach** using Terragrunt and Pull Requests to ensure every deployment is tracked and reversible.

### The Workflow:
1. **Remote Trigger:** Triggered automatically from the application repository (`Capenabelment`) after a new Docker image is built and pushed to AWS ECR.
2. **IaC Update:** This repository (`Cap-infra-repo`) automatically updates the Terragrunt configuration with the new image tag.
3. **Automated PRs:** The workflow generates **one Pull Request per environment** (`dev`, `stg`, `prd`).

### How to Deploy:
To deploy the new version, simply review and **approve the Pull Request**. Once merged, the new image will be live within minutes.

---

## 🤝 Why these two work Together?

By pairing **State Management** with **Automated CD**, we provide a complete toolbox for independent service management.


**The Result:** Developers have full independence to deploy, scale, and debug the Client Simulator without requiring manual DevOps intervention.


## Maintainers
Bar Darzi & Dar Ravina