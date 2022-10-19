clear-host

# files older than n days cleanup required
# development sleeps

function dashedline() { #print dashed line
Write-Host "----------------------------------------------------------------------------------------------------------"
}

$dryrun = "-whatif" #toggle between "-whatif" ""

$CID="C00681" #change ID - update as required
$root = "D:" # base drive letter for data/logging folders - update as required

$GamDir="$root\AppData\GAMXTD3\app" #GAM directory
$DataDir="$root\AppData\MNSP\$CID\Data" #Data dir
$LogDir="$root\AppData\MNSP\$CID\Logs" #Logs dir
$transcriptlog = "$LogDir\$(Get-date -Format yyyyMMdd-HHmmss)_transcript.log"

$siteOUpath = ",OU=Students,OU=WRI,OU=Establishments,DC=writhlington,DC=internal" #update as required
$siteSharePath = "\\MNSP-SYNO-01\MacData01" #update as rquired 

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
$icaclsperms02 = "(OI)(CI)(RX,W,WDAC,WO,DC)" #students modify right
$icaclsperms03 = "(OI)(CI)(RX,W,DC)" #staff/support modify right

#year groups to process array
#$array = @("2000","2019","2018","2017","2016","2015","2014","2013") #update as required 
$array = @("2000","2022") #limited OU(s) for initial development testing.

for ($i=0; $i -lt $array.Count; $i++){
    $INTYYYY = $array[$i] #set 
    Write-Host "Processing Intake year group:$INTYYYY"
    $basepath = "$siteSharePath\$INTYYYY"
    $searchBase = "OU=$INTYYYY$siteOUpath"
    
    #create users array using year group array elements - 2000, 2019 etc...

    $users = Get-aduser  -filter * -SearchBase $SearchBase -Properties sAMAccountName,homeDirectory,userPrincipalName,memberof | select sAMAccountName,homeDirectory,userPrincipalName
    Write-host "Number of students to check/process:" $users.count

Write-Host "Checking for/Creating base path: $basepath"
if (!(Test-Path $basepath))
    {
    new-item -ItemType Directory -Path $basepath -Force
    
    Write-Host "Setting NTFS Permissions..."
    #grant students traverse rights...
    Invoke-expression "icacls.exe $basepath /grant '$($AllstudentsADGroup):$icaclsperms01'" 

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

    } else {
    Write-host "Already exists nothing to do..."
    }
    dashedline
    #sleep 5
}

}
Stop-Transcript


<#

#$INTYYYY = "2000" #update as necessary
#$INTYYYY = @("2019","2018","2017","2016")

#$icaclsperms02 = "(OI)(CI)(RX,W,DC)" #students modify right

$ControlGroup = "C1349-MacData"
$RsyncFirstRun = "firstrun.txt"

    #grant modify right, but with delete sub folders and files, and not delete (root folder)
    ### Invoke-expression "icacls.exe $fullPath /grant '$($user.userPrincipalName):$icaclsperms'"
    
    ### Write-Host "set ownership of MacData dir..."
    ### Invoke-expression "icacls.exe $fullpath /setowner '$($user.userPrincipalName)'"
    
    ### Write-Host "create rsync first runlock file..."
    ### New-Item -path $fullpath -name $RsyncFirstRun -type "file" -value "Rsync first run to do..."

    ### Write-Host "set ownership rsync first runlock file"
    ### Invoke-expression "icacls.exe $fullpath\$RsyncFirstRun /setowner '$($user.userPrincipalName)'"
    
    ### Write-Host "Adding user to control group..."
    ### Add-ADGroupMember -identity "C1349-MacData" $($user.sAMAccountName)

#$users = Get-aduser  -filter * -SearchBase $SearchBase -Properties sAMAccountName,homeDirectory,userPrincipalName,memberof | Where-Object {!($_.memberof -like "*C1349-MacData*")} | select sAMAccountName,homeDirectory,userPrincipalName

$WorkDir = "E:\ps1s\PRD-MacData" #logs, csvs etc.
$log = "$WorkDir\transcript.log"
$array = @("2019","2018","2017","2016")
for ($i=0; $i -lt $array.Count; $i++){
    echo ("Element $i = " + $array[$i])
}


#$basepath = "\\synocluster01\MacData\INT2000"
#$SearchBase = "OU=wri,OU=Intake2000,OU=students,OU=active_users,DC=wsbe,DC=internal"

