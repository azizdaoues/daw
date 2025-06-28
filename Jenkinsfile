pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'ayoub' // Nom configuré dans Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                bat 'composer install'
                bat 'composer config allow-plugins.infection/extension-installer true'
                bat 'composer require --dev infection/infection'
            }
        }

        stage('Tests & Security Scan') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        bat 'if not exist reports mkdir reports'
                        bat 'vendor\\bin\\phpunit --testsuite=Unit --log-junit=reports/unit-tests.xml'
                    }
                }
                stage('Feature Tests') {
                    steps {
                        bat 'if not exist reports mkdir reports'
                        bat 'vendor\\bin\\phpunit --testsuite=Feature --log-junit=reports/feature-tests.xml'
                    }
                }
                stage('Security Scan Dependencies') {
                    steps {
                        bat 'if not exist reports mkdir reports'
                        bat 'composer audit --format=json > reports\\security-audit.json'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('ayoub') {
                    bat 'vendor\\bin\\phpunit --log-junit=reports/sonar-tests.xml'
                    bat '"C:\\Users\\MSI\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" -Dsonar.projectKey=laravel-app -Dsonar.sources=app -Dsonar.tests=tests -Dsonar.host.url=http://localhost:9000 -Dsonar.login=%SONAR_AUTH_TOKEN%'
                }
            }
        }

        stage('Mutation Tests') {
            steps {
                bat 'copy .env .env.backup'
                bat 'php artisan key:generate'
                bat 'vendor\\bin\\phpunit --log-junit=reports/mutation-tests.xml'
                // Mutation testing requires code coverage extensions (xdebug/pcov) not available on Windows
                // bat 'vendor\\bin\\infection --threads=2 --noop'
                echo 'Mutation testing skipped - requires code coverage extensions not available on Windows'
            }
        }

        stage('Build with Docker Compose') {
            steps {
                bat 'docker-compose build'
            }
        }

        stage('Docker Image Security Scan') {
            steps {
                bat 'if not exist reports mkdir reports'
                bat 'docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image laravel-app --format json --output reports/trivy-scan.json'
            }
        }

        stage('Deploy') {
            steps {
                bat 'docker-compose up -d'
            }
        }
    }

    post {
        always {
            // Publier les rapports de tests JUnit
            publishTestResults testResultsPattern: 'reports/*.xml'
            
            // Publier les rapports de sécurité
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: 'security-audit.json',
                reportName: 'Security Audit Report'
            ])
            
            // Publier le rapport Trivy
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: 'trivy-scan.json',
                reportName: 'Docker Security Scan Report'
            ])
        }
        
        success {
            echo 'Pipeline completed successfully! All tests passed and reports generated.'
        }
        
        failure {
            echo 'Pipeline failed! Check the test reports for details.'
        }
        
        cleanup {
            // Nettoyer les fichiers temporaires
            bat 'if exist reports rmdir /s /q reports'
        }
    }
}
