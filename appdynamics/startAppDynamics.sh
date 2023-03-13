#!/bin/bash
#
# Script to support dynamic attachment of an AppDynamics Java Agent to a CHIPS
# managed server that is running within a Docker container.
#
# The script is intended to be invoked upon the start of the 
# CHIPS managed server instance within the Docker container
# and run continuosly thereafter. The script assumes there will only ever be one 
# instance of a CHIPS managed server process running in the container.
# 
# The script detects the presence of the new CHIPS managed server process
# and dynamically attaches the AppDynamics Java Agent. 
# 
# Given that the AppDynamics Java Agent has not already been started
# for the CHIPS managed server instance, then the AppDynamics Java Agent is attached.
# 
# The script guards against attempts to re-attach an AppDynamics Java Agent
# to the CHIPS managed server process.
# 
# A delay is used between JVM detection and attachment. This is intended
# to allow time for the CHIPS application to be started and prevent
# any application specific classpath issues from impacting 
# agent instrumentation.
#
# In the event of a JVM crash of the CHIPS managed server process and the
# subsequent start of a new CHIPS managed server JVM process being started, 
# the script ensures that the AppDynamics Java Agent is automatically re-attached 
# to the new server JVM process (even if the PID assigned to the new server
# JVM process is same as that used before crash).
#
# Dynamic attachment allows for the installation of the AppDynamics Java Agent 
# without a JVM restart. 
#
# The benefits of dynamic attachment are:
#   - adopts workaround for historic issues encountered with CHIPS classpath 
#     that, otherwise, block the successful start of the Java agent at JVM start time
#   - allows the server JVM to be started/be usable, more quickly
#     upon a JVM restart (as delays code instrumentation)
# 
# The downsides of dynamic attachment are:
#   - can be brief period of application use without AppDynamics monitoring
#   - some temporary agent overhead is encountered at attachment time. 
#     The application performance will degrade when the agent perfoms the class
#     introspection needed to instrument the application, then return to 
#     normal operating level upon completion.
#   - should not be done if attaching the agent to a pre-instrumented environment
#
# By default, no AppDynamics Java Agent monitoring is enabled. 
#
# To enable monitoring requires some configuration via environment variables. The environment
# being monitored must also be either production or staging.
#
# The environment variables are:
#
# ** Required:
# 
# APPDYNAMICS_CONTROLLER_HOST_NAME: The hostname or the IP address of the AppDynamics Controller
#
# APPDYNAMICS_CONTROLLER_PORT: The HTTP(S) port of the AppDynamics Controller
#
# APPDYNAMICS_CONTROLLER_SSL_ENABLED: If true, specifies that the agent should use SSL (HTTPS) to connect to the Controller
#
# APPDYNAMICS_AGENT_APPLICATION_NAME: The name of the logical business application that this JVM node belongs to
#
# APPDYNAMICS_AGENT_TIER_NAME: The name of the tier that this JVM node belongs to
#
# APPDYNAMICS_AGENT_ACCOUNT_NAME: The account name used to authenticate with the Controller.
#
# APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY: The account access key used to authenticate with the Controller. 
#
# APPDYNAMICS_AGENT_HOME: Specifies location to place runtime agent related data. 
# The directory should be different to the directory housing the actual java agent. 
# By default, this directory will store:
# - details of Weblogic server JVM processes attached to AppDynamics java agent
# - the runtime directory for all runtime files (logs and transaction configuration) for agent nodes using the agent installation 
#   (agent logs are written to <APPDYNAMICS_AGENT_HOME>/defaultAgentVersion/logs/node-name and
#    transaction configuration is written to the <APPDYNAMICS_AGENT_HOME>/defaultAgentVersion/conf/node-name directory)
#
# Example: APPDYNAMICS_AGENT_HOME="/apps/appdynamics/appAgent"
#
# Note the runtime directory for all runtime files can be optionally switched using <APPDYNAMICS_AGENT_BASE_DIR>.
#
# ** Optional
#
# APPDYNAMICS_AGENT_ENABLED: If true, enables the dynamic attachment of the AppDynamics Java Agent. 
# Defaults to false.
#
# Example: APPDYNAMICS_AGENT_ENABLED=true
#
#
# APPDYNAMICS_AGENT_NODE_NAME: The name of the node. Defaults to generate a node name that is
# unique within the business application and physical host.
#
# Example: APPDYNAMICS_AGENT_NODE_NAME="staging-chips-ef-batch0-wlserver1-1"
#
# 
# APPDYNAMICS_AGENT_BASE_DIR: The runtime directory for all runtime files (logs and transaction configuration) for agent nodes 
# using the agent installation.
# 
# If this property is specified, all agent logs are written to <Agent-Runtime-Directory>/logs/node-name 
# and transaction configuration is written to the <Agent-Runtime-Directory>/conf/node-name directory.
#
# Where not supplied, defaults to ${APPDYNAMICS_AGENT_HOME}/defaultAgentVersion.
#
# Example: APPDYNAMICS_AGENT_BASE_DIR="${APPDYNAMICS_AGENT_HOME}/22.12.0.34603"
#
#
# APPDYNAMICS_PROXY_OPTS: Specify system properties for proxy host/port if using a proxy to connect to the 
# AppDynamics Controller.
#
# Example:  APPDYNAMICS_PROXY_OPTS="-Dappdynamics.http.proxyHost=<proxy host> -Dappdynamics.http.proxyPort=<proxy port>"
#
# No proxy required by default.
#

