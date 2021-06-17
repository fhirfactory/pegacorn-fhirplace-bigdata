FROM fhirfactory/pegacorn-base-hadoop:1.0.0

HEALTHCHECK CMD curl -f http://localhost:9864/ || exit 1

ENV MULTIHOMED_NETWORK=1
ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
RUN mkdir -p /hadoop/dfs/data

COPY run.sh /run.sh
RUN chmod a+x /run.sh

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

EXPOSE 9864

CMD ["/run.sh"]
