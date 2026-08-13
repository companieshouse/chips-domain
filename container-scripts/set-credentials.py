# Set the domain credentials
domain_name  = os.environ.get("DOMAIN_NAME", "wldomain")
admin_name  = os.environ.get("ADMIN_NAME", "wladmin")
admin_pass   = os.environ.get("ADMIN_PASSWORD")
domain_path  = '/apps/oracle/%s' % domain_name
domain_credential  = os.environ.get("DOMAIN_CREDENTIAL", "domain_credential")
ldap_credential  = os.environ.get("LDAP_CREDENTIAL", "ldap_credential")

print('domain_name : [%s]' % domain_name);
print('admin_name : [%s]' % admin_name);
print('domain_path : [%s]' % domain_path);

# Open the domain
# ======================
readDomain(domain_path)

# Set the domain credential
cd('/SecurityConfiguration/' + domain_name)
set('CredentialEncrypted', encrypt(domain_credential, domain_path))

# Set the Node Manager user name and password 
set('NodeManagerUsername', 'weblogic')
set('NodeManagerPasswordEncrypted', admin_pass)

# Set the Embedded LDAP server credential
cd('/EmbeddedLDAP/'  + domain_name)
set('CredentialEncrypted', encrypt(ldap_credential, domain_path))

# Write and close domain after final changes
updateDomain()
closeDomain()

# Exit WLST
exit()
