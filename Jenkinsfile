pipeline {
    agent any

    environment {
        SONARQUBE_SERVER = 'ayoub' // Nom configuré dans Jenkins
        DOCKER_IMAGE = "laravel-app:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Composer Install') {
            steps {
                bat 'composer install'
            }
        }

        stage('Trivy Scan') {
            steps {
                bat 'docker build -t %DOCKER_IMAGE% .'
                bat 'docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image %DOCKER_IMAGE%'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    bat 'vendor\\bin\\phpunit --coverage-clover=coverage.xml'
                    bat '''
                    sonar-scanner ^
                      -Dsonar.projectKey=laravel-app ^
                      -Dsonar.php.coverage.reportPaths=coverage.xml ^
                      -Dsonar.sources=app ^
                      -Dsonar.tests=tests ^
                      -Dsonar.host.url=%SONAR_HOST_URL% ^
                      -Dsonar.login=%SONAR_AUTH_TOKEN%'
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                bat 'vendor\\bin\\phpunit'
            }
        }

        stage('Mutation Tests') {
            steps {
                bat 'vendor\\bin\\infection --threads=2 --min-msi=80 --min-covered-msi=80'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t %DOCKER_IMAGE% .'
            }
        }

        stage('Deploy') {
            steps {
                bat 'docker run -d --rm -p 9000:9000 %DOCKER_IMAGE%'
            }
        }
    }
}
