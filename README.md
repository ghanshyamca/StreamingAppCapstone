# End-to-End DevOps Pipeline for a Web Application with CI/CD

This repository contains a microservice-based streaming web application that is being used as the workload for an end-to-end DevOps capstone. The project focuses on building a repeatable delivery pipeline with Docker, Jenkins, Terraform, Ansible, Kubernetes on AWS EKS, and observability with Prometheus and Grafana.

## Project Scope

The goal is to automate the full path from code change to production deployment:

1. Build and test the application in Jenkins.
2. Package services into Docker images and publish them to AWS ECR.
3. Provision AWS infrastructure with Terraform.
4. Configure compute and tooling with Ansible.
5. Deploy the application to Kubernetes on AWS EKS.
6. Monitor the stack with Prometheus, Grafana, and Jenkins alerts.

## Application Architecture

The current application is a modular video streaming platform composed of four backend services, a React frontend, and MongoDB.

| Service | Port | Description |
| --- | --- | --- |
| `authService` | 3001 | User authentication, registration, JWT issuance |
| `streamingService` | 3002 | Video catalogue, S3 playback endpoints, public APIs |
| `adminService` | 3003 | Asset management and upload workflows |
| `chatService` | 3004 | REST + realtime chat for watch parties |
| `frontend` | 3000 | React SPA for browsing, playback, and admin actions |
| `mongo` | 27017 | Shared MongoDB instance |

## Current Repository State

The application stack is already containerized and runnable locally with Docker Compose. The DevOps layers listed below are the intended delivery work for this capstone and can be implemented on top of the existing services.

Included today:

- Backend services under `backend/`
- React frontend under `frontend/`
- Docker Compose for local orchestration

Planned for the pipeline project:

- Jenkins pipeline jobs and shared credentials
- Terraform modules for VPC, subnets, security groups, EKS, EC2, and S3 state storage
- Ansible playbooks for instance and node configuration
- Kubernetes manifests or Helm charts for deployment
- Prometheus and Grafana dashboards and alert rules

## Sprint Plan

### Sprint 1: Architecture, Dockerization, and Jenkins Setup

- Design the AWS deployment architecture.
- Build Docker images for each service and publish to AWS ECR.
- Set up Jenkins on AWS EC2 and install the Docker, Kubernetes, and AWS CLI plugins.
- Configure Jenkins credentials and IAM access for AWS and EKS.
- Enable Git-based build triggers for CI.

### Sprint 2: Terraform Infrastructure Provisioning

- Create Terraform for VPC, subnets, route tables, security groups, EC2, and EKS.
- Store Terraform state in AWS S3 with locking if required.
- Trigger Terraform from Jenkins and verify repeatable provisioning.

### Sprint 3: Configuration Management with Ansible

- Write playbooks to install Docker, kubectl, and required dependencies.
- Configure EC2 instances and supporting nodes consistently.
- Chain Ansible execution after Terraform completes.

### Sprint 4: Kubernetes Deployment on EKS

- Build a multi-stage Jenkins pipeline for build, test, image push, and deploy.
- Deploy the application to EKS using Kubernetes manifests.
- Add readiness and liveness checks, resource requests, limits, and autoscaling.

### Sprint 5: Monitoring and Alerting

- Install Prometheus in EKS to collect cluster and application metrics.
- Visualize metrics in Grafana dashboards.
- Configure alerts for deployment failures and critical resource conditions.

### Sprint 6: Testing and Final Automation

- Add smoke tests and deployment validation checks.
- Document Jenkins, Terraform, Ansible, Kubernetes, and monitoring setup.
- Run end-to-end testing from code push to production-ready deployment.

## CI/CD Pipeline Stages

1. Build Stage
- Trigger on code push.
- Run tests and build Docker images.
- Push versioned images to AWS ECR.

2. Infrastructure Provisioning Stage
- Apply Terraform to provision AWS infrastructure.
- Persist state in AWS S3 for team access and reproducibility.

3. Configuration Management Stage
- Run Ansible to configure hosts and dependencies.
- Prepare infrastructure for Kubernetes workloads.

4. Deployment Stage
- Deploy manifests to EKS with `kubectl` or Helm.
- Validate service exposure, health checks, and autoscaling.

5. Testing and Monitoring Stage
- Execute post-deployment smoke tests.
- Monitor jobs, application health, and cluster metrics with Prometheus and Grafana.

## Environment Configuration

Create an `.env` for each service or export the variables before running locally.

### Auth Service (`backend/authService/.env`)
```ini
PORT=3001
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-south-1
AWS_S3_BUCKET=
```

### Streaming Service (`backend/streamingService/.env`)
```ini
PORT=3002
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-south-1
AWS_S3_BUCKET=
AWS_CDN_URL=
STREAMING_PUBLIC_URL=http://localhost:3002
```

### Admin Service (`backend/adminService/.env`)
```ini
PORT=3003
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-south-1
AWS_S3_BUCKET=
```

### Chat Service (`backend/chatService/.env`)
```ini
PORT=3004
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
```

### Frontend build variables (`frontend/.env` or Docker build args)
```ini
REACT_APP_AUTH_API_URL=http://localhost:3001/api
REACT_APP_STREAMING_API_URL=http://localhost:3002/api
REACT_APP_STREAMING_PUBLIC_URL=http://localhost:3002
REACT_APP_ADMIN_API_URL=http://localhost:3003/api/admin
REACT_APP_CHAT_API_URL=http://localhost:3004/api/chat
REACT_APP_CHAT_SOCKET_URL=http://localhost:3004
```

## Running Locally

Build and start the full local stack with Docker Compose:

```bash
docker-compose up --build
```

Open `http://localhost:3000` in your browser after the services are ready.

For manual development, install dependencies per service and run them in separate terminals:

```bash
# auth service
cd backend/authService && npm install && npm run dev

# streaming service
cd ../streamingService && npm install && npm run dev

# admin service
cd ../adminService && npm install && npm run dev

# chat service
cd ../chatService && npm install && npm run dev

# frontend
cd ../../frontend && npm install && npm start
```

## Testing

Recommended smoke checks for the current application stack:

1. Register and log in through the frontend.
2. Confirm that browse and streaming pages load data correctly.
3. Verify chat messages synchronize across multiple browser tabs.
4. Confirm admin upload flows when AWS credentials and S3 assets are available.

## Deliverables

- End-to-end Jenkins CI/CD pipeline.
- Terraform-based AWS infrastructure provisioning.
- Ansible-based configuration management.
- Kubernetes deployment on AWS EKS.
- Prometheus and Grafana monitoring with alerts.
- Documentation for setup, deployment, troubleshooting, and validation.

## License

MIT © StreamFlix Team
