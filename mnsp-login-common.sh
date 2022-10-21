#!/bin/bash
# *******************************************************************
## @type: shellscript
## ********************************************************************

# Script Configuration
CNF_ENABLED="YES" #run script yes or no
CNF_LOGGING="YES" #log script output or not
CNF_UPDATES="NO" #check mac server for updates and download them
CNF_AUTOSTART="YES" #run login items script
CNF_HDRIVE="NO" #enable/disable network drive mounts
CNF_SLINK="NO" #enable/didable symlinks to desktop
CNF_FIXES="YES" #enable/disable special 'because on a mac fixes...'
CNF_SERVER="wrisch-macserver01.writhlington.internal" #address of server hosting resources
CNF_STAHOME="wri-sr-004"
CNF_STUHOME="wri-sr-003"
#CNF_SETUP="/Writhlington" #local location for all scripts and assets
CNF_SETUP="/private/mnsp" #local location for all scripts and assets
CNF_VER="1" #script version used for update checking
CNF_SWTAR="10.13.6" #macos target version
CNF_LOGNAME="login" #name for this scripts log file

#agreed MAT common smbshare name
CNF_SMBSHARE="MacData01"

# Script Variables
VAR_NAME=$(basename $0) #script name
VAR_USERNAME="$1" #current user logging in
VAR_USERHOME="/Users/$VAR_USERNAME" #users local home dir
VAR_USERBACKUP="CNF_SETUP/.backups/$VAR_USERNAME" #users backup directory
VAR_HOST=$(scutil --get ComputerName) #computer hostname
VAR_SWVER-$(sw_vers | grep -i ProductVersion | awk -F" " '{print $2}') #get macos version


# Script Functions
function _mainTimestamp() {
	#gets current date and time
	date +'%d/%m/%y %H:%M:%S'
}

function _mainLog() { 
	#handles log requests
	if [ "$1" == "err" ]; then
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][ERRO] $2"
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][ERRO] $2" >> "$CNF_SETUP/logs/SAMS-$CNF_LOGNAME.log"
	elif [ "$1" == "wrn" ]; then
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][WARN] $2"
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][WARN] $2" >> "$CNF_SETUP/logs/SAMS-$CNF_LOGNAME.log"
	elif [ "$1" == "inf" ]; then
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][INFO] $2"
		echo "[$(_mainTimestamp)][$VAR_USERNAME][$VAR_NAME][$VAR_HOST][INFO] $2" >> "$CNF_SETUP/logs/SAMS-$CNF_LOGNAME.log"
	elif [ "$1" == "def" ]; then
		echo "$2"
		echo "$2" >> "$CNF_SETUP/logs/SAMS-$CNF_LOGNAME.log"
	fi 
}

# Main Script Body
mkdir "$CNF_SETUP/logs" #needs if exist check
_mainLog "def" "******************** $VAR_NAME v$CNF_VER ********************" #opening log entry
_mainLog "inf" "Starting Script" #opening log entry

# Dertimne local IP address, broadcast set location
VAR_LOCALIPADD=$(ifconfig en0 | grep -w "inet" | awk -F" " {'print $2'})
VAR_LOCALBCAST=$(ifconfig en0 | grep -w "inet" | awk -F" " {'print $NF'})
_mainLog "inf" "Local IP address: $VAR_LOCALIPADD"
_mainLog "inf" "Local Broadcast : $VAR_LOCALBCAST"

if [ $VAR_LOCALBCAST == "10.54.3.255" ]; then
	_mainLog "inf" "Location: BeechenCliff"
	CNF_NAS="iMacBackup"
	CNF_ADNETBIOSNAME="BEECHENCLIFF"
elif [ $VAR_LOCALBCAST == "10.55.39.255" ]; then 
	_mainLog "inf" "Location: Writhlington"
	CNF_NAS="mnsp-syno-01"
	CNF_ADNETBIOSNAME="WRITHLINGTON"
elif [ $VAR_LOCALBCAST == "10.4.11.255" ]; then 
	_mainLog "inf" "Location: NORTONHILL"
	CNF_NAS="UNKNOWN"
	CNF_ADNETBIOSNAME="NORTONHILL"
fi

_mainLog "inf" "Local NAS NetbiosName: $CNF_NAS"
_mainLog "inf" "AD NetBiosName: $CNF_ADNETBIOSNAME"

