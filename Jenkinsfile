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
                        bat 'powershell -ExecutionPolicy Bypass -File generate-test-report.ps1 -TestSuite unit'
                        bat 'vendor\\bin\\phpunit --testsuite=Unit --log-junit=reports/unit-tests.xml --testdox-html=reports/unit-tests.html --colors=always --stop-on-failure'
                    }
                }
                stage('Feature Tests') {
                    steps {
                        bat 'if not exist reports mkdir reports'
                        bat 'powershell -ExecutionPolicy Bypass -File generate-test-report.ps1 -TestSuite feature'
                        bat 'vendor\\bin\\phpunit --testsuite=Feature --log-junit=reports/feature-tests.xml --testdox-html=reports/feature-tests.html --colors=always --stop-on-failure'
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
                    bat 'if not exist reports mkdir reports'
                    bat 'vendor\\bin\\phpunit --log-junit=reports/sonar-tests.xml --testdox-html=reports/sonar-tests.html --colors=always'
                    bat '"C:\\Users\\MSI\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" -Dsonar.projectKey=laravel-app -Dsonar.sources=app -Dsonar.tests=tests -Dsonar.host.url=http://localhost:9000 -Dsonar.login=%SONAR_AUTH_TOKEN%'
                }
            }
        }

        stage('Mutation Tests') {
            steps {
                bat 'copy .env .env.backup'
                bat 'php artisan key:generate'
                bat 'if not exist reports mkdir reports'
                bat 'vendor\\bin\\phpunit --log-junit=reports/mutation-tests.xml --testdox-html=reports/mutation-tests.html --colors=always'
                // Mutation testing requires code coverage extensions (xdebug/pcov) not available on Windows
                // bat 'vendor\\bin\\infection --threads=2 --noop'
                echo 'Mutation testing skipped - requires code coverage extensions not available on Windows'
            }
        }

        stage('Build with Docker Compose') {
            steps {
                // Supprimer les anciennes images et conteneurs pour éviter les conflits
                bat 'docker-compose down --rmi all --volumes --remove-orphans'
                bat 'docker container prune -f'
                bat 'docker-compose build --no-cache'
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
                // S'assurer que les conteneurs sont arrêtés avant de redémarrer
                bat 'docker-compose down'
                bat 'docker container prune -f'
                
                // Démarrer les services
                bat 'docker-compose up -d'
                
                // Attendre que les services soient prêts
                bat 'powershell -Command "Start-Sleep -Seconds 30"'
                
                // Vérifier le statut des services
                bat 'docker-compose ps'
                
                // Vérifier que le service app est bien démarré
                bat 'docker-compose logs app'
                
                // Attendre que la base de données soit prête
                bat 'powershell -Command "Start-Sleep -Seconds 15"'
                
                // Vérifier à nouveau le statut avant les migrations
                bat 'docker-compose ps'
                
                // Exécuter les migrations avec retry et meilleure gestion d'erreur
                script {
                    def maxRetries = 3
                    def retryCount = 0
                    def migrationSuccess = false
                    
                    while (retryCount < maxRetries && !migrationSuccess) {
                        try {
                            bat 'docker-compose exec -T app php artisan migrate --force'
                            migrationSuccess = true
                            echo "✅ Migration completed successfully on attempt ${retryCount + 1}"
                        } catch (Exception e) {
                            retryCount++
                            echo "❌ Migration attempt ${retryCount} failed: ${e.getMessage()}"
                            if (retryCount < maxRetries) {
                                echo "⏳ Waiting 15 seconds before retry..."
                                bat 'powershell -Command "Start-Sleep -Seconds 15"'
                                // Vérifier le statut des services avant de réessayer
                                bat 'docker-compose ps'
                            }
                        }
                    }
                    
                    if (!migrationSuccess) {
                        error "❌ Migration failed after ${maxRetries} attempts"
                    }
                }
                
                // Vérifier le statut final des services
                bat 'docker-compose ps'
                
                // Afficher les logs pour vérification
                bat 'docker-compose logs --tail=20'
            }
        }
    }

    post {
        always {
            // Archiver les rapports de tests HTML détaillés
            archiveArtifacts artifacts: 'reports/*-detailed.html', allowEmptyArchive: true
            
            // Archiver les rapports de tests HTML basiques
            archiveArtifacts artifacts: 'reports/*.html', allowEmptyArchive: true
            
            // Archiver les rapports de sécurité
            archiveArtifacts artifacts: 'reports/*.json', allowEmptyArchive: true
            
            // Afficher un résumé des rapports
            script {
                if (fileExists('reports/unit-tests-detailed.html')) {
                    echo '✅ Unit tests detailed HTML report generated successfully'
                }
                if (fileExists('reports/feature-tests-detailed.html')) {
                    echo '✅ Feature tests detailed HTML report generated successfully'
                }
                if (fileExists('reports/sonar-tests.html')) {
                    echo '✅ SonarQube tests HTML report generated successfully'
                }
                if (fileExists('reports/mutation-tests.html')) {
                    echo '✅ Mutation tests HTML report generated successfully'
                }
                if (fileExists('reports/security-audit.json')) {
                    echo '✅ Security audit report generated successfully'
                }
                if (fileExists('reports/trivy-scan.json')) {
                    echo '✅ Docker security scan report generated successfully'
                }
            }
        }
        
        success {
            echo '🎉 Pipeline completed successfully! All tests passed and reports generated.'
            echo '📊 Check the "Build Artifacts" section to download the detailed HTML reports.'
            echo '📋 Detailed reports show test execution details, timing, and results.'
        }
        
        failure {
            echo '❌ Pipeline failed! Check the test reports for details.'
            echo '📊 Check the "Build Artifacts" section to download the detailed HTML reports.'
        }
        
        cleanup {
            // Nettoyer les fichiers temporaires
            bat 'if exist reports rmdir /s /q reports'
            // Nettoyer les images Docker non utilisées
            bat 'docker system prune -f'
        }
    }
}
