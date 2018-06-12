#!/bin/sh

## Tested on macSO only! TODO: need to run this in on more OSs in docker

set -u

_browserify() {
    if command -v browserify > /dev/null; then
        browserify package/ui/js/main.js -o package/ui/js/bundle.js
    else
        echo "browserify is required to bundle JavaScript files. Install with 'yarn global add browserify'" >&2
        exit 1
    fi
    cp node_modules/codemirror/lib/*.css package/ui/css/
    cp node_modules/codemirror/addon/dialog/*.css package/ui/css/
}

## Update node_modules
update() {
    if command -v yarn > /dev/null; then
        yarn upgrade --latest
    elif command -v npm > /dev/null; then
        npm update
    fi

    _browserify
}

## Step 1 Install dependencies
dependencies() {
    if [ ! -d node_modules ]; then
        if command -v yarn > /dev/null; then
            yarn
        elif command -v npm > /dev/null; then
            npm install
        else
            echo "JavaScript libraries are NOT updated! Requires Yarn or NPM to be installed on the system." >&2
        fi
        _browserify
    fi
}

compileAll() {
    dependencies

    arch="arm arm64 386 amd64 ppc64"
    for ARCH in ${arch}
    do
       compile "$ARCH"
       package "$ARCH"
    done
}

## Step 2 compile
compile() {
    ARCH="${1:-""}"
    if command -v go > /dev/null; then
        gofmt -s -w -- package/src/*.go
        if [ -z "$ARCH" ]; then
            go build -ldflags "-s -w" -o package/ui/index.cgi -- package/src/*.go
        else
            env GOOS=linux GOARCH="$ARCH" go build -ldflags "-s -w" -o package/ui/index.cgi -- package/src/*.go
        fi
    else
        echo "go is missing. Install golang before trying again. This software doesn't compile itself!" >&2
        echo "https://golang.org/"
        exit 1
    fi
}

compress() { # not recommended, slows down launch time ~0.8s
    if command -v upx > /dev/null; then
        upx package/ui/index.cgi
        # upx --brute package/ui/index.cgi # slow
    else
        echo "upx not found. This option requires upx. 'brew insall upx'" >&2
        exit 1
    fi
}

## Step 3 Compress package and create spk
package() {
    ARCH=${1:-native}
    # sha1sum="$(shell command -v sha1sum 2>/dev/null || command -v gsha1sum 2>/dev/null)"
    # sha256sum="$(shell command -v sha256sum 2>/dev/null || command -v gsha256sum 2>/dev/null)"
    md5sum="$(shell command -v md5sum 2>/dev/null || command -v gmd5sum 2>/dev/null)"

    ## Create package.tgz
    tar cvfz package.tgz --exclude='src' --exclude='ui/test' -C package .

    ## Create checksum
    checksum=$($md5sum package.tgz | awk '{print $1}')
    sed -i '' -e "s/checksum=.*/checksum=\"${checksum}\"/" INFO

    ## Create spk
    tar cpf synoedit-"$ARCH".spk \
        --exclude='node_modules' \
        --exclude='*.afdesign' \
        --exclude='*.afphoto' \
        --exclude='.DS_Store' \
        --exclude='yarn.lock' \
        --exclude='package.json' \
        --exclude='ui/js/main.js' \
        --exclude='package' \
        --exclude='*.sh' \
        --exclude='*.spk' \
        --exclude='.git' \
        -- *
}

CMD="${1:-""}"
BUILD_ARCH="${2:-""}"
if [ "$CMD" = "compress" ]; then
    compress
elif [ "$CMD" = "update" ]; then
    update
elif [ "$CMD" = "dependencies" ] || [ "$CMD" = "javascript" ] || [ "$CMD" = "yarn" ] || [ "$CMD" = "npm" ]; then
    dependencies
elif [ "$CMD" = "all" ]; then
    _browserify
    compileAll
    compile
elif [ "$CMD" = "compile" ]; then
    compile "$BUILD_ARCH"
elif [ "$CMD" = "package" ]; then
    package
else
    dependencies
    compile
    package
fi
