#!/usr/bin/python
# -*- coding:utf-8 -*-
from __future__ import print_function

import sys
import oss2

# TODO 最后要把秘钥抽到 jenkins 管理
# 秘钥 key
AccessKeyID = 'PZCAh8QJC2mlM967'
AccessKeySecret = 'ZXGi7Ll1twitnxkiRR1aGhdTHBi3LR'
endpoint = 'oss-cn-hangzhou.aliyuncs.com'
bucketName = 'ydh'

auth = oss2.Auth(AccessKeyID, AccessKeySecret)
bucket = oss2.Bucket(auth, endpoint, bucketName)

# 外部传参 文件名  例如 python upload_file.py $argv
key = sys.argv[1]
filename = sys.argv[2]
print(key)

# 进度条
def percentage(consumed_bytes, total_bytes):
    if total_bytes:
        rate = int(100 * (float(consumed_bytes) / float(total_bytes)))
        print('\r{0}% '.format(rate), end='')
        sys.stdout.flush()

# 上传方法 （桶， 上传到用户空间的文件名 待上传本地文件名）
oss2.resumable_upload(bucket, key, filename,
    store=oss2.ResumableStore(root='/tmp'),
    multipart_threshold=100*1024,
    part_size=100*1024,
    num_threads=4,
	progress_callback=percentage)

bucket.put_object_acl(key,oss2.OBJECT_ACL_PRIVATE)

# Upload
# bucket.put_object(key, 'Ali Baba is a happy youth.')