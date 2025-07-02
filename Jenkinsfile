// Jenkinsfile
pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'us-east-2'
    // Usa credenciales almacenadas en Jenkins (tipo "Secret text" o "Username with password")
    AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
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
      steps {
        dir('terraform') {
          sh 'terraform plan -var-file="secret.tfvars"'
        }
      }
    }

    stage('Terraform Apply') {
      when {
        branch 'main'
      }
      steps {
        dir('terraform') {
          sh 'terraform apply -auto-approve -var-file="secret.tfvars"'
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

// Jenkinsfile (con opción para destruir)
pipeline {
  agent any

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Destruir infraestructura')
  }

  environment {
    AWS_DEFAULT_REGION = 'us-east-2'
    AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        dir('terraform') {
          sh 'terraform init'
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
}

