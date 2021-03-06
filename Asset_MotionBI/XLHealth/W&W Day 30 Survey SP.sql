USE [ProvoQMS_Prod]
GO
/****** Object:  StoredProcedure [dbo].[DinsertXLHealth30DayCall]    Script Date: 9/26/2016 4:37:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		GHyatt	
-- Create date: 2015-6-11
-- Description:	Loads the participants into the xl health 7 day follow up call on the 7th day from Dermsl_Prod.dbo.Member.RowCreatedDatetime(6th day from provoqms_prod.dbo.member.rowCreatedDatetime(count as day 2))
-- =============================================
ALTER PROCEDURE  [dbo].[DinsertXLHealth30DayCall]

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


Declare @WelcomeCallProject int = (Select Distinct P.Projectid 
FROM dbo.Project P
	INNER JOIN dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where  P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName in ('W&W Welcome Call NP Group', 'W&W Outbound Set-Up Call')	)

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


/**	Identify the project and treatment from the 30 day call*************/

-- Alternate Program
Declare @30dayCallTreatmentAP int = 
(
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 30 Alternate Program'	
)

-- NP Group
Declare @30dayCallTreatmentNP int = 
(
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 30 NP Group'	
)

-- Intrinsic Motivation
Declare @30dayCallTreatmentIM int = 
(
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 30 Intrinsic Motivation'	
)

-- Extrinsic Motivation
Declare @30dayCallTreatmentEM int = 
(
Select T.Treatmentid 
FROM dbo.Project P
	INNER JOIN PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName = 'W&W Day 30 Extrinsic Motivation'	
)


-- PROJECTID
Declare @30dayCallProject int = (Select Distinct P.Projectid 
FROM dbo.Project P
	INNER JOIN dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where  P.ProjectName = 'W&W Follow Up Queue' and T.TreatmentName in ('W&W Day 30 Alternate Program', 'W&W Day 30 NP Group', 'W&W Day 30 Intrinsic Motivation', 'W&W Day 30 Extrinsic Motivation')	)

--Print (@WelcomeCallProject)
--Print (@WelcomeCallTreatment)
--Print (@30dayCallProject)
--Print (@30dayCallTreatment)



 --2 Create a temp table of member's records for the 4 day call follow-up.
/*******************Create a table of data to load to the member and member phone tables.************/



IF object_ID('tempdb.dbo.#LoadTable') is not null
Drop table #LoadTable



-- Alternate Program
Select  m.IndividualSysId				
		,EncryptedFirstname		= m.Firstname				  
		,EncryptedLastName		= m.LastName				    
		,EncryptedAddress1		= m.Address1				    
		,EncryptedAddress2		= m.Address2				    
		,m.City						    
		,m.StateCode					
		,m.ZipCode					
		,EncryptedBirthDate	    = m.BirthDate			
		,m.GenderCode					
		,m.MemberRowEndDateTime		
		,Notes   = m.Notes
		,LookupMemberStatusId			= 1
		,m.SubScriberId				
		,m.SeverityId					
		,m.Conditioncode				
		,RowCreatedSysUserId			= 60
		,RowCreatedDateTime				= Getdate()	
		,RowModifiedSysUserid			= 60
		,RowModifiedDateTime			= Getdate()	
		,ProjectId						= @30dayCallProject
		,SysAgentId						= 60
		,LookupParticipantStatusId  	= 1
		,TreatmentId					= @30dayCallTreatmentAP
		,m.EmailAddress				
		,m.GroupName				  	
		,m.MaxAttemptDatetime		  	
		,m.DNCDateTime				
		, HomePhone					    = Case when Mp.PhoneCode = 'Home' then mp.PhoneNumber end
		,CellPhone						= Case when Mp.PhoneCode = 'Cell' then mp.PhoneNumber end
		,VisitSpecialtyCode				
		,VisitIcdDescription            
		,VisitICD9Code  				
		,VisitServiceCode				
		,HospitalIcd9Code				
		,HospitalIcdDescription			
		,HospitalServiceCode				= IIF(HospitalServiceCode > 50, 50, HospitalServiceCode)		
 Into #LoadTable
--Select *
FROM vmember  m
	Left jOIN MemberPhone MP on m.memberid = mp.Memberid
	Left JOIN MemberCallLog MCL ON m.memberid = mcl.memberid
	Left join LOOKUPCallStatus lcs on mcl.lookupcallstatusid = lcs.LOOKUPCallStatusID
	Left join PROJECTDisposition pd on mcl.PROJECTDispositionID = pd.PROJECTDispositionID   
	LEft JOIN (   Select * FROM WalkandWin_FitMetrics
				) Steps
			On m.IndividualSysID = Steps.IndividualSysid
