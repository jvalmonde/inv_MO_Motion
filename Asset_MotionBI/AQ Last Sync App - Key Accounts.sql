
-- 9/1/2016

-- This script pulls the list of members who have synced their TRIO recently.

Select Distinct ruleGroupname,Firstname, Lastname, Email, Platformname , AppVersion, SyncDate
FROM 
(
Select dm.RuleGroupName, dm.FirstName, dm.Lastname, dm.Email, vps.AppVersion, vps.PlatformName, vps.SyncDate , RN = Row_Number()Over(Partition by dm.Account_id order by Syncdate desc) FROM Dim_member dm 
	Inner join vwProgramSync  vps 
		On dm.Account_ID = vps.Account_ID 
Where dm.Clientname = 'Key Accounts UHCM' and dm.ActiveMemberFlag = 1 
and PlatformName not in ('PC','Sync Station','SyncStation') and AppVersion is not null 
) a
Where RN = 1 

-- 989 rows returned

-- Updated script to determine which users are not using this app version: iOS 1.1.1.xx or Android 1.1.0.xx or PC 1.8.1.6 or Mac 1.8.0.1

Select Distinct ruleGroupname,Firstname, Lastname, Email, AppVersion, SyncDate
FROM 
(
Select dm.RuleGroupName, dm.FirstName, dm.Lastname, dm.Email, vps.AppVersion, vps.PlatformName, vps.SyncDate , RN = Row_Number()Over(Partition by dm.Account_id order by Syncdate desc) FROM Dim_member dm 
	Inner join vwProgramSync  vps 
		On dm.Account_ID = vps.Account_ID 
Where dm.Clientname = 'Key Accounts UHCM' and dm.ActiveMemberFlag = 1 
and PlatformName not in ('PC','Sync Station','SyncStation')
and AppVersion not like '1.1.1.%' 
and AppVersion not like '1.1.0.%'
and AppVersion not like '1.8.1.6'
--and AppVersion not like '1.8.0.1'
) a
Where RN = 1 

-- 1,156 rows returned

