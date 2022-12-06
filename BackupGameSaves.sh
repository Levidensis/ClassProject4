#!/bin/bash

## Script By Levidensis ##
# Version: 1
## not really intended for distribution ##
  ## This Script was made as a class project.
  ## It was rushed and not very well thought out. You have been warned. 

##-------------------------------------------------------##
 ## This Script was made to backup Steam Save files in userdata and MyGames
 ## modify if needed/wanted. Mind the jank.

 ## Manual Overides ##
  # edit these only if you need to overide the Scripts Auto detection for some reason #

  ## Change this to your Steam ID
  SteamUID=""
  #Note: the script will try and find your SteamID from your system, but it might not work.

  ## Change this to where you want the backups to save to
  DirBackup=""

  ## Depending on your steam setup this path might be different. 
  ## If auto detection fails, set this.
  ## Needs to point to userdata, needs single quotes.
  ## Example: '/C/Program Files (x86)/Steam/userdata' 
  SteamDir=''

  ## Script shouldn't have any issue finding a standard location for this folder. Will outright ignore it if it can't find it. 
  ## path to the "My Games" Folder. usually "/c/Users/<username>/Documents/My Games"
  ## Needs to point to "My Games", needs single quotes.
  MyGamesDir=''

  ## Change to the Number of log files you want to keep, deleting older logs. Setting to 0 will not delete any old logs. 
  #Default: 5
  NumLogsToKeep=5

 ## \Manual Overides ##

 ##-------------------------------------------------------##
 ## You should not need to edit anything below this point ##
 ##-------------------------------------------------------##
  
  
  ## Various Variables I'll Need Later
   FileDate=$(date '+%Y-%m-%d_%H-%M-%S')
   AutoIDBool=0
  ## Innitial build of path variables. 
   DirSaves="$SteamDir/$SteamUID"
   DirGinfo="$DirBackup/Ginfo"
   OrrScriptDir=$(pwd)
  ##steam web API link
   APIURL='https://store.steampowered.com/api/appdetails?appids='
  ## Log file location and name
   LogFile="$DirBackup/SteamBack.Log"

 
##-------------------------------------------------------##

## Script Start ##

## Check to see if Backup location is specified. if not use current Dir to make a folder. 
     if [ -z "$DirBackup" ] ; then
        cd "$OrrScriptDir"
        printf "\nBackup Location not specified. Using Script location:\n"
        pwd
        DirBackup=$(pwd)
        DirGinfo="$DirBackup/Ginfo"
        LogFile="$DirBackup/SteamBack.Log"
     fi
printf "\nHere We Go~\n\n"

##Check to see if backup directories that script makes exist, if not create them. also make log file if missing. 
    if [ ! -d "$DirBackup" ]; then
        mkdir -p "$DirBackup"
    fi
    if [ ! -d "$DirGinfo" ]; then
        mkdir -p "$DirGinfo"
    fi
    if [ ! -d  "$DirBackup/SteamUserdataSaves" ]; then
        mkdir -p "$DirBackup/SteamUserdataSaves"
    fi
    if [ ! -d  "$DirBackup/MyDocSaves" ]; then
        mkdir -p "$DirBackup/MyDocSaves"
    fi
    if [ ! -f "$LogFile" ]; then
        printf "Log file created on $FileDate\n" > "$LogFile"
    fi 

## check size of log file, if over line limit incriment with FileDate
    if [ $(wc -l $LogFile | awk '{print $1}') -gt "25000" ]; then
        printf "\nLog is getting big iterating log(s)\n" |& tee -a "$LogFile"
        printf "\n"

        ## Set count to 0 and use it to rename log file from non-numbered to log0 for use in loop
        Count=0
        mv -v "$LogFile" "$LogFile$Count" |& tee -a "$LogFile"

        ## make new Logfile to replace the one just renamed
        printf "Log file created on $FileDate\n" > "$LogFile"

        ## Get list of log files from DirGinfo
        AryLogs=$(ls "$DirBackup"/SteamBack.Log*)

        ## get true count of Array entries
        for Log in ${AryLogs[@]}; do
            OrrCount=$[OrrCount + 1] 
        done
        ## set Count for loop
        Count=$[OrrCount - 1]
        ## Loop to rename log files starting from highest number and moving backward
        for Log in ${AryLogs[@]}; do
            x=$Count ; y=$[Count + 1]
            mv -v "$LogFile$x" "$LogFile$y" |& tee -a "$LogFile"
            Count=$[Count - 1]
            unset x y
        done
        ## Remove log file numbers higher or equal to than NumLogsToKeep variable so that total number of logs(including current unnumbered log) is actually equal to NumLogsToKeep
        if [ "$NumLogsToKeep" -ne 0 ] && [ "$OrrCount" -ge "$NumLogsToKeep" ]; then
            if [ "$OrrCount" -eq "$NumLogsToKeep" ]; then
                rm -v "$LogFile$NumLogsToKeep" |& tee -a "$LogFile"
            else 
                for i in $(seq $NumLogsToKeep $OrrCount); do 
                rm -v "$LogFile$i" |& tee -a "$LogFile"
                done
            fi
        fi
        ## Cleanup
        unset Count OrrCount AryLogs 
    fi

