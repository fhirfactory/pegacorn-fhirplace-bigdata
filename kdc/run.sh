#!/bin/bash

set -e

# Kerberos KDC server configuration
# Ref: https://github.com/dosvath/kerberos-containers/blob/master/kdc-server/init-script.sh

echo ${MY_HOST_IP} ${MY_NODE_NAME} >> /etc/hosts
sed -i "s/realmValue/${REALM}/g" /etc/krb5kdc/kdc.conf
sed -i "s/realmValue/${REALM}/g" /etc/krb5.conf
sed -i "s/kdcserver/${MY_NODE_NAME}:88/g" /etc/krb5.conf
sed -i "s/kdcadmin/${MY_NODE_NAME}:749/g" /etc/krb5.conf

echo "==== Creating realm ==============================================================="
echo "==================================================================================="
KADMIN_PRINCIPAL=root/admin
KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM
# This command also starts the krb5-kdc and krb5-admin-server services
krb5_newrealm <<EOF
$KDC_PASSWORD
$KDC_PASSWORD
EOF
echo ""

echo "==================================================================================="
echo "======== Creating hdfs principal in the acl ======================================="
echo "==================================================================================="
echo "Adding $KADMIN_PRINCIPAL principal"
echo ""
kadmin.local -q "addprinc -pw $KDC_PASSWORD $KADMIN_PRINCIPAL_FULL"
echo ""

echo "========== Writing keytab to ${KEYTAB_DIR} ========== "
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "addprinc -randkey nn/pegacorn-fhirplace-namenode-0.pegacorn-fhirplace-namenode.site-a.svc.cluster.local@${REALM}"
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "xst -k hdfs.keytab nn/pegacorn-fhirplace-namenode-0.pegacorn-fhirplace-namenode.site-a.svc.cluster.local"
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "addprinc -randkey jboss/pegacorn-fhirplace-bigdata-api.site-a@${REALM}"
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "xst -k jboss.hdfs.keytab jboss/pegacorn-fhirplace-bigdata-api.site-a"
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "addprinc -randkey HTTP/pegacorn-fhirplace-namenode-0.pegacorn-fhirplace-namenode.site-a.svc.cluster.local@${REALM}"
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "xst -k http.hdfs.keytab HTTP/pegacorn-fhirplace-namenode-0.pegacorn-fhirplace-namenode.site-a.svc.cluster.local"

# secure datanodes
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "addprinc -randkey dn/pegacorn-fhirplace-datanode-alpha.site-a@$REALM"
kadmin -p ${KADMIN_PRINCIPAL} -w ${KDC_PASSWORD} -q "xst -k hdfs.keytab dn/pegacorn-fhirplace-datanode-alpha.site-a"
echo ""

echo "==================================================================================="
echo "================ Moving keytab files to mount location ============================"
echo ""
mv hdfs.keytab ${KEYTAB_DIR}
mv jboss.hdfs.keytab ${KEYTAB_DIR}
mv http.hdfs.keytab ${KEYTAB_DIR}
ls -lah ${KEYTAB_DIR}

echo "==================================================================================="
echo "========== Merging of the Keytab files with HTTP Keytab file ======================"
echo ""
printf "%b" "read_kt ${KEYTAB_DIR}/hdfs.keytab\nread_kt ${KEYTAB_DIR}/http.hdfs.keytab\nwrite_kt ${KEYTAB_DIR}/merged-krb5.keytab\nquit" | ktutil
printf "%b" "read_kt ${KEYTAB_DIR}/hdfs.keytab\nread_kt ${KEYTAB_DIR}/jboss.hdfs.keytab\nwrite_kt ${KEYTAB_DIR}/hbase-krb5.keytab\nquit" | ktutil
printf "%b" "read_kt ${KEYTAB_DIR}/merged-krb5.keytab\nlist" | ktutil
printf "%b" "read_kt ${KEYTAB_DIR}/hbase-krb5.keytab\nlist" | ktutil

echo "==================================================================================="
echo "========== Changing permissions on Keytab files ======================"
echo ""
chmod 444 ${KEYTAB_DIR}/hdfs.keytab
chmod 444 ${KEYTAB_DIR}/merged-krb5.keytab
chmod 444 ${KEYTAB_DIR}/http.hdfs.keytab
chmod 777 ${KEYTAB_DIR}/hbase-krb5.keytab
ls -lah ${KEYTAB_DIR}
echo ""

echo "KDC Server Configuration Successful"

ping -i 3600 ${MY_HOST_IP} >> ${KEYTAB_DIR}/keepalive.log

exec "$@"