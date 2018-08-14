/**
 * @author chenjz
 * 2018/8/13
 */

def call() {

    pipeline {
        agent any

        tools {
            maven 'Maven 3.5.3' // 需要现在全局配置中设置，可以选取已安装的，也可以配置自动安装
        }
        // properties or parameters? try one!
        parameters {
            string defaultValue: 'master', description: 'shared library 分支', name: 'LIB_VERSION', trim: true
            string defaultValue: 'openresty/nginx/conf/vhosts/corp_product.conf', description: 'nginxConfigLocation', name: 'nginxConfigLocation', trim: false
            choice choices: ['none', 'jgitflow:release-start', 'jgitflow:release-finish'], description: '', name: 'jgitflowFlag'
        }
//        options {
//            skipDefaultCheckout true
//        }
        stages {
            stage('Check Environment') {
                steps {
                    sh 'echo "$MAVEN_HOME"'
                    sh 'echo "$PATH"'
                    sh "mvn -version"
                }
            }
            stage('Build Project') {
                environment {
                    mvnBasicArgs = "-e -B -f pom.xml -Dmaven.javadoc.skip=true"
                }
                steps {

//                    library identifier: 'shared-lib@master', retriever: modernSCM(
//                            [$class: 'GitSCMSource',
//                             credentialsId: 'username-password-for-github',
//                             id: 'c67f6abb-dca9-467c-92ef-b6fa4a745110',
//                             remote: 'https://github.com/ChenJianzhao/shared-library.git',
//                             traits: [[$class: 'jenkins.plugins.git.traits.BranchDiscoveryTrait']]])

                    // 调用 shared lib
                    buildPlugin()

                }
                post {
                    always {
                        archiveArtifacts artifacts: 'target/**/*.war', fingerprint: true
                        // junit 'target/**/*.xml' // 需要遵循 “/**/*.xml” 的格式，否则会报错
                    }
                }
            }
            stage('Collect Config'){
                steps {
                    // git 是 checkout 的一种缩略形式，似乎不能定义检出到子目录
                    // 但 options 似乎有一个选项可以设置子目录，未验证
                    // git branch: 'master', credentialsId: 'jenkins-username-password-for-github', url: 'https://github.com/ChenJianzhao/gocd-demo.git'
                    checkout([$class: 'GitSCM',
                              branches: [[name: '*/jwt']],
                              doGenerateSubmoduleConfigurations: false,
                              extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'nginx']],
                              submoduleCfg: [],
                              userRemoteConfigs: [[credentialsId: 'username-password-for-gitlab',
                                                   url: 'http://chenjz@gitlab.dinghuo123.com/Test/nginx.git']]])
                    sh 'pwd'
                    sh 'ls -lat'
                    echo "nginxConfigLocation: ${params.nginxConfigLocation}"
                }
                post {
                    always {
                        archiveArtifacts artifacts: "nginx/${params.nginxConfigLocation}", fingerprint: true
                    }
                }
            }
            stage('Deploy Dev'){
                steps {
                    echo "Deploy to Dev Environment"
                }
            }
            stage('Smoke Test'){
                input {
                    message "Should we continue?"
                    ok "Yes, we should."
                    parameters {
                        string(name: 'PERSON', defaultValue: 'admin', description: 'Who should I say hello to?')
                    }
                    submitter "admin"
                }
                steps {
                    echo "Hello, ${PERSON}, Smoke Test Pass."
                }
            }
            stage('Deploy Test') {
                steps {
                    echo "Deploy to Test Environment"
//                sshPublisher(
//                    publishers: [
//                        sshPublisherDesc(
//                            configName: 'aliyun',
//                            transfers: [
//                                sshTransfer(excludes: '',
//                                    execCommand: '''if [ -f "/home/admin/devops-demo/deploy.sh" ]; then /home/admin/devops-demo/deploy.sh stop; fi
//                                    /home/admin/devops-demo/deploy.sh start''',
//                                execTimeout: 120000,
//                                flatten: false,
//                                makeEmptyDirs: false,
//                                noDefaultExcludes: false,
//                                patternSeparator: '[, ]+',
//                                remoteDirectory: 'home/admin/devops-demo',
//                                remoteDirectorySDF: false,
//                                removePrefix: 'target',
//                                sourceFiles: '**/*.war')
//                            ],
//                            usePromotionTimestamp: false,
//                            useWorkspaceInPromotion: false,
//                            verbose: false
//                        )
//                    ]
//                )
                }
            }
            stage('Auto Test'){
                steps {
                    echo "Auto Test"
                }
            }
            stage('Manual Test') {
                input {
                    message "Should we continue?"
                    ok "Yes, we should."
                    parameters {
                        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
                    }
                }
                steps {
                    echo "Hello, ${PERSON}, Manual Test Pass."
                }
            }
            stage('Deploy to Stage'){
                steps {
                    echo "Deploy to Prod"
                }
            }
            stage('Staging Test') {
                input {
                    message "Should we continue?"
                    ok "Yes, we should."
                    parameters {
                        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
                    }
                }
                steps {
                    echo "Hello, ${PERSON}, Staging Test Pass."
                }
            }
            stage('Deploy to Prod'){
                steps {
                    echo "Deploy to Prod"
                }
            }
        }
    }
}