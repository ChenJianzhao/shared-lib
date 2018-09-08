/**
 * @author chenjz
 * 2018/8/17
 */

def call() {

    def uploadScript = libraryResource 'deploy/upload_file.py'
    writeFile file: 'upload_file.py', text: uploadScript

    // 获取当前 “年月日时分”，只到分是否有可能会重复？
    def dateStr = new Date().format( 'yyyy-MM-dd_HHmm' )
    def basePath = "devops/app/${APP_NAME}/${dateStr}"
    echo "basePath: ${basePath}"
    echo "ARTIFACTS_BASE_PATH: ${ARTIFACTS_BASE_PATH}"

    // sh 'python -m pip install oss2'

    // 上传 artifact
    def key = "${ARTIFACTS_BASE_PATH}${JAR_NAME}"
    echo "upload artifact: ${JAR_NAME} to ${ARTIFACTS_BASE_PATH}"
    sh "python upload_file.py ${key} artifact/${JAR_NAME}"

    // 上传 nginx 配置
    def pathArray = params.nginxConfigLocation.split('/')
    def nginxFileName = pathArray[pathArray.length-1]
    key = "${ARTIFACTS_BASE_PATH}${nginxFileName}"

    echo "upload nginx config file: ${nginxFileName} to ${ARTIFACTS_BASE_PATH}"
    sh "python upload_file.py ${key} artifact/nginx/${nginxFileName}"

    // 部署预发布
//    def server_host = 'http://192.168.1.245:8091'
//    def deployPreProdScript = libraryResource 'deploy/deploy-pre-prod.py'
//    writeFile file: 'deploy-pre-prod.py', text: deployPreProdScript
//    sh "python deploy-pre-prod.py ${server_host} ${APP_NAME} ${ARTIFACTS_BASE_PATH}"
}
   