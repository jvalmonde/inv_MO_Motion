USE [ProvoQMS_Prod]
GO
/****** Object:  StoredProcedure [dbo].[DInsertXLHealthIdleMember]    Script Date: 9/29/2016 9:50:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Proc [dbo].[DInsertXLHealthIdleMember]
as 
Begin


/*Created by: GHyatt / 8.25.2015*/


/*Modified Ghyat 9/29/2016
Modified Lines 80 - 93 to use reference to this table instead of the old devsql14.Dermsl_prod references
Used alternate source for #ActvXLMembers because of server migration	*****/
/* Added by Koy 20160606 */
 /*** Remove members in QMS that are not anymore members in WalkandWin ***/

Select c.*
  Into #ActvXLMbrs
From Provoqms_NewMembers	c
Where c.ActiveMEMBERFlag = 1 and d.ClientName = 'XLHealth'

update a
Set a.LOOKUPMemberStatusID	=	6
  FROM [ProvoQMS_Prod].[dbo].[MEMBER]	a
Join [ProvoQMS_Prod].[dbo].Project		b	on	a.PROJECTID	=	b.PROJECTID
--Join #ActvXLMbrs						c	on	a.IndividualSysID	=	c.CustomerID
WHere b.ProjectName = 'W&W Inconsistent Syncing'	-- 590 Members
	and not exists (Select * From #ActvXLMbrs c where c.MEMBERID	=	a.IndividualSysID)	-- members that are still in QMS but not active WalkandWin Members
	and a.LOOKUPMemberStatusID = 1

  /******Insert members into Idle queue for XL Health(XLW&W Inconsistent Syncing - project # 140***/
If Object_ID('Tempdb.dbo.#LoadTable') is not null
Drop table #LoadTable


SELECT [IndividualSysID]
      ,[FirstName]
      ,[LastName]
      ,[Address1]
      ,[Address2]
      ,[City]
      ,[StateCode]
      ,[ZIPCode]
      ,[BirthDate]
      ,[GenderCode]
      ,[MemberRowEndDateTime]
      ,[Notes]
      ,[LOOKUPMemberStatusID]
      ,[SubscriberID]
      ,[SeverityID]
      ,[ConditionCode]
	  ,RowCreatedSysUserid = 60 
	  ,RowCreatedDateTime  = Getdate()
	  ,RowModifiedSysUserid = 60
	  ,RowModifiedDateTime = Getdate()
      ,[PROJECTID]
      ,[SYSAgentID]
      ,[LOOKUPParticipantStatusID]
      ,[TreatmentID]
      ,[EmailAddress]
      ,[GroupName]
      ,[MaxAttemptDateTime]
      ,[DNCDateTime]
	  ,HomePhone
	  ,CellPhone
	  INTO #LoadTable
  FROM Devsql14.[pdb_DermReporting].[dbo].[XLHealth_IdleTable] x
  Where Not exists(Select * FROM Provoqms_prod.dbo.Member m where m.IndividualSysID = x.IndividualSysID and m.PROJECTID = x.Projectid and m.LOOKUPMemberStatusID = 1)
  and Not Exists  (Select * FROM Provoqms_prod.dbo.Member m where m.IndividualSysID = x.IndividualSysID and m.PROJECTID = x.Projectid and DateDiff(day,m.RowCreatedDateTime,getdate()) <= 10)---Not sure what the proper length of time is for this. Should maybe use membercall log.

 /****If a member is in the queue but no longer on the idle list, indicate that the member is now syncing in the member generic data fields.*******/

update mgd set mgd.GenericValue = 'Member Logging - Follow up if needed and Disposition as Member Reached' 
FROM dbo.Member  a	
				INNER JOIN dbo.Project p on a.PROJECTID = p.PROJECTID and p.ProjectDescription = 'W&W Inconsistent Syncing' 			
				Left join memberGenericData mgd on a.memberid = mgd.Memberid and mgd.LookupGenericDataid = 75 and mgd.GenericValue = 'Idle'
				Left JOIN Devsql14.DermReporting_Dev.dbo.WalkandWinInactives m on a.Individualsysid = Convert(Varchar(30),m.IndividualSysid )
Where m.IndividualSySID is  null  and a.LOOKUPMemberStatusID = 1 


update a set a.LookupMemberstatusid = (Select LOOKUPMemberStatusID FROM LOOKUPMemberStatus where statuscode = 'Expired')
FROM dbo.Member  a	
				INNER JOIN dbo.Project p on a.PROJECTID = p.PROJECTID and p.ProjectDescription = 'W&W Inconsistent Syncing' 			
				Left join memberGenericData mgd on a.memberid = mgd.Memberid and mgd.LookupGenericDataid = 75 and mgd.GenericValue = 'Idle'
				Left JOIN Devsql14.DermReporting_Dev.dbo.WalkandWinInactives m on a.Individualsysid = Convert(Varchar(30),m.IndividualSysid )
Where m.IndividualSySID is  null  and a.LOOKUPMemberStatusID = 1 



		

/*****Insert the idle members into the idle table**************/

  
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
								and a.ProjectID = sub.PROJECTID
								and a.TreatmentID = sub.TreatmentID
        Where a.HomePhone is not null 
		AND NOT EXISTS (sELECT * from Memberphone MP WHERE a.HomePhone = MP.PhoneNumber AND SUB.MemberId = MP.Memberid	)


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
		 --Select * 
		FROM #LoadTable	a
					inner join 
						 (
						 Select a.*
						 FROM dbo.Member  a
						 Where  Datediff(minute,a.RowCreatedDateTime,GetDate()) < 10		 -- Make sure I am loading the phne #s for the members that I just loaded(in the last 10 minutes)
						 ) sub
								on a.IndividualSysID = sub.IndividualSysID
								and a.ProjectID = sub.PROJECTID
								and a.TreatmentID = sub.TreatmentID
        Where a.CellPhone is not null 
		AND NOT EXISTS (sELECT * from memberphone MP WHERE a.CellPhone = MP.PhoneNumber AND SUB.Memberid = MP.Memberid	)



/**********************Insert the status of the member as idle*************/

Insert into membergenericdata 
([MEMBERID]
      ,[GenericValue]
      ,[RowCreatedSYSUserID]
      ,[RowCreatedDateTime]
      ,[RowModifiedSYSUserID]
      ,[RowModifiedDateTime]
      ,[LOOKUPGenericDataID]
)
Select Memberid
,GenericValue = 'Idle'
	  ,RowCreatedSysUserid = 60 
	  ,RowCreatedDateTime  = Getdate()
	  ,RowModifiedSysUserid = 60
	  ,RowModifiedDateTime = Getdate()
	  ,LOOKUPGenericDataID = 75
	  FROM #LoadTable	a
			inner join dbo.Member  b
				on	a.IndividualSysID = b.IndividualSysID
				and a.ProjectID = b.PROJECTID
				and a.TreatmentID = b.TreatmentID
Where not exists (select * FROM MemberGenericData mgd where b.memberid = mgd.Memberid and mgd.GenericValue = 'Idle' and mgd.LOOKUPGenericDataID = 74) 


 END


