#!/bin/sh

## Tested on macSO only! TODO: need to run this in on more OSs in docker

set -u

_browserify() {
    if command -v browserify > /dev/null; then
        browserify package/ui/js/main.js -o package/ui/js/bundle.js
    else
        echo "browserify is required to bundle JavaScript files. Install with 'yarn global add browserify'"
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
            UPDATE_LIBS="true"
        elif command -v npm > /dev/null; then
            npm install
            UPDATE_LIBS="true"
        else
            echo "JavaScript libraries are NOT updated! Requires Yarn or NPM to be installed on the system."
        fi

        if [ $UPDATE_LIBS = "true" ]; then
            _browserify
        fi
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
        echo "go is missing. Install golang before trying again. This software doesn't compile itself!"
        echo "https://golang.org/"
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
        --exclude='package' \
        --exclude='*.sh' \
        --exclude='*.spk' \
        --exclude='.git' \
        -- *
}

CMD="${1:-""}"
if [ "$CMD" = "update" ]; then
    update
    exit 0
elif [ "$CMD" = "dependencies" ] || [ "$CMD" = "javascript" ] || [ "$CMD" = "yarn" ] || [ "$CMD" = "npm" ]; then
    dependencies
    exit 0
elif [ "$CMD" = "all" ]; then
    compileAll
    exit 0
elif [ "$CMD" = "compile" ]; then
    compile "$2"
    exit 0
elif [ "$CMD" = "package" ]; then
    package
    exit 0
else
    dependencies
    compile
    package
fi
