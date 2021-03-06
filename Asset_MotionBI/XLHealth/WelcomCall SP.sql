USE [ProvoQMS_Prod]
GO
/****** Object:  StoredProcedure [dbo].[DinsertXLHealthWelcomeCall]    Script Date: 9/26/2016 1:55:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[DinsertXLHealthWelcomeCall] 
As 
begin 


-- NP
Declare @WelcomeCallTreatment1 int = (Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'W&W Welcome Call NP Group'	)

-- IVR/DM
Declare @WelcomeCallTreatment2 int = (Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'W&W Outbound Set-Up Call'	)

-- Inbound Sign-up
Declare @WelcomeCallTreatment3 int = (
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'W&W Inbound Sign-Up Call'	)


-- ProjectID
Declare @WelcomeCallProject int = (Select distinct P.Projectid 
FROM dbo.Project P
	INNER JOIN dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName in ('W&W Welcome Call NP Group', 'W&W Outbound Set-Up Call', 'W&W Inbound Sign-Up Call')	)


/*** NEW WELCOME CALL TREATMENT ***/
Declare @WelcomeCallTreatment4 int = 
(
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'Inbound call return queue'	
)


-- Nurse Practitioner Treatment
-- REGULAR LOAD/ NOT THROUGH IVR/DM
IF object_ID('tempdb.dbo.#LoadTable') is not null
Drop table #LoadTable

Select IndividualSysId	     
	,Firstname               
	,LastName		         
	,Address1		         
	,Address2		         
	,City			         
	,StateCode	             
	,ZipCode		         
	,m.BirthDate	  			            		
	,GenderCode	              
	,MemberRowEndDateTime	  = NULL   
	,Notes						 = ''
	,LookupMemberStatusId		 = 1   
	,SubScriberId				 = m.IndividualSysId   
	,SeverityId					 = 0
	,Conditioncode				 = ''
	,RowCreatedSysUserId		 = 1	  
	,RowCreatedDateTime			 = Getdate()  
	,RowModifiedSysUserid		 = 1  
	,RowModifiedDateTime		 = Getdate()	  
	,ProjectId					 =  @WelcomeCallProject 
	,SysAgentId					  
	,LookupParticipantStatusId   
	,TreatmentId				 = @WelcomeCallTreatment1 
	,EmailAddress				 = NULL				
	,GroupName				  	
	,MaxAttemptDatetime		  	
	,DNCDateTime				
	, HomePhone
	,CellPhone 
	,NP
	,AccountCreatedDateTime     
	,DeliveryDate				
	--,ps.enrollmentsource
  --INTO  #LoadTable
FROM Provoqms_NewMembers m
Where  Convert(Date,m.AccountCreatedDateTime) < Convert(Date,Getdate()) and m.AccountCreatedDateTime >= '2016-06-08 15:44:09.977'
	and (m.enrollmentsource <> 2)																		-- not through IVR/DM
	and not exists (Select * FROM member qm where qm.IndividualSysiD = m.IndividualSysId and qm.Projectid = @WelcomeCallProject and qm.TreatmentID = @WelcomeCallTreatment1)
	---and not exists(move to outbound dispo)
	UNION	
	---Select * FROM Provoqms_NewMembers m
---- THROUGH IVR/DM
--INSERT INTO #LoadTable
Select --*--, CONVERT(date, AccountCreatedDateTime), DATEADD(DAY, sub.Days, CONVERT(date, AccountCreatedDateTime)),sub.days,CONVERT(date,getdate()),
	IndividualSysId
	,Firstname             
	,LastName		       
	,Address1		       
	,Address2		       
	,City			       
	,StateCode	           
	,ZipCode		       
	,BirthDate	  		
	,GenderCode	           
	,MemberRowEndDateTime	
	,Notes						
	,LookupMemberStatusId		
	,SubScriberId				
	,SeverityId					
	,Conditioncode				
	,RowCreatedSysUserId		
	,RowCreatedDateTime			
	,RowModifiedSysUserid		
	,RowModifiedDateTime		
	,ProjectId				
	,SysAgentId					
	,LookupParticipantStatusId 
	,TreatmentId				
	,EmailAddress				
	,GroupName				  	
	,MaxAttemptDatetime		  	
	,DNCDateTime				
	, HomePhone
	,CellPhone
	,NP
	,AccountCreatedDateTime
	,DeliveryDate
