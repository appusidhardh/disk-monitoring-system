#!/bin/bash
thersholdPercentage=$1
mailId=$2
#this function checks for error $1 is the value returned by the 
#command $3 is the message to print $2 decide whether to exit or not
checkError()
{
        returnValue=$1
        message=$3
        exitValue=$2
        if [ $returnValue -ne 0 ]; then
                echo $message
                echo "Returned value $returnValue"
                if [ $exitValue -eq 1 ]; then
                        echo "Critical error. Unable to proceed. Exiting."
                        exit
                fi
        fi

}
#checking if script is running as sudo or root
ruser=`whoami`
if [ "$ruser" != 'root' ]; then
	echo "You are using a non-privileged account. Try sudo ./monitor.sh. Exiting"
	sleep 5
	exit
fi

sudo smartctl -v | grep smartctl >/dev/null #checking if smartctl exist else insall it
if [ $? -ne 0 ]; then
	echo "smartmontools is not installed. Trying to install smartmontools."
	sudo apt-get install smartmontools
	checkError $? 1 "Install smartmontools failed."
	echo "smartmontools installed successfully"
fi

#----this while runs forever keeping the script alive------------------------#
while [ false ]
do
	#greping infromation about diskspace from df
	df | grep -vE '^Filesystem|tmpfs|cdrom|none|udev' | awk '{ print $5 " " $1 " " $3 " " $4 }' > tempDiskinfo
	#counting total number of disks
	diskCount=`df -H | grep -vE '^Filesystem|tmpfs|cdrom|none|udev' | wc -l`
	#loop through all the disks
	while [ $diskCount -gt 0 ]
	do
		#removing whitspace in file diskcheckStatus
		sed -r 's/\s+//g' diskcheckStatus>>/dev/null
		diskName=`sed "${diskCount}q;d" tempDiskinfo | awk '{print $2}'`
		diskFreepercentage=`sed "${diskCount}q;d" tempDiskinfo | awk '{print $1}'|awk -F'%' '{print $1}'`
		diskFreespace=`sed "${diskCount}q;d" tempDiskinfo | awk '{print $4}'`
		diskUsedspace=`sed "${diskCount}q;d" tempDiskinfo | awk '{print $3}'`
		#following two var s are used for check if the disk had any previous failure
		diskName_th=$(echo "disk"$diskCount"th")
		diskName_hc=$(echo "disk"$diskCount"hc")
		#writing basic info to log

		echo "Disk Name: $diskName" >> disk.log
		echo "Use: $diskFreepercentage% Available: $diskFreespace Used: $diskUsedspace" >> disk.log
		#checking if the thersold is less than diskspace
		if [ $thersholdPercentage -lt $diskFreepercentage ]; then
			#disk usage is greater than the thershold->writitng to file
			
			echo "`date` : Thershold broke for disk $diskName. Available disk Space is $diskFreespace">>disk.log 
			echo "Thershold broke for disk $diskName on `date`. Available disk Space is $diskFreespace" | mail -s "Disk problem detected" $mailId
			#writting the failure to a different file for future checking
			grep -q "^${diskName_th}" diskcheckStatus || echo $diskName_th>>diskcheckStatus
			#sed -i "s/^${diskName}/${diskName}=0/; t; $ a${diskName}=0" diskcheckStatus
			
		else
			#checking if this disk had issues before if yes log and mail that its recovered now and clearing the value from diskcheckStatus
			grep -q "^${diskName_th}" diskcheckStatus && echo "`date` : disk space is issue resolved">>disk.log && echo "Disk space issue resolved" | mail -s "Disk problem detected" $mailId && sed "s|$diskName_th||g" -i diskcheckStatus
			echo "`date` : thershold is okay for disk $diskName">>disk.log
			
			
		fi
		#checking if the disk has any health issues
		healtStatus=`smartctl -d ata -H $diskName | grep "test result" | awk -F ': ' '{print $2}'`
		passed="PASSED"
		if [ $healtStatus=$passed ]; then
			#if passed checking for any previous failure and report the recovery from that failure
			grep -q "^${diskName_hc}" diskcheckStatus && echo "`date` : disk health issue is resolved">>disk.log && echo "Disk health issue resolved" | mail -s "Disk problem detected" $mailId && sed "s|$diskName_th||g" -i diskcheckStatus
			echo "`date` : Overall healthscheck result for $diskName: Passed">>disk.log
			
		else
			#if failed report it and save it for future checking 
			echo "`date` : Overall healthcheck result for $diskName: failed" >>disk.log
			echo "`date` : Overall healthcheck result for $diskName: failed" | mail -s "Disk problem detected" $mailId
			grep -q "^${diskName_hc}" diskcheckStatus || echo $diskName_hc>>diskcheckStatus
			
		fi
		one=1
		diskCount=$(( diskCount-one ))
		echo "-----------------------------------------------------------------------------------------">>disk.log
	done
echo "=========================================================================================">>disk.log
sleep 5
done
