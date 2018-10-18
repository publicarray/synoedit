#!/bin/sh

## Tested on macSO only! TODO: need to run this in on more OSs in docker

set -u

usage() {
    echo "Usage:  $0 command"
    echo
    echo "Commands:"
    echo "  compress       compresses compiled binary with upx"
    echo "  update         update dependencies with yarn or npm"
    echo "  dependencies   installs dependencies and bundles them through browserify"
    echo "  all            Runs browserify and Compiles go project for all architectures"
    echo "  compile        compile go project"
    echo "  package        create spk"
    echo "  dev            runs '_browserify', 'compile' and 'package' commands"
    echo ""
}

_browserify() {
    # A dump function to run browserify
    if command -v browserify > /dev/null; then
        browserify package/ui/js/main.js -o package/ui/js/bundle.js
    elif command -v yarn > /dev/null && yarn list 2> /dev/null | grep -q browserify; then
        yarn browserify package/ui/js/main.js -o package/ui/js/bundle.js
    elif command -v npm > /dev/null; then
        npm run browserify package/ui/js/main.js -o package/ui/js/bundle.js
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

    if command -v dep > /dev/null; then
        cd package || exit
        export GOPATH=$PWD
        cd src/synoedit || exit
        dep ensure -update
        cd ../../../ || exit
    fi
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
    if [ ! -d package/src/synoedit/vendor ]; then
        if command -v dep > /dev/null; then
            cd package || exit
            export GOPATH=$PWD
            cd src/synoedit || exit
            dep ensure
            cd ../../../ || exit
        else
            echo "dep (https://github.com/golang/dep) is needed for dependency management. Try brew install dep if your on macOS"
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
        gofmt -s -w -- package/src/synoedit/*.go
        cd package || exit
        export GOPATH=$PWD
        cd src/synoedit || exit
        echo "go compiling ..."
        if [ -z "$ARCH" ]; then
            go build -ldflags="-s -w" -o ../../ui/index.cgi
            # go build -ldflags "-s -w" -o package/ui/index.cgi -- package/src/synoedit/*.go
        else
            # env GOOS=linux GOARCH="$ARCH" go build -ldflags "-s -w" -o package/ui/index.cgi -- package/src/*.go
            env CGO_ENABLED=0 GOOS=linux GOARCH="$ARCH" go build -ldflags "-s -w" -o ../../ui/index.cgi
        fi
        cd ../../.. || edit
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
    tar cvfz package.tgz --exclude='src' \
        --exclude="pkg" \
        --exclude='ui/test' \
        --exclude='ui/test.sh' \
        --exclude='.DS_Store' \
        -C package .

     # arch="arm arm64 386 amd64 ppc64" ->  arm, x86, x86_64

    ## Create checksum
    checksum=$($md5sum package.tgz | awk '{print $1}')
    sed -i '' -e "s/checksum=.*/checksum=\"${checksum}\"/" INFO
    # sed -i '' -e "s/arch=.*/arch=\"${ARCH}\"/" INFO
    # pkg_get_spk_platform
    # pkg_get_spk_family

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
        --exclude='*.log' \
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
    _browserify
    compile "$BUILD_ARCH"
elif [ "$CMD" = "package" ]; then
    package
elif [ "$CMD" = "dev" ]; then
    _browserify
    compile
    package
else
    usage
fi
