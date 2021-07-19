#!/bin/sh

# example: ./build.sh compile amd64;  ./build.sh package amd64 apollolake 7.0-4000

set -eu

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

gsha256sum() {
     if command -v sha256sum > /dev/null; then
        command sha256sum "$@"
    elif command -v gsha256sum > /dev/null; then
        command gsha256sum "$@"
    fi
}

gmd5sum() {
     if command -v md5sum > /dev/null; then
        command md5sum "$@"
    elif command -v gmd5sum > /dev/null; then
        command gmd5sum "$@"
    fi
}

sedi() {
    if [ "$(uname)" = 'Darwin' ]; then
        command sed -i '' "$@"
    else
        command sed -i "$@"
    fi
}
usage() {
    echo "Usage:  $0 command"
    echo
    echo "Commands:"
    echo "  compress                                        compresses compiled binary with upx"
    echo "  update                                          update dependencies with yarn or npm"
    echo "  dependencies                                    installs npm and go dependencies (yarn/npm and dep)"
    echo "  all                                             compiles go project for all architectures and DSM6/7 versions"
    echo "  compile [arch]                                  compile go project: e.g. compile amd64"
    echo "  package [arch] [syno_arch] [min_dsm_version]    create spk e.g. package amd64 broadwell 6.1-14715"
    echo "  dev                                             runs '_cp', 'compile' and 'package' commands using the native platform"
    echo "  clean|clear                                     remove all *spk files"
    echo "  lint                                            lint code"
    echo "  test                                            run a simple test"
    echo "  amd64                                           alias to compile and package for amd64 only, good for quick development"
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

clean() {
    rm -v ./*.spk
}

## Update node_modules
update() {
    if command -v yarn > /dev/null; then
        yarn upgrade --latest
    elif command -v npm > /dev/null; then
        npm update
    fi
    _cp

    if command -v go > /dev/null; then
        go list -u -m all
        go get -u
        go mod vendor
        # go get -u=patch
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
    # if [ ! -d vendor ]; then
    #     if command -v go > /dev/null; then
    #         go mod download
    #         go mod vendor
    #     else
    #         echo "go is needed for dependency management. Try brew install go if your on macOS"
    #     fi
    # fi
}

checksum_database(){
    sha256sum="$(shell command -v sha256sum 2>/dev/null || command -v gsha256sum 2>/dev/null)"
    checksum=$($sha256sum package/ui/database.toml | awk '{print $1}')
    if ! grep -q "$checksum" package/src/synoedit/main.go; then
        echo "Checksum mismatch!"
        $sha256sum package/ui/database.toml
        grep 'DefaultDatabaseSHA256Checksum =' package/src/synoedit/main.go
        exit 1
    fi
}

checksum_database_fix() {
    sha256sum="$(shell command -v sha256sum 2>/dev/null || command -v gsha256sum 2>/dev/null)"
    checksum=$($sha256sum package/ui/database.toml | awk '{print $1}')
    if ! grep -q "$checksum" package/src/synoedit/main.go; then
        echo "Checksum mismatch! Fixing..."
        sedi -e "s/DefaultDatabaseSHA256Checksum\s*=.*/DefaultDatabaseSHA256Checksum = \"${checksum}\"/" package/src/synoedit/main.go
    fi
}

compileAll() {
    checksum_database
    lint
    dependencies

    ## match arches to go build arches:
    arches="arm arm64 386 amd64 ppc64"
    os_min_ver="${1:-"7.0-4000"}"
    for arch in ${arches}; do
        supported_arches=""
        case "$arch" in
            "arm")
                compile "$arch" "5"
                package "$arch"_v5 "$ARM5_ARCHES" "$os_min_ver"

                compile "$arch" "7"
                ARM7_ARCHES=$(echo "$ARM7_ARCHES" | sed 's/ ipq806x//' | sed 's/ northstarplus//')
                package "$arch"_v7 "$ARM7_ARCHES" "$os_min_ver"
                # SRM
                package "$arch"_v7 "ipq806x northstarplus" "1.1.6-6931"
                ;;
            "arm64") # ARMv8
                compile "$arch"
                supported_arches="$ARM8_ARCHES"
                ;;
            "386")
                compile "$arch"
                supported_arches="$x86_ARCHES"
                ;;
            "amd64")
                compile "$arch"
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
        package "$arch" "$supported_arches" "$os_min_ver"
    done
}

