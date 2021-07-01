FROM fhirfactory/pegacorn-base-hadoop:1.0.0

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install apt-transport-https krb5-user jsvc

HEALTHCHECK CMD curl -f http://localhost:9864/ || exit 1

ENV MULTIHOMED_NETWORK=1
ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/datanode
ENV KEYTAB_DIR=/etc/security/keytabs

RUN mkdir -p /hadoop/dfs/datanode
RUN mkdir -p /etc/security/keytabs

COPY run.sh /run.sh
RUN chmod a+x /run.sh
# COPY root.hdfs.keytab /etc/security/keytabs/root.hdfs.keytab

# Kerberos configuration
COPY krb5.conf /etc/krb5.conf
COPY hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

EXPOSE 9864 9866 50010 50075

CMD ["/run.sh"]
