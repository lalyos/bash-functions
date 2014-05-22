#!/bin/bash

: ${TOKEN?"please set you github token into KEY env variable"}

github(){
  curl https://api.github.com/$1 -H "Authorization: token $TOKEN"
}

github_put(){
  curl https://api.github.com/$1 -H "Authorization: token $TOKEN" -X PUT -d ""
}

github_post(){
  curl https://api.github.com/$1 -H "Authorization: token $TOKEN" -X POST -d @-
}

choose_repo(){
  select repo in $(github orgs/sequenceiq/repos | jq .[].full_name -r); do
    break
  done
  echo $repo
}

repo=$(choose_repo)

get_teamid(){
  org=$1
  team=$2
  x=$(github orgs/$org/teams | jq '.[]| [.id, .name]' -c | grep $team)
  y=${x%%,*}
  teamid=${y:1}
  echo $teamid
}

teamid=$(get_teamid sequenceiq dev)
set -x
github_put teams/$teamid/repos/$repo

:<<COMMENT
github_post orgs/sequenceiq/teams <<EOF
  {
  "name": "dev",
  "permission": "push",
  "repo_names": [
    "github/dotfiles"
   ]
 }
EOF
COMMENT