From
(
	Select IndividualSysId	      
		,Firstname                
		,LastName		          
		,Address1		          
		,Address2		          
		,City			          
		,StateCode	              
		,ZipCode		          
		,m.BirthDate	  			
		,GenderCode	              
		,MemberRowEndDateTime	  = NULL   
		,Notes						 = ''
		,LookupMemberStatusId		 = 1   
		,SubScriberId				 = m.IndividualSysId   
		,SeverityId					 = 0
		,Conditioncode				 = ''
		,RowCreatedSysUserId		 = 1	  
		,RowCreatedDateTime			 = Getdate()  
		,RowModifiedSysUserid		 = 1  
		,RowModifiedDateTime		 = Getdate()	  
		,ProjectId					 =  @WelcomeCallProject 
		,SysAgentId					 = 60 
		,LookupParticipantStatusId   = 1
		,TreatmentId				 = @WelcomeCallTreatment2 
		,EmailAddress				 = NULL 
		,GroupName				  	 
		,MaxAttemptDatetime		  	 
		,DNCDateTime				 
		, HomePhone
		,CellPhone
		,NP 
		,AccountCreatedDateTime = m.RowCreatedDateTime
		--,ps.enrollmentsource
		,DeliveryDate				= ''
		,days =	Case	When dd.DAY_ABBR_CD	= 'FRI' Then 12				-- Depending on what day the enrollment falls, the number of days to add differs.
						When dd.DAY_ABBR_CD	= 'SAT' Then 11
						When dd.DAY_ABBR_CD	= 'SUN' Then 10
						When dd.DAY_ABBR_CD	= 'MON' Then 9
						When dd.DAY_ABBR_CD	= 'TUE' Then 8
						When dd.DAY_ABBR_CD	= 'WED' Then 7
						When dd.DAY_ABBR_CD	= 'THU' Then 6
						Else 0
				END
 FROM  Provoqms_NewMembers	 M
		INNER JOIN Devsql14.pdb_DermReporting.dbo.Dim_Date dd
			ON	CONVERT(Date,M.AccountCreatedDateTime)	=	CONVERT(Date,dd.FULL_DT)
	Where  Convert(Date,m.AccountCreatedDateTime) < Convert(Date,Getdate()) and m.AccountCreatedDateTime >= '2016-06-08 15:44:09.977'
		and m.enrollmentsource = 2		---or enrollment source = 3 and move to outbound exists...
)	sub
Where  DATEADD(DAY, sub.Days, CONVERT(date, AccountCreatedDateTime)) <= CONVERT(date,getdate())		-- Members should only be inserted 5 days or more after shipping date which happens every friday.
	and not exists (Select * FROM member qm where qm.IndividualSysiD = sub.IndividualSysId and qm.Projectid = @WelcomeCallProject and qm.TreatmentID = @WelcomeCallTreatment2)
	
UNION	

/*** NEW INBOUND TREATMENT ***/

