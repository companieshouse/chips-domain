
domain_name  = os.environ.get("DOMAIN_NAME", "wldomain")
domain_path  = '/apps/oracle/%s' % domain_name
db_user_chipsDS  = os.environ.get("DB_USER_CHIPSDS", 'db_user_chipsds_missing')
db_password_chipsDS  = os.environ.get("DB_PASSWORD_CHIPSDS", 'db_password_chipsds_missing')
db_url_chipsDS  = os.environ.get("DB_URL_CHIPSDS", 'db_url_chipsds_missing')
db_user_staffDS  = os.environ.get("DB_USER_STAFFDS", 'db_user_staffds_missing')
db_password_staffDS  = os.environ.get("DB_PASSWORD_STAFFDS", 'db_password_staffds_missing')
db_url_staffDS  = os.environ.get("DB_URL_STAFFDS", 'db_url_staffds_missing')

print('domain_name : [%s]' % domain_name);
print('domain_path : [%s]' % domain_path);
print('db_url_chipsDS : [%s]' % db_url_chipsDS);
print('db_url_staffDS : [%s]' % db_url_staffDS);

# Open the domain
# ======================
readDomain(domain_path)

cd('/JDBCSystemResource/chipsDS/JdbcResource/chipsDS/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', db_password_chipsDS)
cmo.setUrl(db_url_chipsDS)

cd('/JDBCSystemResource/chipsDS/JdbcResource/chipsDS/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user')
cmo.setValue(db_user_chipsDS)

cd('/JDBCSystemResource/chipsBulkDS/JdbcResource/chipsBulkDS/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', db_password_chipsDS)
cmo.setUrl(db_url_chipsDS)

cd('/JDBCSystemResource/chipsBulkDS/JdbcResource/chipsBulkDS/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user')
cmo.setValue(db_user_chipsDS)

cd('/JDBCSystemResource/staffwareDs/JdbcResource/staffwareDs/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', db_password_staffDS)
cmo.setUrl(db_url_staffDS)

cd('/JDBCSystemResource/staffwareDs/JdbcResource/staffwareDs/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user')
cmo.setValue(db_user_staffDS)

# Write Domain
# ============
updateDomain()
closeDomain()

# Exit WLST
# =========
exit()
