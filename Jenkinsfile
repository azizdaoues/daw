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
                bat 'docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image laravel-app --format json > reports\\trivy-scan.json'
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
            // Archiver les rapports de tests JUnit
            archiveArtifacts artifacts: 'reports/*.xml', allowEmptyArchive: true
            
            // Archiver les rapports de sécurité
            archiveArtifacts artifacts: 'reports/*.json', allowEmptyArchive: true
            
            // Afficher un résumé des rapports
            script {
                if (fileExists('reports/unit-tests.xml')) {
                    echo 'Unit tests report generated successfully'
                }
                if (fileExists('reports/feature-tests.xml')) {
                    echo 'Feature tests report generated successfully'
                }
                if (fileExists('reports/security-audit.json')) {
                    echo 'Security audit report generated successfully'
                }
                if (fileExists('reports/trivy-scan.json')) {
                    echo 'Docker security scan report generated successfully'
                }
            }
        }
        
        success {
            echo 'Pipeline completed successfully! All tests passed and reports generated.'
            echo 'Check the "Build Artifacts" section to download the reports.'
        }
        
        failure {
            echo 'Pipeline failed! Check the test reports for details.'
            echo 'Check the "Build Artifacts" section to download the reports.'
        }
        
 
    }
}
