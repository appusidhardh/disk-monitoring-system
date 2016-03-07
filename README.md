A minimum viable disk monitoring system that can accomplish the following: - Supports any number of disks in any configuration. - Runs constantly and monitors disk utilization and health information. - Can be run on any number of systems without modification. - Alerts via email when the disk utilization is above certain threshold or upon a disk failure. - If the state of the alert changes, the monitoring system should detect it and log it. 

How to run: 

sudo sh disk-monitoring-system threshold value(integer) email-id

The script logs everything to the file disk.log and send mails in case of failures or recoveries (assuming the mail server is setup already. This script check three things.

1.If the disk is used more than the % of the threshold value provided. If the usage ia above than the value provided it confiders the disk is running out of space. 
2.Script check the disks with smartctl. If the overall health check result is failure then it consider the disk has bad health 
3.Has the disk recovered from any of the above mentioned issues 

In all three cases above mentioned script reports this to log and send email. This script runs in an infinite loops with five seconds delay.

Files explained:
monitor.sh is the bash script which does the job. This script has been tested in ubuntu 14.04 only due to the limited resorsources I could gather at the moment.
disk.log is the main log file which logs everything 
tempDiskinfo is a temporary file used for storing information,which get over write every 5 sec
diskcheckStatus is the file which is used to store the information about previous failures.