if [ ! "$CNF_ENABLED" == "YES" ]; then #exit if the script is not enabled
	_mainLog "wrn" "Script is disabled please change variable CNF_ENABLED to YES if you would like to use it";
	exit; 
fi

if [ ! $CNF_SWTAR == $VAR_SWVER ]; then #check macos version and log if mismatch
	_mainLog "wrn" "*** Running on untested version of macOS ($VAR_SWVER). Script designed for macOS ($CNF_SWTAR). There may be issues"
fi

if [ "$CNF_UPDATES" == "YES" ]; then #if enabled chack for updates
	_mainLog "inf" "Checking server $CNF_SERVER is up and responding"
	ping -q -c5 "$CNF_SERVER" > /dev/null #ping server to see if its up 
	if [ $? -eq 0 ]; then #check ping result
		_mainLog "inf" "Server $CNF_SERVER is alive"
		_mainLog "inf" "Downloading latest scripts"
		curl --url "http://$CNF_SERVER/SAMS/scripts/wrisch-login.sh" --output "$CNF_SETUP/.scripts/wrisch-login.sh" > /dev/null
		curl --url "http://$CNF_SERVER/SAMS/scripts/wrisch-logout.sh" --output "$CNF_SETUP/.scripts/wrisch-logout.sh" > /dev/null
		curl --url "http://$CNF_SERVER/SAMS/scripts/loginitems.sh" --output "$CNF_SETUP/.scripts/loginitems.sh" > /dev/null
		chmod +x "/$CNF_SETUP/.scripts/loginitems.sh"
		curl --url "http://$CNF_SERVER/SAMS/resources/LicenceServerInfo" --output "$CNF_SETUP/.scripts/LicenceServerInfo" > /dev/null
		mv "$CNF_SETUP/.scripts/LicenceServerInfo" "/Library/Application Support/Sibelius Software/Sibelius 6/_manuscript/LicenceServerInfo"
	else
		_mainLog "wrn" "Server $CNF_SERVER failed to respond skipping update check"
	fi
fi

if [ "$CNF_HDRIVE" == "YES" ]; then #mounting network drives
	if [[ "$VAR_USERNAME" == *.* ]]; then #path for student network drives
		_mainLog "inf" "Mounting network drive on $CNF_STUHOME for $VAR_USERNAME"
		sudo -u "$VAR_USERNAME" osascript -e 'mount volume "smb://wri-sr-003/'$VAR_USERNAME'$''"'
	elif [[ ! "$VAR_USERNAME" == *.* ]] && [ ! "$VAR_USERNAME" == "systemadmin" ]; then #path for staff network drives
		_mainLog "inf" "Mounting network drive on $CNF_STAHOME for $VAR_USERNAME"
		sudo -u "$VAR_USERNAME" osascript -e 'mount volume "smb://wri-sr-004/'$VAR_USERNAME'$''"'
	fi
fi

if [ "$CNF_SLINK" == "YES" ]; then #set desktop symlinks
	if [ ! "$VAR_USERNAME" == "systemadmin" ]; then
		_mainLog "inf" "Creating desktop symlink for network drive for $VAR_USERNAME"
		ln -s "/Volumes/$VAR_USERNAME$" "/Users/$VAR_USERNAME/Desktop/$VAR_USERNAME"
	fi
fi

if [ "$CNF_FIXES" == "YES"]; then #a set of macos 'fixes'
	_mainLog "inf" "Disabling shared drives in finder"
	cp "/Writhlington/.resources/com.apple.LSSharedFileList.NetworkBrowser.sfl2" "/Users/$VAR_USERNAME/Library/Application Support/com.apple.sharedfilelist/" #disable shared drives in finder
	chmod 644 "/Users/$VAR_USERNAME/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.NetworkBrowser.sfl2"

	_mainLog "inf" "Setting timezone to Europe/London"
	systemsetup -settimezone "Europe/London" #set timezone

	_mainLog "inf" "Disabling wifi card"
	networksetup -setnetworkserviceenabled Wi-Fi off #disable wifi card
fi

if [ "$CNF_AUTOSTART" == "YES" ]; then #autostart applications after login as user
	if [ ! "$VAR_USERNAME" == "systemadmin" ]; then
		_mainLog "inf" "Launching startup items"
		sudo -u "$USER_SHORT_NAME" "/Writhlington/.scripts/loginitems.sh" &
	fi
