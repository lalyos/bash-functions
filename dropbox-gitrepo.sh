#!/bin/bash

if [ $1 == "-h" ] ; then
cat<<EOF

create a git repo in Dropbox poormans github
  usage: $(basename $0) [repo_name]
  default [repo_name] is the current directory name

EOF
  exit -1
fi

REPO=$1
echo REPO=${REPO:=${PWD##*/}}

cd ~/Dropbox/git
git init --bare $REPO.git

cd -
git remote add dropbox /Users/lalyos/Dropbox/git/$REPO.git
