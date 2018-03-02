import sys, requests

#Form successfull OSD message
def successMessageJSON(computerName):
    
    msgJSON = '{"@type": "MessageCard","@context": "http://schema.org/extensions","summary": "OSD Status Message","sections": [{"activityTitle": "%s: Operating system deployment completed succesfully"}],"markdown": true}' % computerName
    return msgJSON

#Form failed OSD message
def failureMessageJSON(computerName):
    
    msgJSON = '{{"@type": "MessageCard","@context": "http://schema.org/extensions","summary": "OSD Status Message","sections": [{"activityTitle": "%s: Operating system deployment failed"}],"markdown": true}' % computerName
    return msgJSON

#Handle message delivery status
def messageDeliveryStatus(statuscode):
    #Print succeess message if message delivery succeeded. Else print failure message and HTTP failure code
    if(statuscode == 200):
        print("Message delivered successfully")
        sys.exit(0)
    else:
        print("Message delivery failure. HTTP Error code:%d" %statuscode)
        sys.exit(statuscode)

#Read Teams URI from file
def getTeamsURI():
    
    teamsURIFile = open("TeamsURI.txt","r")
    teamsURI = teamsURIFile.read()

    return teamsURI

def main(computerName,deploymentStatus):
   
    #Form messages according deployment status
    if(deploymentStatus == "success"):
        message = successMessageJSON(computerName)
    elif(deploymentStatus == "failure"):
        message = failureMessageJSON(computerName)
    else:
        print("Usage: python OSDStatusMessage.py computername deploymentstatus(success/failure)")
        return

    #Get location of Teams channel
    teamsURI = getTeamsURI()

    #Post message to Teams channel
    messageHttpPostObject = requests.post(teamsURI,data=message)
    #Handle message return status
    messageDeliveryStatus(messageHttpPostObject.status_code)

#If script is run from command line
if __name__ == "__main__":
    #Check if two parameters are provided. Else print help.
    if (len(sys.argv) == 3):
        main(sys.argv[1],sys.argv[2])
    else:
        print("Usage: python OSDStatusMessage.py computername deploymentstatus(success/failure)")