Select Distinct 
m.IndividualSysId				
	, m.Firstname					  
	, m.LastName					    
	, m.Address1					    
	, m.Address2					    
	, m.City						    
	, m.StateCode					
	, m.ZipCode					
	, EncryptedBirthDate			=	m.Birthdate 			
	, m.GenderCode					
	, m.MemberRowEndDateTime		
	, m.Notes						
	, LookupMemberStatusId		    =	1
	, m.SubScriberId				
	, m.SeverityId					
	, m.Conditioncode				
	, RowCreatedSysUserId			=	60
	, RowCreatedDateTime			=	Getdate()	
	, RowModifiedSysUserid			=	60
	, RowModifiedDateTime			=	Getdate()	
	, ProjectId						=	@WelcomeCallProject
	, m.SysAgentId					
	, LookupParticipantStatusId  	=	1
	, TreatmentId					=	@WelcomeCallTreatment4
	, m.EmailAddress				
	, m.GroupName				  	
	, m.MaxAttemptDatetime		  	
	, m.DNCDateTime				
	, HomePhone						=	Case when Mp.PhoneCode = 'Home' then mp.PhoneNumber end
	, CellPhone						=	Case when Mp.PhoneCode = 'Cell' then mp.PhoneNumber end
	, NP							=	NULL
	, AccountCreatedDatetime		=	m.RowCreatedDateTime
	, DeliveryDate					=	''
FROM dbo.vmember  m	
	Left jOIN dbo.MemberPhone MP
		on m.memberid = mp.Memberid
	INNER JOIN dbo.MemberCallLog mcl
		on m.memberid = mcl.Memberid
	inner join dbo.ProjectDisposition PD
		on mcl.ProjectDispositionid = pd.PROJECTDispositionID 
		and DispositionDescription = 'Inbound voicemail callback - Not Reached'
		and pd.DispositionDescription <> 'Medically Unable to Respond'
Where  1=1 --m.projectid = @WelcomeCallProject and Treatmentid = @WelcomeCallTreatment3			-- welcome Call; Inbound Signup
	and mcl.RowCreatedDateTime < Getdate()
	and pd.DispositionDescription <> 'Silver Sneakers - Move to 30 day alternate program'	-- For W&W Day 30 Alternate Program
	and not exists (Select * FROM dbo.member qm where qm.IndividualSysiD = m.IndividualSysId and qm.Projectid = @WelcomeCallProject and (qm.TreatmentID  in ( @WelcomeCallTreatment4,@WelcomeCallTreatment2,@WelcomeCallTreatment1)))	-- Inbound call return queue/Outbound setup/ np welcome


/***LOAD MEMBERS WITH ENCRYPTION***/
OPEN SYMMETRIC KEY symkey_ProvoQMS
       DECRYPTION BY CERTIFICATE cert_ProvoQMS;

       INSERT INTO dbo.MEMBER
      (
             IndividualSysId          
             ,EncryptedFirstname               
             ,EncryptedLastName                  
             ,EncryptedAddress1                  
             ,EncryptedAddress2                  
             ,City                         
             ,StateCode                 
             ,ZipCode                      
             ,EncryptedBirthDate                        
             ,GenderCode                
             ,MemberRowEndDateTime      
             ,Notes                            
             ,LookupMemberStatusId             
             ,SubScriberId                     
             ,SeverityId                              
             ,Conditioncode                           
             ,RowCreatedSysUserId       
             ,RowCreatedDateTime               
             ,RowModifiedSysUserid             
             ,RowModifiedDateTime       
             ,ProjectId                               
             ,SysAgentId                              
             ,LookupParticipantStatusId  
             ,TreatmentId                      
             ,EmailAddress                     
             ,GroupName                               
             ,MaxAttemptDatetime               
             ,DNCDateTime                      
      )
	   Select IndividualSysId
			, EncryptedFirstname	=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(Firstname))            
			, EncryptedLastName		=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(LastName	))	       
			, EncryptedAddress1		=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(Address1	))	       
			, EncryptedAddress2		=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(Address2	))	       
			, City			       
			, StateCode	           
			, ZipCode		       
			, EncryptedBirthDate	=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), CONVERT(VARCHAR(25), CAST(BirthDate AS DATETIME), 101))	
			, GenderCode	           
			, MemberRowEndDateTime	
			, Notes						
			, LookupMemberStatusId		
			, SubScriberId				
			, SeverityId					
			, Conditioncode				
			, RowCreatedSysUserId		
			, RowCreatedDateTime			
			, RowModifiedSysUserid		
			, RowModifiedDateTime		
			, ProjectId				
			, SysAgentId					
			, LookupParticipantStatusId 
			, TreatmentId				
			, EmailAddress				
			, GroupName				  	
			, MaxAttemptDatetime		  	
			, DNCDateTime
	   From #LoadTable

