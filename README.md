# SISsync
A collection of scripts for automating data synchronization between Active Directory and Student Information Systems

Designed to be run nightly

Refer to the scripts themselves for comments and usage

As the script makes heavy use of querying Active Directory's "EmployeeID" attribute, it is STRONGLY reccomended you add it
to the list of indexed attributes using the instructions here: https://technet.microsoft.com/en-ca/library/aa995762(v=exchg.65).aspx

These scripts are provided more as a guideline/example to be modified to suit your environment
and not intended to be a complete turnkey solution for provisioning users.

These scripts also do not attempt to delete or remove any old users/data folders by design.

SISsync.ps1 - PowerShell script for creating/updating users

SISsync.sql - Sample SQLPlus script for creating tab delimited export file from PowerSchool

updatePowerSchool.ps1 - PowerShell script for creating a SQLPlus script for updating attributes in PowerSchool
