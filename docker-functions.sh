#####################################
# curl -Lo /tmp/docker-functions http://j.mp/docker-functions && source /tmp/docker-functions
#####################################

DOCKER_FUNCTION_VERSION=0.9

alias dps='docker ps'
alias dpsa='docker ps -a'
alias drun='docker run -it --rm'
 
# create the completition function
_dpeco() { 
  : ${IMG_CACHE:=/tmp/docker-images}
  if [ ! -f $IMG_CACHE  ] || [[ "$(find $IMG_CACHE -cmin +60)"  ]] ; then 
    docker images | tail -n +2 | sed "s/ \+/ /g" | cut -d ' ' -f 1,2 | sed "s/ /:/" |sort -u > $IMG_CACHE
  fi
  COMPREPLY=$(cat $IMG_CACHE|peco --query "$2 " ); 
}; complete -F _dpeco drun

: ${DEBUG:=1}

PRG="$BASH_SOURCE"

docker-functions() {
  echo DOCKER_FUNCTION_VERSION=$DOCKER_FUNCTION_VERSION
  echo source=$PRG
}

dunset() {
    unset ${!DOCK*}
}

dim() {
    docker images|grep MB|sort -n --key=7; docker images|grep GB|sort -n --key=7
}

dim-sort() {
  docker images | sed -n "s/\(.*\) \([0-9]*\)\.[0-9]* MB$/\2+++\1/p"|sed "s/ \+/ /g"|cut -d' ' -f 1,2|tr ' ' ':'|sed 's/+++/ /'|sort -n
}

docker-select-version() {
  select ver in /usr/local/Cellar/docker/* ; do
    local binary=$ver/bin/docker
    debug docker aliased to: $binary
    alias docker=$binary
    break
  done
}

docker-reload() {
  source ${BASH_SOURCE[0]}
}

docker-in-docker() {
  docker run --privileged -d -p 4444 -e PORT=4444 --name dind jpetazzo/dind
  [ -f /tmp/docker-0.11.1 ] || ( curl -o /tmp/docker-0.11.1 https://get.docker.io/builds/Darwin/x86_64/docker-0.11.1; chmod +x /tmp/docker-0.11.1)

  DIND_IP=$(docker inspect -f "{{.NetworkSettings.IPAddress}}" dind)
  cat <<EOF

  docker in docker (DIND)started in a daemon container
  on port 4444. the daemon is 0.11.1 version, so to
  communicate with DIND use this alias:

############################################################
  alias docker='/tmp/docker-0.11.1 -H tcp://$DIND_IP:4444'
############################################################

  if you want to switch back to the original docker just:

  unalias docker; hash -r
EOF
}

docker-pi() {
    alias docker='echo -e "\n=== RaspbPI ===\n" 1>&2 ; ~/.boot2docker/docker-0.11.0 -H tcp://rpi:2375'
}

docker-find-pi() {
  nmap -np2375 $(ifconfig en0|sed -n "/broadcast/ s/.*broadcast.//p")/24
}

docker-in-docker-end() {
  docker stop -t 0 dind
  docker rm dind
  unalias docker
  hash -r
}

docker-enter() { boot2docker ssh -t "[ -f /var/lib/boot2docker/nsenter ] || docker run --rm -v /var/lib/boot2docker/:/target jpetazzo/nsenter; sudo /var/lib/boot2docker/docker-enter $@"; }

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
  CONTAINERS="$@"
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
    _docker-kill-containers $(docker ps -qaf since=$1)
  fi
}

docker-env() { 
  for v in $(eval "echo \${!${1:? env prefix required}*}"); do 
      echo "  -e $v=\$$v \\"
  done
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
  docker inspect $(docker ps -q)|jq ".[]| {path: .Path, args: .Args, cmd: .Config.Cmd, entrypoint: .Config.Entrypoint}" -c
}
