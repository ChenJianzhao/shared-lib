/**
 * @author chenjz
 * 2018/8/16
 */

def call() {

//    agent { label '115' }

//    steps {

    if (packName.contains("jar")) {
        def deploy_docker = libraryResource 'deploy/deploy-docker.sh'
        writeFile file: "deploy-docker.sh", text: deploy_docker
        sh """
        chmod 755 ./deploy-docker.sh
        ./deploy-docker.sh
        #sleep 60
        """
    }else if (packName.contains("war")){
        sh "rm -rf *"
        echo "Deploy to Dev Environment"
        // 从包管理仓库 Artifactory 下载包
        echo "artifactsBasePath: ${artifactsBasePath}"
        // 指定 Jenkins 预配置的仓库名
        def repo = 'artifactory-server'
        def server = Artifactory.server repo
        def downloadSpec = """{
         "files": [
            {
              "pattern": "example-repo-local/${artifactsBasePath}${packName}",
              "target": "",
              "flat": "true"
            }
          ]
        }"""
        server.download(downloadSpec)
        def deploy_v3 = libraryResource 'deploy/deploy-v3.sh'
        writeFile file: "deploy-v3.sh", text: deploy_v3
        sh """
                        chown develop:develop ./deploy-v3.sh
                        chmod +x ./deploy-v3.sh
                        ./deploy-v3.sh 
        """
    }



}
