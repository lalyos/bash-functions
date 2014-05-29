#####################################
# curl -Lo /tmp/docker-functions http://j.mp/docker-functions && source /tmp/docker-functions
#####################################

alias dps='docker ps'
alias dpsa='docker ps -a'

docker-restart() {
    boot2docker ssh "sudo /etc/init.d/docker restart && docker version"
}

docker-ps() {
  #docker ps|sed "s/ \{3,\}/#/g"|cut -d '#' -f 1,2,7|sed "s/#/\t/g"
  docker inspect --format="{{.Name}} {{.NetworkSettings.IPAddress}} {{.Config.Image}} {{.Config.Entrypoint}} {{.Config.Cmd}}" $(docker ps -q)
}

docker-psa() {
  #docker ps|sed "s/ \{3,\}/#/g"|cut -d '#' -f 1,2,7|sed "s/#/\t/g"
  docker inspect --format="{{.Name}} {{.NetworkSettings.IPAddress}} {{.Config.Image}} {{.Config.Entrypoint}} {{.Config.Cmd}}" $(docker ps -qa)
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

docker-kill-all() {
  docker stop -t 0 $(docker ps -q)
  docker rm $(docker ps -qa)
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

docker-commands-full() {
  docker inspect $(docker ps -q)|jq ".[]| {path: .Path, args: .Args, cmd: .Config.Cmd, pointcut: .Config.Entrypoint}" -c
}
