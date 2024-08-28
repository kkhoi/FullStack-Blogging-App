pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }
    environment {
        SCANNER_HOME = tool 'sonarscanner'
    }
    stages {
        stage('Git checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/kkhoi/FullStack-Blogging-App.git'
            }
        }
        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }
        stage('Sonar Ana') {
            steps {
                withSonarQubeEnv('sonarserver') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=Blogging-app -Dsonar.projectName=Blogging-app \
                    -Dsonar.java.binaries=target '''
                }
            }
        }
        stage('Build') {
            steps {
                sh 'mvn package'
            }
        }
        stage('Publish Artifact') {
            steps {
                withMaven(globalMavenSettingsConfig: 'maven-setting', jdk: 'jdk17', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh 'mvn deploy'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker') {
                    sh 'docker build -t khoi2010/bloggingapp:latest .'
                    }                
                }
            }
            
        }
        stage('Push Docker Image') {
            steps {
                script {
                withDockerRegistry(credentialsId: 'dockerhub-cred', toolName: 'docker') {
                    sh 'docker push khoi2010/bloggingapp:latest'
                    }                
                }
            }
            
        }
        stage('Deploy To Kubernetes') {
            steps {
                withKubeCredentials(kubectlCredentials: [[caCertificate: '', clusterName: 'bloggingapp', contextName: '', credentialsId: 'kube-cred', namespace: 'webapps', serverUrl: 'https://72AC27E8BFC7AC351AAFE1B1B4AB7C8A.yl4.ap-southeast-1.eks.amazonaws.com']]) {
                    sh "kubectl apply -f deployment-service.yml"
                    sleep 20
                }
            }
        }
        stage('Verify Deployment') {
            steps {
                withKubeCredentials(kubectlCredentials: [[caCertificate: '', clusterName: 'bloggingapp', contextName: '', credentialsId: 'kube-cred', namespace: 'webapps', serverUrl: 'https://72AC27E8BFC7AC351AAFE1B1B4AB7C8A.yl4.ap-southeast-1.eks.amazonaws.com']]) {
                    sh "kubectl get svc -n webapps"
                }
            }
        }
    }
}
