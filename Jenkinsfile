pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'suresh53/esewa'
        BUILD_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '📦 Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Build WAR with Maven') {
            steps {
                echo '🔨 Building WAR file...'
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:${BUILD_TAG} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_TAG} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '⬆️ Pushing to Docker Hub...'
                sh """
                    echo \$DOCKER_CREDENTIALS_PSW | docker login -u \$DOCKER_CREDENTIALS_USR --password-stdin
                    docker push ${DOCKER_IMAGE}:${BUILD_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                    docker logout
                """
            }
        }

        stage('Update Kubernetes Manifests') {
            steps {
                echo '📝 Updating Kubernetes deployment...'
                sh """
                    sed -i 's|image: suresh53/esewa:.*|image: suresh53/esewa:${BUILD_TAG}|g' k8s/deployment.yaml
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '🚀 Deploying to Kubernetes...'
                sh """
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout status deployment/esewa-app --timeout=2m
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                sh """
                    echo "=== Pods Status ==="
                    kubectl get pods -l app=esewa
                    echo ""
                    echo "=== Service Info ==="
                    kubectl get svc esewa-service
                    echo ""
                    echo "=== Application URL ==="
                    minikube service esewa-service --url || echo "Run: minikube service esewa-service --url"
                """
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            echo "✅ Application deployed with image: ${DOCKER_IMAGE}:${BUILD_TAG}"
        }
        failure {
            echo '❌ Pipeline failed! Check logs above.'
        }
        always {
            echo '🧹 Cleaning up...'
            sh 'docker system prune -f || true'
        }
    }
}