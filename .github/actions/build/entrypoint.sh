#!/bin/sh

set -eu

./build --all

mv ./*.spk "${GITHUB_WORKSPACE}"/
