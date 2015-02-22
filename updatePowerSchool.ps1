#Assuming you have LDAP integration between AD and Powerschool for student sign in, this script will set the LDAP username in PowerSchool based off the student ID number stored in the EmployeeID AD variable
#If desired, you can also use it to set/update the webid and parent password for the students at this time the example below sets the web ID to their student number and password to their DOB in mm/dd/yyyy format similar to the authentiation KEV uses for SchoolCash
#If you don't want to set the parent variables, remove ", AllowWebAccess = 1, Web_ID = Student_Number, Web_Password = to_char(DOB, 'mm/dd/yyyy')" below
#This script will generate an output file C:\SISSync\updatePowerSchool.sql designed to be run against the powerschool database using SQLPlus

import-module ActiveDirectory
write-output "set ECHO off" | out-file -encoding Default C:\SISSync\updatePowerSchool.sql
write-output "set HEADING off" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
write-output "set FEEDBACK off" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
write-output "set LINESIZE 256" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
write-output "set PAGESIZE 0" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
write-output "set TERMOUT off" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
write-output "set TRIMSPOOL on" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
write-output "alter session set nls_date_format = 'mm/dd/yyyy';" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql

#Find any users with employeeID set and export them
$students = Get-ADUser -LDAPFilter "(employeeID=*)" -Properties employeeID
foreach  ($student in $students) {
	$samname = $student.sAMAccountName
	$studentid = $student.employeeID
	write-output "UPDATE Students" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
	write-output "SET Student_AllowWebAccess = 1, LDAPEnabled = 1, Student_Web_ID = '$samname', AllowWebAccess = 1, Web_ID = Student_Number, Web_Password = to_char(DOB, 'mm/dd/yyyy')" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
	write-output "WHERE Student_Number = $studentid;" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
}

write-output "exit;" | out-file -encoding Default -append C:\SISSync\updatePowerSchool.sql
