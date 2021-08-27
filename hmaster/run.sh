#!/bin/bash

set -e

function addProperty() {
  local path=$1
  local name=$2
  local value=$3

  local entry="<property><name>$name</name><value>${value}</value></property>"
  local escapedEntry=$(echo $entry | sed 's/\//\\\//g')
  sed -i "/<\/configuration>/ s/.*/${escapedEntry}\n&/" $path
}

function configure() {
    local path=$1
    local module=$2
    local envPrefix=$3

    local var
    local value
    
    echo "Configuring $module"
    for c in `printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix=$envPrefix`; do 
        name=`echo ${c} | perl -pe 's/___/-/g; s/__/@/g; s/_/./g; s/@/_/g;'`
        var="${envPrefix}_${c}"
        value=${!var}
        echo " - Setting $name=$value"
        addProperty $path $name "$value"
    done
}

configure /etc/hbase/hbase-site.xml hbase HBASE_CONF

if [ "$MULTIHOMED_NETWORK" = "1" ]; then
    echo "Configuring for multihomed network"

    # HBASE
    addProperty /etc/hbase/hbase-site.xml hbase.cluster.distributed true
    addProperty /etc/hbase/hbase-site.xml hbase.zookeeper.quorum ${ZOOKEEPER_CLUSTER_IP}
    addProperty /etc/hbase/hbase-site.xml hbase.rootdir hdfs://${NAMENODE_CLUSTER_IP}:8020/hbase
    addProperty /etc/hbase/hbase-site.xml hbase.master.hostname ${MY_POD_IP}
    addProperty /etc/hbase/hbase-site.xml hbase.master.port 16000
    addProperty /etc/hbase/hbase-site.xml hbase.master.info.port 16010
    addProperty /etc/hbase/hbase-site.xml hbase.regionserver.port 16020
    addProperty /etc/hbase/hbase-site.xml hbase.regionserver.info.port 16030
    addProperty /etc/hbase/hbase-site.xml hbase.zookeeper.property.clientPort 2181
    addProperty /etc/hbase/hbase-site.xml hbase.zookeeper.property.dataDir /data
fi


function wait_for_it()
{
    local serviceport=$1
    local service=${serviceport%%:*}
    local port=${serviceport#*:}
    local retry_seconds=5
    local max_try=100
    let i=1

    nc -z $service $port
    result=$?

    until [ $result -eq 0 ]; do
      echo "[$i/$max_try] check for ${service}:${port}..."
      echo "[$i/$max_try] ${service}:${port} is not available yet"
      if (( $i == $max_try )); then
        echo "[$i/$max_try] ${service}:${port} is still not available; giving up after ${max_try} tries. :/"
        exit 1
      fi

      echo "[$i/$max_try] try in ${retry_seconds}s once again ..."
      let "i++"
      sleep $retry_seconds

      nc -z $service $port
      result=$?
    done
    echo "[$i/$max_try] $service:${port} is available."
}

for i in "${SERVICE_PRECONDITION[@]}"
do
    wait_for_it ${i}
done

/opt/hbase-$HBASE_VERSION/bin/hbase master start

exec jboss $@
