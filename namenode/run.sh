#!/bin/bash

# Kerberos KDC server configuration
# Ref: https://github.com/dosvath/kerberos-containers/blob/master/kdc-server/init-script.sh

# kerberos client
sed -i "s/localhost/${MY_POD_NAME}/g" /etc/krb5.conf

# certificates
cp /etc/hadoop/ssl/namenode.crt /usr/local/share/ca-certificates
update-ca-certificates --verbose

echo "==== Creating realm ==============================================================="
echo "==================================================================================="
# TDL -- Use HELM env variables for passwords
MASTER_PASSWORD=Peg@corn
KADMIN_PRINCIPAL=root/admin
REALM=PEGACORN-FHIRPLACE-NAMENODE.SITE-A
KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM
# This command also starts the krb5-kdc and krb5-admin-server services
krb5_newrealm <<EOF
$MASTER_PASSWORD
$MASTER_PASSWORD
EOF
echo ""

echo "==================================================================================="
echo "==== Creating hdfs principal in the acl ======================================="
echo "==================================================================================="
echo "Adding $KADMIN_PRINCIPAL principal"
# kadmin.local -q "delete_principal -force K/M@PEGACORN-FHIRPLACE-NAMENODE.SITE-A"
echo ""
kadmin.local -q "addprinc -pw $MASTER_PASSWORD $KADMIN_PRINCIPAL_FULL"
echo ""

kadmin -p root/admin -w ${MASTER_PASSWORD} -q "addprinc -randkey jboss/admin@$REALM"
kadmin -p root/admin -w ${MASTER_PASSWORD} -q "xst -k root.hdfs.keytab jboss/admin"
# secure alpha datanode
kadmin -p root/admin -w ${MASTER_PASSWORD} -q "addprinc -randkey alpha/admin@$REALM"
kadmin -p root/admin -w ${MASTER_PASSWORD} -q "xst -k alpha.hdfs.keytab alpha/admin"

mv root.hdfs.keytab ${KEYTAB_DIR}
mv alpha.hdfs.keytab ${KEYTAB_DIR}
chmod 400 ${KEYTAB_DIR}/root.hdfs.keytab
chmod 400 ${KEYTAB_DIR}/alpha.hdfs.keytab

### Start entrypoint.sh
### https://github.com/big-data-europe/docker-hadoop/blob/master/base/entrypoint.sh
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

configure /etc/hadoop/core-site.xml core CORE_CONF
configure /etc/hadoop/hdfs-site.xml hdfs HDFS_CONF
configure /etc/hadoop/yarn-site.xml yarn YARN_CONF
configure /etc/hadoop/httpfs-site.xml httpfs HTTPFS_CONF
configure /etc/hadoop/kms-site.xml kms KMS_CONF
configure /etc/hadoop/mapred-site.xml mapred MAPRED_CONF

