import os
import yaml
import json

def find_applications(root_dir):
    app_dirs = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        if 'Dockerfile' in filenames and 'meta.yaml' in filenames:
            app_dirs.append(dirpath)
    return app_dirs

def substitute_name_in_meta(meta_path, app_name):
    with open(meta_path, 'r') as f:
        meta = yaml.safe_load(f)
    # Recursively substitute {name} in all string values
    def substitute(obj):
        if isinstance(obj, dict):
            return {k: substitute(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [substitute(i) for i in obj]
        elif isinstance(obj, str):
            return obj.replace("{name}", app_name)
        else:
            return obj
    return substitute(meta)

def parse_meta(app_dir):
    meta_path = os.path.join(app_dir, "meta.yaml")
    with open(meta_path) as f:
        meta = yaml.safe_load(f)
    return {
        "name": os.path.basename(app_dir),
        "port": meta.get("port", 80),
        "cpu": meta.get("cpu", 256),
        "memory": meta.get("memory", 512)
    }

if __name__ == "__main__":
    root = "."
    apps = find_applications(root)
    print("Found application directories:")
    for app in apps:
        print(app)
        meta_path = os.path.join(app, "meta.yaml")
        app_name = os.path.basename(app)
        substituted_meta = substitute_name_in_meta(meta_path, app_name)
        print(f"Substituted meta.yaml for {app_name}:")
        print(yaml.dump(substituted_meta, sort_keys=False))
        
    with open("found_apps.txt", "w") as f:
        for app in apps:
            f.write(app + "\n")

    # Generate terraform/locals.auto.tfvars.json for Terraform automation
    locals_apps = [parse_meta(app) for app in apps]
    os.makedirs("terraform", exist_ok=True)
    with open("terraform/locals.auto.tfvars.json", "w") as f:
        json.dump({"apps": locals_apps}, f, indent=2)

    # Generate .gitlab-ci-build-matrix.yml for GitLab CI
    with open("found_apps.txt") as f:
        apps = [os.path.basename(line.strip()) for line in f if line.strip()]

    matrix = {
        "build_apps": {
            "stage": "build",
            "image": "docker:24.0.5",
            "services": ["docker:24.0.5-dind"],
            "parallel": {
                "matrix": [{"APP_NAME": apps}]
            },
            "script": [
                'app_dir=$(grep "/$APP_NAME$" found_apps.txt)',
                'if [ -z "$app_dir" ]; then echo "App dir for $APP_NAME not found."; exit 1; fi',
                'aws ecr get-login-password --region "$AWS_DEFAULT_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"',
                'terraform -chdir=terraform output -json ecr_repos > ecr_repos.json',
                'echo "Building $APP_NAME from $app_dir"',
                'docker build -t "$APP_NAME:latest" "$app_dir"',
                'ecr_repo=$(jq -r --arg name "$APP_NAME" \'.[$name]\' ecr_repos.json)',
                'docker tag "$APP_NAME:latest" "$ecr_repo:latest"',
                'docker push "$ecr_repo:latest"'
            ]
        }
    }

    with open(".gitlab-ci-build-matrix.yml", "w") as f:
        yaml.dump(matrix, f, default_flow_style=False)