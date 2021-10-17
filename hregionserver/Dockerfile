FROM fhirfactory/pegacorn-base-hbase:1.0.0

RUN export HBASE_MANAGES_ZK=false

HEALTHCHECK CMD curl -f http://localhost:16010/ || exit 1

ENV MULTIHOMED_NETWORK=1

# Add jboss user to HDFS
RUN addgroup pegacorn
RUN adduser jboss --no-create-home --disabled-password --gecos ""
RUN usermod -aG pegacorn jboss
RUN usermod -aG sudo jboss

COPY hbase-site.xml /etc/hbase/hbase-site.xml
COPY log4j.properties /opt/hbase-2.3.6/conf/log4j.properties
COPY run.sh /run.sh
RUN chmod +x /run.sh

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

EXPOSE 16020 16030

RUN chmod -R 777 /etc/hbase
RUN chown -R jboss:0 /etc/hbase
RUN chmod -R 777 /opt/hbase-2.3.6/logs
RUN chown -R jboss:0 /opt/hbase-2.3.6/logs

USER jboss

CMD ["/run.sh"]
