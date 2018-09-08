
### 脚本片段生成助手

[Snippet Generator](http://192.168.1.200:8080/job/product-service/job/feature%252Fjenkins-cd/pipeline-syntax/)

### 变量的使用

- groovy 解析全局变量必须包含在双引号中
 
    `def branch = "${BRANCH_NAME}"`
    
- 如果不用双引号，则可以使用 `env.BRANCH_NAME` 取到全局变量

    `def branch = env.BRANCH_NAME`


- 如果使用 `sh` 等外部程序，可以直接使用 `$BRANCH_NAME`，因为其本身就是一个环境变量

    `sh 'echo $BRANCH_NAME'`
    
- 使用构建参数

    `def libVersion = "${params.LIB_VERSION}"`