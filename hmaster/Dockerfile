FROM fhirfactory/pegacorn-base-hbase:1.0.0

RUN export HBASE_MANAGES_ZK=false

HEALTHCHECK CMD curl -f http://localhost:16010/ || exit 1

ENV MULTIHOMED_NETWORK=1

# Add jboss user to Sudo
RUN adduser jboss --no-create-home --disabled-password --gecos ""
RUN usermod -aG sudo jboss

COPY hbase-site.xml /etc/hbase/hbase-site.xml
COPY run.sh /run.sh
RUN chmod +x /run.sh

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

EXPOSE 16000 16010

CMD ["/run.sh"]
