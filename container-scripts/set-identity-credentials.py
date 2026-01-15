# Set the credentials used to access the custom identity keystore
domain_name  = os.environ.get("DOMAIN_NAME", "wldomain")
admin_name  = os.environ.get("ADMIN_NAME", "wladmin")
domain_path  = '/apps/oracle/%s' % domain_name
ch_weblogic_identity_password  = os.environ.get("CH_WEBLOGIC_IDENTITY_PASSWORD")

print('domain_name : [%s]' % domain_name);
print('admin_name : [%s]' % admin_name);
print('domain_path : [%s]' % domain_path);

# Open the domain
readDomain(domain_path)

# Configure Custom Identity Keystore and SSL credentials
def setIdentityAndSSLCredentials(server, encrypted_password):
    cd('/Server/' + server)
    set('CustomIdentityKeyStorePassPhraseEncrypted', encrypted_password)
    cd('SSL/' + server)
    set('ServerPrivateKeyPassPhraseEncrypted', encrypted_password)
    
encrypted_password = encrypt(ch_weblogic_identity_password, domain_path)
setIdentityAndSSLCredentials(admin_name, encrypted_password)
setIdentityAndSSLCredentials('wlserver1', encrypted_password)
setIdentityAndSSLCredentials('wlserver2', encrypted_password)
setIdentityAndSSLCredentials('wlserver3', encrypted_password)
setIdentityAndSSLCredentials('wlserver4', encrypted_password)

# Write and close domain after final changes
updateDomain()
closeDomain()

# Exit WLST
exit()
