
domain_name  = os.environ.get("DOMAIN_NAME", "wldomain")
admin_name  = os.environ.get("ADMIN_NAME", "wladmin")
admin_port   = int(os.environ.get("ADMIN_PORT", "7001"))
admin_pass   = os.environ.get("ADMIN_PASSWORD")
cluster_name = os.environ.get("CLUSTER_NAME", "wlcluster")
domain_path  = '/apps/oracle/%s' % domain_name

print('domain_name : [%s]' % domain_name);
print('admin_name : [%s]' % admin_name);
print('admin_port  : [%s]' % admin_port);
print('cluster_name: [%s]' % cluster_name);
print('domain_path : [%s]' % domain_path);

# Open default domain template
# ======================
readTemplate("/apps/oracle/wlserver/common/templates/wls/wls.jar")

set('Name', domain_name)
setOption('DomainName', domain_name)

# Configure the Administration Server and SSL port.
cd('/Servers/AdminServer')
cmo.setName(admin_name)
set('ListenAddress', 'wladmin')
set('ListenPort', admin_port)

# Define the password for 'weblogic' user
# =====================================
cd('/Security/%s/User/weblogic' % domain_name)
cmo.setPassword(admin_pass)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode', 'prod')

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
