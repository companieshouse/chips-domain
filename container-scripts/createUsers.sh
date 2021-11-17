#!/bin/bash

# This script deletes any existing realm (LDAP) data that may exist for the wladmin server
# and then adds the required entries into the DefaultAuthenticatorInit LDIF file for any users that 
# are specified in environment variables. LDIF=LDAP Data Interchange Format - see https://datatracker.ietf.org/doc/html/rfc2849.
# The variable names are of the form REALM_USER_#, where # is a suffix to ensure each variable has a unique name.
# The value of the variable is the username, then a pipe separator, then the password. E.g.:
# REALM_USER_0=username|password


DOMAIN_HOME="/apps/oracle/${DOMAIN_NAME}"
LDIF_FILE=$DOMAIN_HOME/security/DefaultAuthenticatorInit.ldift

echouser() {
  echo "dn: uid=$1,ou=people,ou=@realm@,dc=@domain@"
  echo "description: $1"
  echo "objectclass: inetOrgPerson"
  echo "objectclass: organizationalPerson"
  echo "objectclass: person"
  echo "objectclass: top"
  echo "cn: $1"
  echo "sn: $1"
  echo "userpassword: $2"
  echo "uid: $1"
  echo "objectclass: wlsUser"
  echo 
}

# Remove any existing realm data so that it is reloaded from the LDIF files
rm -rf ${DOMAIN_HOME}/servers/wladmin/data/ldap

# Loop through all REALM_USER env vars and add the user to the DefaultAuthenticatorInit LDIF file
REALM_USERS=$(env | sort | grep "^REALM_USER_")
for REALM_USER in ${REALM_USERS};
do
  while IFS='|' read -r REALM_USER_NAME REALM_USER_PASSWORD;
  do
    echouser ${REALM_USER_NAME} ${REALM_USER_PASSWORD} >> ${LDIF_FILE}
  done < <(echo ${REALM_USER##*=})
done
