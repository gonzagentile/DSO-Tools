// This pipeline revolves around building a Docker image:
// - Lint: Lints a Dockerfile using hadolint
// - Trivy Scan: Scan Docker image Vulnerabilities
// - Build and test: Builds and tests a Docker image
// - Push: Pushes the image to the registry

pipeline {
    agent any

    environment { // Environment variables defined for all steps
        DOCKER_IMAGE = "dso-tools"
        GITHUB_TOKEN = credentials("github_token")
        TOOLS_IMAGE = "ghcr.io/pablorechimon/dso-tools:${BRANCH_NAME}"
        TRIVY_IMAGE = "aquasec/trivy:latest"
    }

    stages {
        stage("Lint") {
            agent {
                docker {
                    image "docker.io/hadolint/hadolint:latest-debian"
                    reuseNode true
                }
            }
            steps {
                script {
                    def result = sh label: "Lint Dockerfile",
                        script: """\
                            hadolint Dockerfile > hadolint-results.txt
                        """,
                    returnStatus: true
                    if (result > 0) {
                        unstable(message: "Linting issues found")
                    }
                }
            }
        }

        stage("Build and test image") {
            steps {
                script {
                    // Use commit tag if it has been tagged
                    tag = sh(returnStdout: true, script: "git tag --contains").trim()
                    if ("$tag" == "") {
                        if ("${BRANCH_NAME}" == "main") {
                            tag = "latest"
                        } else {
                            tag = "${BRANCH_NAME}"
                        }
                    }
                    def image = docker.build("$DOCKER_IMAGE", "--build-arg 'BUILDKIT_INLINE_CACHE=1' --cache-from $DOCKER_IMAGE:$tag --cache-from $DOCKER_IMAGE:latest .")
                    // Make sure that the user ID exists within the container
                    image.inside("--volume /etc/passwd:/etc/passwd:ro") {
                        sh label: "Test anchore-cli",
                            script: "anchore-cli --version"
                        sh label: "Test curl",
                            script: "curl --version"
                        sh label: "Test cyclonedx",
                            script: "cyclonedx-py --help"
                        sh label: "Test detect-secrets",
                            script: "detect-secrets --version"
                        sh label: "Test sonar-scanner",
                            script: "sonar-scanner --version"
                        sh label: "Test trufflehog",
                            script: "trufflehog --help"
                        sh label: "Test trivy",
                            script: "trivy --help"
                    }
                }
            }
        }

        stage("trivy scan") {
            agent {
                docker {
                    image "${TOOLS_IMAGE}"
                    // Make sure that username can be mapped correctly
                    args "--user devsecops -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/"
                    reuseNode true
                }
            }
            steps {
                // Determine commit of previous successful build when this is master
                script {
                    def result = sh label: "Trivy scan",
                        script: """\
                            trivy --help
                        """,
                        returnStatus: true
                        //image ghcr.io/pablorechimon/dso-tools:03-scanning-image-trivy --output trivy_report.html
                    // Exit code 1 is generated when secrets are detected or no baseline is present
                    // Exit code 3 is generated only when .secrets.baseline.json is updated,
                    // eg. when the line numbers don't match anymore
                    if (result == 1) {
                        // There are (unaudited) secrets detected: fail stage
                        unstable(message: "unaudited image")
                    }
                }
            }
        }
        

        stage("Push to registry"){
            steps {
                script {
                    // Use commit tag if it has been tagged
                    tag = sh(returnStdout: true, script: "git tag --contains").trim()
                    if("$tag" == ""){
                        if ("${BRANCH_NAME}" == "main"){
                            tag = "latest"
                        } else {
                            tag = "${BRANCH_NAME}"
                        }
                    }
                    // Login to GHCR
                    sh "echo $GITHUB_TOKEN_PSW | docker login ghcr.io -u $GITHUB_TOKEN_USR --password-stdin"
                    sh "docker tag  $DOCKER_IMAGE:$tag ghcr.io/$GITHUB_TOKEN_USR/$DOCKER_IMAGE:$tag"
                    // By specifying only the image name, all tags will automatically be pushed
                    sh "docker push ghcr.io/$GITHUB_TOKEN_USR/$DOCKER_IMAGE:$tag"
                }
            }
        }
    }
    // This is for save files created during the pipeline at the end.
    post {
        always {
            archiveArtifacts artifacts: "*-results.txt, *-report.html"
            publishHTML ([
            allowMissing: true,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: '.',
            reportFiles: 'trivy_report.html',
            reportName: 'Trivy Scan',
                ])
        }
    }
}
