file_path=${1:-"/home/gens/genscript.png"}

fid_url=`curl -s http://localhost:9333/dir/assign | python -m json.tool  | grep fid | awk -F"[\"\"]" '{print $4}'`
echo "fid和url为：${fid_url}"

# 上传内容
curl -s -F file=@${file_path} http://127.0.0.1:8080/${fid_url} | python -m json.tool

#文件预览地址
file_preview="http://10.1.26.76:8081/${fid_url}"
echo "文件预览地址：${file_preview}"


# 文件上传
#./weed upload /home/gens/genscript.png 
