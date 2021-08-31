#!/bin/bash

# Prevent Derby from being started
export DERBY_FLAG=false

# Launch managed server startup in a separate process
( ${ORACLE_HOME}/container-scripts/startManagedServer.sh ) > ${ORACLE_HOME}/auto-start.log  &

${ORACLE_HOME}/container-scripts/startNodeManager.sh