if [ "$MULTIHOMED_NETWORK" = "1" ]; then
    echo "Configuring for multihomed network"

    # CORE
    addProperty /etc/hadoop/core-site.xml fs.defaultFS hdfs://${MY_POD_NAME}:8020
    addProperty /etc/hadoop/core-site.xml hadoop.security.authentication kerberos
    addProperty /etc/hadoop/core-site.xml hadoop.security.authorization true
    addProperty /etc/hadoop/core-site.xml hadoop.security.auth_to_local DEFAULT
    addProperty /etc/hadoop/core-site.xml hadoop.ssl.server.conf ssl-server.xml
    addProperty /etc/hadoop/core-site.xml hadoop.ssl.client.conf ssl-client.xml
    addProperty /etc/hadoop/core-site.xml hadoop.ssl.require.client.cert false
    addProperty /etc/hadoop/core-site.xml hadoop.rpc.protection privacy
    addProperty /etc/hadoop/core-site.xml hadoop.ssl.keystores.factory.class org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory
    

    # HDFS
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.rpc-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.servicerpc-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.http-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.https-bind-host 0.0.0.0
    addProperty /etc/hadoop/hdfs-site.xml dfs.https.port 50470
    addProperty /etc/hadoop/hdfs-site.xml dfs.https.address ${MY_POD_NAME}:50470
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.https-address 0.0.0.0:9871
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.datanode.registration.ip-hostname-check false
    addProperty /etc/hadoop/hdfs-site.xml dfs.client.use.datanode.hostname true
    addProperty /etc/hadoop/hdfs-site.xml dfs.datanode.use.datanode.hostname true
    addProperty /etc/hadoop/hdfs-site.xml dfs.permissions.superusergroup pegacorn
    addProperty /etc/hadoop/hdfs-site.xml dfs.replication 2
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.keytab.file ${KEYTAB_DIR}/root.hdfs.keytab
    addProperty /etc/hadoop/hdfs-site.xml dfs.datanode.keytab.file ${KEYTAB_DIR}/alpha.hdfs.keytab
    addProperty /etc/hadoop/hdfs-site.xml dfs.namenode.kerberos.principal jboss/admin@${REALM}
    addProperty /etc/hadoop/hdfs-site.xml dfs.block.access.token.enable true
    addProperty /etc/hadoop/hdfs-site.xml dfs.https.server.keystore.resource ssl-server.xml
    addProperty /etc/hadoop/hdfs-site.xml dfs.client.https.keystore.resource ssl-client.xml
    addProperty /etc/hadoop/hdfs-site.xml dfs.http.policy HTTPS_ONLY

    # YARN ---- Not required in current release <configured for future use>
    addProperty /etc/hadoop/yarn-site.xml yarn.acl.enable 0
    addProperty /etc/hadoop/yarn-site.xml yarn.resourcemanager.hostname ${MY_POD_IP}
    addProperty /etc/hadoop/yarn-site.xml yarn.nodemanager.aux-services mapreduce_shuffle
    addProperty /etc/hadoop/yarn-site.xml yarn.nodemanager.resource.memory-mb 3072
    addProperty /etc/hadoop/yarn-site.xml yarn.scheduler.maximum-allocation-mb 3072
    addProperty /etc/hadoop/yarn-site.xml yarn.scheduler.minimum-allocation-mb 512
    addProperty /etc/hadoop/yarn-site.xml yarn.resourcemanager.bind-host 0.0.0.0
    addProperty /etc/hadoop/yarn-site.xml yarn.nodemanager.bind-host 0.0.0.0
    addProperty /etc/hadoop/yarn-site.xml yarn.timeline-service.bind-host 0.0.0.0

    # MAPRED ---- Not required in current release <configured for future use>
    addProperty /etc/hadoop/mapred-site.xml mapreduce.framework.name yarn
    addProperty /etc/hadoop/mapred-site.xml yarn.app.mapreduce.am.env HADOOP_MAPRED_HOME=$HADOOP_HOME
    addProperty /etc/hadoop/mapred-site.xml mapreduce.map.env HADOOP_MAPRED_HOME=$HADOOP_HOME
    addProperty /etc/hadoop/mapred-site.xml mapreduce.reduce.env HADOOP_MAPRED_HOME=$HADOOP_HOME
    addProperty /etc/hadoop/mapred-site.xml mapreduce.jobtracker.address 8021
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

for i in ${SERVICE_PRECONDITION[@]}
do
    wait_for_it ${i}
done

### End entrypoint.sh

namedir=`echo $HDFS_CONF_dfs_namenode_name_dir | perl -pe 's#file://##'`
if [ ! -d $namedir ]; then
  echo "Namenode name directory not found: $namedir"
  exit 2
fi

if [ -z "$CLUSTER_NAME" ]; then
  echo "Cluster name not specified"
  exit 2
fi

echo "remove lost+found from $namedir"
rm -r $namedir/lost+found

if [ "`ls -A $namedir`" == "" ]; then
  echo "Formatting namenode name directory: $namedir"
  $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR namenode -format $CLUSTER_NAME
fi

$HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR namenode

exec $@