Where m.projectid = @WelcomeCallProject and Treatmentid in (@WelcomeCallTreatment1, @WelcomeCallTreatment2)  
	--and Exists(Select * From Member M2 Inner join PROJECT p on m2.PROJECTID = p.PROJECTID 
	--												 and p.Projectid IN (@4dayCallProject,@7dayCallProject)
	--		   Where m.IndividualSysID = m2.Individualsysid and Datediff(DW,m.RowCreatedDateTime,Getdate())  >= 30  ) 
	and Not exists(Select * FROM ProjectDisposition pd inner join memberCallLog mcl on mcl.ProjectDispositionid = pd.PROJECTDispositionID 
				   Where m.Memberid = mcl.Memberid and pd.DispositionDescription = 'Medically Unable to Respond' )
	and pd.DispositionDescription = 'Silver Sneakers - Move to 30 day alternate program'	-- For W&W Day 30 Alternate Program


UNION


-- Nurse Practitioner
Select  m.IndividualSysId				
		,EncryptedFirstname		= m.Firstname					  
		,EncryptedLastName		= m.LastName					    
		,EncryptedAddress1		= m.Address1					    
		,EncryptedAddress2		= m.Address2					    
		,m.City						    	    
		,m.StateCode							
		,m.ZipCode						
		,EncryptedBirthDate	    = m.BirthDate	  			
		,m.GenderCode					
		,m.MemberRowEndDateTime		
		,Notes   = m.Notes
		,LookupMemberStatusId			= 1
		,m.SubScriberId				
		,m.SeverityId					
		,m.Conditioncode				
		,RowCreatedSysUserId			= 60
		,RowCreatedDateTime				= Getdate()	
		,RowModifiedSysUserid			= 60
		,RowModifiedDateTime			= Getdate()	
		,ProjectId						= @30dayCallProject
		,SysAgentId						= 60
		,LookupParticipantStatusId  	= 1
		,TreatmentId					= @30dayCallTreatmentNP
		,m.EmailAddress				
		,m.GroupName				  	
		,m.MaxAttemptDatetime		  	
		,m.DNCDateTime				
		, HomePhone					    = Case when Mp.PhoneCode = 'Home' then mp.PhoneNumber end
		,CellPhone						= Case when Mp.PhoneCode = 'Cell' then mp.PhoneNumber end
		,VisitSpecialtyCode				
		,VisitIcdDescription            
		,VisitICD9Code  				
		,VisitServiceCode				
		,HospitalIcd9Code				
		,HospitalIcdDescription			
		,HospitalServiceCode				= IIF(HospitalServiceCode > 50, 50, HospitalServiceCode)
--Select *
FROM vmember  m
	Left jOIN MemberPhone MP on m.memberid = mp.Memberid
	Left JOIN MemberCallLog MCL ON m.memberid = mcl.memberid
	Left join LOOKUPCallStatus lcs on mcl.lookupcallstatusid = lcs.LOOKUPCallStatusID
	Left join PROJECTDisposition pd on mcl.PROJECTDispositionID = pd.PROJECTDispositionID   
	LEft JOIN ( Select * FROM WalkandWin_FitMetrics
				) Steps
			On m.IndividualSysID = Steps.IndividualSysid
Where m.projectid = @WelcomeCallProject and Treatmentid = @WelcomeCallTreatment1	-- NP 

and (Exists(Select * From Member M2 Inner join PROJECT p on m2.PROJECTID = p.PROJECTID 
												 and p.Projectid IN (@4dayCallProject,@7dayCallProject)
		   Where m.IndividualSysID = m2.Individualsysid and Datediff(DW,m.RowCreatedDateTime,Getdate())  >= 30  ) 
	or exists(Select * FROM member m3  Where m3.memberid = m.memberid and steps.Logdates >= 14 and Datediff(DW,m.RowCreatedDateTime,Getdate())  >= 30 ))

and Not exists(Select * FROM ProjectDisposition pd inner join memberCallLog mcl on mcl.ProjectDispositionid = pd.PROJECTDispositionID 
			   Where m.Memberid = mcl.Memberid and pd.DispositionDescription = 'Medically Unable to Respond' )
and pd.DispositionDescription <> 'Silver Sneakers - Move to 30 day alternate program'	-- For W&W Day 30 Alternate Program


UNION


