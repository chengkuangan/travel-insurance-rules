#!/bin/bash

#================== Global Variables  ==================

PROJ_NAME_PREFIX='gck'
PROJ_TOOLS_NAME="$PROJ_NAME_PREFIX-tools"
PROJ_DM_NAME="$PROJ_NAME_PREFIX-dm"
USERNAME=""
PASSWORD=""
MASTER_NODE_URL=""
HOSTNAME=""
GITHUB_USERNAME=""
GITHIB_PASSWORD=""

#================== Functions ==================

function printCmdUsage(){
    echo
    echo "Command Usage: init.sh -url <OCP Master URL> -u <username> -p <password> -hostname <hostname>"
    echo
    echo "-url  OCP Master URL"
    echo "-u  OCP Username"
    echo "-p  OCP Password"
    echo "-hostname  OCP domain name, e.g. apps.ocp.demo.com"
    echo
}

function printUsage(){
    echo
    echo "This command initialize a CI/CD demo in OpenShift based on Parskmap demo codes."
    echo "It has been tested in OpenShift 3.5"
    echo
    printCmdUsage
    echo
    printAdditionalRemarks
    echo
    printImportantNoteBeforeExecute
    echo
}

function printImportantNoteBeforeExecute(){
    echo
    echo
}

function printAdditionalRemarks(){
    echo
    echo "================================ Additional Manual Steps Required ================================"
    echo
}

function printVariables(){
    echo
    echo "The following information will be used to create the demo:"
    echo
    echo
}

function processArguments(){

    if [ $# -eq 0 ]; then
        printCmdUsage
        exit 0
    fi

    while (( "$#" )); do
      if [ "$1" == "-h" ]; then
        printUsage
        exit 0
      elif [ "$1" == "-project-name-prefix" ]; then
        shift
        PROJ_NAME_PREFIX="$1"
      elif [ "$1" == "-u" ]; then
        shift
        USERNAME="$1"
      elif [ "$1" == "-p" ]; then
        shift
        PASSWORD="$1"
      elif [ "$1" == "-url" ]; then
        shift
        MASTER_NODE_URL="$1"
      elif [ "$1" == "-hostname" ]; then
        shift
        HOSTNAME="$1"  
      elif [ "$1" == "-github-username" ]; then
        shift
        GITHUB_USERNAME="$1"    
      elif [ "$1" == "-github-password" ]; then
        shift
        GITHUB_PASSWORD="$1"      
      else
        echo "Unknown argument: $1"
        printCmdUsage
        exit 0
      fi
      shift
    done

    if [ "$MASTER_NODE_URL" = "" ]; then
        echo "Missing -url argument. Master node URL is required."
        exit 0
    fi

}

######################################################################################################
####################################### It starts from here ##########################################
######################################################################################################

#================== Process Command Line Arguments ==================

processArguments $@
printVariables
printImportantNoteBeforeExecute
echo
echo "Press ENTER (OR Ctrl-C to cancel) to proceed..."
read bc

oc login -u $USERNAME -p $PASSWORD $MASTER_NODE_URL

#================== Delete Projects if Found ==================

#================== Create projects required with neccessary permissions ==================

echo
echo "---> Creating all required projects now..."
echo

oc new-project $PROJ_TOOLS_NAME --display-name="Tools"
oc new-project $PROJ_DM_NAME --display-name="Decision Manager"


echo
echo "---> Adding all necessary users and system accounts permissions..."
echo

oc policy add-role-to-user edit system:serviceaccount:$PROJ_TOOLS_NAME:jenkins -n $PROJ_DM_NAME
oc policy add-role-to-user system:image-puller system:serviceaccount:$PROJ_DM_NAME:default -n $PROJ_DM_NAME
    
#================== Deploy Gogs ==================


echo
echo "---> Provisioning gogs now..."
echo
oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/gogs-persistent-template.yaml -p SKIP_TLS_VERIFY=true -p HOSTNAME=$HOSTNAME -p PROJECT_NAME=$PROJ_TOOLS_NAME -n $PROJ_TOOLS_NAME 

echo
echo "---> Populating sample codes into gogs now..."
echo

#curl -o /tmp/initGogs.sh -s https://raw.githubusercontent.com/chengkuangan/scripts/master/initGogs.sh; source initGogs.sh -su $GITHUB_USERNAME -sp $GITHIB_PASSWORD -proj 4 -surl https://github.com/chengkuangan/gobear.git -tu $USERNAME -tp $PASSWORD

#================== Deploy Nexus3 ==================

echo
echo "---> Provisioning nexus3 now..."
echo
oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/nexus3-persistent-templates.yaml -n $PROJ_TOOLS_NAME


#================== Deploy Jenkins ==================

#echo
#echo "---> Provisioning Jenkins now..."
#echo
#oc new-app jenkins-persistent -n $PROJ_TOOLS_NAME

### Required Manual Steps
#
# 1. Login gogs
# 2. Create New Items for each of the build required for nationalparks, parksmap-web and mlbparks
# 3. Make sure to add user.name and user.email in the task config else error will occurs.
#
##

#================== Other Settings ==================

if [ "$LOGOUT_WHEN_DONE" = "true" ]; then
    oc logout
fi

printAdditionalRemarks

echo
echo "==============================================================="
echo "Well, the demo should have been deployed and configured now... "
echo "==============================================================="
echo

######################################################################################################
####################################### It ENDS  here ################################################
######################################################################################################
