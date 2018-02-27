Param(
    [switch]$debug
)

Function checkComputerInfoFromDB($computer, $location, $purpose)
{    
    $global:totalComputerCounter++

    if ($debug)
    {
        Write-Host "Checking Computer:" $computer
    }

    $sqlQuery = "SELECT * FROM efecte_computer_locations WHERE (computer_name = '$computer')"
    $MYSQLCommand.CommandText = $sqlQuery
    $MYSQLDataAdapter.SelectCommand = $MYSQLCommand    
    
    $NumberOfDataSets = $MYSQLDataAdapter.Fill($MYSQLDataSet, "data")

    if ($NumberOfDataSets -eq 0)
    {
        insertNewComputerInfoToDB $computer $location $purpose
        return
    }

    if ($location -eq "")
    {
        Add-Content -Path "$($global:logFile)" -Value "$(Get-Date) $computer Location missing in Efecte"
        return
    }

    if ($MYSQLDataSet.Tables["data"].computer_location -eq $location)
    {
        if ($debug)
        {
            Write-Host "Computer $computer Location match"
        }
    } else {
        updateComputerLocationToDB $computer $location $MYSQLDataSet.Tables["data"].computer_location
        $global:locationUpdateCounter++
    }

    if ($MYSQLDataSet.Tables["data"].computer_purpose -eq $purpose)
    {
        if ($debug)
        {
            Write-Host "Computer $computer Purpose match"
        }
    } else {
        updateComputerPurposeToDB $computer $purpose $MYSQLDataSet.Tables["data"].computer_purpose
        $global:purposeUpdateCounter++
    }

    $MYSQLDataSet.Tables.Clear()
}

Function insertNewComputerInfoToDB($computer, $location, $purpose)
{
    Write-Host "Inserting $computer to Database. Location $location and purpose $purpose"
    Add-Content -Path "$($global:logFile)" -Value "$(Get-Date) $computer added to database"
    
    $sqlInsert = "INSERT INTO efecte_computer_locations(computer_name, computer_location, computer_purpose) VALUES ('$computer','$location','$purpose')"
    $MYSQLCommand.CommandText = $sqlInsert
    $sqlResult = $MYSQLCommand.ExecuteNonQuery()

    if ($debug)
    {
        if ($sqlResult -eq 1)
        {
            Write-Host "SQL Insert Successful"
        } else {
            Write-Host "SQL Insert failed"
        }
    }
    
    return
}

Function updateComputerLocationToDB($computer, $location, $oldLocation)
{
    Write-Host "Computer: $computer Location: $location Old Location: $oldLocation"
    Add-Content -Path "$($global:logFile)" -Value "$(Get-Date) $computer location changed. New location $location, old location $oldLocation"
    
    $sqlInsert = "UPDATE efecte_computer_locations SET computer_location='$location', previous_computer_location='$oldLocation' WHERE computer_name='$computer'"
    $MYSQLCommand.CommandText = $sqlInsert
    $sqlResult = $MYSQLCommand.ExecuteNonQuery()
    
    return
}

Function updateComputerPurposeToDB($computer, $purpose, $oldPurpose)
{
    Write-Host "Computer: $computer Purpose: $purpose Old Purpose: $oldPurpose"
    Add-Content -Path "$($global:logFile)" -Value "$(Get-Date) $computer purpose changed. New purpose $purpose, old purpose $oldPurpose"
    
    $sqlInsert = "UPDATE efecte_computer_locations SET computer_purpose='$purpose', previous_computer_purpose='$oldPurpose' WHERE computer_name='$computer'"
    $MYSQLCommand.CommandText = $sqlInsert
    $sqlResult = $MYSQLCommand.ExecuteNonQuery()
    
    return
}

#---------------------General---------------------
$global:logFile = "$env:TEMP\Get-ChangesInComputerLocations.log"

$runCounter = 0
$computerCount = 0
$global:totalComputerCounter = 0
$global:locationUpdateCounter = 0
$global:purposeUpdateCounter = 0

#---------------------Credetials-----------------------------
$dbUser = "dummyDBUser"
$dbPwd = "dummyDBPwd"
$assetUser = "dummyAssetUser"
$assetPwd = "dummyAssetPwd"

#---------------------Database connection---------------------
Add-Type -Path 'C:\Program Files (x86)\MySQL\MySQL Connector Net 6.8.8\Assemblies\v4.5\MySql.Data.dll'

$connection = [Mysql.Data.MySqlClient.MySqlConnection]@{ConnectionString='server=127.0.0.1;port=3306;uid=' + $dummyDBUser + ';pwd=' + $dummyDBPwd + ';database=efecteTempStore'}
$connection.Open()

$MYSQLCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$MYSQLDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter
$MYSQLDataSet = New-Object System.Data.DataSet
$MYSQLCommand.Connection=$Connection

#---------------------Asset connection---------------------
$efecteQuery = "SELECT `$host_name`$,`$node_location`$, `$hallinnollinen_kayttotarkoitus`$ FROM entity WHERE `$state`$ LIKE 'K%yt%ss%' AND entity.folder.name = '1.Tietokone' AND entity.deleted = false AND template.id = '79'"
$url = "https://dummy.efectecloud.com/api/itsm/search.ws?query=" + $efecteQuery

$webclient = new-object System.Net.WebClient
$webclient.Credentials = New-Object System.Net.NetworkCredential($assetUser, $assetPwd, "")
$webclient.Encoding = [System.Text.Encoding]::UTF8

$efecteReturnXML = [xml]$webclient.DownloadString($url)

if ($efecteReturnXML.HasChildNodes)
{    
    #Loop thru returned data
    foreach ($computer in $efecteReturnXML.Result.ChildNodes)
    {
      if ($computer.HasChildNodes)
      {
        checkComputerInfoFromDB $computer.ChildNodes[0].InnerText $computer.ChildNodes[1].InnerText $computer.ChildNodes[2].InnerText
      }              
    }
} else {
    Write-Host "No matches returned by asset search"
}

Clear-Variable -Name efecteReturnXML
$Connection.Close()

Add-Content -Path "$($global:logFile)" -Value "$(Get-Date) Total of $global:totalComputerCounter computers checked."
Add-Content -Path "$($global:logFile)" -Value "$(Get-Date) $global:locationUpdateCounter location data updated."
Add-Content -Path "$($global:logFile)" -Value "$(Get-Date) $global:purposeUpdateCounter computer purpose data updated."

Write-Host "Total of $global:totalComputerCounter computers checked."
Write-Host "$global:locationUpdateCounter location data updated."
Write-Host "$global:purposeUpdateCounter computer purpose data updated."