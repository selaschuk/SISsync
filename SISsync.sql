/*Sample SQL export from PowerSchool
If the preferred name indicator is Alias, export using the AKA name
otherwise use the legal name*/
set ECHO off
set HEADING off
set FEEDBACK off
set LINESIZE 256
set PAGESIZE 0
set TERMOUT off
set TRIMSPOOL on
alter session set nls_date_format = 'mm/dd/yyyy';
spool E:\Exports\SISsync.txt
select
CASE ps_customfields.getstudentscf(id, 'AB_PreferredNameInd') WHEN 'Alias' THEN ps_customfields.getstudentscf(id, 'AB_AKA_Surname') ELSE last_name END||chr(9)||
CASE ps_customfields.getstudentscf(id, 'AB_PreferredNameInd') WHEN 'Alias' THEN ps_customfields.getstudentscf(id, 'AB_AKA_Given_Names') ELSE first_name END||chr(9)||
SchoolID||chr(9)||
Student_Number||chr(9)||
Grade_Level||chr(9)||
Sched_YearOfGraduation
FROM students WHERE enroll_status = 0;
spool off
exit;
