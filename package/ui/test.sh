#!/bin/sh

set -u

urlencode() {
    # https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command/10797966#10797966
    echo "$1" | curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | cut -c 3-
}

# ---------------------------------------------------------------------------

setup() {
    mkdir -p test/dnscrypt-proxy/target/var
    #ln -sf $(pwd)/../../work-*/install/var/packages/dnscrypt-proxy/target/bin/dnscrypt-proxy test/bin/dnscrypt-proxy
    # ln -sf $(which dnscrypt-proxy) test/bin/dnscrypt-proxy
#     cp ../../work-*/install/var/packages/dnscrypt-proxy/target/example-* test/var/
#     for file in test/var/example-*; do
#         mv "${file}" "${file//example-/}"
#     done

    # wget -t 3 -O test/var/generate-domains-blacklist.py \
        # --https-only https://raw.githubusercontent.com/jedisct1/dnscrypt-proxy/master/utils/generate-domains-blacklists/generate-domains-blacklist.py
#     wget -t 3 -O test/var/domains-blacklist.conf \
#         --https-only https://raw.githubusercontent.com/jedisct1/dnscrypt-proxy/master/utils/generate-domains-blacklists/domains-blacklist.conf
    touch test/dnscrypt-proxy/target/var/domains-whitelist.txt
#     touch test/var/domains-time-restricted.txt
#     touch test/var/domains-blacklist-local-additions.txt
}

fixLinks() {
    sed -i '' -e "s@/webman/3rdparty/synoedit/@../@" $1
}

if [ ! -d test ]; then
    echo "Preparing test folder.."
    setup
fi

## lint
# gofmt -s -w cgi.go

## build
# go get github.com/BurntSushi/toml
# go build -ldflags "-s -w" -o index.cgi -- *.go

# compress
# upx --brute index.cgi

## test index.html
export REQUEST_METHOD=GET
export SERVER_PROTOCOL=HTTP/1.1
mkdir -p test
./index.cgi --dev | tail -n +4 > test/index.html
fixLinks test/index.html

## test GET file
export REQUEST_METHOD=GET
export QUERY_STRING="ajax=true&app=dnscrypt-proxy&file=domains-whitelist.txt"
./index.cgi --dev | tail -n +4 > test/file.html
fixLinks test/file.html

# export REQUEST_METHOD=POST
# data="$(urlencode "$(cat test/var/dnscrypt-proxy.toml)")"
# echo "$data" > post.html

# echo "ListenAddresses=0.0.0.0%3A1053+&ServerNames=cloudflare+google+ " | ./index.cgi --dev
# echo "file=config&fileContent=$data" | ./index.cgi --dev | tail -n +4 > test/post.html
# fixLinks test/post.html

# export REQUEST_METHOD=GET
# export QUERY_STRING=file=blacklist
# ./index.cgi --dev | tail -n +4 > test/get.html
# fixLinks test/get.html

# export REQUEST_METHOD=POST
# echo "generateBlacklist=true" | ./index.cgi --dev > test/generateBlacklist.html
