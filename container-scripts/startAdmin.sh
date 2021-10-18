#!/bin/bash

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

# Generate and set the tuxedo configuration from the environment
cd ${DOMAIN_HOME}/config
${ORACLE_HOME}/container-scripts/generateTuxedoConfigFromEnv.sh > tuxedo-config.xml
sed -i -e '/@tuxedo-config@/{r tuxedo-config.xml' -e 'd' -e '}' config.xml

# Set the managed server startup arguments
sed -i "s/@start-args@/${START_ARGS}/g" config.xml

# Update the domain credentials to those provided by env var
${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${ORACLE_HOME}/container-scripts/set-credentials.py

# Set the jdbc connection strings and credentials
${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${ORACLE_HOME}/container-scripts/set-jdbc-details.py

# Prevent Derby from being started
export DERBY_FLAG=false

${DOMAIN_HOME}/bin/startWebLogic.sh $*