fi

#mount NAS drive
CNF_MyMediaWork="smb://$CNF_NAS/$CNF_SMBSHARE"
#sudo -u "$VAR_USERNAME" osascript -e 'mount volume "smb://mnsp-syno-01/MacData01"'

	_mainLog "inf" "Mounting NAS SMB share: $CNF_MyMediaWork"

sudo -u "$VAR_USERNAME" osascript -e "mount volume \"${CNF_MyMediaWork}\""

#check if logging in user is staff or student
VAR_ROLE=$(dscl "/Active Directory/$CNF_ADNETBIOSNAME/All Domains" -read "Users/$VAR_USERNAME" distinguishedName)
_mainLog "inf" "Users DN: $VAR_ROLE"

if [[ "${VAR_ROLE}" =~ "Students" ]] ;then
	_mainLog "inf" "Logging in User Role: Student"
		#use dscl to get intake year...
		#VAR_DN1=$(dscl "/Active Directory/BEECHENCLIFF/All Domains" -read "Users/$VAR_USERNAME" distinguishedName | awk -F"OU=Students" {'print $1'} ) #split at "OU=Students"
		VAR_DN1=$(dscl "/Active Directory/$CNF_ADNETBIOSNAME/All Domains" -read "Users/$VAR_USERNAME" distinguishedName | awk -F"OU=Students" {'print $1'} ) #split at "OU=Students"
		VAR_DN2=$(echo $VAR_DN1 | awk -F"," '{print $(NF-1)}') #split using commas, select penultimate
		INTYR=$(echo $VAR_DN2 | awk -F"OU=" '{print $2}') #split at OU=, select second element.
			_mainLog "inf" "Creating My Media Work symlink"
			_mainLog "inf" "Symlink LDAP distinguished Name part 1: $VAR_DN1"
			_mainLog "inf" "Symlink LDAP distinguished Name part 2: $VAR_DN2"
			_mainLog "inf" "Symlink Intake year: $INTYR"
			_mainLog "inf" "Symlink content: /Volumes/MacData01/$INTYR/$VAR_USERNAME /Users/$VAR_USERNAME/Desktop/My Media Work"
		#create user's dektop symlink
		[ -f "/Users/$VAR_USERNAME/Desktop/My Media Work" ] && rm -f "/Users/$VAR_USERNAME/Desktop/My Media Work" #force delete if exists
		sudo -u "$VAR_USERNAME" ln -s /Volumes/$CNF_SMBSHARE/$INTYR/$VAR_USERNAME "/Users/$VAR_USERNAME/Desktop/My Media Work" #create symlink using extracted vars from DSCL/LDAP lookup
elif [[ "${VAR_ROLE}" =~ "Staff" ]] ;then
	_mainLog "inf" "Logging in User Role: Staff"
		[ -f "/Users/$VAR_USERNAME/Desktop/Mac Student Areas" ] && rm -f "/Users/$VAR_USERNAME/Desktop/Mac Student Areas" #force delete if exists
		sudo -u "$VAR_USERNAME" ln -s /Volumes/$CNF_SMBSHARE "/Users/$VAR_USERNAME/Desktop/Mac Student Areas" #create symlink using extracted vars from DSCL/LDAP lookup

fi

#sed -i 's/old-text/new-text/g'

#mount windows home drive#
VAR_SMB="smb:"
VAR_WINHOME1=$(dscl "/Active Directory/$CNF_ADNETBIOSNAME/All Domains" -read "Users/$VAR_USERNAME" SMBHome | awk -F" " {'print $2'} ) # get users home path
VAR_WINHOME2=$(echo $VAR_WINHOME1 | sed 's/\\/\//g' ) #swap \ with / as osx/nix needs it this way.
VAR_WINHOME3=$VAR_SMB$VAR_WINHOME2 #join vars together

_mainLog "inf" "Mounting Users Windows home drive: $VAR_WINHOME3"
sudo -u "$VAR_USERNAME" osascript -e "mount volume "$VAR_WINHOME3""

#sudo -u "$VAR_USERNAME" osascript -e 'mount volume "smb://wri-sr-004/'$VAR_USERNAME'$''"'

_mainLog "inf" "$VAR_NAME finished"
_mainLog "def" "************************************************************"
