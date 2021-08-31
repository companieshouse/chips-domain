################################################################
# Starts a specified WL managed server using the admin server
# The Admin server must be running
################################################################
#Functions
################################################################
def getServerStatus(svrName):
   slrBean = cmo.lookupServerLifeCycleRuntime(svrName)
   return slrBean.getState()

adminServerT3 = 't3://wladmin:7001'
adminUsername = 'weblogic'
adminPassword = os.environ.get("ADMIN_PASSWORD")
srvName = os.environ.get("HOSTNAME")

#Connect to admin server 
connect(username=adminUsername, password=adminPassword, url=adminServerT3)

domainRuntime()

#Check if the server is already running
serverStatus = getServerStatus(srvName)
if (serverStatus == 'RUNNING'):
   print 'Server is already running'
   exit()


#Start the server async
start(srvName,'Server',block='false')
