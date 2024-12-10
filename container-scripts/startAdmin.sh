#!/bin/bash -x

if [ -z ${ADMIN_PASSWORD+x} ]; then
  echo "Env var ADMIN_PASSWORD must be set! Exiting.."
  exit 1
fi

# This is the admin server so we will use different memory args
export USER_MEM_ARGS=${ADMIN_MEM_ARGS}

DOMAIN_HOME="/apps/oracle/${DOMAIN_NAME}"
. ${DOMAIN_HOME}/bin/setDomainEnv.sh

# Set the admin password to the one supplied via env var
java weblogic.security.utils.AdminAccount weblogic $ADMIN_PASSWORD $DOMAIN_HOME/security

# Set up the boot.properties file to allow automatic startup
mkdir -p ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security
echo "username=weblogic" > ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/boot.properties
echo "password=${ADMIN_PASSWORD}" >> ${DOMAIN_HOME}/servers/${ADMIN_NAME}/security/boot.properties

# Delete any existing realm data and add any users defined in env vars
${ORACLE_HOME}/container-scripts/createUsers.sh

# Generate and set the tuxedo configuration from the environment
cd ${DOMAIN_HOME}/config
${ORACLE_HOME}/container-scripts/generateTuxedoConfigFromEnv.sh > tuxedo-config.xml
sed -i -e '/@tuxedo-config@/{r tuxedo-config.xml' -e 'd' -e '}' config.xml

# Set the managed server startup arguments
sed -i "s/@start-args@/${START_ARGS}/g" config.xml

# Set the t3 channel external listen address and port prefix
sed -i "s/@t3-host-fqdn@/${T3_HOST_FQDN}/g" config.xml
sed -i "s/@t3-host-port-prefix@/${T3_HOST_PORT_PREFIX}/g" config.xml

# Set the Single Sign On configuration
sed -i "s/@sso-published-site-url@/${SSO_PUBLISHED_SITE_URL}/g" config.xml
sed -i "s/@sso-entity-id@/${SSO_ENTITY_ID}/g" config.xml
sed -i "s/@sso-chips-default-url@/${SSO_CHIPS_DEFAULT_URL}/g" config.xml

# Update the domain credentials to those provided by env var
${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${ORACLE_HOME}/container-scripts/set-credentials.py

# Set the jdbc connection strings and credentials
${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${ORACLE_HOME}/container-scripts/set-jdbc-details.py

# Prevent Derby from being started
export DERBY_FLAG=false

# Update the CLASSPATH of the Admin server to allow viewing of EF JMS messages and for the swadmin application
export CLASSPATH=${DOMAIN_HOME}/chipsconfig/jmstool.jar:${DOMAIN_HOME}/chipsconfig/chips-common.jar:${DOMAIN_HOME}/chipsconfig/log4j.jar:${DOMAIN_HOME}/chipsconfig/jdom.jar:${DOMAIN_HOME}/chipsconfig/ssoRMI.jar:${DOMAIN_HOME}/chipsconfig/aqapi12.jar:${DOMAIN_HOME}/chipsconfig:${CLASSPATH}

# Set the startup params of the Admin server
export JAVA_OPTIONS="${JAVA_OPTIONS} ${ADMIN_START_ARGS}"

# Set the env vars in the ServersBean.properties file for the swadmin application
cd ~/${DOMAIN_NAME}/chipsconfig
envsubst < ServersBean.properties.template > ServersBean.properties

${DOMAIN_HOME}/bin/startWebLogic.sh $*
