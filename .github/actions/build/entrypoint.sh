#!/bin/sh

set -eu

./build.sh dependencies
./build.sh all

mv ./*.spk "${GITHUB_WORKSPACE}"/