#get homedir INT####
#split home dir path using \ and create array with it
$CharArray=$($user.homeDirectory).Split("\")
#look for array elemnt that matches INT* - set $INTYR to that value
$INTYR = @($CharArray) -like 'INT*'

#$users = Get-aduser  -filter * -SearchBase $SearchBase -Properties sAMAccountName,homeDirectory,userPrincipalName | select sAMAccountName,homeDirectory,userPrincipalName
$SAM = "andrew.aardvark"

#check for emty vars:
if ($intYR)  { 'not empty' } else { 'empty' }

$fullpath1 = "\\WRISCH-MGMT01\testshare1\$SAM"

$acl = Get-Acl -path $fullPath\$RsyncFirstRun
$acl.SetOwner($user.sAMAccountName)


# Define the owner account/group
$Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'BUILTIN\Administrators';

# Get a list of folders and files
$ItemList = Get-ChildItem -Path c:\test -Recurse;

# Iterate over files/folders
foreach ($Item in $ItemList) {
    $Acl = $null; # Reset the $Acl variable to $null
    $Acl = Get-Acl -Path $Item.FullName; # Get the ACL from the item
    $Acl.SetOwner($Account); # Update the in-memory ACL
    Set-Acl -Path $Item.FullName -AclObject $Acl;  # Set the updated ACL on the target item
}



   $acl = Get-Acl $fullPath
   $FileSystemRights = [System.Security.AccessControl.FileSystemRights]"Modify"
   #$FileSystemRights = [System.Security.AccessControl.FileSystemRights]"DeleteSubdirectoriesAndFiles, Write, ReadAndExecute, Synchronize"
   $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
   $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
   $PropagationFlags = [System.Security.AccessControl.PropagationFlags]"None"

   #$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($SAM, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)
   $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($SAM, $FileSystemRights, $AccessControlType)
   $acl.AddAccessRule($AccessRule)
 
   Set-Acl -Path $fullPath -AclObject $acl -ea Stop
 
   sleep 10



Allow  DeleteSubdirectoriesAndFiles, Write, ReadAndExecute, Synchronize

$acl = Get-Acl \\fs1\shared\sales
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("ENTERPRISE\T.Simpson","FullControl","Allow")

$acl.SetAccessRule($AccessRule)

$acl | Set-Acl \\fs1\shared\sales



$acl = Get-Acl $fullPath
#$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSBE\andrew.aardvark","DeleteSubdirectoriesAndFiles, Write, ReadAndExecute, Synchronize","Allow")
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSBE\andrew.aardvark","FullControl","Allow")

$acl.SetAccessRule($AccessRule)

$acl | Set-Acl $fullPath


#set owner

$acl = Get-Acl $fullPath

$object = New-Object System.Security.Principal.Ntaccount("WSBE\andrew.aardvark")

$acl.SetOwner($object)

$acl | Set-Acl $fullPath


<#

$acl = Get-Acl $fullPath1
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSBE\andrew.aardvark","Modify","Allow")
$acl.SetAccessRule($AccessRule)
$acl | Set-Acl $fullPath1


   $acl = Get-Acl $fullPath1
   $FileSystemRights = [System.Security.AccessControl.FileSystemRights]"Modify"
   #$FileSystemRights = [System.Security.AccessControl.FileSystemRights]"DeleteSubdirectoriesAndFiles, Write, ReadAndExecute, Synchronize"
   $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
   $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
   $PropagationFlags = [System.Security.AccessControl.PropagationFlags]"None"

   $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($SAM, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)
   
   $acl.AddAccessRule($AccessRule)
 
   Set-Acl -Path $fullPath1 -AclObject $acl -ea Stop

   #$Ar = New-Object system.Security.AccessControl.FileSystemAccessRule($user_account, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")

#SET ICACLSPERMS=(OI)(CI)(RX,W,DC)
icacls.exe $Path /grant "${Principal}:(OI)(CI)(R)"

############
#eureka this works: grant modify right, but with delete sub folders and files, and not delete (root folder)
$perms="(OI)(CI)(RX,W,DC)"
icacls.exe $fullPath /grant "WSBE\andrew.aardvark:$perms"
#set owner
icacls.exe $fullpath /setowner "WSBE\andrew.aardvark"
############


############
#eureka this works: grant modify right, but with delete sub folders and files, and not delete (root folder)
#Invoke-expression "icacls.exe $fullPath /grant 'WSBE\$($user.sAMAccountName):$icaclsperms'"
#Invoke-expression "icacls.exe $fullPath /grant '$($user.userPrincipalName):$icaclsperms'"
#set owner
#Invoke-expression "icacls.exe $fullpath /setowner 'WSBE\$($user.sAMAccountName)'"
#Invoke-expression "icacls.exe $fullpath /setowner '$($user.userPrincipalName)'"

############


#>
