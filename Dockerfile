FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/ch-weblogic:1.5.0

# IMPORTANT - the default admin password should be supplied as a build arg
# e.g. --build-arg ADMIN_PASSWORD=notsecure123.  This password will be visible in the image
# so MUST later be reset to a secure value when starting the admin container.
ARG ADMIN_PASSWORD

ENV ORACLE_HOME=/apps/oracle \
    DOMAIN_NAME=chipsdomain \
    ADMIN_NAME=wladmin \
    ARTIFACTORY_BASE_URL=http://repository.aws.chdev.org:8081/artifactory

WORKDIR $ORACLE_HOME

# Copy over utility scripts for creating the domain, setting security and starting servers
COPY --chown=weblogic:weblogic container-scripts container-scripts/

# Initialise the domain using a standard template provided with WebLogic
RUN $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/create-domain.py 

# Copy across a custom config.xml, along with jdbc and jms configuration
COPY --chown=weblogic:weblogic config ${DOMAIN_NAME}/config/

# Copy across chipsconfig directory
COPY --chown=weblogic:weblogic chipsconfig ${DOMAIN_NAME}/chipsconfig/

# Download libs and ixbrl fonts from artifactory
RUN cd ${DOMAIN_NAME}/chipsconfig && \
    curl ${ARTIFACTORY_BASE_URL}/libs-release/antlr/antlr/2.7.6/antlr-2.7.6.jar -o antlr-2.7.6.jar && \
    curl ${ARTIFACTORY_BASE_URL}/libs-release/org/xhtmlrenderer/core-renderer/R5pre1patched/core-renderer-R5pre1patched.jar -o core-renderer.jar && \
    curl ${ARTIFACTORY_BASE_URL}/libs-release/log4j/log4j/1.2.14/log4j-1.2.14.jar -o log4j.jar && \
    curl ${ARTIFACTORY_BASE_URL}/local-ch-release/oracle/AQ/unknown/AQ-unknown.jar -o aqapi12.jar && \
    curl ${ARTIFACTORY_BASE_URL}/libs-release/com/lowagie/itext/2.0.8/itext-2.0.8.jar -o itext-2.0.8.jar && \
    curl ${ARTIFACTORY_BASE_URL}/libs-release/com/staffware/ssoRMI/11.4.1/ssoRMI-11.4.1.jar -o ssoRMI.jar && \
    cd .. && \
    curl ${ARTIFACTORY_BASE_URL}/local-ch-release/uk/gov/companieshouse/chips-ixbrl-fonts/1.0.0/chips-ixbrl-fonts-1.0.0.tar -o chips-ixbrl-fonts.tar && \
    tar -xvf chips-ixbrl-fonts.tar && rm chips-ixbrl-fonts.tar

# Set the credentials in the custom config.xml
RUN $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/set-credentials.py && \
    chmod 754 container-scripts/*.sh

# Download fop fonts and endorsed libs from artifactory and install into JRE
USER root
RUN cd ${JAVA_HOME}/jre/lib && \
    curl ${ARTIFACTORY_BASE_URL}/local-ch-release/uk/gov/companieshouse/chips-fop-fonts/1.0.0/chips-fop-fonts-1.0.0.tar -o chips-fop-fonts.tar && \
    tar -xvf chips-fop-fonts.tar && rm chips-fop-fonts.tar && \
    mkdir -p endorsed && cd endorsed && curl ${ARTIFACTORY_BASE_URL}/libs-release/xalan/xalan/2.7.0/xalan-2.7.0.jar -o xalan-2.7.0.jar

USER weblogic
CMD ["bash"]


