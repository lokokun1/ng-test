import os
import sys
import argparse
import subprocess
from datetime import datetime

def set_github_output(name, value):
    """Sets an output variable for subsequent steps in a GitHub Actions workflow."""
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write(f"{name}={value}\n")

def run_command(command, error_message):
    """Runs a shell command and exits if it fails."""
    try:
        result = subprocess.run(command, check=True, text=True, capture_output=True)
        print(f"Successfully executed: {' '.join(command)}")
        if result.stdout.strip():
            print("Stdout:", result.stdout.strip())
        if result.stderr.strip():
            print("Stderr:", result.stderr.strip())
    except subprocess.CalledProcessError as e:
        print(f"ERROR: {error_message}")
        print("Stderr:", e.stderr.strip() if e.stderr else "")
        sys.exit(1)

def safe_run(command, error_message):
    """Runs a shell command but continues gracefully if the resource doesn't exist."""
    try:
        result = subprocess.run(command, check=True, text=True, capture_output=True)
        print(f"Successfully executed: {' '.join(command)}")
        if result.stdout.strip():
            print("Stdout:", result.stdout.strip())
        if result.stderr.strip():
            print("Stderr:", result.stderr.strip())
    except subprocess.CalledProcessError as e:
        stderr_output = e.stderr.strip() if e.stderr else ""
        if "ResourceNotFoundException" in stderr_output or "ResourceNotFound" in stderr_output:
            print(f"⚠️  Resource not found for command: {' '.join(command)} — skipping.")
        else:
            print(f"ERROR: {error_message}")
            print("Stderr:", stderr_output)
            sys.exit(1)

def main():
    # --- 1.0 configure python env
    parser = argparse.ArgumentParser(description="Client Simulator CI/CD tag updater.")
    env = ["prd","stg","dev"]
    parser.add_argument("--ImageTag", required=True, help="Image tag from docker-push.yaml file.")
    args = parser.parse_args()
    # --- 1.1 configure git
    run_command(["git", "config", "--global", "user.name", "GitHub Actions"], "Git config failed.")
    run_command(["git", "config", "--global", "user.email", "actions@github.com"], "Git config failed.")
    
    # ---  1.2 iterate over envs  
    for i in range(len(env)):
        base_path = f"./products/anan-magen/il-central-1/{env[i]}/client-simulator/ecs-task-def/terragrunt.hcl"

        if not os.path.exists(base_path):
            print(f"ERROR: File not found: {base_path}")
            sys.exit(1)

        with open(base_path, 'r') as f:
            lines = f.readlines()

        new_lines = []
        found = False
        # --- 1.2.1 find the row that says image in the file  
        for line in lines:
            if not found and "image" in line:
                colon_index = line.find(':')
                quote_index = line.rfind('"')
                if colon_index != -1 and quote_index != -1:
                    prefix = line[:colon_index+1]
                    new_line = f"{prefix}{args.ImageTag}\"\n"
                    # --- 1.2.2 update to latest image  
                    print(f"🔄 Updating line:\n{line.strip()} \n  {new_line.strip()}")
                    new_lines.append(new_line)
                    found = True
                    continue  
            new_lines.append(line)


        if not found:
            print("No image line found. No changes made.")
            sys.exit(1)

        with open(base_path, 'w') as f:
            f.writelines(new_lines)

        print("File updated successfully.")

        # 1.3: Commit and push the changes to trigger the Terragrunt workflow
        print("Committing and pushing changes to trigger Terragrunt deployment...")
        run_command(["git", "add", base_path], "Git add failed.")
        commit_message = f"update task def, env:{env[i]} tag:{args.ImageTag}"
        branch_name = f"{args.ImageTag}-{env[i]}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        print(f"Creating new branch for PR: {branch_name}")

        # Create and checkout new branch
        run_command(["git", "checkout", "-b", branch_name], "Failed to create branch.")
        # commit after moving to new branch
        run_command(["git", "commit", "-m", commit_message], "Git commit failed.")
        # Push branch to origin
        run_command(["git", "push", "origin", branch_name], "Git push failed.")

        print(f"✅ Branch '{branch_name}' pushed successfully. Please open a PR to merge into main.")
        print("Push successful. The Terragrunt apply workflow should now be triggered after a merge.")
        print("Creating pull request automatically...")

        pr_title = f"Update task def, ENV:{env[i]} TAG:{args.ImageTag}"
        pr_body = f"Triggered automatically by cicd workflow for {env[i]} environment."

        run_command(
            [
                "gh", "pr", "create",
                "--title", pr_title,
                "--body", pr_body,
                "--base", "main",
                "--head", branch_name
            ],
            "Failed to create pull request."
        )
        run_command(["git", "fetch", "origin", "main"], "Git fetch failed.")
        run_command(["git", "checkout", "main"], "Git checkout main failed.")
        run_command(["git", "pull", "origin", "main"], "Git pull failed.")

if __name__ == "__main__":
    main()