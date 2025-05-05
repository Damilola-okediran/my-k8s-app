# My K8s App

This is a simple Python Flask application that runs on Kubernetes.
This shows it's implementation using AWS EKS.
## What It Does

- Displays a message in the browser.
- Containerized with Docker.
- Deployed to a Kubernetes cluster on AWS (EKS).

## How to Run

1. **Build the Docker image**:
   ```bash
   docker build -t git_username/git_directory:latest .

2. Push to Docker Hub:

docker push github user_name/project_directory:latest


3. Deploy to Kubernetes:

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

4. Get the external IP:
   kubectl get service


List of Files in This Project

1. app.py: The Python app

2. requirements.txt: Python dependencies

3. Dockerfile: Builds the Docker image

4. deployment.yaml: Kubernetes deployment config

5. service.yaml: Kubernetes service config

6. README.md: Project guide
