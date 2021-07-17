#!/bin/sh

gitlab_url="http://xxxxxx" # 末尾の/は不要
gitlab_user="root"
gitlab_password="pass"

cookie_file_name="/tmp/gitlab_logon_cookie"
timestamp=$(date "+%s")

# check urls list
check_urls=("/")
check_urls+=("/admin")
check_urls+=("/admin/projects")

function check_status_code () {
  if [ $1 != "200" ] ; then
    echo "  ==> NG!!! : status code is not 200 = [$1]"
    exit 0
  fi
  echo "  ==> OK : status code = [$1]"
}

# start script
echo "access gitlab : [${gitlab_url}]"
echo "create cookie file :[${cookie_file_name}${timestamp}]"
csrf_token=$(curl -c ${cookie_file_name}${timestamp}_01.txt -s -L -X GET "${gitlab_url}/users/sign_in" | grep csrf-token | sed -e  's/.*content\=\"//g'  | sed -e 's/\" \/.*//g')

echo "start get csrf_token"
if [ -z ${csrf_token} ] ; then
  echo " ==> NG!!! : can't get csrf_token"
  exit 0
fi
echo "  ==> OK : csrf_token : [${csrf_token}]"

# user logon and get auth_token 
echo "start user logon : [${gitlab_user}]"
curl -b ${cookie_file_name}${timestamp}_01.txt -c ${cookie_file_name}${timestamp}_02.txt -s -L -F "user[login]=${gitlab_user}" -F "user[password]=${gitlab_password}" -F "user[remember_me]=0" -F "authenticity_token=${csrf_token}" "${gitlab_url}/users/sign_in" -o /dev/null

# Logonのチェック方法
# 認証エラーでもWeb上では200で戻ってくる。
# 成功時はcookieファイルに認証情報が追加されるので01と02ではサイズが異なる
size01=$(wc -c ${cookie_file_name}${timestamp}_01.txt | awk '{print $1}')
size02=$(wc -c ${cookie_file_name}${timestamp}_02.txt | awk '{print $1}')
if [ ${size01} -eq ${size02} ] ; then
    echo "  ==> NG!!! : logon failure"
    exit 0
fi

# check status code 200
for v in ${check_urls[@]}
do
  echo "check access url : [${gitlab_url}${v}]"
  status_code=$(curl -b ${cookie_file_name}${timestamp}_02.txt -I -X GET "${gitlab_url}${v}" -o /dev/null -w '%{http_code}\n' -s)
  check_status_code ${status_code}
done

echo "Finish!!!!!  OK !!!"