# The location of the Java AppDynamics Java Agent files
APP_AGENT_REPO_HOME="/opt/appdynamics/AppServerAgent"

source ${APP_AGENT_REPO_HOME}/logging_functions  


# =============================================================================
# functions: 
# =============================================================================

# 
# Checks for existence of any PIDs representing running Weblogic Server JVM instances.
# Exits if encounters invalid state of more than one PID found.
# Returns 0 if no Weblogic Server JVM instance PID found; or
# Returns the PID of any single Weblogic Server JVM instance PID found
#
f_getWeblogicServerPID() {
  # Look for Weblogic Server  
  javaWeblogicServer=$(pgrep --full --delimiter ',' "weblogic.Server")

  # String not empty and contains comma => illegal state 
  if [[ -n "${javaWeblogicServer}" ]] && [[ "${javaWeblogicServer}" == *","* ]]
  then 
    exit 1 # Error, illegal state
  elif [[ -n "${javaWeblogicServer}" ]] # Single Server PID detected  
  then 
    echo "$javaWeblogicServer"
  else # No server PID detected  
    echo 0    
  fi  
}

#
# Checks the PID supplied is still the  current Weblogic Server instance
#
# Arg 1: Prior PID
#
# Returns 0 if true, 1 if false or no PIDS running
#
f_isSameWeblogicServerPID() {
  typeset priorPID=$1; shift
  currentPID=$(f_getWeblogicServerPID)

  if [[ -n "${currentPID}" ]]  &&  [[ "${currentPID}" == "${priorPID}" ]]; then
    echo 0 #true    
  else    
    echo 1 #false
  fi
  
}


#
# Checks the conditions to enable AppDynamics monitoring
# Returns true if allowed, else false.
#
f_initAppDynamicsEnabled() {
  if [[ -z "${APPDYNAMICS_AGENT_ENABLED}" ]]
  then 
    f_logWarn "APPDYNAMICS_AGENT_ENABLED not set. Will be disabled by default."
    APPDYNAMICS_AGENT_ENABLED=false
  fi

  if [[ "${APPDYNAMICS_AGENT_ENABLED}" == true ]]
  then
    # Decide if env supports use based on match to naming of a higher environment
    if [[ -n "${ENVIRONMENT_LABEL}" ]]
    then 

      # Check var contains either Live or Staging
      if echo "$ENVIRONMENT_LABEL" | grep -q "Live\|Staging";
      then
        APPDYNAMICS_AGENT_ENABLED=true
        f_logInfo "APPDYNAMICS_AGENT_ENABLED: $APPDYNAMICS_AGENT_ENABLED"
      else 
        APPDYNAMICS_AGENT_ENABLED=false
        f_logWarn "APPDYNAMICS_AGENT_ENABLED set as true but disabling as not supported in environment."                
      fi

    else      
      APPDYNAMICS_AGENT_ENABLED=false              
      f_logWarn "APPDYNAMICS_AGENT_ENABLED set as true but disabling as cannot determine environment."              
    fi

  fi
}


# =============================================================================
# pre-requisites: 
# =============================================================================

# Set up logging
LOGS_DIR=${APPDYNAMICS_AGENT_HOME}/logs
mkdir -p "${LOGS_DIR}"
LOG_FILE="${LOGS_DIR}/${HOSTNAME}-appd-java-agent-control-$(date +'%Y-%m-%d_%H-%M-%S').log"

# Direct output to logfile
exec >> "${LOG_FILE}" 2>&1


if [[ "$#" -gt "0" ]]; then f_logError "Usage: No arguments required. Configure using environment variables."; exit 1; fi

