#!/bin/bash

# $1 :: ${{ inputs.auth }}
# $2 :: ${{ inputs.gist_url }}
# $3 :: ${{ inputs.gist_title }}
# $4 :: ${{ inputs.gist_description }}
# $5 :: ${{ inputs.github_file }}
# $6 :: ${{ inputs.file_encoding }}

Error() {
    echo "$1"
    exit "$2"
}

auth_token=$1

gist_api="https://api.github.com/gists/"
gist_id=$(grep -Po "\w+$" <<< "$2")
gist_endpoint=$gist_api$gist_id

title=$(echo "$3" | sed 's/\"/\\"/g')
description=$(echo "$4" | sed 's/\"/\\"/g')

[[ -r "$5" ]] || Error "The file '$5' does not exist or is not readable" 1

raw_data=$(iconv -f "$6" -t UTF-8 "$5")

echo "$raw_data" > encoded_file.txt

content=$(sed -e 's/\\/\\\\/g' -e 's/\t/\\t/g' -e 's/\"/\\"/g' -e 's/\r//g' encoded_file.txt | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g')

echo '{"description": "'"$description"'", "files": {"'"$title"'": {"content": "'"$content"'"}}}' > postContent.json || Error 'Failed to write temp json file' 2

curl -s -X PATCH \
    -H "Content-Type: application/json" \
    -H "Authorization: token $auth_token" \
    -d @postContent.json "$gist_endpoint" \
    --fail --show-error || Error 'Failed to patch gist' 3
