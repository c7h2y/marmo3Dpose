# this project needs Nvidia container toolkit
install guide \
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html \
note the section of "Configuring Docker" \
this toolkit needs to configure the runtime
# docker command
## with proxy
```
export $http_proxy='http://proxy_url:port'
bash dockerbld_withproxy.sh $http_proxy
```
## without proxy
```
bash dockerbld.sh
```
# run test in the docker container
```
bash docker_run_test.sh
```