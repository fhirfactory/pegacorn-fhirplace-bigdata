FROM debian:buster

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    krb5-kdc \ 
    krb5-admin-server \ 
    nano \
    lsof \
    && rm -rf /var/lib/apt/lists/*

ENV KEYTAB_DIR=/etc/security/keytabs
ENV KRB_LOG_DIR=/var/log/kerberos

COPY kadm5.acl /etc/krb5kdc/kadm5.acl
COPY kdc.conf /etc/krb5kdc/kdc.conf
COPY krb5.conf /etc/krb5.conf
RUN chmod -R 777 /etc/krb5kdc

RUN mkdir -p /var/log/kerberos
RUN mkdir -p /etc/security/keytabs

COPY run.sh /run.sh
RUN chmod a+x /run.sh

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

EXPOSE 88 749

ENTRYPOINT ["/run.sh"]

CMD ["bash"]