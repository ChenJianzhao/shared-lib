/*
   需要的参数
  "gitUrl":"http://chengxd@gitlab.dinghuo123.com/Test/product.git",
  "credentialsId":"62cbdecc-93cc-4b25-a1a9-ffcb2bda5a09",
  "jgitflowFlag":"none",
  "skipUnitTest":true,
  "appName":"product-service",
  "branch":"feature/jenkins-cd",
  "packName":"product-service-feature-jenkins-cd.jar",
  "artifactsBasePath":"devops/app/product-service/feature-jenkins-cd/1000/"
*/

def call() {
    checkout([
            $class: 'GitSCM', branches: [[name: "*/${env.branch}"]],
            extensions: [[$class: 'CleanBeforeCheckout']],
            userRemoteConfigs: [[url: "${env.gitUrl}",credentialsId:"${env.credentialsId}"]]
    ])
    def buildScript = libraryResource 'build/mvn.sh'
    writeFile file: 'mvn.sh', text: buildScript

    sh """
            chmod +x mvn.sh
            ./mvn.sh
        """

    // 开发分支手机执行报告
    if( ! skipUnitTest ) {
        junit 'target/surefire-reports/*.xml' // 需要遵循 “/**/*.xml” 的格式，否则会报错
    }

    if (packName.contains("war")){
        def packcript = libraryResource 'pack/pack.sh'
        sh packcript
        archiveArtifacts artifacts: 'artifact/*.war', fingerprint: true

    }else if (packName.contains("jar")){
        def packcript = libraryResource 'pack/pack-service.sh'
        sh packcript
        archiveArtifacts artifacts: 'artifact/*.jar', fingerprint: true
    }

    echo "artifactsBasePath: ${artifactsBasePath}"
    // 指定 Jenkins 预配置的仓库名
    def repo = 'artifactory-server'
    def server = Artifactory.server repo
    def uploadSpec = """{
         "files": [
            {
              "pattern": "artifact/*",
              "target": "example-repo-local/${artifactsBasePath}"
            }
          ]
        }"""
    server.upload(uploadSpec)

    def buildInfo = Artifactory.newBuildInfo()
//    server.download spec: downloadSpec, buildInfo: buildInfo
    server.upload spec: uploadSpec, buildInfo: buildInfo
    server.publishBuildInfo buildInfo
}