CLOSE SYMMETRIC KEY symkey_ProvoQMS;



--B	--Insert into MemberPhone table.
		Insert dbo.MEMBERPhone
		(
		[MemberID]
		,[IndividualSysID]
		,[PhoneCode]
		,[PhoneNumber]
		,[ResponseDate]
		,[RowCreatedSYSUserID]
		,[RowCreatedDateTime]
		,[RowModifiedSYSUserID]
		,[RowModifiedDateTime]
		)
		Select 	  Distinct
		sub.[MemberID]
		,sub.IndividualSysId 
		,[PhoneCode]		=  'HOME'
		,[PhoneNumber] =    [dbo].[RemoveNonNumericCharacters](a.HomePhone)
		,[ResponseDate]  =  NULL
		,[RowCreatedSYSUserID] = 1
		,[RowCreatedDateTime] = getdate()
		,[RowModifiedSYSUserID] = 1
		,[RowModifiedDateTime] = getdate()
		 --Select * ,xlqilab2_dev.[dbo].[RemoveNonAlphaCharacters](a.HomePhone)
		 FROM #LoadTable	a
					inner join 
						 (
						 Select a.*
						 FROM dbo.Member  a
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
								and a.ProjectId	=	sub.PROJECTID
								and a.TreatmentId = sub.TreatmentID
        Where a.HomePhone is not null 
		AND NOT EXISTS (sELECT * from mEMBERPHONE MP WHERE .[dbo].[RemoveNonAlphaCharacters](a.hOMEphONE) = .[dbo].[RemoveNonAlphaCharacters](MP.pHONEnUMBER) AND SUB.mEMBERID = MP.mEMBERID	)


--B	--Insert into MemberPhone table.
		Insert dbo.MEMBERPhone
		(
		[MemberID]
		,[IndividualSysID]
		,[PhoneCode]
		,[PhoneNumber]
		,[ResponseDate]
		,[RowCreatedSYSUserID]
		,[RowCreatedDateTime]
		,[RowModifiedSYSUserID]
		,[RowModifiedDateTime]
		)
		Select 	  Distinct
		sub.[MemberID]
		,sub.IndividualSysId 
		,[PhoneCode]		=  'Cell'
		,[PhoneNumber] =    .[dbo].[RemoveNonAlphaCharacters](a.CellPhone)
		,[ResponseDate]  =  NULL
		,[RowCreatedSYSUserID] = 1
		,[RowCreatedDateTime] = getdate()
		,[RowModifiedSYSUserID] = 1
		,[RowModifiedDateTime] = getdate()
		 --Select * ,xlqilab2_dev.[dbo].[RemoveNonAlphaCharacters](a.HomePhone)
		 FROM #LoadTable	a
					inner join 
						 (
						 Select a.*
						 FROM dbo.Member  a
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
								and a.ProjectId	=	sub.PROJECTID
								and a.TreatmentId = sub.TreatmentID
        Where a.CellPhone is not null 
		AND NOT EXISTS (sELECT * from mEMBERPHONE MP WHERE .[dbo].[RemoveNonAlphaCharacters](a.CellPhone) = .[dbo].[RemoveNonAlphaCharacters](MP.pHONEnUMBER) AND SUB.mEMBERID = MP.mEMBERID	)



Insert into MEMBERHospital
(	   [IndividualSysID]
      ,[ServiceDateTime]
      ,[ServiceCode]
      ,[ICD9Code]
      ,[ICDDescription]
      ,[AllowedAmount]
      ,[RowCreatedSYSUserID]
      ,[RowCreatedDateTime]
      ,[RowModifiedSYSUserID]
      ,[RowModifiedDateTime]
      ,[MemberID]
)
Select 
 [IndividualSysID]	  = sub.IndividualSysID
,[ServiceDateTime]	  = ''
,[ServiceCode]		  = Case When a.TreatmentId = @WelcomeCallTreatment1 Then convert(varchar(25),a.NP)
							When a.TreatmentId = @WelcomeCallTreatment2 Then convert(varchar(25),a.DeliveryDate)
							Else ''
						End
,[ICD9Code]			  = ''
,[ICDDescription]	  = ''
,[AllowedAmount]	  = ''
,[RowCreatedSYSUserID]	  = 1
,[RowCreatedDateTime]	  = Getdate()
,[RowModifiedSYSUserID]	  = 1
,[RowModifiedDateTime]	  = Getdate()
,[MemberID]				  = sub.MEMBERID
	 FROM #LoadTable	a
					inner join 
						 (
						 Select a.*
						 FROM dbo.Member  a
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
								and a.ProjectId	=	sub.PROJECTID
								and a.TreatmentId = sub.TreatmentID
        Where NOT EXISTS (sELECT * from MEMBERVisit MV WHERE  SUB.mEMBERID = MV.MEMBERID	)


  /***Insert the date for the 7 day in program marker***/

  Insert into MEMBERGenericData 
(	[MEMBERID]
      ,[GenericValue]
      ,[RowCreatedSYSUserID]
      ,[RowCreatedDateTime]
      ,[RowModifiedSYSUserID]
      ,[RowModifiedDateTime]
      ,[LOOKUPGenericDataID]
)
Select 
[MEMBERID]		= sub.Memberid
      ,[GenericValue]	  = Dateadd(Day,6,a.AccountCreatedDatetime)
      ,[RowCreatedSYSUserID]	 = 60
      ,[RowCreatedDateTime]		 = Getdate()
      ,[RowModifiedSYSUserID]	 = 60
      ,[RowModifiedDateTime]	 = Getdate()
      ,[LOOKUPGenericDataID]	= (Select LookupGenericDataID FROM LOOKUPGenericData Where GenericName = '7 Day Sync Deadine')
		 FROM #LoadTable	a
					inner join 
						 (
						 Select a.*
						 FROM dbo.Member  a
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
								and a.ProjectId	=	sub.PROJECTID
								and a.TreatmentId = sub.TreatmentID
        Where NOT EXISTS (sELECT * from MEMBERGenericdata MV inner join LookupGenericData lgd on mv.LookupGenericDataid = lgd.LookupGenericDataid 
		and lgd.GenericName = '7 Day Sync Deadine' and mv.memberid = sub.Memberid)



/****Need to add the url to the new records**************/

Insert into membergenericdata 
(Memberid
,GenericValue
,RowCreatedSysUserid
,RowCreatedDatetime
,RowModifiedSysuserid
,RowModifiedDatetime
,LookupGenericDataid
)
Select Distinct m.Memberid
,mgd.GenericValue, RowCreatedSysUserid = 60, rowCreatedDatetime = getdate(), RowmodifiedSysuserid = 60 , rowmodifiedDatetime = Getdate()
, lgd.LOOKUPGenericDataID
 FROM vMember m
	Inner join vmember m2 on m.Firstname = m2.firstname and m.Lastname = m2.Lastname and m2.TreatmentID = @WelcomeCallTreatment3
	Inner join MemberCallLog mcl on m2.memberid = mcl.memberid 
	inner join PROJECTDisposition pd on mcl.PROJECTDispositionID = pd.PROJECTDispositionID and pd.DispositionDescription = 'Inbound voicemail callback - Not Reached'
	Inner join membergenericData mgd on m2.memberid = mgd.Memberid
	Inner join lookupGenericData lgd on mgd.LOOKUPGenericDataID = lgd.LookupGenericDataid and genericName = 'Registration URL'
	   where m.Treatmentid = @WelcomeCallTreatment4 
and not exists(select * FROM membergenericdata mgd2 where mgd2.memberid = m.memberid and mgd2.LOOKUPGenericDataID = mgd.LOOKUPGenericDataID)





END