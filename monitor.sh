#!/bin/bash
thesholdPercentage=$1
mailId=$2
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

ruser=`whoami`
if [ "$ruser" != 'root' ]; then
	echo "You are using a non-privileged account. Try sudo ./monitor.sh. Exiting"
	sleep 5
	exit
fi

sudo smartctl -v | grep smartctl >/dev/null
if [ $? -ne 0 ]; then
	echo "smartmontools is not installed. Trying to install smartmontools."
	sudo apt-get install smartmontools
	checkError $? 1 "Install smartmontools failed."
	echo "smartmontools installed successfully"
fi

#----Writting all the info to file------------------------#
while [ false ]
do
	df | grep -vE '^Filesystem|tmpfs|cdrom|none|udev' | awk '{ print $5 " " $1 " " $3 " " $4 }' > tempDiskinfo.txt
	diskCount=`df -H | grep -vE '^Filesystem|tmpfs|cdrom|none|udev' | wc -l`
	while [ $diskCount -gt 0 ]
	do
		diskName=`sed "${diskCount}q;d" tempDiskinfo.txt | awk '{print $2}'`
		diskFreepercentage=`sed "${diskCount}q;d" tempDiskinfo.txt | awk '{print $1}'|awk -F'%' '{print $1}'`
		diskFreespace=`sed "${diskCount}q;d" tempDiskinfo.txt | awk '{print $4}'`
		diskUsedspace=`sed "${diskCount}q;d" tempDiskinfo.txt | awk '{print $3}'`
		echo "Disk Name: $diskName" >> disk.log
		echo "Use: $diskFreepercentage% Available: $diskFreespace Used: $diskUsedspace" >> disk.log
		
		if [ $thesholdPercentage -lt $diskFreepercentage ]; then
			time_stamp=`date`
			echo "$time_stamp : Thershold broke for disk $diskName. Available disk Space is $diskFreespace">>disk.log 
			echo "Thershold broke for disk $diskName on $time_stamp. Available disk Space is $diskFreespace" | mail -s "Disk problem detected" $mailId
		else
			echo "`date` : thershold is okay for disk $diskName">>disk.log
		fi
		healtStatus=`smartctl -d ata -H $diskName | grep "test result" | awk -F ': ' '{print $2}'`
		passed="PASSED"
		if [ $healtStatus=$passed ]; then
			echo "$time_stamp : Overall healthscheck result for $diskName: Passed">>disk.log
		else
			echo "$time_stamp : Overall healthcheck result for $diskName: failed" >>disk.log
			echo "$time_stamp : Overall healthcheck result for $diskName: failed" | mail -s "Disk problem detected" $mailId

		fi
		one=1
		diskCount=$(( diskCount-one ))
		echo "-----------------------------------------------------------------------------------------">>disk.log
	done
echo "=========================================================================================">>disk.log
sleep 2
done
