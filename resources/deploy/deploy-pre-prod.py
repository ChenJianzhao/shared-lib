import requests
import re
import sys
import json
my_headers = {
    'User-Agent' : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.116 Safari/537.36',
    'Accept' : 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Encoding' : 'gzip',
    'Accept-Language' : 'zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4'
}

# test data
# server = 'http://192.168.2.89:8091'
# app_name = 'product-service'
# oss_url = 'devops/app/product-service/2018-08-20_1500'

server = sys.argv[1]
app_name = sys.argv[2]
oss_url = sys.argv[3]

print('server:' + server)
print('app_name:' + app_name)
print('oss_url:' + oss_url)


s = requests.Session()

# get login page token
login_page_url = server + "/login/"
login_page_response = s.get(login_page_url, headers = my_headers)
pattern_csrf = re.compile(r"name='csrfmiddlewaretoken' value='(.*?)' />", re.S)
csrf = re.findall(pattern_csrf, login_page_response.content.decode('utf-8'))
token = csrf[0]
print(token)

# login
login_data = {"username": "root",
              "password": "Dinghuo0815",
              "csrfmiddlewaretoken": token,
              "renew": 'False',
              "warn": 'on'}

login_response = s.post(server + "/login/", headers = my_headers, data = login_data)


# get env list
env_url = server + "/deploy/env"
env_response = s.get(env_url)
# print(env_response.content.decode('utf-8'))
env_json = json.loads(env_response.content)
print(env_json['env'])

# get ip list
ip_data = {
    "env":'prod',
    "appName":app_name,
    "csrfmiddlewaretoken": token,
}
ip_response =s.post(server + "/deploy/ip",  data=ip_data)
# print(get_ip.content.decode('utf-8'))
ip_json = json.loads(ip_response.content)
print(ip_json['ip'])

# deploy PreProd
pre_deploy_data = {
    "down_url": oss_url,
    "env":'prod',
    "ip": ip_json['ip'][0],
    "appName": app_name,
}
pre_deploy_url = server + "/deploy/preDeploy"
pre_deploy_response = s.post(pre_deploy_url,  data=pre_deploy_data)
print(pre_deploy_response)

# get deploy state
# deploy_status = {
# 	"ip":"10.25.87.35",
# 	"appName": 'ORDER-SERVICE'
# }
# # deploy_status_api = s.post("http://127.0.0.1:8091/deploy/deployStatus?ip='10.25.87.35'&appName='ORDER-SERVICE'",  )
# deploy_status_url = server + '/deploy/deployStatus'
# deploy_status_response = s.post(deploy_status_url, data=deploy_status)
# print(deploy_status_response.content)
