#eval $(dvm env)
export DOCKER_HOST=tcp://127.0.0.1:4243
alias dps='docker ps'
alias dpsa='docker ps -a'
alias reload="source ~/apps/bin/docker-functions.sh"

docker-restart() {
    sshpass -p tcuser ssh docker@127.0.0.1 -p 2022  "sudo /etc/init.d/docker restart && docker version"
}

docker-kill-last() {
    LAST_CONTAINER=$(docker ps -q -l)
    docker stop -t 0 $LAST_CONTAINER
    docker rm $LAST_CONTAINER
}

docker-kill-between() {
    if [ $# -lt 2 ] ; then
      echo please specify SINCE and BEFORE containers
      return
    fi
    docker stop -t 0 $(docker ps -q --since $1 --before $2)
    docker rm $(docker ps -q --since $1 --before $2)
}

docker-kill-before() {
  if [ $# -lt 1 ] ; then
    echo please specify BEFORE containers
    return
  fi

  docker stop -t 0 $(docker ps -q  --before $1)
  docker rm $(docker ps -q  --before $1)
}

docker-kill-since() {
  if [ $# -lt 1 ] ; then
    echo please specify SINCE containers
    return
  fi

  docker stop -t 0 $(docker ps -q  --since $1)
  docker rm $(docker ps -q  --since $1)
}

docker-play-mybase() {
    docker run -i -t mybase /bin/bash
    docker-kill-last
}

docker-logs(){
  sshpass -p tcuser ssh -p 2022 docker@127.0.0.1  tail -f /var/log/docker.log
}

drd() {
 docker  run -i -t -dns 127.0.0.1 --name $1 -h $1 dnsmasq /bin/bash
}

docker-rmi-unnamed() {
  docker rmi $(docker images | sed -n  "/<none>/ s/.*\([a-z0-9]\{12\}\).*/\1/p")
}

docker-commands() {
  //docker inspect $(docker ps -q)|jq ".[]| {name:.Name, ip: .NetworkSettings.IPAddress, cmd: .Config.Cmd, pointcut: .Config.Entrypoint}" -c
  docker inspect $(docker ps -q)|jq ".[]| [.NetworkSettings.IPAddress, .Name, .Config.Entrypoint[], .Config.Cmd[]]" -c
}

docker-commands-full() {
  docker inspect $(docker ps -q)|jq ".[]| {path: .Path, args: .Args, cmd: .Config.Cmd, pointcut: .Config.Entrypoint}" -c
}