## Print Date for log file
    FileDate=$(date '+%Y-%m-%d_%H-%M-%S')
    printf "\n\nDate: $FileDate" |& tee -a "$LogFile"

## Find The 'My Games' folder
    if [ -z $MyGamesDir ]; then
        DirUser="/Users/$(whoami)/Documents/My Games"
        for Letter in {a..z}; do
            if [ -d "/$Letter/$DirUser" ]; then
                MyGamesDir="/$Letter/$DirUser"
                printf "\n"
                printf "\nI found \"My Games\" at: \n$MyGamesDir" |& tee -a "$LogFile"
                break
            fi
        done
    fi
## Auto Detect Steam Info
    ## Checking for Steam install location
    if [ -z "$SteamDir" ]; then 
        ## Search alphabet drives, break when one is found.
        for Letter in {a..z}; do
            if [ -d "/$Letter/Program Files (x86)/Steam/userdata" ]; then
                SteamDir="/$Letter/Program Files (x86)/Steam/userdata"
                printf "\n"
                printf "\nI found\"userdata\" at: \n$SteamDir" |& tee -a "$LogFile"
                break
            fi
        done
        ##If the above loop could not find the Steam Dir (variable will still be empty) ask user if they would like to perform full search. It's time consuming but should work. Was successful in testing but Extreamly strange installations might cause it issue. The search first looks through C drive, and then the D drive if one exists. No other drives are considered.
        ## Users always have option to manually set userdata folder in script.
        if [ -z "$SteamDir" ]; then 
            printf "\nCould not find Steam in usual places." |& tee -a "$LogFile"
            printf "\nWould you like you try a search?\nthis could take a very long time if you have a lot of storage.\n"
            read -p "Perform search? " -n 1 -r
            printf "\n"
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                printf "Set path in script override section where indicated,\n\nHave A Nice Day.\n"
                exit 1
            fi
            printf "\nSearching for steam" |& tee -a "$LogFile"
            printf ", this could take a while, please be patient.\n\n"
            printf "It is safe to ignore \"Permission denied\" errors." 
            sleep 1
            printf "\n"
            SteamDir=$(find /c/ -type d -wholename */Steam/userdata -print -quit )
            if [ ! -d "$SteamDir" ] && [ -d "/d/" ]; then
                printf "\nCouldn't find on C drive, trying the D\n" |& tee -a "$LogFile"
                SteamDir=$(find /d/ -type d -wholename */Steam/userdata -print -quit )
            fi
            if [ ! -d "$SteamDir" ]; then
                printf "I wasn't able to find anything, Sorry." |& tee -a "$LogFile"
                exit 1
            fi
            printf "I found: \n$SteamDir" |& tee -a "$LogFile"
        fi
    fi
    ## Checking for Steam ID, Searches for 4 numeric digits followed by anything. This should get any UIDs that are four digits or longer while ignoring the non-UID items in the location.
    ## Does not account for multiple steam IDs.
        if [ -z $SteamUID ]; then
            printf "\n"
            printf "\nTrying to find Steam ID." |& tee -a "$LogFile"
            printf " \n(this might fail if your Steam ID is smaller than 4 digits)\n"
            cd "$SteamDir"
            SteamUID=$(ls -d -- [0-9][0-9][0-9][0-9]*)
            printf "\nHere's what I found: $SteamUID" |& tee -a "$LogFile"
            printf "\nTrying it..."
            DirSaves="$SteamDir/$SteamUID"
            AutoIDBool=1
        fi

        if [ -d "$DirSaves" ]; then
            printf "\nShould be good\n"
         elif [ -d "$SteamDir" ] && [ ! -d "$DirSaves" ]; then
            printf "\nSomething went wrong."
            printf "\nError ID: Wierd-AutoUID-1" |& tee -a "$LogFile"
         else
            printf "\nIt didn't work, manually set SteamUID in Script."
            exit 1
        fi

