pipeline {
    agent any
    
    parameters {
        choice(
            name: 'OS',
            choices: ['linux', 'darwin', 'windows'],
            description: 'Target operating system'
        )
        choice(
            name: 'ARCH',
            choices: ['amd64', 'arm64'],
            description: 'Target architecture'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip running tests'
        )
        booleanParam(
            name: 'SKIP_LINT',
            defaultValue: false,
            description: 'Skip running linter'
        )
    }
    
    environment {
        GITHUB_TOKEN=credentials('sakharuk')
        REPO = 'https://github.com/sakharuk/kbot.git'
        BRANCH = 'main'
    }

    stages {

        stage('clone') {
            steps {
                echo 'Clone Repository'
                git branch: "${BRANCH}", url: "${REPO}"
            }
        }
        
        stage('lint') {
            when { !SKIP_LINT }
            steps {
                echo 'Testing started'
                sh 'make lint'
            }
        }

        stage('test') {
            when { !SKIP_TEST }
            steps {
                echo 'Testing started'
                sh 'make test'
            }
        }

        stage('build') {
            steps {
                script{
                    def target = (params.ARCH == 'amd64') ? params.OS : "${params.OS}-arm"
                    echo "Building binary for platform ${params.OS} on ${params.ARCH} started"
                    sh "make ${target}"
                }
            }
        }

        stage('image') {
            steps {
                echo 'Building image for platform ${params.OS} on ${params.ARCH} started'
                sh 'make image'
            }
        }
        
        stage('login to GHCR') {
            steps {
                sh 'echo $GITHUB_TOKEN_PSW | docker login ghcr.io -u $GITHUB_TOKEN_USR --password-stdin'
            }
        }

        stage('push image') {
            steps {
                sh 'make push'
            }
        } 
    }
    
}