## Step 2 compile
compile() {
    _ARCH="${1:-""}"
    _GOARM="${2:-""}"
    checksum_database
    if command -v go > /dev/null; then
        cd package/src/synoedit || exit
        echo "go compiling ..."
        if [ -z "$_ARCH" ]; then
            go build -ldflags="-s -w" -o ../../ui/index.cgi
            # go build -ldflags "-s -w" -o package/ui/index.cgi -- package/src/synoedit/*.go
        else
            # env GOOS=linux GOARCH="$ARCH" go build -ldflags "-s -w" -o package/ui/index.cgi -- package/src/*.go
            echo "GOARCH=$_ARCH GOARM=$_GOARM"
            env CGO_ENABLED=0 GOOS=linux GOARCH="$_ARCH" GOARM="$_GOARM" go build -ldflags "-s -w" -o ../../ui/index.cgi
            chmod +x ../../ui/index.cgi
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
        echo "upx not found. This option requires upx. 'brew install upx'" >&2
        exit 1
    fi
}

## Step 3 Compress package and create spk
package() {
    _arch=${1:-native}
    _supported_arches=${2:-noarch}
    _os_min_ver=${3:-7.0-4000}

    # sha1sum="$(shell command -v sha1sum 2>/dev/null || command -v gsha1sum 2>/dev/null)"
    # sha256sum="$(shell command -v sha256sum 2>/dev/null || command -v gsha256sum 2>/dev/null)"
    md5sum="$(shell command -v md5sum 2>/dev/null || command -v gmd5sum 2>/dev/null)"

    ## Create package.tgz
    echo "tar cpf package.tgz"
    tar cfz package.tgz --exclude='src' \
        --exclude="pkg" \
        --exclude='ui/test' \
        --exclude='ui/test.sh' \
        --exclude='.DS_Store' \
        -C package .

     # arch="arm arm64 386 amd64 ppc64" ->  arm, x86, x86_64

    ## Create checksum
    checksum=$($md5sum package.tgz | awk '{print $1}')
    sedi -e "s/checksum=.*/checksum=\"${checksum}\"/" INFO
    sedi -e "s/arch=.*/arch=\"${_supported_arches}\"/" INFO
    sedi -e "s/os_min_ver=.*/os_min_ver=\"${_os_min_ver}\"/" INFO
    # pkg_get_spk_platform
    # pkg_get_spk_family

    ## Create spk

    echo "tar cpf $_arch-$_os_min_ver.spk"
    tar cpf synoedit-"$_arch"-"$_os_min_ver".spk \
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
        --exclude='synoedit-*' \
        --exclude='*.log' \
        --exclude='.git' \
        --exclude='.github' \
        --exclude='go.mod' \
        --exclude='go.sum' \
        --exclude='vendor' \
        -- *
}

lint () {
    gofmt -s -w -- package/src/synoedit/*.go
    if ! command -v golint > /dev/null || ! command -v revive > /dev/null; then
        go get -u golang.org/x/lint/golint
    fi
    go mod tidy

    if command -v golint > /dev/null; then
        golint package/src/synoedit/*.go
    elif command -v revive > /dev/null; then
        revive package/src/synoedit/*.go
    fi

    if command -v yarn > /dev/null; then
        yarn audit
    elif command -v npm > /dev/null; then
        npm audit
    fi
}

test () {
    lint
    compile
    env SERVER_PROTOCOL=HTTP/1.1 REQUEST_METHOD=GET package/ui/index.cgi --dev > package/ui/test.html
    # godoc ./package/src/synoedit/
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
    compileAll 7.0-4000
    compileAll 6.1-14715
    compile
elif [ "$CMD" = "compile" ]; then
    _cp
    compile "$BUILD_ARCH"
elif [ "$CMD" = "package" ]; then
    shift
    package "$@"
elif [ "$CMD" = "dev" ]; then
    _cp
    checksum_database_fix
    compile
    package
elif [ "$CMD" = "clean" ] || [ "$CMD" = "clear" ]; then
    clean
elif [ "$CMD" = "lint" ]; then
    lint
elif [ "$CMD" = "test" ]; then
    test
elif [ "$CMD" = "amd64" ]; then
    _cp
    checksum_database_fix
    compile amd64
    package amd64 "${x64_ARCHES}" 6.1-14715
    package amd64 "${x64_ARCHES}" 7.0-4000
else
    usage
fi
