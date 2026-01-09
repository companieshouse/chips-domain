
domain_name  = os.environ.get("DOMAIN_NAME", "wldomain")
domain_path  = '/apps/oracle/%s' % domain_name
db_user_chipsDS  = os.environ.get("DB_USER_CHIPSDS", 'db_user_chipsds_missing')
db_password_chipsDS  = os.environ.get("DB_PASSWORD_CHIPSDS", 'db_password_chipsds_missing')
db_url_chipsDS  = os.environ.get("DB_URL_CHIPSDS", 'db_url_chipsds_missing')
db_user_staffDS  = os.environ.get("DB_USER_STAFFDS", 'db_user_staffds_missing')
db_password_staffDS  = os.environ.get("DB_PASSWORD_STAFFDS", 'db_password_staffds_missing')
db_url_staffDS  = os.environ.get("DB_URL_STAFFDS", 'db_url_staffds_missing')
db_client_machine_override = os.environ.get("APP_INSTANCE_NAME", 'APP_INSTANCE_NAME missing') + '-${servername}'

print('domain_name : [%s]' % domain_name);
print('domain_path : [%s]' % domain_path);
print('db_url_chipsDS : [%s]' % db_url_chipsDS);
print('db_url_staffDS : [%s]' % db_url_staffDS);
print('db_client_machine_override : [%s]' % db_client_machine_override);

# Open the domain
# ======================
readDomain(domain_path)

cd('/JDBCSystemResource/chipsDS/JdbcResource/chipsDS/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', encrypt(db_password_chipsDS, domain_path))
cmo.setUrl(db_url_chipsDS)

cd('/JDBCSystemResource/chipsDS/JdbcResource/chipsDS/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user')
cmo.setValue(db_user_chipsDS)

cd('/JDBCSystemResource/chipsBulkDS/JdbcResource/chipsBulkDS/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', encrypt(db_password_chipsDS, domain_path))
cmo.setUrl(db_url_chipsDS)

cd('/JDBCSystemResource/chipsBulkDS/JdbcResource/chipsBulkDS/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user')
cmo.setValue(db_user_chipsDS)

cd('/JDBCSystemResource/staffwareDs/JdbcResource/staffwareDs/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', encrypt(db_password_staffDS, domain_path))
cmo.setUrl(db_url_staffDS)

cd('/JDBCSystemResource/staffwareDs/JdbcResource/staffwareDs/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user')
cmo.setValue(db_user_staffDS)

## Override the client machine property to include the instance name
errorMessage='This error is ok. v$session.machine property already present - will update it.'

# chipsDS
cd('/JDBCSystemResource/chipsDS/JdbcResource/chipsDS/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0')
try:
  create('v$session.machine','Property')
except:
  print errorMessage

cd('Property/v$session.machine')
set('SysPropValue', db_client_machine_override)

# staffwareDs
cd('/JDBCSystemResource/staffwareDs/JdbcResource/staffwareDs/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0')
try:
  create('v$session.machine','Property')
except:
  print errorMessage

cd('Property/v$session.machine')
set('SysPropValue', db_client_machine_override)

# chipsBulkDS
cd('/JDBCSystemResource/chipsBulkDS/JdbcResource/chipsBulkDS/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0')
try:
  create('v$session.machine','Property')
except:
  print errorMessage

cd('Property/v$session.machine')
set('SysPropValue', db_client_machine_override)

# Write Domain
# ============
updateDomain()
closeDomain()

# Exit WLST
# =========
exit()
