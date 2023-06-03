#!/bin/bash


#读取token
jtoken="Opentoken.json"
tok="token.txt"
token=$(cat ${tok})
#设置默认Headers参数
Header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.54 Safari/537.36"
Rererer=https://www.aliyundrive.com/
#刷新token并获取drive_id、access_token
response=$(curl https://auth.aliyundrive.com/v2/account/token -X POST -H "User-Agent:$Header" -H "Content-Type:application/json" -H "Rererer:$Rererer" -d '{"refresh_token":"'$token'", "grant_type": "refresh_token"}')
drive_id=$(echo "$response" | sed -n 's/.*"default_drive_id":"\([^"]*\).*/\1/p')
new_token=$(echo "$response" | sed -n 's/.*"refresh_token":"\([^"]*\).*/\1/p')
access_token=$(echo "$response" | sed -n 's/.*"access_token":"\([^"]*\).*/\1/p')
if [ -z "$new_token" ]; then
	echo "刷新Token失败"
	exit 1
fi
echo ${new_token} | tr -d '\n' > ${tok}
#签到
response=$(curl "https://member.aliyundrive.com/v1/activity/sign_in_list" -X POST -H "User-Agent:$Header" -H "Content-Type:application/json" -H "Authorization:Bearer $access_token" -d '{"grant_type":"refresh_token", "refresh_token":"'$new_token'"}')
success=$(echo $response | cut -f1 -d, | cut -f2 -d:)
if [ $success = "true" ]; then
	echo "阿里签到成功"
fi
#获取opentoken
response=$(curl "https://open.aliyundrive.com/oauth/users/authorize?client_id=76917ccccd4441c39457a04f6084fb2f&redirect_uri=https://alist.nn.ci/tool/aliyundrive/callback&scope=user:base,file:all:read,file:all:write&state=" -X POST -H "User-Agent:$Header" -H "Content-Type:application/json" -H "Rererer:$Rererer" -H "Authorization:Bearer $access_token" -d '{"authorize":"1", "scope": "user:base,file:all:read,file:all:write"}')
code=$(echo $response | sed -n 's/.*code=\([^"]*\).*/\1/p')
response=$(curl "https://api.nn.ci/alist/ali_open/code" -X POST -H "User-Agent:$Header" -H "Content-Type:application/json" -H "Rererer:$Rererer" -H "Authorization:Bearer $access_token" -d '{"code":"'$code'", "grant_type":"authorization_code"}')
opentoken=$(echo $response | sed -n 's/.*"refresh_token":"\([^"]*\).*/\1/p')
openactoken=$(echo $response | sed -n 's/.*"access_token":"\([^"]*\).*/\1/p')


JSON_STRING="{
         \"driveid\":\"${drive_id}\",
         \"refreshtoken\":\"${new_token}\",
         \"refreshTokenOpen\":\"${opentoken}\",
         \"refreshacTokenOpen\":\"Bearer ${openactoken}\"
         }"
         echo ${JSON_STRING} | jq > ${jtoken}
