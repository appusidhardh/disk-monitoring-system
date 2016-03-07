# disk-monitoring-system
a minimum viable disk monitoring system that can accomplish the following:  - Supports any number of disks in any configuration. - Runs constantly and monitors disk utilization and health information. - Can be run on any number of systems without modification. - Alerts via email when the disk utilization is above  certain threshold or upon a disk failure. - If the state of the alert changes, the monitoring system should detect it and log it.
How to run:
sudo sh disk-monitoring-system thersholdvalue(integer) email-id

The script logs everything to the file disk.log and send mails incase of failures or recoveries (assuming the mail server is setup already.
This script check three things 
1.If the disk is used more than the % of the thershold value provided. If the usage ia above than the value provided it confiders
the disk is running out of space.
2.Script check the disks with smartctl. If the overall healthcheck result is failure then it consider the disk has bad health
3.Has the disk recovered from any of the above mentioned issues
In all three cases above mentiones script reports this to log and send email.
