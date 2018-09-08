/*
  "jgitflowFlag":"none",
  "appName":"product-service",
  "branch":"feature/jenkins-cd",
  "packName":"product-service-feature-jenkins-cd.jar",
  "artifactsBasePath":"devops/app/product-service/feature-jenkins-cd/1001/",
  "buildNumber":"1001"
*/

def call() {
    sh "rm -rf ./*"
    echo "artifactsBasePath: ${artifactsBasePath}"
    // 指定 Jenkins 预配置的仓库名
    def repo = 'artifactory-server'
    def server = Artifactory.server repo
    def downloadSpec = """{
         "files": [
            {
              "pattern": "example-repo-local/${artifactsBasePath}${packName}",
              "target": "./",
              "flat": "true"
            }
          ]
        }"""
    server.download(downloadSpec)
    // 执行打包脚本
    def Dockerfile = libraryResource 'build/Dockerfile'
    writeFile file: 'Dockerfile', text: Dockerfile
    def docker_inner_run = libraryResource 'build/docker_inner_run.sh'
    writeFile file: 'run.sh', text: docker_inner_run
    def packdockercript = libraryResource 'pack/build-docker-image.sh'
    sh packdockercript
    //build-docker-images.sh包含
    //cp $basepath/Dockerfile $WORKSPACE
    //cp $basepath/docker_inner_run.sh $WORKSPACE/run.sh
    //toDO 获取resources的绝对路径替换$basepath


    //Artifactory docker仓库需要付费版
//    // Step 1: Obtain an Artifactiry instance, configured in Manage Jenkins --> Configure System:
//    def server = Artifactory.server '<ArtifactoryServerID>'
//
//    // Step 2: Create an Artifactory Docker instance:
//    def rtDocker = Artifactory.docker server: server
//    // Or if the docker daemon is configured to use a TCP connection:
//    // def rtDocker = Artifactory.docker server: server, host: "tcp://<docker daemon host>:<docker daemon port>"
//    // If your agent is running on OSX:
//    // def rtDocker= Artifactory.docker server: server, host: "tcp://127.0.0.1:1234"
//
//    // Step 3: Push the image to Artifactory.
//    // Make sure that <artifactoryDockerRegistry> is configured to reference <targetRepo> Artifactory repository. In case it references a different repository, your build will fail with "Could not find manifest.json in Artifactory..." following the push.
//    def buildInfo = rtDocker.push '<artifactoryDockerRegistry>/hello-world:latest', '<targetRepo>'
//
//    // Step 4: Publish the build-info to Artifactory:
//    server.publishBuildInfo buildInfo

}