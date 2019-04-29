#!/usr/bin/env bash

set -eu

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

for _file in "${GITHUB_WORKSPACE}"/*"$1"; do
    AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
    RELEASE_ID=$(jq --raw-output '.release.id' "$GITHUB_EVENT_PATH")
    FILENAME=$(basename "$_file")
    CONTENT_TYPE_HEADER="Content-Type: $(file --mime-type -b "$_file")"
    CONTENT_LENGTH_HEADER="Content-Length: $(stat -c%s "${_file}")"
    UPLOAD_URL="https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/${RELEASE_ID}/assets?name=${FILENAME}"
    echo "Uploading $FILENAME... as $CONTENT_TYPE_HEADER to $UPLOAD_URL"

    # Upload the file
    _response=$(curl \
      -sSL \
      -X POST "${UPLOAD_URL}" \
      -H "Accept: application/vnd.github.manifold-preview" \
      -H "${AUTH_HEADER}" \
      -H "${CONTENT_LENGTH_HEADER}" \
      -H "${CONTENT_TYPE_HEADER}" \
      --upload-file "${_file}")

    _state=$(jq -r '.state' <<< "$_response")
    if [ "$_state" != "uploaded" ]; then
        echo "Error! Artifact not uploaded: $FILENAME"
    fi
done
