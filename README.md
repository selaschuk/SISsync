# SISsync
A collection of scripts for automating data synchronization between Active Directory and Student Information Systems

Designed to be run nightly

Refer to the scripts themselves for comments and usage

As the script makes heavy use of querying Active Directory's "EmployeeID" attribute, it is STRONGLY reccomended you add it
to the list of indexed attributes using the instructions here: https://technet.microsoft.com/en-ca/library/aa995762(v=exchg.65).aspx

These scripts are provided more as a guideline/example to be modified to suit your environment
and not intended to be a complete turnkey solution for provisioning users.

These scripts also do not attempt to delete or remove any old users/data folders by design.

SISsync.ps1 - PowerShell script for creating/updating users. This will also generate a file called UpdateSIS.txt which can be imported by a powerschool AutoComm job similar to this: https://i.imgur.com/M32MpYI.png Goes on the AD server

PSExport.bat - Simple batch file for calling the SQL script. Goes on the PS server and scheduled to run before SISsync.ps1. The resulting file needs to be shipped to the AD server for importing.

PSExport.sql - Sample SQLPlus script for creating tab delimited export file from PowerSchool. Goes on the PS server.

