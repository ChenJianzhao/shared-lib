/**
 * @author chenjz
 * 2018/8/16
 */

def call() {
    // git 是 checkout 的一种缩略形式，似乎不能定义检出到子目录
    // 但 options 似乎有一个选项可以设置子目录，未验证
    // git branch: 'master', credentialsId: 'jenkins-username-password-for-github', url: 'https://github.com/ChenJianzhao/gocd-demo.git'
    checkout([$class: 'GitSCM',
              branches: [[name: '*/jwt']],
              doGenerateSubmoduleConfigurations: false,
              extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'nginx']],
              submoduleCfg: [],
              userRemoteConfigs: [[credentialsId: 'gitlab Credentials',
                                   url: 'http://root@gitlab.dinghuo123.com/Test/nginx.git']]])
    sh 'pwd'
    sh 'ls -lat'
    echo "nginxConfigLocation: ${params.nginxConfigLocation}"
    sh "mkdir ${WORKSPACE}/artifact/nginx && cp nginx/${params.nginxConfigLocation} ${WORKSPACE}/artifact/nginx/"

    // 归档
    archiveArtifacts artifacts: "artifact/nginx/*.conf", fingerprint: true

}