Param(
    [switch]$Log,
    [switch]$Verbose
)

Import-Module ActiveDirectory

$primusUsersADGroup = "Dummy_Primus_Users_AD_Group"
$logFile = "$env:TEMP\AD - Manage Primus users AD group memberships.log"


$primusUsers = Get-ADUser -Filter {title -eq "koulutus*"} -Properties title| Select SamAccountName, GivenName, Surname, title
$primusUsers += Get-ADUser -Filter {title -like "yksikönjohtaja"} -Properties title | Select SamAccountName, GivenName, Surname, title
$primusUsers += Get-ADUser -Filter {title -like "opinto*"} -Properties title | Select SamAccountName, GivenName, Surname, title
$primusUsersGroupMembers = Get-ADGroupMember -Identity $primusUsersADGroup


#Check if user is a member of group
#Add user to group if not already a member
foreach ($primusUser in $primusUsers)
{
    if ($primusUsersGroupMembers.SamAccountName.Contains($primusUser.SamAccountName))
    {
        if($Verbose)
        {
            Write-Host "$($primusUser.SamAccountName) is member of group $primusUsersADGroup" -ForegroundColor Green
        }        
    } else {
        if($Verbose)
        {
            Write-Host "$($primusUser.SamAccountName) is not member of group $primusUsersADGroup" -ForegroundColor Yellow
            Write-Host "Adding user $($primusUser.SamAccountName) to group $primusUsersADGroup"
        }        
        
        #Add user to Primus users AD group
        try {
            Add-ADGroupMember -Identity $primusUsersADGroup -Members $primusUser.SamAccountName
            if($Log){
                Add-Content -Path $logFile -Value "$(Get-Date) ADD $($primusUser.SamAccountName) to group $primusUsersADGroup"
            }
        }
        catch {
            if($Log){
                Add-Content -Path $logFile -Value "$(Get-Date) ERROR $($primusUser.SamAccountName) $primusUsersADGroup $($_.Exception.Message)"
            }
        }
        
    }
}
if($Verbose)
{
    Write-Host "------------------------"
}

#Check if existing member of a group is not part of primusUsers
#Remove user from group if not a Primus user anymore
foreach ($primusGroupMember in $primusUsersGroupMembers)
{
    if ($primusGroupMember.objectClass -eq "user")
    {
        if($primusUsers.SamAccountName.Contains($primusGroupMember.SamAccountName))
        {   
            IF($Verbose)
            {
                Write-Host "$($primusGroupMember.SamAccountName) is a Primus User" -ForegroundColor Green
            }
            
        } else {
            
            if($Verbose)
            {
                Write-Host "$($primusGroupMember.SamAccountName) is not a Primus User anymore" -ForegroundColor Yellow
                Write-Host "Removing user $($primusGroupMember.SamAccountName) from group $primusUsersADGroup"
            }            

            #Remove user from Primus users AD group
            try {

                Remove-ADGroupMember -Identity $primusUsersADGroup -Members $primusGroupMember.SamAccountName -Confirm:$false
                if($Log)
                {
                    Add-Content -Path $logFile -Value "$(Get-Date) REMOVE $($primusGroupMember.SamAccountName) from group $primusUsersADGroup"
                }
            } catch {
                if($Log){
                    Add-Content -Path $logFile -Value "$(Get-Date) ERROR $($primusGroupMember.SamAccountName) $primusUsersADGroup $($_.Exception.Message)"
                }
            }
        }
    }
}