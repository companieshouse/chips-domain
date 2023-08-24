# This script is intended to be run manually, after IDP metadata has been manually imported
# into the Weblogic security realm.  The script exports all data, in LDIF format, 
# from the SAML2 Identity Assertion Provider named "SAML_IA".
# The output will be placed in /var/tmp/SAML_IA.ldif
# That LDIF file can then be used to provide initial realm data when the domain is started, by
# adding the data to a file bind mounted into the wladmin container as 
# /apps/oracle/chipsdomain/security/SAML2IdentityAsserterInit.ldift
#
# The script can be run inside the wladmin container, as the weblogic user, with:
# ${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${ORACLE_HOME}/container-scripts/export-saml2-as-ldif.py

# Load environment variables
domain_name = os.environ.get("DOMAIN_NAME", "wldomain")
admin_name = os.environ.get("ADMIN_NAME", "wladmin")
admin_pass = os.environ.get("ADMIN_PASSWORD")

# Connect to the RUNNING admin server
connect('weblogic', admin_pass, 't3://' + admin_name + ':7001')

# Change location to the SAML2 Identity Assertion Provider path 
cd ('SecurityConfiguration/' + domain_name + '/Realms/myrealm/AuthenticationProviders/SAML_IA')

# Export all data as LDIF format, so that it can be imported as default data later on
cmo.exportData('LDIF Template', '/var/tmp/SAML_IA.ldif', Properties())

# Exit WLST
# =========
exit()
