// Jenkinsfile
pipeline {
  agent any

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Destruir infraestructura')
  }

  environment {
    AWS_DEFAULT_REGION = 'us-east-2'
    AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Crear secret.tfvars') {
      steps {
        dir('terraform') {
          writeFile file: 'secret.tfvars', text: '''
db_username = "dbadmin123"
db_password = "dbadmin123"
'''
        }
      }
    }

    stage('Terraform Init') {
      steps {
        dir('terraform') {
          sh 'terraform init'
        }
      }
    }

    stage('Terraform Plan') {
      when {
        expression { !params.DESTROY }
      }
      steps {
        dir('terraform') {
          sh 'terraform plan -var-file="secret.tfvars"'
        }
      }
    }

    stage('Terraform Action') {
      steps {
        dir('terraform') {
          script {
            if (params.DESTROY) {
              sh 'terraform destroy -auto-approve -var-file="secret.tfvars"'
            } else {
              sh 'terraform apply -auto-approve -var-file="secret.tfvars"'
            }
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'terraform/*.tfstate', allowEmptyArchive: true
    }
  }
}