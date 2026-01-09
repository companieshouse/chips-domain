#!/bin/bash
# Adds a custom identity keystore provided by the CH_WEBLOGIC_IDENTITY environment variable
# The variable should contain a base64 encoded PKCS12 keystore file
# The keystore file should contain the private key and certificate for the WebLogic server identity 
# under the alias 'ch-weblogic-identity'

KEYSTORE_PATH="/apps/oracle/${DOMAIN_NAME}/security/ch-weblogic-identity.p12"
echo -n ${CH_WEBLOGIC_IDENTITY} | base64 -d > ${KEYSTORE_PATH}
