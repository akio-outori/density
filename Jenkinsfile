pipeline {

    agent any

    stages {

        stage('Build') {
            steps {
                echo 'Building..'
                sh 'make build'
            }
        }

        stage('Deploy Local') {
            steps {
                echo 'Testing..'
            }
        }

        stage('Deploy Dev') {
            steps {
                echo 'Deploying....'
            }
        }

        stage('Deploy Prod') {
            steps {
                echo 'Deploying...'
            }
        }

    }
}
