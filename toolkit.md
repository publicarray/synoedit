[Prepare build environment](https://developer.synology.com/developer-guide/create_package/prepare_build_environment.html)

<!-- ```sh
mkdir -p ~/git/synoedit/toolkit && cd ~/git/synoedit/toolkit
git clone https://github.com/SynologyOpenSource/pkgscripts-ng.git
# git clone https://github.com/SynologyOpenSource/pkgscripts.git # for older versions
## debian or ubuntu
docker run -it --rm -v $(pwd):/toolkit --name synology ubuntu /bin/bash
## fish shell:
# docker run -it --rm -v (pwd):/toolkit --name synology ubuntu /bin/bash

apt update
apt -y install wget python3
``` -->


in a ubuntu virtual machine:
```sh
cd /toolkit/pkgscripts-ng

./EnvDeploy -v 6.1 -p x64
```
