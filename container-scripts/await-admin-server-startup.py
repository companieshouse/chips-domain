###########################################################################
# Attempts to connect directly to a specified WL server and if a failure occurs
# it retries until either a connection is made or the timeout is exceeded
###########################################################################
#Functions
###########################################################################
def checkConnection(adminUsername, adminPassword, adminServerT3):
   try:
      connect(username=adminUsername,password=adminPassword,url=adminServerT3)
      return true 
   except:
      print 'checkConnection: Failed to connect to server ', adminServerT3
      return false
      

###########################################################################
# Main 
###########################################################################

adminServerT3 = 't3://wladmin:7001'
adminUsername = 'weblogic'
adminPassword = os.environ.get("ADMIN_PASSWORD")
timeout = 120


#Check if the server can be connected to
connected = checkConnection(adminUsername, adminPassword, adminServerT3)
if (connected):
   print 'Server is running'
   exit()


#Check progress of startup
sleepmilli=10000
waited = 0
while (not connected):

   if (waited >=timeout ):
      print 'Server startup timed out after %i seconds' % (waited)
      exit(exitcode=1) 

   Thread.sleep(sleepmilli)
   waited = waited + (sleepmilli/1000)
   connected = checkConnection(adminUsername, adminPassword, adminServerT3)
   print 'Connection status', connected