-- Intrinsic Motivation
Select  m.IndividualSysId				
		,EncryptedFirstname		= m.Firstname					  
		,EncryptedLastName		= m.LastName					    
		,EncryptedAddress1		= m.Address1					    
		,EncryptedAddress2		= m.Address2					    
		,m.City						    	    
		,m.StateCode							
		,m.ZipCode						
		,EncryptedBirthDate	    = m.BirthDate	  			
		,m.GenderCode					
		,m.MemberRowEndDateTime		
		,Notes   = m.Notes
		,LookupMemberStatusId			= 1
		,m.SubScriberId				
		,m.SeverityId					
		,m.Conditioncode				
		,RowCreatedSysUserId			= 60
		,RowCreatedDateTime				= Getdate()	
		,RowModifiedSysUserid			= 60
		,RowModifiedDateTime			= Getdate()	
		,ProjectId						= @30dayCallProject
		,SysAgentId						= 60
		,LookupParticipantStatusId  	= 1
		,TreatmentId					= @30dayCallTreatmentIM
		,m.EmailAddress				
		,m.GroupName				  	
		,m.MaxAttemptDatetime		  	
		,m.DNCDateTime				
		, HomePhone					    = Case when Mp.PhoneCode = 'Home' then mp.PhoneNumber end
		,CellPhone						= Case when Mp.PhoneCode = 'Cell' then mp.PhoneNumber end
		,VisitSpecialtyCode				
		,VisitIcdDescription            
		,VisitICD9Code  				
		,VisitServiceCode				
		,HospitalIcd9Code				
		,HospitalIcdDescription			
		,HospitalServiceCode				= IIF(HospitalServiceCode > 50, 50, HospitalServiceCode)
--Select *
FROM vmember  m
	Left jOIN MemberPhone MP on m.memberid = mp.Memberid
	Left JOIN MemberCallLog MCL ON m.memberid = mcl.memberid
	Left join LOOKUPCallStatus lcs on mcl.lookupcallstatusid = lcs.LOOKUPCallStatusID
	Left join PROJECTDisposition pd on mcl.PROJECTDispositionID = pd.PROJECTDispositionID   
	LEft JOIN (  Select * FROM WalkandWin_FitMetrics
				) Steps
			On m.IndividualSysID = Steps.IndividualSysid
Where m.projectid = @WelcomeCallProject and Treatmentid = @WelcomeCallTreatment2	-- IVR/DM 
and (Exists(Select * From Member M2 Inner join PROJECT p on m2.PROJECTID = p.PROJECTID 
												 and p.Projectid IN (@4dayCallProject,@7dayCallProject)
		   Where m.IndividualSysID = m2.Individualsysid and Datediff(DW,m.RowCreatedDateTime,Getdate())  >= 30  ) ----They  will be called again 4 days after signup, which would be 3 days from the time they were loaded for the welcome call.  Because they are loaded for the Welcome Call one day after registration.
			or exists(Select * FROM member m3  Where m3.memberid = m.memberid and steps.Logdates >= 14 and Datediff(DW,m.RowCreatedDateTime,Getdate())  >= 30 ))
and Not exists(Select * FROM ProjectDisposition pd inner join memberCallLog mcl on mcl.ProjectDispositionid = pd.PROJECTDispositionID 
			   Where m.Memberid = mcl.Memberid and pd.DispositionDescription = 'Medically Unable to Respond' )
and pd.DispositionDescription <> 'Silver Sneakers - Move to 30 day alternate program'	-- For W&W Day 30 Alternate Program
and exists (Select * FROM vmember inbound where treatmentid = 306 and  inbound.EmailAddress like '%Intrinsic%' and m.Firstname = inbound.FirstName and m.Lastname = inbound.Lastname)  



UNION


-- Extrinsic Motivation
Select  m.IndividualSysId				
		,EncryptedFirstname		= m.Firstname					  
		,EncryptedLastName		= m.LastName					    
		,EncryptedAddress1		= m.Address1					    
		,EncryptedAddress2		= m.Address2					    
		,m.City						    	    
		,m.StateCode							
		,m.ZipCode						
		,EncryptedBirthDate	    = m.BirthDate	  			
		,m.GenderCode					
		,m.MemberRowEndDateTime		
		,Notes   = m.Notes
		,LookupMemberStatusId			= 1
		,m.SubScriberId				
		,m.SeverityId					
		,m.Conditioncode				
		,RowCreatedSysUserId			= 60
		,RowCreatedDateTime				= Getdate()	
		,RowModifiedSysUserid			= 60
		,RowModifiedDateTime			= Getdate()	
		,ProjectId						= @30dayCallProject
		,SysAgentId						= 60
		,LookupParticipantStatusId  	= 1
		,TreatmentId					= @30dayCallTreatmentEM
		,m.EmailAddress				
		,m.GroupName				  	
		,m.MaxAttemptDatetime		  	
		,m.DNCDateTime				
		, HomePhone					    = Case when Mp.PhoneCode = 'Home' then mp.PhoneNumber end
		,CellPhone						= Case when Mp.PhoneCode = 'Cell' then mp.PhoneNumber end
		,VisitSpecialtyCode				
		,VisitIcdDescription            
		,VisitICD9Code  				
		,VisitServiceCode				
		,HospitalIcd9Code				
		,HospitalIcdDescription			
		,HospitalServiceCode				= IIF(HospitalServiceCode > 50, 50, HospitalServiceCode)
