#!/bin/sh

set -u

urlencode() {
    # https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command/10797966#10797966
    echo "$1" | curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | cut -c 3-
}

# ---------------------------------------------------------------------------
fixLinks() {
    sed -i '' -e "s@/webman/3rdparty/synoedit/@../@" $1
}

if [ ! -d test ]; then
    echo "Preparing test folder.."
    mkdir -p test/dnscrypt-proxy/target/var
fi

echo "example.com" > test/dnscrypt-proxy/target/var/domains-whitelist.txt

## lint
# gofmt -s -w cgi.go

## build
# go get github.com/BurntSushi/toml
# go build -ldflags "-s -w" -o index.cgi -- *.go

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

export REQUEST_METHOD=GET
export QUERY_STRING="app=dnscrypt-proxy&file=domains-whitelist.txt"
./index.cgi --dev | tail -n +4 > test/file2.html
fixLinks test/file2.html

export REQUEST_METHOD=POST
# data="$(urlencode "$(cat test/dnscrypt-proxy/target/var/domains-whitelist.txt)")"
data="$(urlencode "google.com")"
# echo "$data" > post.txt

# echo "ListenAddresses=0.0.0.0%3A1053+&ServerNames=cloudflare+google+ " | ./index.cgi --dev
echo "ajax=true&app=dnscrypt-proxy&file=domains-whitelist.txt&fileContent=$data" | ./index.cgi --dev | tail -n +4 > test/post.html
fixLinks test/post.html

export REQUEST_METHOD=POST
echo "action=true" | ./index.cgi --dev > test/action.html
