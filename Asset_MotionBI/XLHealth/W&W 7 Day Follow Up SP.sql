USE [ProvoQMS_Prod]
GO
/****** Object:  StoredProcedure [dbo].[DinsertXLHealth7DayCall]    Script Date: 9/26/2016 3:35:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		GHyatt	
-- Create date: 2015-6-11
-- Description:	Loads the participants into the xl health 7 day follow up call on the 7th day from Dermsl_Prod.dbo.Member.RowCreatedDatetime(6th day from provoqms_prod.dbo.member.rowCreatedDatetime(count as day 2))
-- =============================================
ALTER PROCEDURE  [dbo].[DinsertXLHealth7DayCall]

AS
BEGIN

	SET NOCOUNT ON;

---1 Declare variables.

/****Identify the project and treatment from the welcome call*************/
-- NP
Declare @WelcomeCallTreatment1 int = (
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'W&W Welcome Call NP Group'	)

-- IVR/DM
Declare @WelcomeCallTreatment2 int = (
Select T.Treatmentid 
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


Declare @WelcomeCallProject int = (Select Distinct P.Projectid 
FROM dbo.Project P
	INNER JOIN dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where  P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName in ('W&W Welcome Call NP Group', 'W&W Outbound Set-Up Call', 'W&W Inbound Sign-Up Call')	)

/****Identify the project and treatment from the 4 day call*************/
Declare @4dayCallTreatment int = 
(
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 4 Follow Up Call'	
)


Declare @4dayCallProject int = (Select P.Projectid 
FROM dbo.Project P
	INNER JOIN dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where  P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 4 Follow Up Call'	)

/**	Identify the project and treatment from the 7 day call*************/
Declare @7dayCallTreatment int = 
(
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 7 Follow Up Call'	
)


Declare @7dayCallProject int = (Select P.Projectid 
FROM dbo.Project P
	INNER JOIN dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where  P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 7 Follow Up Call'	)

--Print (@WelcomeCallProject)
--Print (@WelcomeCallTreatment)
--Print (@4dayCallProject)
--Print (@4dayCallTreatment)


 --2 Create a temp table of member's records for the 4 day call follow-up.
/*******************Create a table of data to load to the member and member phone tables.************/

/*** Welcome Calls ***/
IF object_ID('tempdb.dbo.#LoadTable') is not null
Drop table #LoadTable


Select  m.IndividualSysId				
	, m.Firstname					  
	, m.LastName					    
	, m.Address1					    
	, m.Address2					    
	, m.City						    
	, m.StateCode					
	, m.ZipCode					
	, m.BirthDate	  			
	, m.GenderCode					
	, m.MemberRowEndDateTime		
	, Notes   = m.Notes
	, LookupMemberStatusId			= 1
	, m.SubScriberId				
	, m.SeverityId					
	, m.Conditioncode				
	, RowCreatedSysUserId			= 60
	, RowCreatedDateTime				= Getdate()	
	, RowModifiedSysUserid			= 60
	, RowModifiedDateTime			= Getdate()	
	, ProjectId						= @7dayCallProject
	, m.SysAgentId					
	, LookupParticipantStatusId  	= 1
	, TreatmentId					= @7dayCallTreatment
	, m.EmailAddress				
	, m.GroupName				  	
	, m.MaxAttemptDatetime		  	
	, m.DNCDateTime				
	, HomePhone					    = Case when Mp.PhoneCode = 'Home' then mp.PhoneNumber end
	, CellPhone						= Case when Mp.PhoneCode = 'Cell' then mp.PhoneNumber end
	, VisitSpecialtyCode				
	, VisitIcdDescription            
	, VisitICD9Code  				
	, VisitServiceCode				
	, HospitalIcd9Code				
	, HospitalIcdDescription			
	, HospitalServiceCode			= IIF(HospitalServiceCode > 50, 50, HospitalServiceCode)		

  INTO  #LoadTable
--Select *
FROM vmember  m
	Left jOIN MemberPhone MP
		on m.memberid = mp.Memberid
	INNER JOIN MemberCallLog MCL
		ON m.memberid = mcl.memberid
	Inner join PROJECTDisposition pd
		on mcl.PROJECTDispositionID = pd.PROJECTDispositionID 
		and pd.DispositionDescription = 'Move To 7 Day Follow Up'
		and pd.DispositionDescription <> 'Medically Unable to Respond' 
	LEFT JOIN	(
				Select * FROM ..WalkandWin_FitMetrics
			) Steps
		On m.IndividualSysID = Steps.IndividualSysid
Where m.projectid = @WelcomeCallProject and Treatmentid in (@WelcomeCallTreatment1, @WelcomeCallTreatment2, @WelcomeCallTreatment3)		-- 08/08 added @WelcomeCallTreatment3
	and Datediff(DW,mcl.RowCreatedDateTime,Getdate())  >= 7
	and pd.DispositionDescription <> 'Silver Sneakers - Move to 30 day alternate program'	-- For W&W Day 30 Alternate Program

  
 union

/*** 4-day calls ***/
Select  m.IndividualSysId				
	, m.Firstname					  
	, m.LastName					    
	, m.Address1					    
	, m.Address2					    
	, m.City						    
	, m.StateCode					
	, m.ZipCode					
	, m.BirthDate	  			
	, m.GenderCode					
	, m.MemberRowEndDateTime		
	, Notes   = m.Notes
	, LookupMemberStatusId			= 1
	, m.SubScriberId				
	, m.SeverityId					
	, m.Conditioncode				
	, RowCreatedSysUserId			= 60
	, RowCreatedDateTime				= Getdate()	
	, RowModifiedSysUserid			= 60
	, RowModifiedDateTime			= Getdate()	
	, ProjectId						= @7dayCallProject
	, m.SysAgentId					
	, m.LookupParticipantStatusId  
	, TreatmentId					= @7dayCallTreatment
	, m.EmailAddress				
	, m.GroupName				  	
	, m.MaxAttemptDatetime		  	
	, m.DNCDateTime				
	, HomePhone					    = Case when Mp.PhoneCode = 'Home' then mp.PhoneNumber end
	, CellPhone						= Case when Mp.PhoneCode = 'Cell' then mp.PhoneNumber end
	, VisitSpecialtyCode				
	, VisitIcdDescription            
	, VisitICD9Code  				
	, VisitServiceCode				
	, HospitalIcd9Code				
	, HospitalIcdDescription			
	, HospitalServiceCode			= IIF(HospitalServiceCode > 50, 50, HospitalServiceCode)	
	
--Select *
FROM vmember  m
	Left jOIN MemberPhone MP
		on m.memberid = mp.Memberid
	INNER JOIN MemberCallLog MCL
		ON m.memberid = mcl.memberid
	Inner join LOOKUPCallStatus lcs
		on mcl.lookupcallstatusid = lcs.LOOKUPCallStatusID
	Left join PROJECTDisposition pd
		on mcl.PROJECTDispositionID = pd.PROJECTDispositionID  
	LEFT JOIN	(
					Select * FROM ..WalkandWin_FitMetrics
			) Steps
		On m.IndividualSysID = Steps.IndividualSysid
Where m.projectid = @4dayCallProject and Treatmentid = @4dayCallTreatment
	and Datediff(DW,mcl.RowCreatedDateTime,Getdate())  >= 3  
	and ((pd.DispositionDescription =  'Move To 7 Day Follow Up' and pd.DispositionDescription <> 'Medically Unable to Respond' )
		or (lcs.Statuscode = 'Maximum attempt' and (pd.DispositionDescription <> 'Medically Unable to Respond' or pd.DispositionDescription is null)))
	and pd.DispositionDescription <> 'Silver Sneakers - Move to 30 day alternate program'	-- For W&W Day 30 Alternate Program
	


  Select * FROM #LoadTable

update	m
Set m.LOOKUPMemberStatusID = 4
,Notes = m.Notes +  '/  member removed from queue because they were added to 7 day queue'
--Select *
From dbo.MEMBER	m
	Inner Join #LoadTable	l	On	m.IndividualSysID	=	l.IndividualSysID			
Where (m.PROJECTID = @WelcomeCallProject
	or	m.TreatmentID = @4dayCallTreatment)
	and m.LOOKUPMemberStatusID = 1 



--3.  Insert the records into the member table.
/*****Insert to member table.  Use the distinct because there will be duplicate demo data if they have multiple phone nums.*****/
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
	From #LoadTable	LT
		Where not exists (Select * FROM Member m Where m.IndividualSysID = lt.Individualsysid and m.PROJECTID = lt.Projectid)	 --make sure not to insert twice.

CLOSE SYMMETRIC KEY symkey_ProvoQMS;


 
--4	--Insert into MemberPhone table.
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
		,[PhoneNumber] =    a.HomePhone
		,[ResponseDate]  =  NULL
		,[RowCreatedSYSUserID] = 1
		,[RowCreatedDateTime] = getdate()
		,[RowModifiedSYSUserID] = 1
		,[RowModifiedDateTime] = getdate()
		 --Select * 
		 FROM #LoadTable	a
					inner join 
						 (
						 Select a.*
						 FROM dbo.Member  a
							INNER JOIN dbo.Project p on a.PROJECTID = p.PROJECTID and p.Projectid = @7dayCallProject
							INNER JOIN dbo.Treatment t on a.TreatmentID = t.Treatmentid and T.Treatmentid = @7dayCallTreatment
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
        Where a.HomePhone is not null 
		AND NOT EXISTS (sELECT * from mEMBERPHONE MP WHERE a.hOMEphONE = MP.pHONEnUMBER AND SUB.mEMBERID = MP.mEMBERID	)


--5	--Insert cell numbers into MemberPhone table.
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
		,[PhoneNumber] =    a.CellPhone
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
							INNER JOIN dbo.Project p on a.PROJECTID = p.PROJECTID and p.ProjectID = @7dayCallProject 
							INNER JOIN dbo.Treatment t on a.TreatmentID = t.Treatmentid and T.TreatmentID = @7dayCallTreatment
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
        Where a.CellPhone is not null 
		AND NOT EXISTS (sELECT * from mEMBERPHONE MP WHERE a.CellPhone = MP.pHONEnUMBER AND SUB.mEMBERID = MP.mEMBERID	)

---6
/******Add Steps Data to Member.Visit table***********/



Insert into MemberVisit
(
IndividualSysid
,ServiceDateTime
,ServiceCode
,ICD9Code
,ICDDescription 
,SpecialityCode 
,RowCreatedSYSUserID
,RowCreatedDateTime
,RowModifiedSYSUserID
,RowModifiedDateTime 
,Memberid
)
Select 		Distinct
SUB.IndividualSysid
,ServiceDateTime   = NULL
,ServiceCode			=	ISNULL(a.VisitServiceCode, 0)
,ICD9Code				=	ISNULL(a.VisitICD9Code, 0)		
,ICDDescription  		=	ISNULL(a.VisitIcdDescription, 0)
,SpecialtyCode			=	ISNULL(a.VisitSpecialtyCode, 0)
,RowCreatedSYSUserID	  = 60 
,RowCreatedDateTime		  = Getdate()
,RowModifiedSYSUserID	  = 60 
,RowModifiedDateTime 	  = GetDate()
,Memberid
FROM #LoadTable	a
	inner join 
		 (
		 Select a.*
		 FROM dbo.Member  a
			INNER JOIN dbo.Project p on a.PROJECTID = p.PROJECTID and p.ProjectID = @7dayCallProject 
			INNER JOIN dbo.Treatment t on a.TreatmentID = t.Treatmentid and T.TreatmentID = @7dayCallTreatment
		-- Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
		 ) sub
				on a.IndividualSysID = sub.IndividualSysID

---7
/******Add Steps Data to MemberHospital table***********/
 

Insert into MEMBERHospital
(
IndividualSysid
,ServiceDateTime
,ServiceCode
,ICD9Code
,ICDDescription 
,AllowedAmount 
,RowCreatedSYSUserID
,RowCreatedDateTime
,RowModifiedSYSUserID
,RowModifiedDateTime 
,Memberid
)
Select 	 Distinct
SUB.IndividualSysid
,ServiceDateTime   = NULL
,ServiceCode			= ISNULL(a.HospitalServiceCode, 0)
,ICD9Code				= ISNULL(HospitalICD9Code, 0)
,ICDDescription 		= ISNULL(a.HospitalIcdDescription, 0)
,AllowedAmount			=	0
,RowCreatedSYSUserID	  = 60 
,RowCreatedDateTime		  = Getdate()
,RowModifiedSYSUserID	  = 60 
,RowModifiedDateTime 	  = GetDate()
,Memberid
FROM #LoadTable	a
	inner join 
		 (
		 Select a.*
		 FROM dbo.Member  a
			INNER JOIN dbo.Project p on a.PROJECTID = p.PROJECTID and p.ProjectID = @7dayCallProject 
			INNER JOIN dbo.Treatment t on a.TreatmentID = t.Treatmentid and T.TreatmentID = @7dayCallTreatment
		 --Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
		 ) sub
				on a.IndividualSysID = sub.IndividualSysID



END
