USE [DERMSL_Prod]

Declare @Clientid varchar(max) = '125'
, @Status Varchar(200) 	  = '<all>'
,@LookupRuleGroupId  varchar(max)   = '351'

/********Create a table of all the rule groups specified in the parameters********/


Set Transaction Isolation Level Read Uncommitted

If Object_Id('tempdb.dbo.#MemberruleGroup') is not null
Drop table #MemberruleGroup

Select Distinct  a.*, f.RuleGroupName , f.OfferCode
Into #MemberruleGroup 
FROM MemberRuleGroup a
INNER JOIN dbo.DelimitedSplit8k(@Lookuprulegroupid,',') e
		 On Convert(Varchar(10),a.LookupRulegroupId) = e.Item or e.item = '<All>'
INNER JOIN LookupRuleGroup f
	ON a.LOOKUPRuleGroupID = f.LookupRulegroupid

	Create unique Clustered index idxrulegroup on #MemberRulegroup(Memberid)



If Object_Id('tempdb.dbo.#LookupruleGroup') is not null
Drop table #LookupruleGroup

Select Distinct  a.*
Into #LookupruleGroup 
FROM LookupRuleGroup a
INNER JOIN dbo.DelimitedSplit8k(@Lookuprulegroupid,',') e
		 On Convert(Varchar(10),a.LookupRulegroupId) = e.Item or e.item = '<All>'
												  
	Create unique Clustered index idxrulegroup on #LookupRulegroup(LookupRuleGroupid)

/*****************Create a table of all relevant clients based on parameters*******/	



If Object_Id('tempdb.dbo.#Client') is not null
Drop table #Client

Select a.*, e.DeviceName  
Into #Client
FROM LookupClient a
	INNER JOIN dbo.DelimitedSplit8K(@ClientID, ',') d 
	on @ClientID =  '<ALL>' 
	or (Convert(varchar(max),a.LookupClientID)) = d.item 
	INNER JOIN LOOKUPDevice e
		ON a.LOOKUPDeviceID = e.Lookupdeviceid


/**************Identify the last sync date*******************/

 


Select Memberid, Max(LastStepDate) as LastStepdate
Into #LastStepDate
FROM 
		(
		Select a.Memberid, LastStepDate = Convert(date,LastStepMinute) 
		FROM MemberstepMovementmetadata a
			Inner join #MemberruleGroup b on a.Memberid = b.memberid 
		Union 
		Select a.Memberid, LastStepDate = Max(LastExportTime) 
		 
		FROM FitbitSubDetailMetaData a
		Inner join #MemberruleGroup b on a.Memberid = b.memberid  Group by a.memberid
		union
		Select a.Memberid, LastStepDate = Max(Dateadd(Hour,c.LastSyncHour + LastSyncMinute/60,Convert(Datetime,lastSyncStepDate))) FROM Member   a
			INNER JOIN   (StreamlineDevices_Prod.dbo.MEmber b Inner join StreamlineDevices_Prod.dbo.MEmberDevice  b2 on b.Memberid = b2.Memberid )
				ON a.Customerid = b.Customerid
			Left Join  StreamlineDevices_Prod.dbo.MemberdevicePedSync c
				ON b2.MemberDeviceID = c.MemberDeviceID 
			Inner join #MemberruleGroup d on a.Memberid = d.memberid 
		Group by a.Memberid
		)a 
Group by a.Memberid 


/****Create a lookup table for the location codes**********/
 
 Select	a.Memberid, LocationCode = Max(MSD.LocationCode)
 INTO #LocationCode
  FROM (Member a Inner JOIN Sysuser a2 on a.Sysuserid = a2.Sysuserid )
	INNER JOIN #Client b
		ON a.LOOKUPClientID = b.Lookupclientid
	INNER JOIN #MemberruleGroup  RG
		ON a.Memberid = RG.Memberid
	INNER JOIN MemberSignupdata MSD
		ON ((a.Firstname = MSD.Firstname and a.Lastname = MSD.Lastname and a.BirthDate = MSD.Birthdate)
	   or (a2.Email = MSD.Emailaddress )
	   Or (a.ClientMemberid = MSD.ClientMemberid  and MSD.ClientMEMBERID <> '' ))
	   and a.LOOKUPClientID = MSD.LOOKUPClientID
Where LocationCode <> ''
Group by a.Memberid

/***************Create a table of all the people who were preloaded but have not signed up yet.***********************************************/

