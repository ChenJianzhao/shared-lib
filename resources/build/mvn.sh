#!/bin/bash

# 必读：注意ydh-build-script分master分支和remote分支，两者是有区别的
# master分支用于内网jenkins构建
# remote分支用于外网jenkins构建
# 修改master分支后，请找对应的负责人修改remote分支
# 不要随意追加内容到该脚本中，可能会影响构建结果的判断

echo "branch: $branch"
echo "skipUnitTest： $skipUnitTest"

# set mvn 参数
mvn_basic_flag="-e -B -f pom.xml -Dmaven.javadoc.skip=true"

## 后续直接在系统中配置？还是直接就没有这一步？
maven_target_branch=`curl -s http://192.168.1.181:5000/ci/maven/target_branch/?branch=$branch`

## if [ "$maven_target_branch" != "develop" ];then
#if [ "$maven_target_branch" != "feature/jenkins-cd" ];then
#    mvn_basic_flag="$mvn_basic_flag -Dmaven.test.skip=true"
if [ "$skipUnitTest" == true ];then
    mvn_basic_flag="$mvn_basic_flag -Dmaven.test.skip=true"
fi

if [[ "$maven_target_branch" != "404" ]];then
    mvn_flag="$mvn_basic_flag -U -Dtarget_branch=$maven_target_branch"
else
    mvn_flag=$mvn_basic_flag
fi
echo "mvn_flag: $mvn_flag"

# 切换到对应的jenkins工作目录下
cd $WORKSPACE
echo "workspace: `pwd`"
echo "jgitflowFlag: $jgitflowFlag"

if [ "$jgitflowFlag" = "none" ];then
    # 不带jgitflowFlag时，直接构建
    ## mvn $mvn_flag clean install deploy
    mvn $mvn_flag clean package

    mvn_result=$?
    ## build_info=`curl -s -d "app=$JOB_BASE_NAME&branch=$branch&status=$mvn_result&type=mvn&job=$BUILD_URL&env=inner" http://192.168.1.181:5000/ci/build/info/`
    echo $build_info
    exit $mvn_result
else
    # 否则更新工作目录下所有本地分支
    git fetch -p
    git update-ref -d refs/notes/commits
    for branch in `git branch -r |awk '{print substr($0,10)}' |grep -v HEAD`
    do
        echo '********************update local branch '$branch
        git checkout $branch
        git branch -a |grep '*'
        git pull --all -p
    done
    git checkout develop
    echo "mvn $mvn_flag $jgitflowFlag"
    mvn $mvn_flag $jgitflowFlag
    mvn_result=$?
    build_info=`curl -s -d "app=$JOB_BASE_NAME&branch=$branch&status=$mvn_result&type=mvn&job=$BUILD_URL&env=inner" http://192.168.1.181:5000/ci/build/info/`
    echo $build_info
    exit $mvn_result
fi
