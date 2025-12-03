# docker command
## with proxy
docker build   --build-arg http_proxy=http://ufproxy.b.cii.u-fukui.ac.jp:8080   --build-arg https_proxy=http://ufproxy.b.cii.u-fukui.ac.jp:8080/ -t marmo:test .

## without proxy
docker build marmotest:test .

# this project needs Nvidia container toolkit
install guide \
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html \
note the section of "Configuring Docker" \
this toolkit needs to configure the runtime

