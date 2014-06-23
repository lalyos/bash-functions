#####################################
# curl -Lo /tmp/docker-functions http://j.mp/docker-functions && source /tmp/docker-functions
#####################################

DOCKER_FUNCTION_VERSION=0.9

alias dps='docker ps'
alias dpsa='docker ps -a'

: ${DEBUG:=1}

PRG="$BASH_SOURCE"

docker-functions() {
  echo DOCKER_FUNCTION_VERSION=$DOCKER_FUNCTION_VERSION
  echo source=$PRG
}

docker-functions-reload() {
  curl -Lo /tmp/docker-functions http://j.mp/docker-functions
  source /tmp/docker-functions
  docker-functions
}

debug() {
  [ $DEBUG -gt 0 ] && echo [DEBUG] "$@" 1>&2
}

docker-restart() {
    boot2docker ssh "sudo /etc/init.d/docker restart && docker version"
}

docker-ps() {
  #docker ps|sed "s/ \{3,\}/#/g"|cut -d '#' -f 1,2,7|sed "s/#/\t/g"
  CONTAINERS=$(docker ps -q)
  [ -n "$CONTAINERS" ] && docker inspect --format="{{.Name}} {{.NetworkSettings.IPAddress}} {{.Config.Image}} {{.Config.Entrypoint}} {{.Config.Cmd}}" $CONTAINERS
}

docker-psa() {
  #docker ps|sed "s/ \{3,\}/#/g"|cut -d '#' -f 1,2,7|sed "s/#/\t/g"
  docker inspect --format="{{.Name}} {{.NetworkSettings.IPAddress}} {{.Config.Image}} {{.Config.Entrypoint}} {{.Config.Cmd}}" $(docker ps -qa)
}

docker-last-ip() {
  CONTAINERS=$(docker ps -q)
  [ -n "$CONTAINERS" ] && docker inspect --format="{{.NetworkSettings.IPAddress}}" $CONTAINERS
}

_docker-kill-containers() {
  CONTAINERS=$1
  if [ -z "$CONTAINERS" ] ; then
    debug no containers to kill ...
  else
    docker stop -t 0 $CONTAINERS
    docker rm $CONTAINERS
  fi
}

docker-kill-last() {
  _docker-kill-containers $(docker ps -q -l)
}

docker-kill-between() {
  if [ $# -lt 2 ] ; then
    echo please specify SINCE and BEFORE containers
  else
    _docker-kill-containers $(docker ps -q --since $1 --before $2)
  fi
}

docker-kill-before() {
  if [ $# -lt 1 ] ; then
    echo please specify BEFORE containers
  else
    _docker-kill-containers $(docker ps -q  --before $1)
  fi
}

docker-kill-since() {
  if [ $# -lt 1 ] ; then
    echo please specify SINCE containers
  else
    _docker-kill-containers $(docker ps -q  --since $1)
  fi
}

docker-kill-all() {
  _docker-kill-containers $(docker ps -qa)
}

docker-play-mybase() {
    docker run -i -t mybase /bin/bash
    docker-kill-last
}

docker-logs(){
  boot2docker ssh tail -f /var/log/docker.log
}

docker-rmi-unnamed() {
  docker rmi $(docker images | sed -n  "/<none>/ s/.*\([a-z0-9]\{12\}\).*/\1/p")
}

docker-commands() {
  //docker inspect $(docker ps -q)|jq ".[]| {name:.Name, ip: .NetworkSettings.IPAddress, cmd: .Config.Cmd, pointcut: .Config.Entrypoint}" -c
  docker inspect $(docker ps -q)|jq ".[]| [.NetworkSettings.IPAddress, .Name, .Config.Entrypoint[], .Config.Cmd[]]" -c
}

docker-commandsa() {
  //docker inspect $(docker ps -q)|jq ".[]| {name:.Name, ip: .NetworkSettings.IPAddress, cmd: .Config.Cmd, pointcut: .Config.Entrypoint}" -c
  docker inspect $(docker ps -qa)|jq ".[]| [.NetworkSettings.IPAddress, .Name, .Config.Entrypoint[], .Config.Cmd[]]" -c
}

docker-commands-full() {
  docker inspect $(docker ps -q)|jq ".[]| {path: .Path, args: .Args, cmd: .Config.Cmd, pointcut: .Config.Entrypoint}" -c
}