--Select *
FROM vmember  m
	Left jOIN MemberPhone MP on m.memberid = mp.Memberid
	Left JOIN MemberCallLog MCL ON m.memberid = mcl.memberid
	Left join LOOKUPCallStatus lcs on mcl.lookupcallstatusid = lcs.LOOKUPCallStatusID
	Left join PROJECTDisposition pd on mcl.PROJECTDispositionID = pd.PROJECTDispositionID   
	LEft JOIN (   Select * FROM WalkandWin_FitMetrics
				) Steps
			On m.IndividualSysID = Steps.IndividualSysid
Where m.projectid = @WelcomeCallProject and Treatmentid = @WelcomeCallTreatment2	-- IVR/DM 
and (Exists(Select * From Member M2 Inner join PROJECT p on m2.PROJECTID = p.PROJECTID 
												 and p.Projectid IN (@4dayCallProject,@7dayCallProject)
		   Where m.IndividualSysID = m2.Individualsysid and Datediff(DW,m.RowCreatedDateTime,Getdate())  >= 30 )
			or exists(Select * FROM member m3  Where m3.memberid = m.memberid and steps.Logdates >= 14 and Datediff(DW,m.RowCreatedDateTime,Getdate())  >= 30  ))
		    
and Not exists(Select * FROM ProjectDisposition pd inner join memberCallLog mcl on mcl.ProjectDispositionid = pd.PROJECTDispositionID 
			   Where m.Memberid = mcl.Memberid and pd.DispositionDescription = 'Medically Unable to Respond' )
and pd.DispositionDescription <> 'Silver Sneakers - Move to 30 day alternate program'	-- For W&W Day 30 Alternate Program
and exists (Select * FROM vmember inbound where treatmentid = 306 and  inbound.EmailAddress like '%Extrinsic%' and m.Firstname = inbound.FirstName and m.Lastname = inbound.Lastname)  

update	m
Set m.LOOKUPMemberStatusID = 4
, notes = m.notes + ' removed from queue because member added to 30 day survey queue'
--Select * 
From dbo.MEMBER	m
	Inner Join #LoadTable	l	On	m.IndividualSysID	=	l.IndividualSysID			
Where (m.PROJECTID = @WelcomeCallProject
	or m.TreatmentId in (@4dayCallTreatment, @7dayCallTreatment) )
	and m.LOOKUPMemberStatusID = 1 
	and not exists (Select * FROM Member m2 Where m.IndividualSysID = m2.Individualsysid and m2.TreatmentID in(@30dayCallTreatmentAP,@30dayCallTreatmentEM,@30dayCallTreatmentIM,@30dayCallTreatmentNP))	 --make sure not to insert twice.




	Alter table WalkandWin_FitMetrics add logdates int
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
			, EncryptedFirstname	=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(EncryptedFirstname))            
			, EncryptedLastName		=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(EncryptedLastName	))	       
			, EncryptedAddress1		=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(EncryptedAddress1	))	       
			, EncryptedAddress2		=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), dbo.ProperCase(EncryptedAddress2	))	       
			, City			       
			, StateCode	           
			, ZipCode		       
			, EncryptedBirthDate	=	ENCRYPTBYKEY(KEY_GUID('symkey_ProvoQMS'), CONVERT(VARCHAR(25), CAST(EncryptedBirthDate AS DATETIME), 101))	
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
		Where not exists (Select * FROM Member m Where m.IndividualSysID = lt.Individualsysid and m.TreatmentID = lt.TreatmentID)	 --make sure not to insert twice.

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
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
								and a.ProjectId	=	sub.PROJECTID
								and a.TreatmentId = sub.TreatmentID
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
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
								and a.ProjectId	=	sub.PROJECTID
								and a.TreatmentId = sub.TreatmentID
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
Select 	Distinct
SUB.IndividualSysid
,ServiceDateTime   = NULL
,a.VisitServiceCode
,a.VisitIcd9Code
,a.VisitIcdDescription 
,a.VisitSpecialtyCode
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
		-- Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
		 ) sub
				on a.IndividualSysID = sub.IndividualSysID
				and a.ProjectId	=	sub.PROJECTID
				and a.TreatmentId = sub.TreatmentID

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
Select 		Distinct
SUB.IndividualSysid
,ServiceDateTime   = NULL
,a.HospitalServiceCode
,a.HospitalIcd9Code
,a.HospitalIcdDescription 
,''
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
		-- Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
		 ) sub
				on a.IndividualSysID = sub.IndividualSysID
				and a.ProjectId	=	sub.PROJECTID
				and a.TreatmentId = sub.TreatmentID


END
