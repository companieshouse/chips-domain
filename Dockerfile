FROM 300288021642.dkr.ecr.eu-west-2.amazonaws.com/ch-weblogic:2.0.0

# IMPORTANT - the default admin password should be supplied as a build arg
# e.g. --build-arg ADMIN_PASSWORD=notsecure123.  This password will be visible in the image
# so MUST later be reset to a secure value when starting the admin container.
ARG ADMIN_PASSWORD

ENV ORACLE_HOME=/apps/oracle \
    DOMAIN_NAME=chipsdomain \
    ADMIN_NAME=wladmin

WORKDIR ${ORACLE_HOME}

# Copy over utility scripts for creating the domain, setting security and starting servers
COPY --chown=weblogic:weblogic container-scripts container-scripts/

# Initialise the domain using a standard template provided with WebLogic
RUN ${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/create-domain.py 

# Copy across a custom config.xml, along with jdbc and jms configuration
COPY --chown=weblogic:weblogic config ${DOMAIN_NAME}/config/

# Copy across chipsconfig directory
COPY --chown=weblogic:weblogic chipsconfig ${DOMAIN_NAME}/chipsconfig/

# Download libs and ixbrl fonts from artifactory
RUN --mount=type=secret,id=artifactory_secrets,uid=1000,target=/artifactory_secrets \
    source /artifactory_secrets && \
    ARTIFACTORY_BASE_URL="${ARTIFACTORY_URL}/virtual-release" && \
    cd ${DOMAIN_NAME}/chipsconfig && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/antlr/antlr/2.7.6/antlr-2.7.6.jar -o antlr-2.7.6.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/org/xhtmlrenderer/core-renderer/R5pre1patched/core-renderer-R5pre1patched.jar -o core-renderer.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/log4j/log4j/1.2.14/log4j-1.2.14.jar -o log4j.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/oracle/AQ/unknown/AQ-unknown.jar -o aqapi12.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/com/lowagie/itext/2.0.8/itext-2.0.8.jar -o itext-2.0.8.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/com/staffware/ssoRMI/11.4.1/ssoRMI-11.4.1.jar -o ssoRMI.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/org/jdom/jdom/1.1/jdom-1.1.jar -o jdom.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/uk/gov/companieshouse/jmstool/1.4.0/jmstool-1.4.0.jar -o jmstool.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/uk/gov/companieshouse/chips-common/1.183.0-rc1/chips-common-1.183.0-rc1.jar -o chips-common.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/uk/gov/companieshouse/weblogic-tux-hostname-patch/1.0.0/weblogic-tux-hostname-patch-1.0.0.jar -o weblogic-tux-hostname-patch-1.0.0.jar && \
    curl -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" ${ARTIFACTORY_BASE_URL}/xalan/xalan/2.7.0/xalan-2.7.0.jar -o xalan.jar

# Set the credentials in the custom config.xml
RUN ${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning container-scripts/set-credentials.py && \
    chmod 754 container-scripts/*.sh

# Modify the umask setting in the WebLogic start scripts
RUN sed -i 's/umask 027/umask 022/' ${DOMAIN_NAME}/bin/startWebLogic.sh && \
    sed -i 's/umask 027/umask 022/' ${ORACLE_HOME}/wlserver/server/bin/startNodeManager.sh

# Copy font archives into oracle home for later installation
COPY *-fonts.tar ${ORACLE_HOME}/

# Install ixbrl fonts
RUN cd ${DOMAIN_HOME} && \
    tar -xvf ${ORACLE_HOME}/chips-ixbrl-fonts.tar && rm ${ORACLE_HOME}/chips-ixbrl-fonts.tar

# Install fop fonts into JRE and OS
# OS font location is used by PDFBox and JRE location by FOP
USER root
RUN cd ${JAVA_HOME}/lib && \
    tar -xvf ${ORACLE_HOME}/chips-fop-fonts.tar && rm ${ORACLE_HOME}/chips-fop-fonts.tar && \
    ln -s ${JAVA_HOME}/lib/fonts /usr/share/fonts 

# Copy across csi web app and correct permissions of upload folder
COPY --chown=weblogic:weblogic csi ${DOMAIN_NAME}/upload/csi/
RUN chown weblogic:weblogic ${DOMAIN_NAME}/upload

# Install gettext to provide envsubst and freetype for FOP
RUN yum -y install gettext && \
    yum -y install freetype && \
    yum -y install fontconfig && \
    yum clean all && \
    rm -rf /var/cache/yum

USER weblogic

# Copy across swadmin web app and extract
COPY --chown=weblogic:weblogic swadmin-*.zip ${DOMAIN_NAME}/upload
RUN cd ${DOMAIN_NAME}/upload && \
     if [ -f swadmin-*.zip ]; then \
       unzip swadmin-*.zip && \
       rm swadmin-*.zip && \
       mv swadmin-*.war swadmin.war; \
     fi

# Install AppDynamics Java Agent and extract
COPY --chown=weblogic:weblogic AppServerAgent-1.8-*.zip /opt/appdynamics/AppServerAgent.zip    
RUN if [ -f /opt/appdynamics/AppServerAgent.zip ]; then \
      unzip /opt/appdynamics/AppServerAgent.zip -d /opt/appdynamics/AppServerAgent/  && \
      rm /opt/appdynamics/AppServerAgent.zip; \
    fi

# Copy across AppDynamics directory
COPY --chown=weblogic:weblogic appdynamics/* /opt/appdynamics/AppServerAgent/
RUN if [ -f /opt/appdynamics/AppServerAgent/startAppDynamics.sh ]; then \
      chmod 754 /opt/appdynamics/AppServerAgent/startAppDynamics.sh; \       
    fi

CMD ["bash"]
