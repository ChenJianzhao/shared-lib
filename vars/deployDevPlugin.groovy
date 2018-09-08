/**
 * @author chenjz
 * 2018/8/16
 */

def call() {

//    agent { label '115' }

//    steps {
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
        if (packName.contains("jar")) {
                def deploy_script = libraryResource 'deploy/deploy-service-devops.sh'
                writeFile file: 'deploy-service-devops.sh', text: deploy_script

                timeout(time: 300, unit: 'SECONDS') {
                        sh '''
                            export tagOr=local,devops
                            echo "tagOr: $tagOr"
                            chown develop:develop ./deploy-service-devops.sh
                            chmod +x ./deploy-service-devops.sh
                            ./deploy-service-devops.sh
                        '''
                }
        }else if (packName.contains("war")){
                def deploy_script = libraryResource 'deploy/deploy.sh'
                writeFile file: 'deploy.sh', text: deploy_script

                sh '''
            chown develop:develop ./deploy.sh
            chmod +x ./deploy.sh
            ./deploy.sh
        '''
        }



}
   