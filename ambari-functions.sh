alias ambari-reload-functions='. ~/apps/bin/ambari-functions.sh'
ambari-req-state() {
  LAST_REQ=$1
  curl -s -H "X-Requested-By: ambari" -u admin:admin http://$AMBARI_URL/api/v1/clusters/MySingleNodeCluster/requests/$LAST_REQ?fields=tasks/Tasks/* |jq ".tasks[].Tasks| [.command_detail, .status]" -c
}

ambari-errors() {
  ERR=$(curl -s -H "X-Requested-By: ambari" -u admin:admin "http://$AMBARI_URL/api/v1/clusters/MySingleNodeCluster/requests/$LAST_REQ?fields=tasks/Tasks/*&tasks/Tasks/status=FAILED"|jq ".tasks[].Tasks.stderr")
  echo -e $ERR
}

ambari-error() {
  curl -s -H "X-Requested-By: ambari" -u admin:admin "http://$AMBARI_URL/api/v1/clusters/MySingleNodeCluster/requests/$LAST_REQ?fields=tasks/Tasks/*&tasks/Tasks/status=FAILED"|jq "[.tasks[].Tasks| {command_detail , stdout, stderr}] " >/tmp/error
  NUM=$1
  echo =====
  cat /tmp/error |jq ".[$NUM].command_detail" -r
  echo =====
  STDOUT=$(cat /tmp/error |jq ".[$NUM].stdout")
  STDERR=$(cat /tmp/error |jq ".[$NUM].stderr")
  #echo ===== STD_OUT =======
  #echo -e $STDOUT
  echo ===== STD_ERR=======
  echo -e $STDERR
}

: <<EOF
while true; do
  clear
  LAST_REQ=$(curl -s -H "X-Requested-By: ambari" -u admin:admin http://$AMBARI_URL/api/v1/clusters/MySingleNodeCluster/requests|jq ".items[].Requests.id"|tail -1)
  curl -s -H "X-Requested-By: ambari" -u admin:admin http://$AMBARI_URL/api/v1/clusters/MySingleNodeCluster/requests/$LAST_REQ?fields=tasks/Tasks/* |jq ".tasks[].Tasks| [.command_detail, .status]" -c
  sleep 10
done
EOF