## Check DirSaves Path one more time, just in case
    if [ ! -d "$DirSaves" ]; then
        printf "\nSomething went wrong" |& tee -a "$LogFile"
        printf "\nDoes not exist: $DirSaves" |& tee -a "$LogFile"
        if [ ! -d "$SteamDir" ]; then
            printf "\nErrorID: D-001\n" |& tee -a "$LogFile"
            printf "\nThis error is typically caused by a non-standard Steam installation location. \nCheck that the path to your steam userdata folder is the same path in the script's SteamDir variable."
         else
         ## if SteamDir exists, but invalid Steam ID is detected, check to see if it was manually set. Different Errors for each state. 
         ## Script should not get this far if using AutoDetect UID
            if [ $AutoIDBool -lt 1 ]; then
                printf "\nErrorID: D-002\n" |& tee -a "$LogFile"
                printf "\nThis error is typically caused by a wrong Steam UID. Your UID should match the folder in your Steam's userdata folder. \nCheck to make sure the SteamUID variable is set correctly."
             else
                printf "\nErrorID: D-003\n" |& tee -a "$LogFile"
                printf "\nAutodetectUID as critically failed. Manually set SteamUID in script."
            fi
        fi
    fi

## Print and Log useful info
    printf "\nSteam Saves Location:" |& tee -a "$LogFile"
    printf "\n "
    printf "$DirSaves \n" |& tee -a "$LogFile"
    printf "\nBackup Location:" |& tee -a "$LogFile"
    printf "\n "
    cd "$DirBackup"
    pwd  |& tee -a "$LogFile"