# Check all required env values are set
if [[ -z "${ENVIRONMENT_LABEL}" ]]; then f_logError "ENVIRONMENT_LABEL not set."; exit 1; fi

if [[ -z "${JAVA_HOME}" ]]; then f_logError "JAVA_HOME not set."; exit 1; 
else f_logInfo "JAVA_HOME: %s" "${JAVA_HOME}"; 
fi

f_initAppDynamicsEnabled

if [[ "${APPDYNAMICS_AGENT_ENABLED}" != true ]]; then
  f_logWarn "AppDynamics Java Agent attachment is NOT enabled. Terminating."
  exit 2
else 
  f_logInfo "AppDynamics Java Agent attachment is enabled."
fi

if [[ -z "${APPDYNAMICS_AGENT_HOME}" ]]; then f_logError "APPDYNAMICS_AGENT_HOME not set."; exit 1; 
else f_logInfo "APPDYNAMICS_AGENT_HOME: %s" "${APPDYNAMICS_AGENT_HOME}"; 
fi

if [[ -z "${APPDYNAMICS_CONTROLLER_HOST_NAME}" ]]; then f_logError "APPDYNAMICS_CONTROLLER_HOST_NAME not set."; exit 1; 
else f_logInfo "JAVA_HOME: %s" "${APPDYNAMICS_CONTROLLER_HOST_NAME}"; 
fi

if [[ -z "${APPDYNAMICS_CONTROLLER_PORT}" ]]; then f_logError "APPDYNAMICS_CONTROLLER_PORT not set."; exit 1; 
else f_logInfo "APPDYNAMICS_CONTROLLER_PORT: %s" "${APPDYNAMICS_CONTROLLER_PORT}"; 
fi

if [[ -z "${APPDYNAMICS_CONTROLLER_SSL_ENABLED}" ]]; then f_logError "APPDYNAMICS_CONTROLLER_SSL_ENABLED not set."; exit 1; 
else f_logInfo "APPDYNAMICS_CONTROLLER_SSL_ENABLED: %s" "${APPDYNAMICS_CONTROLLER_SSL_ENABLED}"; 
fi

if [[ -z "${APPDYNAMICS_AGENT_APPLICATION_NAME}" ]]; then  f_logError "APPDYNAMICS_AGENT_APPLICATION_NAME not set."; exit 1; 
else f_logInfo "APPDYNAMICS_AGENT_APPLICATION_NAME: %s" "${APPDYNAMICS_AGENT_APPLICATION_NAME}"; 
fi

if [[ -z "${APPDYNAMICS_AGENT_ACCOUNT_NAME}" ]]; then f_logError "APPDYNAMICS_AGENT_ACCOUNT_NAME not set."; exit 1; 
else f_logInfo "APPDYNAMICS_AGENT_ACCOUNT_NAME: %s" "${APPDYNAMICS_AGENT_ACCOUNT_NAME}"; 
fi

if [[ -z "${APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY}" ]]; then f_logError "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY not set."; exit 1; 
else f_logInfo "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY: %s" "*************"; 
fi

if [[ -z "${APPDYNAMICS_AGENT_TIER_NAME}" ]]; then f_logError "APPDYNAMICS_AGENT_TIER_NAME not set."; exit 1; 
else f_logInfo "APPDYNAMICS_AGENT_TIER_NAME: %s" "${APPDYNAMICS_AGENT_TIER_NAME}"; 
fi

# Check if optional env values are set
if [[ -z "${APPDYNAMICS_AGENT_BASE_DIR}" ]]; then f_logWarn "APPDYNAMICS_AGENT_BASE_DIR not set. Will use defaults."; fi
if [[ -z "${APPDYNAMICS_AGENT_NODE_NAME}" ]]; then f_logWarn "APPDYNAMICS_AGENT_NODE_NAME not set. Will use defaults."; 
fi

#Default to use sleep of 420 seconds (as per original on premise setting)
SLEEP_SECS=420

# Check the app agent exists
APP_AGENT_LOCATION="${APP_AGENT_REPO_HOME}/javaagent.jar"

if ! [[ -f "${APP_AGENT_LOCATION}" ]]; then f_logError "Unable to access the agent jar. Terminating."; exit 1; fi

# Location to place agent related data in Server container
APP_AGENT_ATTACHED_DIR="$APPDYNAMICS_AGENT_HOME/attached"

if ! [[ -d $APP_AGENT_ATTACHED_DIR ]]; then mkdir -p "$APP_AGENT_ATTACHED_DIR"; fi

