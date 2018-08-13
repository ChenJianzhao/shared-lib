def call() {

//    node {

        // 非开发分支跳过单元测试
        if( env.BRANCH_NAME != 'feature/jenkins-cd') {
            mvnBasicArgs = "$mvnBasicArgs" + " -Dmaven.test.skip=true"
        }

        // 打印最终构建参数
        echo "mvnBasicArgs : $mvnBasicArgs"

        // 构建打包
        sh "mvn $mvnBasicArgs package"

        // 开发分支手机执行报告
        if( env.BRANCH_NAME == 'feature/jenkins-cd') {
            junit 'target/**/*.xml' // 需要遵循 “/**/*.xml” 的格式，否则会报错
        }
//    }
}