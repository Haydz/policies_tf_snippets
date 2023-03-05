// PIPELINES EXAMPLE OF BUILDING A DOCKER IMAGE
// SCANNING WITH SNYK AND SENDING A SLACK NOTIFICATION
pipeline {
    agent any
    //  environment {
    //     //   SYNK_API_TOKEN = credentials('SYNK_API_TOKEN')
    // }
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t hello-world .'
            }
        }
        stage('Snyk Scan') {
            steps {
                withCredentials([string(credentialsId: 'SNYK_API_TOKEN', variable: 'SNYK_API_TOKEN')]) {
//                    sh "snyk auth ${env.SNYK_API_TOKEN}"
                    sh "snyk test --file=Dockerfile --json > snyk-report.json || true"
                }
            }
        }
    }
    post {
        always {
            // emailext ( 
            //     to: 'email',
            //     subject: "Snyk Scan Results for ${env.JOB_NAME} build ${env.BUILD_NUMBER}",
            //     body: """<p>Snyk scan results for ${env.JOB_NAME} build ${env.BUILD_NUMBER}:</p>
            //              <pre>${readFile('snyk-report.json')}</pre>""",
            //     mimeType: 'text/html'
            // )
            slackSend (
                color: "#36a64f",
                message: "Snyk scan results for ${env.JOB_NAME} build ${env.BUILD_NUMBER}:\n```${readFile('snyk-report.json')}```"
      
               
            )
            //  slackSend color: "good", message: "Message from Jenkins Pipeline"
        }
    }
}
