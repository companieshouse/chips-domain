#!/bin/bash

DOMAIN_HOME="/apps/oracle/${DOMAIN_NAME}"
. ${DOMAIN_HOME}/bin/setDomainEnv.sh

env

if [[ ${AUTO_START_NODES} =~ ${HOSTNAME} ]]; then
  echo "This node (${HOSTNAME}) is configured to auto start, so now attempting to start it."
else
  echo "This node (${HOSTNAME}) is NOT configured to auto start, so skipping startup."
  exit
fi

echo "Awaiting startup of the admin server"
${ORACLE_HOME}/wlserver/common/bin/wlst.sh ${ORACLE_HOME}/container-scripts/await-admin-server-startup.py
if [ $? -eq 0 ]; then
  echo "Admin server is running, so starting managed server"

  ${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning ${ORACLE_HOME}/container-scripts/start-managed-server.py
else

  echo "Admin server is not running, or has not started within timeout"
fi

# Only start AppDynamics Java Agent script if files are available
if [ -f "/opt/appdynamics/AppServerAgent/startAppDynamics.sh" ]; then
    
  echo "Starting AppDynamics Java Agent startup script"
  /opt/appdynamics/AppServerAgent/startAppDynamics.sh &
  appDynamicsPID=$!
  sleep 5

  #check whether background process is still running
  count=$(ps -p ${appDynamicsPID} | grep -c  ${appDynamicsPID}) 

  if [[ $count -eq 1 ]]
  then 
    echo "AppDynamics Java Agent startup script now running in background"
  else 
    echo "AppDynamics Java Agent startup script startup failure"
  fi

else  
  echo "AppDynamics Java Agent startup script not available"
fi