Select RG.LookupRuleGroupid
, MEmberid	= NULL
 ,ClientName
, Clientmemberid
,enrollmentdate	   = NULL
,cancelledDatetime 
,firstname
,Lastname
,Birthdate
,a.addressLine
,City
,StateCode
,Zipcode
,ActiveMemberFlag = NULL
,ProgramStartDate
,DaysInPRogram = 0
,RuleGroupName
,Rg.OfferCode
,Registered = 0
,NoOfAccounts = NULL
,NoOfActiveAccounts = NULL
,EmailAddress
,LocationCode
,ActiveDevice = 0
,Deactivated = NULL
,Logdates = NULL
,AvgStepsPerLogDate = Null
,LastStepDate = NULL
,Status = 'Notsignedup'
,TermsAgreementflag = 0
,a.LookupTenantid
,ActiveDeviceId = Convert(varchar(20),NULL )
,DeviceName
,BestTimetoCall = Cast(NULL as Varchar(30))
Into #1
 FROM MemberSignupdata a
	INNER JOIN #Client b
		ON a.LOOKUPClientID = b.Lookupclientid
	INNER JOIN #LookupruleGroup  RG
		ON a.LOOKUPRuleGroupID = RG.LookupruleGroupid
Where AccountVerifiedFlag = 0  and ActiveFlag = 1-- and  (CancelledDateTime is null or cancelledDateTime > getdate())	  --and b.LookupClientid <> 92
and not exists ( Select * From Member m Where a.Firstname = m.Firstname and a.Lastname = m.Lastname and a.BirthDate = m.Birthdate and a.LookupClientid = m.LookupClientid)
and Not exists ( Select * From (Sysuser c Inner join member m2 On c.Sysuserid = m2.Sysuserid) Where a.Emailaddress = c.Email and c.email <> '' and m2.LOOKUPClientID = a.Lookupclientid)
and (a.CancelledDateTime is null or a.CancelledDateTime >= getdate())
and (a.CancelledDateTime is null or a.CancelledDateTime >= a.ProgramStartdate)
  
  
  /**********Create a table with one row for each account and the specifics of the account.******************************************/

 
  Select
 a3.LOOKUPRuleGroupID
 ,a.MEmberid
 ,ClientName
  ,Clientmemberid
 ,EnrollmentDate = a.RowCreatedDatetime
 ,CancelledDatetime = Case when activememberflag =1 then NULL Else CancelledDatetime End
