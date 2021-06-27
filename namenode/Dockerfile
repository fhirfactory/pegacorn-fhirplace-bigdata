FROM fhirfactory/pegacorn-base-hadoop:1.0.0

HEALTHCHECK CMD curl -f http://localhost:9870/ || exit 1

ENV MULTIHOMED_NETWORK=1
ENV HDFS_CONF_dfs_namenode_name_dir=file:///hadoop/dfs/namenode

RUN mkdir -p /hadoop/dfs/namenode

COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Add jboss user to HDFS
RUN addgroup pegacorn
RUN adduser jboss --no-create-home --disabled-password --gecos ""
RUN usermod -aG pegacorn jboss

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

EXPOSE 8020 9000 9870

CMD ["/run.sh"]
