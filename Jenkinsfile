pipeline {
    agent any
    
    environment {
        APP_NAME = 'hello-world'
        APP_VERSION = '1.0.0'
        DOCKER_IMAGE = "${APP_NAME}:${APP_VERSION}"
        DOCKER_IMAGE_LATEST = "${APP_NAME}:latest"
        K8S_NAMESPACE = 'akulaku-sre'
        MAVEN_OPTS = '-Xmx512m'
        PATH = "/opt/homebrew/opt/openjdk@17/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        JAVA_HOME = "/opt/homebrew/opt/openjdk@17"
    }
    
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    
    stages {
        
        stage('0. Environment Check') {
            steps {
                echo '=== STAGE 0: Verify All Tools ==='
                sh '''
                    echo "Java:     $(/opt/homebrew/opt/openjdk@17/bin/java -version 2>&1 | head -1)"
                    echo "Maven:    $(/opt/homebrew/bin/mvn -version | head -1)"
                    echo "Docker:   $(/usr/local/bin/docker --version)"
                    echo "Kubectl:  $(/opt/homebrew/bin/kubectl version --client --short 2>/dev/null || /opt/homebrew/bin/kubectl version --client)"
                    echo "Minikube: $(/opt/homebrew/bin/minikube version | head -1)"
                    echo "Git:      $(git --version)"
                '''
            }
        }
        
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
        
        stage('2. Unit Test') {
            steps {
                echo '=== STAGE 2: Running Unit Tests ==='
                sh '/opt/homebrew/bin/mvn test -B'
            }
            post {
                always {
                    junit testResults: 'target/surefire-reports/*.xml',
                          allowEmptyResults: true
                }
            }
        }
        
        stage('3. Maven Build') {
            steps {
                echo '=== STAGE 3: Building Application with Maven ==='
                sh '/opt/homebrew/bin/mvn clean package -DskipTests -B'
                sh 'ls -lh target/hello-world.jar'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/hello-world.jar',
                                     fingerprint: true
                }
            }
        }
        
        stage('4. Docker Build') {
            steps {
                echo '=== STAGE 4: Building Docker Image ==='
                sh '''
                    eval $(/opt/homebrew/bin/minikube docker-env)
                    /usr/local/bin/docker build -t hello-world:1.0.0 -t hello-world:latest .
                    /usr/local/bin/docker images | grep hello-world
                '''
            }
        }
        
        stage('5. Security Scan') {
            steps {
                echo '=== STAGE 5: Docker Image Security Scan ==='
                sh '''
                    eval $(/opt/homebrew/bin/minikube docker-env)
                    echo "Checking non-root user and exposed ports..."
                    /usr/local/bin/docker inspect hello-world:1.0.0 | grep -E '"User"|"ExposedPorts"'
                    echo "Security scan completed"
                '''
            }
        }
        
        stage('6. Deploy to Kubernetes') {
            steps {
                echo '=== STAGE 6: Deploying to Kubernetes (Minikube) ==='
                sh '''
                    /opt/homebrew/bin/kubectl apply -f k8s/
                    /opt/homebrew/bin/kubectl rollout status deployment/hello-world \
                        -n akulaku-sre --timeout=120s
                '''
            }
        }
        
        stage('7. Smoke Test') {
            steps {
                echo '=== STAGE 7: Running Smoke Tests ==='
                sh '''
                    sleep 15
                    APP_URL=$(/opt/homebrew/bin/minikube service hello-world-svc \
                        -n akulaku-sre --url 2>/dev/null)
                    echo "Testing URL: $APP_URL"
                    
                    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $APP_URL/health)
                    echo "Health check status: $HTTP_STATUS"
                    
                    if [ "$HTTP_STATUS" = "200" ]; then
                        echo "✅ Smoke test PASSED"
                        curl -s $APP_URL/ | python3 -m json.tool
                    else
                        echo "❌ Smoke test FAILED"
                        /opt/homebrew/bin/kubectl get pods -n akulaku-sre
                        /opt/homebrew/bin/kubectl logs -l app=hello-world -n akulaku-sre --tail=20
                        exit 1
                    fi
                '''
            }
        }
        
        stage('8. Verify Deployment') {
            steps {
                echo '=== STAGE 8: Verify Deployment ==='
                sh '''
                    echo "=== Pods ==="
                    /opt/homebrew/bin/kubectl get pods -n akulaku-sre -o wide
                    echo "=== Services ==="
                    /opt/homebrew/bin/kubectl get svc -n akulaku-sre
                    echo "=== Deployment ==="
                    /opt/homebrew/bin/kubectl get deployment -n akulaku-sre
                    echo "=== HPA ==="
                    /opt/homebrew/bin/kubectl get hpa -n akulaku-sre || true
                    echo "=== App Response ==="
                    APP_URL=$(/opt/homebrew/bin/minikube service hello-world-svc -n akulaku-sre --url 2>/dev/null)
                    curl -s $APP_URL/ | python3 -m json.tool
                '''
            }
        }
    }
    
    post {
        success {
            echo '''
            ╔══════════════════════════════════════╗
            ║   ✅ PIPELINE SUCCESS!               ║
            ║   App: hello-world:1.0.0             ║
            ║   Namespace: akulaku-sre             ║
            ╚══════════════════════════════════════╝
            '''
        }
        failure {
            echo '''
            ╔══════════════════════════════════════╗
            ║   ❌ PIPELINE FAILED!                ║
            ║   Check logs above for details       ║
            ╚══════════════════════════════════════╝
            '''
        }
        always {
            sh '/opt/homebrew/bin/kubectl get pods -n akulaku-sre || true'
        }
    }
}