,a.firstname
,a.Lastname
,Birthdate
,a.Address1
,City
,StateCode
,Zipcode
,ActiveMemberFlag
,ProgramStartDate
,DaysInPRogram = DateDiff(day,a.RowCreatedDatetime,Getdate()) + 1
,a3.RuleGroupName
,a3.OfferCode
,Registered = 1
,NoOfAccounts = 1
,NoOfActiveAccounts = Case when ActiveMemberFlag = 1 then 1 else 0 end
,EmailAddress	 = b.Email
,Locationcode = Cast(NULL as Varchar(50))
,ActiveDevice = Max(Case when d.Active = 1 then 1 else 0 end)
,Deactivated = Case when ActiveMemberFlag = 0 then 1 else 0 end
,LogDates = f.Logdates
,f.AvgStepsPerLogdate 
,LastStepDate 
,Status = ''
,a.TermsAgreementFlag
,a.LookupTenantid 
,ActiveDeviceId   = Max(Case when d.Active = 1 then Convert(Varchar(10),d2.Model) + '-' + Convert(Varchar(10),d2.Serial) Else NULL END)
,DeviceName
,a.BestTimeToCall
Into #2
  FROM  (Member a  INNER JOIN #Client a2 On a.LOOKUPClientID = a2.LookupClientid INNER JOIN #MemberRuleGroup a3 ON a.MEmberid = a3.memberid)
	Inner join Sysuser  b 
		ON a.Sysuserid = b.Sysuserid
	Left JOIN #LastStepDate b2
		ON a.Memberid = b2.Memberid
	Left JOIN StreamlineDevices_Prod.dbo.Member c
		ON a.CustomerID = c.CustomerID
	Left JOIN   (StreamlineDevices_Prod.dbo.MEmberdevice d INNER JOIN StreamlineDevices_Prod.dbo.Device d2 On d.DeviceID = d2.DeviceID)
		ON c.MemberID = d.MemberID
	Left Join StreamlineDevices_Prod.dbo.MemberdevicePedSync e
		ON d.MemberDeviceID = e.MemberDeviceID
	Left JOIN (Select Memberid, Logdates = Count(Distinct IncentiveDate),AvgStepsPerLogdate = Avg(Case when TotalSteps >= 300 then TotalSteps else Null end)  
										FROM  (dbo.MemberEarnedIncentives mei inner join LookupRule lr on mei.LOOKUPRuleID = lr.LOOKUPRuleID and RuleName  = 'Tenacity')
										Where TotalSteps >= 300 Group by MemberID) f
		ON a.Memberid = f.Memberid
Where a2.Devicename <> 'fitbit'
 and exists(Select * FROM membersignupdata msd Where a.Clientmemberid = msd.Clientmemberid and a.LOOKUPClientID = msd.LOOKUPClientID and msd.Clientmemberid <> '' and (msd.CancelledDateTime is null or msd.CancelledDateTime >= msd.ProgramStartdate))
 or not exists(Select * FROM membersignupdata msd2 where a.Clientmemberid = msd2.Clientmemberid and a.Lookupclientid = msd2.Lookupclientid)
 
Group by 
a3.LookupRulegroupid
,a.MEmberid
 , ClientName
 ,Clientmemberid
 , a.RowCreatedDatetime
 , Case when activememberflag =1 then NULL Else CancelledDatetime End
,a.firstname				   
,a.Lastname
,a.Birthdate
,a.Address1
,City
,StateCode
,Zipcode
,ActiveMemberFlag
,ProgramStartDate
, DateDiff(day,a.RowCreatedDatetime,Getdate())	+1
,a3.RuleGroupName
,a3.OfferCode
, Case when ActiveMemberFlag = 1 then 1 else 0 end
, b.email
,Case when ActiveMemberFlag = 0 then 1 else 0 end
, f.Logdates
,f.AvgStepsPerLogdate 
,a.TermsAgreementFlag
,a.LookupTenantid
,DeviceName
,LastStepdate
,a.BestTimeToCall																			  

/*********************Put together the final table*******************************/


Select a.* 
,LocationCode = (c.LocationCode)
,d.TenantName
,HHID = Dense_Rank()Over(Order by Lastname,Addressline, Zipcode)
FROM 
(
Select
a.LOOKUPRuleGroupID
,a.Memberid
,ClientMEMBERID
,LookupTenantid
,Clientname			  = (ClientName)
,FirstName		  = (a.Firstname)
,LastName			  = (a.Lastname)
,Birthdate
,Addressline
,City				  = (city)
,StateCode
,Zipcode
,ActiveMemberFlag
,ProgramStartDate
,DaysInPRogram 
,RuleGroupName			= (RuleGroupName)
,GroupID = Offercode

,Enrollmentdate
,CancelledDatetime
,a.Registered  
,NoOfAccounts	
,NoOfActiveAccounts 
,EmailAddress
,ActiveDevice  
,a.Deactivated   
,LastStepDate
,AnySteps = Case when LastStepDate is not null then 1 else 0 end
,AvgStepsPerLogDate
,Logdates
,Status        = Case when a.Status = 'Notsignedup' then a.Status
					 when Deactivated = 1 then 'Deactivated' 
 					 when  LastStepDate > dateadd(day,-11, Convert(Date,Getdate())) and  Logdates > 0 then 'Logging'
				     when  LastStepDate is not null  and  (Logdates = 0 or Logdates is null)  then 'Initial Sync'
					 when  LastStepDate <= dateadd(day,-11, Convert(Date,Getdate())) and Logdates >= 0 then 'Idle'
					 when  a.TermsAgreementFlag = 1 and a.LookupTenantid = 7 then 'Consented'
					 when  a.Registered = 1  then 'Registered'
					 When  a.Registered = 0 and a.cancelleddatetime is null then 'Notsignedup'  else NULL end
,ActiveDeviceId
,DeviceName
,BestTimetoCall
,DaysSinceSync = DateDiff(Day,LastStepDate,Getdate())
 FROM (Select * FROM #1 a
		Union
		Select *FROM #2
	  ) a
Where Firstname <> 'Group admin'
 ) a
	INNER JOIN dbo.DelimitedSplit8K(@Status,',') b on a.Status = b.Item	 or @status = '<all>'
	Left JOIN #LocationCode C ON a.Memberid	 = c.Memberid
	Left JOin LOOKUPTenant d ON a.Lookuptenantid = d.LOOKUPTenantID
ORder by  lastname,Firstname,registered 

