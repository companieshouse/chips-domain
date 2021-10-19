#!/bin/bash

# This script generates the xml for the tuxedo section of the WebLogic config.xml, and expects the following environment variables to be set (this is an example)

# Weblogic instance count
# A WTCServer resource will be created for each instance, with the 1st targeted at wlserver1, and 2nd at wlserver2 etc
#export TUX_WL_NODE_COUNT=4

# Local access points
# <unique name>=<local ap name>|<local port>
# If TUX_WL_NODE_COUNT is greater than 1 then the <local ap name> will be suffixed with an index, starting at 1, and all config
# will be replicated for each WL instance. Otherwise it will be used without a suffix.
#export TUX_LOCAL_AP_0="CHIPS_EF_BATCH0_TUX|7075"

# Remote access points
# <unique name>=<remote ap local name>|<remote ap remote name>|<local ap name>|<connection policy>|<remote address>
#export TUX_REMOTE_AP_0="CHIPS_TUX_TO_CHIPS|CHIPS_TUX_TO_CHIPS|CHIPS_EF_BATCH0_TUX|INCOMING_ONLY|//1.1.1.1:1"
#export TUX_REMOTE_AP_1="CHIPS_TUX_FROM_CHIPS0|CHIPS_TUX_FROM_CHIPS0|CHIPS_EF_BATCH0_TUX|ON_STARTUP|//chips-tux-proxy0.development.heritage.aws.internal:21076"
#export TUX_REMOTE_AP_2="CHIPS_TUX_FROM_CHIPS1|CHIPS_TUX_FROM_CHIPS1|CHIPS_EF_BATCH0_TUX|ON_STARTUP|//chips-tux-proxy1.development.heritage.aws.internal:21076"

# Exported services
# <unique name>=<local service name>|<remote service name>|<local ap name>|<ejb>
#export TUX_EXPORT_0="ONLINE_SERVICES|ONLINE_SERVICES|CHIPS_EF_BATCH0_TUX|tuxedo.services.OnlineServiceHome"
#export TUX_EXPORT_1="CHIPSELEC|CHIPSELEC|CHIPS_EF_BATCH0_TUX|tuxedo.services.EfilingServiceHome"
#export TUX_EXPORT_2="CHIPS_READ|CHIPS_READ|CHIPS_EF_BATCH0_TUX|tuxedo.services.ChipsReadFunctionHome"
#export TUX_EXPORT_3="STEM_READ_FUNC1|STEM_READ_FUNC1|CHIPS_EF_BATCH0_TUX|tuxedo.services.ChipsReadFunctionHome"
#export TUX_EXPORT_4="STEM_READ_FUNC2|STEM_READ_FUNC2|CHIPS_EF_BATCH0_TUX|tuxedo.services.ChipsReadFunctionHome"
#export TUX_EXPORT_5="STEM_READ_FUNC3|STEM_READ_FUNC3|CHIPS_EF_BATCH0_TUX|tuxedo.services.ChipsReadFunctionHome"
#export TUX_EXPORT_6="STEM_READ_FUNC4|STEM_READ_FUNC4|CHIPS_EF_BATCH0_TUX|tuxedo.services.ChipsReadFunctionHome"
#export TUX_EXPORT_7="STEM_READ_FUNC5|STEM_READ_FUNC5|CHIPS_EF_BATCH0_TUX|tuxedo.services.ChipsReadFunctionHome"

# Imported services
# <unique name>=<local service name>|<remote service name>|<local ap name>|<remote ap names>
#export TUX_IMPORT_0="CABS_Ord|CABS_Ord|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS0,CHIPS_TUX_FROM_CHIPS1"
#export TUX_IMPORT_1="CABS_Ord|CABS_Ord|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS1,CHIPS_TUX_FROM_CHIPS0"
#export TUX_IMPORT_2="IMAGE_ORD|IMAGE_ORD|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS0,CHIPS_TUX_FROM_CHIPS1"
#export TUX_IMPORT_3="IMAGE_ORD|IMAGE_ORD|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS1,CHIPS_TUX_FROM_CHIPS0"
#export TUX_IMPORT_4="ewfFormResponse|ewfFormResponse|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS0,CHIPS_TUX_FROM_CHIPS1"
#export TUX_IMPORT_5="ewfFormResponse|ewfFormResponse|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS1,CHIPS_TUX_FROM_CHIPS0"
#export TUX_IMPORT_6="xmlFormResponse|xmlFormResponse|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS0,CHIPS_TUX_FROM_CHIPS1"
#export TUX_IMPORT_7="xmlFormResponse|xmlFormResponse|CHIPS_EF_BATCH0_TUX|CHIPS_TUX_FROM_CHIPS1,CHIPS_TUX_FROM_CHIPS0"

# Exit without error if TUX_WL_NODE_COUNT is not set
if [ -z ${TUX_WL_NODE_COUNT+x} ]; then
  exit 0
fi

