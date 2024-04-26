#!/bin/bash

# singing_helper $KEY $INPUT_BIN

tmp_file=$(mktemp)

openssl rsautl -sign -inkey $1 -in $2 -out $tmp_file

cat $tmp_file > $2

