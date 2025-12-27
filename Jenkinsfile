pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'suresh53/esewa'
        BUILD_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📦 Cloning repository...'
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Build WAR') {
            steps {
                echo '🔨 Building WAR with Maven...'
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
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '🚀 Deploying to Kubernetes...'
                sh """
                    cat deployment.yaml | sed 's|image: suresh53/esewa:.*|image: ${DOCKER_IMAGE}:${BUILD_TAG}|g' | kubectl apply -f -
                    kubectl apply -f service.yaml
                    kubectl rollout status deployment/esewa-app --timeout=2m
                """
            }
        }

        stage('Verify') {
            steps {
                echo '✅ Verifying deployment...'
                sh """
                    echo "=== Pods ==="
                    kubectl get pods -l app=esewa
                    echo ""
                    echo "=== Service ==="
                    kubectl get svc esewa-service
                    echo ""
                    echo "=== Access URL ==="
                    minikube service esewa-service --url || true
                """
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            echo "✅ Deployed: ${DOCKER_IMAGE}:${BUILD_TAG}"
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            sh 'docker logout || true'
        }
    }
}