f_logInfo "Attached Java Agent Information located at: %s" "${APP_AGENT_ATTACHED_DIR}"

# Check that this process is not already running (as should only be single instance per container)
# Will detect current running only error if multiple processes found
existingScriptPID=$(pgrep --full --delimiter ',' "$(basename "$0")")

# String not empty and contains comma meaning multi processes
if [[ -n "${existingScriptPID}" ]] && [[ "${existingScriptPID}" == *","* ]]
then 
  f_logError "An instance of the AppDynamics java startup script is already running. Exiting."
  exit 1 # Error, illegal state
fi

# Check if proxy set - (eg  APPDYNAMICS_PROXY_OPTS="-Dappdynamics.http.proxyHost=<proxy host> -Dappdynamics.http.proxyPort=<proxy port>")
if [[ -z "${APPDYNAMICS_PROXY_OPTS}" ]]
then
  f_logInfo "No proxy used for AppDynamics connection."  
else
  f_logInfo "Using proxy for AppDynamics connection: %s" "${APPDYNAMICS_PROXY_OPTS}"  
fi

# Optional: Use default unless express need to override
if [[ -z "${APPDYNAMICS_AGENT_NODE_NAME}" ]]
then
  # Convert env label to kebab-case   (e.g.  staging-chips-ef-batch0)
  ENVIRONMENT_LABEL_KEBAB_CASE=$(echo "${ENVIRONMENT_LABEL}" | tr " " "-" | tr "[:upper:]" "[:lower:]")
  
  # Form identifier for node name (must be unique within the AppDynamics tier)
  APPDYNAMICS_AGENT_NODE_NAME=${ENVIRONMENT_LABEL_KEBAB_CASE}-$HOSTNAME

  f_logInfo "Defaulting APPDYNAMICS_AGENT_NODE_NAME to: %s" "$APPDYNAMICS_AGENT_NODE_NAME"      
else
  f_logInfo "Using optional value for APPDYNAMICS_AGENT_NODE_NAME: %s" "$APPDYNAMICS_AGENT_NODE_NAME"
fi


# Optional:  The runtime directory for all runtime files (logs, transaction configuration) for agent nodes using the agent installation.
# If this property is specified, all agent logs are written to <Agent-Runtime-Directory>/logs/node-name 
# and transaction configuration is written to the <Agent-Runtime-Directory>/conf/node-name directory.
# 
if [[ -z "${APPDYNAMICS_AGENT_BASE_DIR}" ]]
then      
  #APPDYNAMICS_AGENT_BASE_DIR=${APPDYNAMICS_AGENT_HOME}/${APPDYNAMICS_AGENT_VERSION}/logs/${APPDYNAMICS_AGENT_NODE_NAME}
  APPDYNAMICS_AGENT_BASE_DIR="${APPDYNAMICS_AGENT_HOME}/defaultAgentVersion"
  f_logInfo "No value supplied for APPDYNAMICS_AGENT_BASE_DIR value. Defaulting to: %s" "${APPDYNAMICS_AGENT_BASE_DIR}"  
else
  f_logInfo "Using optional value for APPDYNAMICS_AGENT_BASE_DIR: %s" "${APPDYNAMICS_AGENT_BASE_DIR}";
fi

AGENT="-jar $APP_AGENT_LOCATION"
TOOLS_JAR=-Xbootclasspath/a:${JAVA_HOME}/lib/tools.jar


# =============================================================================
# Main
# =============================================================================

f_logInfo "Started the AppDynamics Java Agent startup script"

AGENT_IS_ATTACHED=${APP_AGENT_ATTACHED_DIR}/appDynamicsJavaAgentIsAttached.${APPDYNAMICS_AGENT_NODE_NAME}