## Ensure shell is in DirSaves before executing loop
cd "$DirSaves"
## Main loop for Backing up userdata using App_ID array 
    for AppID in *; do

        ## Check for alpha or null characters, IDs should only be numeric
            if [[ $AppID =~ [!a-zA-Z] ]] || [ -z $AppID ]; then
                continue
            fi

        ## Check size of folder, if under 5K continue to next loop itteration
            if [ $(du -s $AppID | awk '{print $1}') -lt "5120" ]; then
                printf "\n"
                printf "\nSkipping: $AppID is less then 5K" |& tee -a "$LogFile"
                printf "\n"
                continue
            fi

        ## Get the app details page and place it into a file, if already exists, skip
            if [ ! -f "$DirGinfo/gameinfo$AppID.txt" ]; then
                printf "\nGetting Game info for $AppID"
                ## outputs to Game info txt file normally, errors get displayed and put into log file. Probably. It worked in small scale testing.
                Curl -sS "$APIURL$AppID" 1> "$DirGinfo/gameinfo$AppID.txt" 2> >(tee -a "$LogFile" >&2)
                ## Fake loading dots, the wait is just to keep the script from spamming Steam servers with requests and triggering their DoS protection. 
                printf "..."
                sleep 1
                printf "\n Info got\n"
            fi

        # If info comes back as failed, continue to next loop
            if [ $(awk /:false}}/ "$DirGinfo/gameinfo$AppID.txt" ) ]; then
                printf "\n"
                printf "\nSkipping: $AppID is not a game ID" |& tee -a "$LogFile"
                printf "\n"
                continue
            fi

        ##get "name":"<gamename>" string from appdetails page and remove trailing spaces, and dots to keep Windows parser happy.
            GameName=$(awk -F, '{print $3}' "$DirGinfo/gameinfo$AppID.txt" | awk -F\" '{print $4}' | sed -e 's/^[[:space:]]*//' | sed 's/\.$//')
            printf "\nWorking on $GameName" |& tee -a "$LogFile"

        # Build backup Dir
            DirGameBackup="$DirBackup/SteamUserdataSaves/$GameName"

        ## Make Folder to put backups in if does not exist
            if [ ! -d "$DirGameBackup" ]; then
                printf "\nMaking: $DirGameBackup" |& tee -a "$LogFile"
                mkdir -p "$DirGameBackup"
            fi

        ## Get last Changed date of game folder
            printf "\n--Last Changed Date:" |& tee -a "$LogFile"
                NewChangeDate=$(stat $AppID | grep "Change:" | awk -F": " '{print $2}')
            printf "\n"
            printf " $NewChangeDate " |& tee -a "$LogFile"

        ## get old hash from file if exists
            if [ -f "$DirGameBackup/LstChDate-$AppID.txt" ]; then 
                OldChangeDate=$(cat "$DirGameBackup/LstChDate-$AppID.txt") 
            fi

        ## if old change date is the same as new change date, continue to next loop itteration, skipping backup stage.
            if [ "$NewChangeDate" == "$OldChangeDate" ]; then
                printf "\nSkipping: Change Date looks unchanged from last backup." |& tee -a "$LogFile"
                printf "\n"
                continue
            fi
        # Update Timestamp
            FileDate=$(date '+%Y-%m-%d_%H-%M-%S')

        #if loction to copy from is good, copy files to destination
            if [ -d "$DirSaves/$AppID" ] && [ -d "$DirGameBackup" ]; then
                printf "\nStarting Copy from $DirSaves/$AppID to $DirGameBackup" |& tee -a "$LogFile"
             ## Make Tarball, print dots in case it takes a while 
                printf "\nBacking up files"
                while true ;do sleep 1 ;printf "." ;done &
                tar -czf "$DirGameBackup/$FileDate.tar.gz" "$AppID"
                kill $!; trap 'kill $!' SIGTERM
             ## After copy is complete, update stored Hash
                printf "$NewChangeDate" > "$DirGameBackup/LstChDate-$AppID.txt"
                printf "\nChange Date written to: $DirGameBackup/LstChDate-$AppID.txt" |& tee -a "$LogFile"           
                printf "\nDone'd\n"
             else
             ## Error catch, moves on after short wait to allow user to terminate script if desired.
                printf "\nsomething went wrong" |& tee -a "$LogFile"
                printf "\nCode: $AppID Copying Chunk Data" |& tee -a "$LogFile"
                sleep 2 
                printf "\nMoving on...\n"
            fi

        ## Cleanup variables set in loop to avoid contamination
            unset NewChangeDate OldChangeDate DirGameBackup GameName
    done

## Ensure in correct Dir before running loop
    cd "$MyGamesDir"
## Main loop for backing up "My Games"
    for MGame in *; do
        printf "\n$MGame"

        # Build backup Dir
            DirGameBackup="$DirBackup/MyDocSaves/$MGame"

        ## Make Folder to put backups in if does not exist
            if [ ! -d "$DirGameBackup" ]; then
                printf "\nMaking: $DirGameBackup" |& tee -a "$LogFile"
                mkdir -p "$DirGameBackup"
            fi

        ## Get Change Date of game folder
            printf "\n--Last Changed Date:" |& tee -a "$LogFile"
                NewChangeDate=$(stat "$MGame" | grep "Change:" | awk -F": " '{print $2}')
            printf "\n"
            printf " $NewChangeDate " |& tee -a "$LogFile"

        ## get old change date from file if exists
            if [ -f "$DirGameBackup/LstChDate-$MGame.txt" ]; then 
                OldChangeDate=$(cat "$DirGameBackup/LstChDate-$MGame.txt") 
            fi

        ## if old change date is the same as new change date, continue to next loop itteration, skipping backup stage.
            if [ "$NewChangeDate" == "$OldChangeDate" ]; then
                printf "\nSkipping: Change Date looks unchanged from last backup" |& tee -a "$LogFile"
                printf "\n"
                continue
            fi
        # Update Timestamp
            FileDate=$(date '+%Y-%m-%d_%H-%M-%S')

        #if loction to copy from is good, copy files to destination
            if [ -d "$MyGamesDir/$MGame" ] && [ -d "$DirGameBackup" ]; then
                printf "\nTaring from $DirSaves/$MGame to $DirGameBackup" |& tee -a "$LogFile"
             ## Make Tarball, print dots in case it takes a while 
                printf "\nBacking up files"
                while true ;do sleep 1 ;printf "." ;done &
                tar -czf "$DirGameBackup/$FileDate.tar.gz" "$MGame"
                kill $!; trap 'kill $!' SIGTERM
             ## After copy is complete, update stored Hash
                printf "$NewChangeDate" > "$DirGameBackup/LstChDate-$MGame.txt"
                printf "\nChange Date written to: $DirGameBackup/LstChDate-$MGame.txt" |& tee -a "$LogFile"
                printf "\nDone'd\n"
             else
             ## Error catch, moves on after short wait to allow user to terminate script if desired.
                printf "\nsomething went wrong" |& tee -a "$LogFile"
                printf "\nCode: $MGame Copying Chunk Data 2" |& tee -a "$LogFile"
                sleep 2 
                printf "\nMoving on...\n"
            fi

        ## Cleanup variables set in loop to avoid contamination
            unset NewChangeDate OldChangeDate DirGameBackup GameName
    done


printf "\n\n\nSuper Done'd \n\n"
## Optional require keypress to close
# printf "\nPress any key to continue\n"
# while [ true ] ; do
# 	read -t 15 -n 1
# 	if [ $? = 0 ] ; then
# 		exit ;
# 	fi
# done