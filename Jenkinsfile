pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    string(name: 'AWS_ACCOUNT_ID', defaultValue: '', description: 'AWS account ID used for ECR image pushes')
    string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'AWS region for ECR and EKS')
    string(name: 'EKS_CLUSTER_NAME', defaultValue: 'streamingapp-cluster', description: 'Target EKS cluster name')
    string(name: 'K8S_NAMESPACE', defaultValue: 'streamingapp', description: 'Kubernetes namespace for deployment')
    string(name: 'FRONTEND_HOST', defaultValue: 'app.example.com', description: 'Public host used for the frontend ingress rule')
    string(name: 'AUTH_HOST', defaultValue: 'auth.example.com', description: 'Public host used for the auth ingress rule')
    string(name: 'STREAMING_HOST', defaultValue: 'streaming.example.com', description: 'Public host used for the streaming ingress rule')
    string(name: 'ADMIN_HOST', defaultValue: 'admin.example.com', description: 'Public host used for the admin ingress rule')
    string(name: 'CHAT_HOST', defaultValue: 'chat.example.com', description: 'Public host used for the chat ingress rule')
    string(name: 'STATE_BUCKET_NAME', defaultValue: 'streamingapp-terraform-state', description: 'S3 bucket used by Terraform backend')
    string(name: 'LOCK_TABLE_NAME', defaultValue: 'streamingapp-terraform-locks', description: 'DynamoDB table used for Terraform locking')
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Optional image tag override')
    string(name: 'REACT_APP_AUTH_API_URL', defaultValue: 'http://localhost:3001/api', description: 'Frontend auth API URL used at build time')
    string(name: 'REACT_APP_STREAMING_API_URL', defaultValue: 'http://localhost:3002/api', description: 'Frontend streaming API URL used at build time')
    string(name: 'REACT_APP_STREAMING_PUBLIC_URL', defaultValue: 'http://localhost:3002', description: 'Frontend public streaming URL used at build time')
    string(name: 'REACT_APP_ADMIN_API_URL', defaultValue: 'http://localhost:3003/api/admin', description: 'Frontend admin API URL used at build time')
    string(name: 'REACT_APP_CHAT_API_URL', defaultValue: 'http://localhost:3004/api/chat', description: 'Frontend chat API URL used at build time')
    string(name: 'REACT_APP_CHAT_SOCKET_URL', defaultValue: 'http://localhost:3004', description: 'Frontend chat socket URL used at build time')
    string(name: 'JWT_SECRET_CREDENTIAL_ID', defaultValue: 'streamingapp-jwt-secret', description: 'Jenkins credential ID for the JWT secret text')
    string(name: 'MONGO_URI_CREDENTIAL_ID', defaultValue: 'streamingapp-mongo-uri', description: 'Jenkins credential ID for the MongoDB URI secret text')
    string(name: 'AWS_ACCESS_KEY_ID_CREDENTIAL_ID', defaultValue: 'streamingapp-aws-access-key-id', description: 'Jenkins credential ID for the AWS access key ID secret text')
    string(name: 'AWS_SECRET_ACCESS_KEY_CREDENTIAL_ID', defaultValue: 'streamingapp-aws-secret-access-key', description: 'Jenkins credential ID for the AWS secret access key secret text')
    string(name: 'AWS_S3_BUCKET_CREDENTIAL_ID', defaultValue: 'streamingapp-aws-s3-bucket', description: 'Jenkins credential ID for the S3 bucket name secret text')
  }

  environment {
    AUTH_IMAGE = 'streamingapp-auth'
    STREAMING_IMAGE = 'streamingapp-streaming'
    ADMIN_IMAGE = 'streamingapp-admin'
    CHAT_IMAGE = 'streamingapp-chat'
    FRONTEND_IMAGE = 'streamingapp-frontend'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies') {
      parallel {
        stage('Auth Service') {
          steps {
            dir('backend/authService') {
              sh 'npm ci'
            }
          }
        }
        stage('Streaming Service') {
          steps {
            dir('backend/streamingService') {
              sh 'npm ci'
            }
          }
        }
        stage('Admin Service') {
          steps {
            dir('backend/adminService') {
              sh 'npm ci'
            }
          }
        }
        stage('Chat Service') {
          steps {
            dir('backend/chatService') {
              sh 'npm ci'
            }
          }
        }
        stage('Frontend') {
          steps {
            dir('frontend') {
              sh 'npm ci'
            }
          }
        }
      }
    }

    stage('Test Frontend') {
      steps {
        dir('frontend') {
          sh 'CI=true npm test -- --watchAll=false'
        }
      }
    }

    stage('Provision Infrastructure') {
      steps {
        script {
          sh 'terraform -chdir=infra/terraform init -input=false -backend=false'
          sh "terraform -chdir=infra/terraform apply -input=false -auto-approve -var=project_name=streamingapp -var=aws_region=${params.AWS_REGION} -var=state_bucket_name=${params.STATE_BUCKET_NAME} -var=lock_table_name=${params.LOCK_TABLE_NAME}"
          sh "terraform -chdir=infra/terraform init -input=false -migrate-state -reconfigure -backend-config=bucket=${params.STATE_BUCKET_NAME} -backend-config=key=terraform.tfstate -backend-config=region=${params.AWS_REGION} -backend-config=dynamodb_table=${params.LOCK_TABLE_NAME}"
          sh "terraform -chdir=infra/terraform apply -input=false -auto-approve -var=project_name=streamingapp -var=aws_region=${params.AWS_REGION} -var=state_bucket_name=${params.STATE_BUCKET_NAME} -var=lock_table_name=${params.LOCK_TABLE_NAME}"
        }
      }
    }

    stage('Configuration Validation') {
      steps {
        sh 'ansible-playbook infra/ansible/site.yml --syntax-check -i localhost, -c local'
      }
    }

    stage('Create Kubernetes Secrets') {
      steps {
        script {
          withCredentials([
            string(credentialsId: params.JWT_SECRET_CREDENTIAL_ID, variable: 'JWT_SECRET'),
            string(credentialsId: params.MONGO_URI_CREDENTIAL_ID, variable: 'MONGO_URI'),
            string(credentialsId: params.AWS_ACCESS_KEY_ID_CREDENTIAL_ID, variable: 'AWS_ACCESS_KEY_ID'),
            string(credentialsId: params.AWS_SECRET_ACCESS_KEY_CREDENTIAL_ID, variable: 'AWS_SECRET_ACCESS_KEY'),
            string(credentialsId: params.AWS_S3_BUCKET_CREDENTIAL_ID, variable: 'AWS_S3_BUCKET')
          ]) {
            sh """
              aws eks update-kubeconfig --region ${params.AWS_REGION} --name ${params.EKS_CLUSTER_NAME}
              kubectl apply -f k8s/namespace.yaml
              kubectl create secret generic streamingapp-secrets \
                --namespace streamingapp \
                --dry-run=client -o yaml \
                --from-literal=JWT_SECRET=\"$JWT_SECRET\" \
                --from-literal=MONGO_URI=\"$MONGO_URI\" \
                --from-literal=AWS_ACCESS_KEY_ID=\"$AWS_ACCESS_KEY_ID\" \
                --from-literal=AWS_SECRET_ACCESS_KEY=\"$AWS_SECRET_ACCESS_KEY\" \
                --from-literal=AWS_S3_BUCKET=\"$AWS_S3_BUCKET\" | kubectl apply -f -
            """
          }
        }
      }
    }

    stage('Build Images') {
      steps {
        script {
          imageTag = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : (env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : env.BUILD_NUMBER)
          ecrRegistry = params.AWS_ACCOUNT_ID?.trim() ? "${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com" : ''
          frontendAuthApiUrl = params.AUTH_HOST?.trim() ? "http://${params.AUTH_HOST}/api" : params.REACT_APP_AUTH_API_URL
          frontendStreamingApiUrl = params.STREAMING_HOST?.trim() ? "http://${params.STREAMING_HOST}/api" : params.REACT_APP_STREAMING_API_URL
          frontendStreamingPublicUrl = params.STREAMING_HOST?.trim() ? "http://${params.STREAMING_HOST}" : params.REACT_APP_STREAMING_PUBLIC_URL
          frontendAdminApiUrl = params.ADMIN_HOST?.trim() ? "http://${params.ADMIN_HOST}/api/admin" : params.REACT_APP_ADMIN_API_URL
          frontendChatApiUrl = params.CHAT_HOST?.trim() ? "http://${params.CHAT_HOST}/api/chat" : params.REACT_APP_CHAT_API_URL
          frontendChatSocketUrl = params.CHAT_HOST?.trim() ? "http://${params.CHAT_HOST}" : params.REACT_APP_CHAT_SOCKET_URL

          sh "docker build -t ${AUTH_IMAGE}:${imageTag} backend/authService"
          sh "docker build -t ${STREAMING_IMAGE}:${imageTag} -f backend/streamingService/Dockerfile backend"
          sh "docker build -t ${ADMIN_IMAGE}:${imageTag} -f backend/adminService/Dockerfile backend"
          sh "docker build -t ${CHAT_IMAGE}:${imageTag} -f backend/chatService/Dockerfile backend"
          sh "docker build --build-arg REACT_APP_AUTH_API_URL=${frontendAuthApiUrl} --build-arg REACT_APP_STREAMING_API_URL=${frontendStreamingApiUrl} --build-arg REACT_APP_STREAMING_PUBLIC_URL=${frontendStreamingPublicUrl} --build-arg REACT_APP_ADMIN_API_URL=${frontendAdminApiUrl} --build-arg REACT_APP_CHAT_API_URL=${frontendChatApiUrl} --build-arg REACT_APP_CHAT_SOCKET_URL=${frontendChatSocketUrl} -t ${FRONTEND_IMAGE}:${imageTag} frontend"

          if (ecrRegistry) {
            sh "docker tag ${AUTH_IMAGE}:${imageTag} ${ecrRegistry}/${AUTH_IMAGE}:${imageTag}"
            sh "docker tag ${STREAMING_IMAGE}:${imageTag} ${ecrRegistry}/${STREAMING_IMAGE}:${imageTag}"
            sh "docker tag ${ADMIN_IMAGE}:${imageTag} ${ecrRegistry}/${ADMIN_IMAGE}:${imageTag}"
            sh "docker tag ${CHAT_IMAGE}:${imageTag} ${ecrRegistry}/${CHAT_IMAGE}:${imageTag}"
            sh "docker tag ${FRONTEND_IMAGE}:${imageTag} ${ecrRegistry}/${FRONTEND_IMAGE}:${imageTag}"
          }
        }
      }
    }

    stage('Push Images') {
      when {
        expression {
          return params.AWS_ACCOUNT_ID?.trim()
        }
      }
      steps {
        script {
          sh "aws ecr get-login-password --region ${params.AWS_REGION} | docker login --username AWS --password-stdin ${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com"
          sh "docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${AUTH_IMAGE}:${imageTag}"
          sh "docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${STREAMING_IMAGE}:${imageTag}"
          sh "docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${ADMIN_IMAGE}:${imageTag}"
          sh "docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${CHAT_IMAGE}:${imageTag}"
          sh "docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${FRONTEND_IMAGE}:${imageTag}"
        }
      }
    }

    stage('Deploy to Kubernetes') {
      when {
        allOf {
          expression {
            return params.AWS_ACCOUNT_ID?.trim()
          }
          expression {
            return fileExists('k8s')
          }
        }
      }
      steps {
        script {
          sh "aws eks update-kubeconfig --region ${params.AWS_REGION} --name ${params.EKS_CLUSTER_NAME}"
          sh "sed -i 's|__IMAGE_TAG__|${imageTag}|g' k8s/*.yaml"
          sh "sed -i 's|__AWS_ACCOUNT_ID__|${params.AWS_ACCOUNT_ID}|g' k8s/*.yaml"
          sh "sed -i 's|__AWS_REGION__|${params.AWS_REGION}|g' k8s/*.yaml"
          sh "sed -i 's|__FRONTEND_HOST__|${params.FRONTEND_HOST}|g' k8s/ingress.yaml"
          sh "sed -i 's|__AUTH_HOST__|${params.AUTH_HOST}|g' k8s/ingress.yaml"
          sh "sed -i 's|__STREAMING_HOST__|${params.STREAMING_HOST}|g' k8s/ingress.yaml"
          sh "sed -i 's|__ADMIN_HOST__|${params.ADMIN_HOST}|g' k8s/ingress.yaml"
          sh "sed -i 's|__CHAT_HOST__|${params.CHAT_HOST}|g' k8s/ingress.yaml"
          sh "kubectl apply -f k8s/namespace.yaml"
          sh "kubectl apply -f k8s/configmap.yaml"
          sh "kubectl apply -f k8s/auth-service.yaml"
          sh "kubectl apply -f k8s/streaming-service.yaml"
          sh "kubectl apply -f k8s/admin-service.yaml"
          sh "kubectl apply -f k8s/chat-service.yaml"
          sh "kubectl apply -f k8s/frontend.yaml"
          sh "kubectl apply -f k8s/ingress.yaml"
          sh "kubectl apply -f k8s/monitoring.yaml"
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed successfully.'
    }
    failure {
      echo 'Pipeline failed. Review the Jenkins console output for the first broken stage.'
    }
  }
}