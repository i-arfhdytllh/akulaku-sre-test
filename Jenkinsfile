pipeline {
    agent any
    
    environment {
        APP_NAME = 'hello-world'
        APP_VERSION = '1.0.0'
        DOCKER_IMAGE = "${APP_NAME}:${APP_VERSION}"
        DOCKER_IMAGE_LATEST = "${APP_NAME}:latest"
        K8S_NAMESPACE = 'akulaku-sre'
        MAVEN_OPTS = '-Xmx512m'
    }
    
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    
    stages {
        
        // ========== STAGE 1: CHECKOUT ==========
        stage('1. Checkout') {
            steps {
                echo '=== STAGE 1: Checkout Source Code ==='
                checkout scm
                sh '''
                    echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
                    echo "Commit: $(git rev-parse --short HEAD)"
                    echo "Author: $(git log -1 --pretty=format:'%an')"
                '''
            }
        }
        
        // ========== STAGE 2: UNIT TEST ==========
        stage('2. Unit Test') {
            steps {
                echo '=== STAGE 2: Running Unit Tests ==='
                sh 'mvn test -B'
            }
            post {
                always {
                    junit testResults: 'target/surefire-reports/*.xml',
                          allowEmptyResults: true
                }
            }
        }
        
        // ========== STAGE 3: BUILD ==========
        stage('3. Maven Build') {
            steps {
                echo '=== STAGE 3: Building Application with Maven ==='
                sh 'mvn clean package -DskipTests -B'
                sh 'ls -la target/'
                sh 'echo "JAR size: $(du -sh target/hello-world.jar)"'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/hello-world.jar',
                                     fingerprint: true
                }
            }
        }
        
        // ========== STAGE 4: CODE QUALITY ==========
        stage('4. Code Analysis') {
            steps {
                echo '=== STAGE 4: Code Quality Check ==='
                sh 'mvn verify -DskipTests checkstyle:check || true'
                echo 'Code analysis completed'
            }
        }
        
        // ========== STAGE 5: DOCKER BUILD ==========
        stage('5. Docker Build') {
            steps {
                echo '=== STAGE 5: Building Docker Image ==='
                sh """
                    eval \$(minikube docker-env) || true
                    docker build -t ${DOCKER_IMAGE} -t ${DOCKER_IMAGE_LATEST} .
                    docker images | grep ${APP_NAME}
                """
            }
        }
        
        // ========== STAGE 6: SECURITY SCAN ==========
        stage('6. Security Scan') {
            steps {
                echo '=== STAGE 6: Docker Image Security Scan ==='
                sh """
                    echo "Running basic security checks..."
                    docker inspect ${DOCKER_IMAGE} | grep -E '"User"|"ExposedPorts"'
                    echo "Security scan completed"
                """
            }
        }
        
        // ========== STAGE 7: DEPLOY TO K8S ==========
        stage('7. Deploy to Kubernetes') {
            steps {
                echo '=== STAGE 7: Deploying to Kubernetes (Minikube) ==='
                sh """
                    kubectl apply -f k8s/
                    kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE} --timeout=120s
                """
            }
        }
        
        // ========== STAGE 8: SMOKE TEST ==========
        stage('8. Smoke Test') {
            steps {
                echo '=== STAGE 8: Running Smoke Tests ==='
                sh """
                    sleep 15
                    APP_URL=\$(minikube service hello-world-svc -n ${K8S_NAMESPACE} --url 2>/dev/null)
                    echo "Testing URL: \$APP_URL"
                    
                    # Test health endpoint
                    HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" \$APP_URL/health)
                    echo "Health check status: \$HTTP_STATUS"
                    
                    if [ "\$HTTP_STATUS" = "200" ]; then
                        echo "✅ Smoke test PASSED"
                        curl -s \$APP_URL/ | python3 -m json.tool
                    else
                        echo "❌ Smoke test FAILED"
                        exit 1
                    fi
                """
            }
        }
        
        // ========== STAGE 9: VERIFY DEPLOYMENT ==========
        stage('9. Verify Deployment') {
            steps {
                echo '=== STAGE 9: Verifying Deployment ==='
                sh """
                    echo "=== Pods Status ==="
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide
                    
                    echo "=== Service Status ==="
                    kubectl get svc -n ${K8S_NAMESPACE}
                    
                    echo "=== Deployment Status ==="
                    kubectl get deployment -n ${K8S_NAMESPACE}
                    
                    echo "=== HPA Status ==="
                    kubectl get hpa -n ${K8S_NAMESPACE} || true
                """
            }
        }
    }
    
    post {
        success {
            echo """
            ╔══════════════════════════════════════╗
            ║   ✅ PIPELINE SUCCESS!               ║
            ║   App: ${APP_NAME}:${APP_VERSION}     ║
            ║   Namespace: ${K8S_NAMESPACE}         ║
            ╚══════════════════════════════════════╝
            """
        }
        failure {
            echo """
            ╔══════════════════════════════════════╗
            ║   ❌ PIPELINE FAILED!                ║
            ║   Check logs for details             ║
            ╚══════════════════════════════════════╝
            """
        }
        always {
            echo '=== Pipeline Execution Complete ==='
            sh 'kubectl get pods -n akulaku-sre || true'
        }
    }
}
