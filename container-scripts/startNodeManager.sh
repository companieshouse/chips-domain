#!/bin/bash

if [ -z ${ADMIN_PASSWORD+x} ]; then
  echo "Env var ADMIN_PASSWORD must be set! Exiting.."
  exit 1
fi

DOMAIN_HOME="${ORACLE_HOME}/${DOMAIN_NAME}"
. ${DOMAIN_HOME}/bin/setDomainEnv.sh

# Restore USER_MEM_ARGS value as this is needed in the environment when starting node manager in order to pass on to managed server
export USER_MEM_ARGS=${MEM_ARGS}

# Update the nodemanager.properties to set the ListenAddress to the current hostname
sed -i 's/ListenAddress=localhost/ListenAddress='${HOSTNAME}'/g' ${DOMAIN_HOME}/nodemanager/nodemanager.properties

# Add the properties for the custom identity keystore to the nodemanager.properties
(
  echo "KeyStores=CustomIdentityAndJavaStandardTrust"
  echo "CustomIdentityKeyStoreFileName=${DOMAIN_HOME}/security/ch-weblogic-identity.p12"
  echo "CustomIdentityAlias=ch-weblogic-identity"
  echo "CustomIdentityPrivateKeyPassPhrase=${CH_WEBLOGIC_IDENTITY_PASSWORD}"
  echo "CustomIdentityKeyStorePassPhrase=${CH_WEBLOGIC_IDENTITY_PASSWORD}"
) >> ${DOMAIN_HOME}/nodemanager/nodemanager.properties

# Set the credentials for nodemanager
echo "username=weblogic" > ${DOMAIN_HOME}/config/nodemanager/nm_password.properties
echo "password=${ADMIN_PASSWORD}" >> ${DOMAIN_HOME}/config/nodemanager/nm_password.properties

# Update env var name for the nodemanager memory arguments
sed -i 's/{MEM_ARGS}/{NM_MEM_ARGS}/; s/^MEM_ARGS/NM_MEM_ARGS/' ${ORACLE_HOME}/wlserver/server/bin/startNodeManager.sh

${DOMAIN_HOME}/bin/startNodeManager.sh $*

