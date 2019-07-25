@echo OFF
set EXPORTS=C:\SISSync
sqlplus -s PSNavigator/PSNavigatorPassword @%EXPORTS%\PSExport.sql
exit
