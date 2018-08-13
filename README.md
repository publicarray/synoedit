# Syno Edit

[![Go Report Card](https://goreportcard.com/badge/github.com/publicarray/synoedit)](https://goreportcard.com/report/github.com/publicarray/synoedit)

Synology package to edit files on the file system

![screen shot](https://user-images.githubusercontent.com/5497998/41282074-7e3f81f6-6e76-11e8-8436-0187282b1b87.png)
![screen shot](https://user-images.githubusercontent.com/5497998/41282242-f7290420-6e76-11e8-81da-43769de7a269.png)


## Build manually

```sh
git clone https://github.com/publicarray/synoedit.git
cd synoedit/package
export GOPATH=$PWD
cd src/synoedit
dep ensure
go build -ldflags="-s -w" -o ../../ui/index.cgi
# Run the binary
cd ../../ui/
./index.cgi --dev > test.html
```
