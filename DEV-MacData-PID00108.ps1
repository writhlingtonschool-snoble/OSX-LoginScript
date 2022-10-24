clear-host


function dashedline() { #print dashed line
Write-Host "----------------------------------------------------------------------------------------------------------"
}

#$dryrun = "-whatif" #toggle between "-whatif" ""

$CID="C00681" #change ID - update as required
$root = "D:" # base drive letter for data/logging folders - update as required

#$GamDir="$root\AppData\GAMXTD3\app" #GAM directory
$DataDir="$root\AppData\MNSP\$CID\Data" #Data dir
$LogDir="$root\AppData\MNSP\$CID\Logs" #Logs dir
$transcriptlog = "$LogDir\$(Get-date -Format yyyyMMdd-HHmmss)_transcript.log"

$StudentSiteOUpath = ",OU=Students,OU=WRI,OU=Establishments,DC=writhlington,DC=internal" #update as required
$StudentSiteSharePath = "\\MNSP-SYNO-01\MacData01" #update as required 

$StaffSiteOUpath = ",OU=WRI,OU=Establishments,DC=writhlington,DC=internal" #update as required
$StaffSiteSharePath = "\\MNSP-SYNO-01\MacData02" #update as required 

#create required logging/working directory(s) paths if not exist...
If(!(test-path -PathType container $DataDir))
{
      New-Item -ItemType Directory -Path $DataDir
}

If(!(test-path -PathType container $LogDir))
{
      New-Item -ItemType Directory -Path $LogDir
}

#begin logging all output...
Start-Transcript -Path $transcriptlog -Force -NoClobber -Append

$ADshortName = "WRITHLINGTON" # update as required
$AllstudentsADGroup = "$ADshortName\WRI Students" # update as required
$AllTeachingStaffADGroup = "$ADshortName\WRI Teaching Staff" # update as required
$AllSupportStaffADGroup = "$ADshortName\WRI Non-Teach Staff" # update as required


$fullPath = "$basepath\$SAM" #students home drive
$icaclsperms01 = "(NP)(RX)" #students traverse right
$icaclsperms02 = "(OI)(CI)(RX,W,WDAC,WO,DC)" #common modify right - home directories for owner
$icaclsperms03 = "(OI)(CI)(RX,W,DC)" #staff/support modify right

Write-Host "Processing Students..."
#year groups to process array
#$array = @("2000","2019","2018","2017","2016","2015","2014","2013") #update as required 
$array = @("2000","2022") #limited OU(s) for initial development testing.

for ($i=0; $i -lt $array.Count; $i++){
    $INTYYYY = $array[$i] #set 
    Write-Host "Processing Intake year group:$INTYYYY"
    $basepath = "$StudentSiteSharePath\$INTYYYY"
    $searchBase = "OU=$INTYYYY$StudentSiteOUpath"
    
    #create users array using year group array elements - 2000, 2019 etc...
    $users=@() #empty any existing array
    $users = Get-aduser  -filter * -SearchBase $SearchBase -Properties sAMAccountName,homeDirectory,userPrincipalName,memberof | Select-Object sAMAccountName,homeDirectory,userPrincipalName
    Write-host "Number of students to check/process:" $users.count

Write-Host "Checking for/Creating base path: $basepath"
if (!(Test-Path $basepath))
    {
    new-item -ItemType Directory -Path $basepath -Force
    
    Write-Host "Setting NTFS Permissions..."
    #grant students traverse rights...
    Invoke-expression "icacls.exe $basepath /grant '$($AllstudentsADGroup):$icaclsperms01'" 
    Start-sleep 60 #comment after initial run, once happy script is ready for full unuattended runs
    } else {
    Write-Host "$basepath already exists..."
    }
    dashedline

foreach ($user in $users) {

    dashedline
    Write-host "Processing user: $($user.sAMAccountname)"
    Write-host "UPN: $($user.userPrincipalName)"
    $fullPath = "$basepath\$($user.sAMAccountName)"

Write-Host "Checking for full path: $fullpath"
if (!(Test-Path $fullPath))
    {
    Write-Host "Creating directory for student..."
    new-item -ItemType Directory -Path $fullpath -Force
    

    Write-Host "Setting NTFS Permissions..."
    #grant student permissions...
    Invoke-expression "icacls.exe $fullPath /grant '$($user.userPrincipalName):$icaclsperms02'"
    
    #grant staff perms...
    Invoke-expression "icacls.exe $fullPath /grant '$($AllTeachingStaffADGroup):$icaclsperms03'"
    Invoke-expression "icacls.exe $fullPath /grant '$($AllSupportStaffADGroup):$icaclsperms03'"
    Start-sleep 60 #comment after initial run, once happy script is ready for full unuattended runs
    } else {
    Write-host "Already exists nothing to do..."
    }
    dashedline
    #sleep 5
}

}

Write-Host "Processing staff..."
$StaffOUarray = @("Teaching Staff","Non-Teaching Staff") #limited OU(s) for initial development testing.

for ($i=0; $i -lt $StaffOUarray.Count; $i++){
    $StaffRole = $StaffOUarray[$i] #set 
    Write-Host "Processing Staff Role OU:$StaffRole"
    $basepath = "$StafffSiteSharePath\$StaffRole"
    $searchBase = "OU=$StaffRoleSiteOUpath"

    #create users array using year group array elements - Teaching, Non-Teaching  etc...
    $users=@() #empty any existing array
    $users = Get-aduser  -filter * -SearchBase $SearchBase -Properties sAMAccountName,homeDirectory,userPrincipalName,memberof | Select-Object sAMAccountName,homeDirectory,userPrincipalName
    Write-host "Number of staff to check/process:" $users.count
}
#Delete any transaction logs older than 30 days
Get-ChildItem "$LogDir\*_transcript.log" -Recurse -File | Where-Object CreationTime -lt  (Get-Date).AddDays(-30) | Remove-Item -verbose

Stop-Transcript


