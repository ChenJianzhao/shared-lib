
First of all,

`def branch = ${BRANCH_NAME}`

is not valid Groovy, or at least not doing what you think. Perhaps you meant

`def branch = "${BRANCH_NAME}"`

which would just be a silly way of writing

`def branch = BRANCH_NAME`

Anyway environment variables are not currently accessible directly as Groovy variables in Pipeline (there is a proposal to allow it); you need to use the env global variable:

`def branch = env.BRANCH_NAME`

From within an external process, such as a sh step, it is an actual environment variable, so

`sh 'echo $BRANCH_NAME'`

简而言之
- groovy 解析变量必须包含在双引号中 `"${BRANCH_NAME}"`
- 如果不用双引号定义变量，则可以使用 `env.BRANCH_NAME` 取到全局变量
- 如果使用 `sh` 等外部程序，可以直接使用 `$BRANCH_NAME`，因为其本身就是一个环境变量