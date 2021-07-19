# Syno Edit

[![Go Report Card](https://goreportcard.com/badge/github.com/publicarray/synoedit)](https://goreportcard.com/report/github.com/publicarray/synoedit)
[![GoDoc](https://godoc.org/github.com/publicarray/synoedit/package/src/synoedit?status.svg)](https://godoc.org/github.com/publicarray/synoedit/package/src/synoedit)

Synology package for editing files through a web interface

![screen shot](https://user-images.githubusercontent.com/5497998/41282074-7e3f81f6-6e76-11e8-8436-0187282b1b87.png)
![screen shot](https://user-images.githubusercontent.com/5497998/41282242-f7290420-6e76-11e8-81da-43769de7a269.png)

## Build using script

```sh
git clone https://github.com/publicarray/synoedit && cd synoedit
./build all # builds all available versions/architectures
./build amd64 # alias to build amd64 architecture only for both DSM6 and DSM7 (good for development)
./build help # see all options
```

## Build manually

```sh
git clone https://github.com/publicarray/synoedit.git
cd synoedit/package/src/synoedit
go build -ldflags="-s -w" -o ../../ui/index.cgi
# Run the binary
go run . -h
env SERVER_PROTOCOL=HTTP/1.1 REQUEST_METHOD=GET go run . -dev -config ../../ui/database.toml -layout ../../ui/layout.html
# or
cd ../../ui/
env SERVER_PROTOCOL=HTTP/1.1 REQUEST_METHOD=GET ./index.cgi --dev > test.html
```

## Add package support

1. Add your package to the synocommunity group

    for synocommunity packages add `SPK_GROUP=synocommunity` to your `Makefile` Otherwise add it to your `privilege` file

    ```json
    {
    "defaults": {
        "run-as": "package"
    },
    "username": "<your-package-name>",
    "groupname": "synocommunity"
    }
    ```

2. In the `postinstall` script add group read and write permissions for the files you want to add support for

```sh
chmod g+rw -R "$SYNOPKG_PKGVAR"
```
