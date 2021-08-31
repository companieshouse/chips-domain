
domain_name  = os.environ.get("DOMAIN_NAME", "wldomain")
admin_name  = os.environ.get("ADMIN_NAME", "wladmin")
admin_pass   = os.environ.get("ADMIN_PASSWORD")
domain_path  = '/apps/oracle/%s' % domain_name
domain_credential  = os.environ.get("DOMAIN_CREDENTIAL", "domain_credential")
ldap_credential  = os.environ.get("LDAP_CREDENTIAL", "ldap_credential")
ad_host  = os.environ.get("AD_HOST", "ad_host")
ad_port  = eval(os.environ.get("AD_PORT", "389"))
ad_principal  = os.environ.get("AD_PRINCIPAL", "ad_principal")
ad_credential  = os.environ.get("AD_CREDENTIAL", "ad_credential")
ad_user_base_dn  = os.environ.get("AD_USER_BASE_DN", "ad_user_base_dn")
ad_group_base_dn  = os.environ.get("AD_GROUP_BASE_DN", "ad_group_base_dn")

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

# Active Directory connection details and credentials
cd('/SecurityConfiguration/' + domain_name + '/Realms/myrealm/AuthenticationProviders/AD_LDAP')
set('GroupBaseDN', ad_group_base_dn)
set('UserBaseDN', ad_user_base_dn)
set('Host', ad_host)
set('Port', ad_port)
set('Principal', ad_principal)
set('CredentialEncrypted', encrypt(ad_credential, domain_path))

# Set the Embedded LDAP server credential
cd('/EmbeddedLDAP/'  + domain_name)
set('CredentialEncrypted', encrypt(ldap_credential, domain_path))

# Write Domain
# ============
updateDomain()
closeDomain()

# Exit WLST
# =========
exit()
