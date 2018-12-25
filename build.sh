#!/bin/sh

## Tested on macSO only! TODO: need to run this in on more OSs in docker

set -u

# https://originhelp.synology.com/developer-guide/appendix/index.html
# https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model
# https://github.com/SynoCommunity/spksrc/blob/master/mk/spksrc.common.mk
ARM5_ARCHES="88f6281"
ARM7_ARCHES="alpine armada370 armada375 armada38x armadaxp comcerto2k monaco hi3535 ipq806x northstarplus"
ARM8_ARCHES="rtd1296 armada37xx aarch64"
ARM_ARCHES="$ARM5_ARCHES $ARM7_ARCHES $ARM8_ARCHES"
PPC32_ARCHES="powerpc ppc824x ppc853x ppc854x qoriq"
x86_ARCHES="evansport"
x64_ARCHES="apollolake avoton braswell broadwell broadwellnk bromolow cedarview denverton dockerx64 grantley kvmx64 x86 x64 x86_64"
# x64_ARCHES="x86 cedarview bromolow"

usage() {
    echo "Usage:  $0 command"
    echo
    echo "Commands:"
    echo "  compress       compresses compiled binary with upx"
    echo "  update         update dependencies with yarn or npm"
    echo "  dependencies   installs npm and go dependencies (yarn/npm and dep)"
    echo "  all            Compiles go project for all architectures"
    echo "  compile        compile go project"
    echo "  package        create spk"
    echo "  dev            runs '_cp', 'compile' and 'package' commands"
    echo ""
}

_cp() {
    mkdir -p package/ui/codemirror/theme/
    cp -r node_modules/codemirror/addon package/ui/codemirror/
    cp -r node_modules/codemirror/keymap package/ui/codemirror/
    cp -r node_modules/codemirror/lib package/ui/codemirror/
    cp -r node_modules/codemirror/mode package/ui/codemirror/
    # cp -r node_modules/codemirror/theme package/ui/codemirror/
    # cp -r node_modules/codemirror/theme/monokai.css package/ui/codemirror/theme/
}

## Update node_modules
update() {
    if command -v yarn > /dev/null; then
        yarn upgrade --latest
    elif command -v npm > /dev/null; then
        npm update
    fi
    _cp

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
        _cp
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

    ## match arches to go build arches:
    arch="arm arm64 386 amd64 ppc64"
    for ARCH in ${arch}; do
        compile "$ARCH"
        supported_arches=""
        case "$ARCH" in
            "arm")
                supported_arches="$ARM5_ARCHES $ARM7_ARCHES"
                package "$ARCH" "ipq806x northstarplus" "1.1"

                supported_arches=$(echo "$supported_arches" | sed 's/ ipq806x//' | sed 's/ northstarplus//')
                ;;
            "arm64")
                supported_arches="$ARM8_ARCHES"
                ;;
            "386")
                supported_arches="$x86_ARCHES"
                ;;
            "amd64")
                supported_arches="$x64_ARCHES"
                ;;
            "ppc64")
                supported_arches=""
                ;;
            *)
                echo "Unsupported Architecture!"
                exit 1
                ;;
        esac
        OS_MIN_VER=6.1-14715
        package "$ARCH" "$supported_arches" "$OS_MIN_VER"
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
    SUPP_ARCH=${2:-noarch}
    OS_MIN_VER=${3:-6.1-14715}
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
    sed -i '' -e "s/arch=.*/arch=\"${SUPP_ARCH}\"/" INFO
    sed -i '' -e "s/os_min_ver=.*/os_min_ver=\"${OS_MIN_VER}\"/" INFO
    # pkg_get_spk_platform
    # pkg_get_spk_family

    ## Create spk
    tar cpf synoedit-"$ARCH"-"$OS_MIN_VER".spk \
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
    _cp
    compileAll
    compile
elif [ "$CMD" = "compile" ]; then
    _cp
    compile "$BUILD_ARCH"
elif [ "$CMD" = "package" ]; then
    package
elif [ "$CMD" = "dev" ]; then
    _cp
    compile
    package
else
    usage
fi
