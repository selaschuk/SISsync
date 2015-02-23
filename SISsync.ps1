# Import the Active Directory functions
Import-Module ActiveDirectory

#Setup some hashtables
#For each school code in your SIS, map it to the appropriate fileserver in the format "schoolcode" = "servername";
$server = @{"1001" = "SchoolA-FS"; "1002" = "SchoolB-FS"; "1003" = "SchoolC-FS"}
#If you're using standardized abbreviations anywhere (perhaps your groups are named like like SITEA-Students, SITEB-Students etc) It's useful to create a map of those abbreviations
$siteabbr = @{"1001" = "SITEB"; "1002" = "SITEB"; "1003" = "SITEC"}
#Create a map of codes to Active Directory OUs where students should be moved/created etc
$orgunits = @{"1001" = "School A High"; "1002" = "School B Elementary"; "1003" = "School C Jr High"}

# Import the Data - This is based on using the accompanying SISsync.sql file to extract data from PowerSchool and expects a tab delimited file, if you're using a CSV from another system or autosend, change `t to , (or omit the delimiter option entirely) and modify the headers appropriately
$sisfile = Import-Csv -delimiter "`t" -Path C:\SISSync\SISsync.txt -Header "sn","givenName","schoolid","studentid","grade","gradyear"

#Start Processing per file line
foreach ($sisline in $sisfile) {
	#Set the username example below is firstname.lastname
	$sAMAccountName = $sisline.givenName + "." + $sisline.sn
	#tidy up samaccountName to make it more valid (no spaces, double periods or apostrophies. Helpful for when there's data entry 'issues' in your source
	$sAMAccountName = $sAMAccountName.replace(" ","")
	$sAMAccountName = $sAMAccountName.replace("..",".")
	$sAMAccountName = $sAMAccountName.replace("'","")
	#Set the displayname for the account in AD example below is firstname space lastname
	$name = $sisline.givenName + " " + $sisline.sn
	#Set a password for the account, example below takes their student number and assigns it as their initial password
	$password = ConvertTo-SecureString -AsPlainText $sisline.studentid -Force
	#Set the UPN for the account for most instances, should be AD Account name + @AD.FQDN
	$userPrincipalName = $sAMAccountName + "@school.local"
	#Set the mail attribute for the account (if desired, usually helpful if you're synchronizing to Google Apps/Office 365)
	$mail = $sAMAccountName + "@school.ca"
	#Set name attributes
	$givenName = $sisline.givenName
	$sn = $sisline.sn
	#Store student ID in AD's "EmployeeID" attribute
	$employeeID = $sisline.studentid
	#Optional location attributes, helpful if syncing to Moodle via LDAP
	$c = "CA"
	$co = "Canada"
	$l = $orgunits.Get_Item($sisline.schoolid)
	#Optional other attribute population we set these because they're easy to view with the MMC taskpad we push to secretaries to allow them to reset passwords
	$company = $orgunits.Get_Item($sisline.schoolid)
	$physicalDeliveryOfficeName = $sisline.grade
	$description = $sisline.gradyear
	$comment = $sAMAccountName + "@school.ca"
	#Create a hashtable of all the "otherattributes" this is used when we create/update the user
	$otherAttributes = @{'userPrincipalName' = "$userPrincipalName"; 'mail' = "$mail"; 'comment' = "$comment"; 'givenName' = "$givenName"; 'sn' = "$sn"; 'employeeID' = "$employeeID"; 'c' = "$c"; 'l' = "$l"; 'company' = "$company"; 'physicalDeliveryOfficeName' = "$physicalDeliveryOfficeName"; 'description' = "$description"}

	#recast description as a string because AD commands require it and it gets converted to int if it's all numeric.
	$otherAttributes.description = [string]$otherAttributes.description

	#set the path variable to the OU the student should end up in. In the example below the AD OU Structure is Schools -> Schoolname -> Students
	$path = "OU=Students,OU=" + $company + ",OU=Schools,DC=school,DC=local"

	#Check if student exists
	#THIS IS WHERE IT GETS TERRIBLY SLOW IF YOU HAVEN'T ADDED EMPLOYEEID TO THE LIST OF INDEXED AD ATTRIBUTES. STRONGLY CONSIDER THIS.
	$user = Get-ADUser -Filter {employeeID -eq $employeeID}

	if ($user -eq $null) {
		#student doesn't exist, create them
		#find a valid username
		#This is probably the most inelegant backwards way of doing this, but it works. Feel free to improve
		$i = 1
		$sAMSearch = $sAMAccountName
		while ((Get-ADUser -Filter {sAMAccountName -eq $sAMSearch}) -ne $null) {		
			$sAMSearch = $sAMAccountName + $i
			$i++
		}
		$i--
		if ($i -ne 0) {
		#name was taken, update constants to reflect new name containing number
			$sAMAccountName = $sAMSearch
			$otherAttributes.Set_Item("userPrincipalName", $sAMAccountName + "@school.local")
			$otherAttributes.Set_Item("mail", $sAMAccountName + "@school.ca")
			$otherAttributes.Set_Item("comment", $sAMAccountName + "@school.ca")
			$name = $name + $i
		}
		#create user using $sAMAccountName and set attributes and assign it to the $user variable
		New-ADUser -sAMAccountName $sAMAccountName -Name $name -Path $path -otherAttributes $otherAttributes -Enable $true -AccountPassword $password
		$user = Get-ADUser -Filter {employeeID -eq $employeeID}
	} elseif (($user.Surname -ne $sn) -or ($user.givenName -ne $givenName)) {
		#The first or last names were changed in the import source, need to make some changes to the user
		#find a valid username
		#This is probably the most inelegant backwards way of doing this, but it works. Feel free to improve
		$i = 1
		$sAMSearch = $sAMAccountName
		while ((Get-ADUser -Filter {sAMAccountName -eq $sAMSearch}) -ne $null) {		
			$sAMSearch = $sAMAccountName + $i
			$i++
		}
		$i--
		if ($i -ne 0)
		#need to update Name, sAMAccountName, UPN and email because of name collison  
		{
			$sAMAccountName = $sAMSearch
			$otherAttributes.Add("sAMAccountName", $sAMAccountName)
			$otherAttributes.Set_Item("userPrincipalName", $sAMAccountName + "@school.local")
			$otherAttributes.Set_Item("mail", $sAMAccountName + "@school.ca")
			$otherAttributes.Set_Item("comment", $sAMAccountName + "@school.ca")
			$name = $name + $i
		}
		Rename-ADObject -Identity $user $name
		#need to re-key user variable after rename
		$user = Get-ADUser -Filter {employeeID -eq $employeeID}
		#Update AD attributes to reflect changes
		
		Set-ADUser -Identity $user -replace $otherAttributes -SamAccountName $sAMAccountName
	} else {
		#Update AD Attributes for existing user whos name hasn't changed. Unset anything usernamebased first since the username hasn't changed
		$otherAttributes.Remove("userPrincipalName")
		$otherAttributes.Remove("mail")
		$otherAttributes.Remove("comment")  
		Set-ADUser -Identity $user -replace $otherAttributes
	}
	#reset the samaccountname variable to what it currently queries out of AD as, probably not necessary
	$sAMAccountName = $user.SamAccountName
	#check to see if the DN of the user contains the school name, if not, move it to the correct location
	$properdn = "OU=$company,"
	write-host $properdn
	if ($user.DistinguishedName -notlike "*$properdn*")
	{
		Move-ADObject -Identity $user -TargetPath $path
		$user = Get-ADUser -Filter {employeeID -eq $employeeID}
	}

	#Check to see if folders exist on proper server, if not, create them and set permissions.
	$servername = $server.Get_Item($sisline.schoolid)

	#The example below assumes student home folders exist in a \\schoola-fs\home\username structure
	$homepath = "\\"  + $servername + "\Home\" + $sAMAccountName
	if ((Test-Path ($homepath)) -ne $true)
	{
		#create folder and set permissions
		#Change DOMAIN below with your AD Domain
		New-Item -ItemType directory -Path $homepath
		$acl = Get-Acl $homepath
		$permission = "DOMAIN\$sAMAccountName","FullControl","ContainerInherit,ObjectInherit","None","Allow"
		$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
		$acl.SetAccessRule($accessRule)
		$acl | Set-Acl $homepath
	}

	#A quick 100ms pause to make sure the folder has been created and the permissions applied. you may be able to dial that back or remove it entirely	
	Start-Sleep -m 100

	#Set the users homedrive
	Set-ADUser -Identity $user -HomeDirectory $homepath -HomeDrive "H:"

	#Add user to site student group and grad year group also a good place to add any other groups you may require
	#This assumes a security group with the site abbreviation-Students exists and a group called Grad#### exists
	#It doesn't check to see if the user is already a part of these groups, so it will often print an error stating it can't add them because they already exist
	$studentgroup = $siteabbr.Get_Item($sisline.schoolid) + "-Students"
	$gradgroup = "Grad" + $description
	Add-ADGroupMember $studentgroup $user
	Add-ADGroupMember $gradgroup $user

}