while true;
do
  # Look for Weblogic Managed Server
  RUNNING_WEBLOGIC_SERVER_PID=$(f_getWeblogicServerPID)

  # If running and not attached
  if [[ "${RUNNING_WEBLOGIC_SERVER_PID}" != "0" ]] && [[ ! -e "${AGENT_IS_ATTACHED}" ]]
  then
    f_logInfo "Managed Server detected as running. Sleeping for %s seconds, then attaching AppDynamics Java Agent." ${SLEEP_SECS}

    # sleep to wait for jvm to start
    sleep "${SLEEP_SECS}"

    # Check same PID running following the pause    
    RUNNING_WEBLOGIC_SERVER_PID_POST_PAUSE=$(f_isSameWeblogicServerPID "$RUNNING_WEBLOGIC_SERVER_PID")     
    if [[ "${RUNNING_WEBLOGIC_SERVER_PID_POST_PAUSE}" != 0 ]]; then
      f_logInfo "Running Weblogic Server instance is different post pause"
      break
    fi

    if [[ ! -e "${AGENT_IS_ATTACHED}" ]] # We know one PID running
    then
      f_logInfo "Creating: %s" "$AGENT_IS_ATTACHED"
    else
      f_logError "Unexpected state of process to inject AppDynamics Java Agent. Ensure multiple instances of this script are not running. Terminating.";
      exit 1
    fi

    # create an attach file
    echo "$RUNNING_WEBLOGIC_SERVER_PID" > "$AGENT_IS_ATTACHED"      
    f_logInfo "Attaching AppDynamics Java Agent to pid: %s" "$RUNNING_WEBLOGIC_SERVER_PID"

    # Attach the agent
    JAVA_OPTS="$APPDYNAMICS_PROXY_OPTS"     

    #java $JAVA_OPTS $TOOLS_JAR $AGENT "$RUNNING_WEBLOGIC_SERVER_PID"
    java $JAVA_OPTS $TOOLS_JAR $AGENT "$RUNNING_WEBLOGIC_SERVER_PID" appdynamics.agent.nodeName="${APPDYNAMICS_AGENT_NODE_NAME}",appdynamics.agent.runtime.dir="${APPDYNAMICS_AGENT_BASE_DIR}" 

    #check agent start worked
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then      
      f_logError "Non-zero exit code of %s upon agent attachment indicates failure to attach AppDynamics Java Agent to pid: %s. Terminating." ${exit_code} "${RUNNING_WEBLOGIC_SERVER_PID}"

      ## Back out failed attachment
      rm "${AGENT_IS_ATTACHED}"      
      exit 1
    fi

  # running and attached
  elif [[ "${RUNNING_WEBLOGIC_SERVER_PID}" != "0" ]] && [[ -e "${AGENT_IS_ATTACHED}" ]]
  then 
    # Check the PID in the attachment file is the right PID
    attached_pid=$(cat "${AGENT_IS_ATTACHED}")

    if [[ "$attached_pid" != "$RUNNING_WEBLOGIC_SERVER_PID" ]]
    then    
      f_logWarn "Agent already recorded attached to java process of %s but current process id is %s" "$attached_pid" "$RUNNING_WEBLOGIC_SERVER_PID"
      f_logWarn "Removing: %s" "${AGENT_IS_ATTACHED}"
      rm "${AGENT_IS_ATTACHED}"
    else
      f_logInfo "Agent already attached to java process %s." "$RUNNING_WEBLOGIC_SERVER_PID"         

      # Need to double check the current PID really does relate to the attachment file
      # The time in seconds the process has been running MUST exceed the last modified date of the attachment file
      # If it does not, it implies a container has restarted with same PID (not actually ncommon) thus need to re-attach agent
      SERVER_TIME_UP_SECONDS=$(ps -p "$RUNNING_WEBLOGIC_SERVER_PID" -o etimes | grep -v ELAPSED | sed 's/ //g')
      AGENT_ATTACHMENT_SECONDS=$(($(date +%s) - $(stat  -c %Y "${AGENT_IS_ATTACHED}")))

      if (( SERVER_TIME_UP_SECONDS < AGENT_ATTACHED_UP_SECONDS ))
      then
        f_logInfo "Container has assigned same PID %s to the old Server process used previously. Removing record of Agent attachment to force re-attachment." "$attached_pid"
        f_logWarn "Removing: %s" "${AGENT_IS_ATTACHED}"        rm "${AGENT_IS_ATTACHED}"
      fi

    fi

  # not running so remove the attached file
  else
    if [[ -e "${AGENT_IS_ATTACHED}" ]]
    then 
      rm "${AGENT_IS_ATTACHED}"
      f_logInfo "Java process not running so removed existing attachment file: %s." "${AGENT_IS_ATTACHED}"
    fi
  fi

  SLEEP_SECS_BETWEEN_ITERATIONS=60
  f_logInfo "Sleeping for %s seconds before next attempt to attach Java agent." $SLEEP_SECS_BETWEEN_ITERATIONS
  sleep $SLEEP_SECS_BETWEEN_ITERATIONS

  #Housekeeping of agent log files - remove files whose data was last modified 1 day ago
  find /apps/appdynamics/appAgent/logs/ -mindepth 1 -mtime +1 -delete

done
