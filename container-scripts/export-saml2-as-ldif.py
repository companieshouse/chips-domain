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
