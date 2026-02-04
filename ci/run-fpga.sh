#!/bin/bash

username=$1; shift
boardname=$1; shift
remote=$1; shift
script=$1; shift

# run the script over ssh
ssh -o BatchMode=yes $username@$boardname "cd $remote && bash -l -s" "$@" < $script