# Create a WTCServer for each WL node
for WTC_NODE_INDEX in $(seq ${TUX_WL_NODE_COUNT});
do
  echo "  <wtc-server>"
  echo "    <name>WTCServer${WTC_NODE_INDEX}</name>"
  echo "    <target>wlserver${WTC_NODE_INDEX}</target>"
  
  # Create the local access points for this wtc-server
  LOCAL_APS=$(env | sort | grep "^TUX_LOCAL_AP_")
  for LOCAL_AP in ${LOCAL_APS};
  do
    while IFS='|' read -r LOCAL_AP_NAME LOCAL_AP_PORT;
    do

      if [ ${TUX_WL_NODE_COUNT} -gt 1 ]; then
        LOCAL_AP_NAME="${LOCAL_AP_NAME}${WTC_NODE_INDEX}"
      fi
      
      echo "    <wtc-local-tux-dom>"
      echo "      <name>${LOCAL_AP_NAME}</name>"
      echo "      <access-point>${LOCAL_AP_NAME}</access-point>"
      echo "      <access-point-id>${LOCAL_AP_NAME}</access-point-id>"
      echo "      <nw-addr>//wlserver${WTC_NODE_INDEX}:${LOCAL_AP_PORT}</nw-addr>"
      echo "    </wtc-local-tux-dom>"
    done < <(echo ${LOCAL_AP##*=})
  done

  # Create the remote access points
  REMOTE_APS=$(env | sort | grep "^TUX_REMOTE_AP_")
  for REMOTE_AP in ${REMOTE_APS};
  do
    while IFS='|' read -r REMOTE_AP_LOCAL_NAME REMOTE_AP_REMOTE_NAME LOCAL_AP_NAME CONN_POLICY ADDRESS;
    do

      if [ ${TUX_WL_NODE_COUNT} -gt 1 ]; then
        LOCAL_AP_NAME="${LOCAL_AP_NAME}${WTC_NODE_INDEX}"
      fi
    
      echo "    <wtc-remote-tux-dom>"
      echo "      <name>${REMOTE_AP_LOCAL_NAME}</name>"
      echo "      <access-point>${REMOTE_AP_LOCAL_NAME}</access-point>"
      echo "      <access-point-id>${REMOTE_AP_REMOTE_NAME}</access-point-id>"
      echo "      <connection-policy>${CONN_POLICY}</connection-policy>"
      echo "      <local-access-point>${LOCAL_AP_NAME}</local-access-point>"
      echo "      <nw-addr>${ADDRESS}</nw-addr>"
      echo "    </wtc-remote-tux-dom>"
    done < <(echo ${REMOTE_AP##*=})
  done

  # Create the exported services
  SERVICE_COUNT=0
  TUX_EXPORTS=$(env | sort | grep "^TUX_EXPORT_")
  for TUX_EXPORT in ${TUX_EXPORTS};
  do
    while IFS='|' read -r LOCAL_SERVICE REMOTE_SERVICE LOCAL_AP_NAME EJB;
    do
      if [ ${TUX_WL_NODE_COUNT} -gt 1 ]; then
        LOCAL_AP_NAME="${LOCAL_AP_NAME}${WTC_NODE_INDEX}"
      fi

      echo "    <wtc-export>"
      echo "      <name>WTCExportedService-${SERVICE_COUNT}</name>"
      echo "      <resource-name>${LOCAL_SERVICE}</resource-name>"
      echo "      <local-access-point>${LOCAL_AP_NAME}</local-access-point>"
      echo "      <ejb-name>${EJB}</ejb-name>"
      echo "      <remote-name>${REMOTE_SERVICE}</remote-name>"
      echo "    </wtc-export>"

      SERVICE_COUNT=$((SERVICE_COUNT+1))
    done < <(echo ${TUX_EXPORT##*=})
  done

  # Create the imported services
  SERVICE_COUNT=0
  TUX_IMPORTS=$(env | sort | grep "^TUX_IMPORT_")
  for TUX_IMPORT in ${TUX_IMPORTS};
  do
    while IFS='|' read -r LOCAL_SERVICE REMOTE_SERVICE LOCAL_AP_NAME REMOTE_ACCESS_POINTS;
    do
      if [ ${TUX_WL_NODE_COUNT} -gt 1 ]; then
        LOCAL_AP_NAME="${LOCAL_AP_NAME}${WTC_NODE_INDEX}"
      fi

      echo "    <wtc-import>"
      echo "      <name>WTCImportedService-${SERVICE_COUNT}</name>"
      echo "      <resource-name>${LOCAL_SERVICE}</resource-name>"
      echo "      <local-access-point>${LOCAL_AP_NAME}</local-access-point>"
      echo "      <remote-access-point-list>${REMOTE_ACCESS_POINTS}</remote-access-point-list>"
      echo "      <remote-name>${REMOTE_SERVICE}</remote-name>"
      echo "    </wtc-import>"

      SERVICE_COUNT=$((SERVICE_COUNT+1))
    done < <(echo ${TUX_IMPORT##*=})
  done

  echo "  </wtc-server>"

done

