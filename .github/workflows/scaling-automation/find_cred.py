import os
import sys
import json
import argparse


def set_github_output(name, value):
    """Sets an output variable for subsequent steps in a GitHub Actions workflow."""
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        f.write(f"{name}={value}\n")

def extract_account_id_from_arn(arn):
    account_id = arn[-12:]
    if not account_id.isdigit():
        print(f"FATAL: Could not extract valid account ID from ARN: {arn}")
        sys.exit(1)
    return account_id

def main():
# --- Phase 0: Initialization & Environment Mapping ---
    parser = argparse.ArgumentParser(description="Map environment to its build role ARN.")
    parser.add_argument("--environment", required=True, help="Environment name (INT, DEV, STG, PRD).")
    args = parser.parse_args()
# 0.2: Get the mapping from the GitHub Secret, passed as an environment variable
    mapping_json = os.getenv("ENV_MAPPING_SECRET")
    if not mapping_json:
        print("FATAL: ENV_MAPPING_SECRET not found.")
        sys.exit(1)

    env_mapping = json.loads(mapping_json)
    arn = env_mapping.get(args.environment)

    if not arn:
        print(f"FATAL: Environment '{args.environment}' not found in secret.")
        sys.exit(1)

# 0.3 slice the arn to extract needed account id
    account_id = extract_account_id_from_arn(arn)

# 0.4: Set the account_id as an output for the GHA workflow
    print(f"✅ Found build role ARN for '{args.environment}': {arn}")
    print(f"Extracted Target Account ID: {account_id}")

    set_github_output("build_role_arn", arn)
    set_github_output("account_id", account_id)


if __name__ == "__main__":
    main()