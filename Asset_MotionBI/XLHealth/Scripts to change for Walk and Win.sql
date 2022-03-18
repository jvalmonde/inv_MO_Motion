
/********Pull from Derm for Welcome Call***********/


Select IndividualSysId	      = Convert(Varchar(30),m.MEMBERID	     )        
	,Firstname                = Convert(Varchar(50),m.Firstname               )  
	,LastName		          = Convert(Varchar(30),m.LastName		         )    
	,Address1		          = Convert(Varchar(40),m.Address1		         )    
	,Address2		          = Convert(Varchar(40),m.Address2		         )    
	,City			          = Convert(Varchar(40),m.City			         )    
	,StateCode	              = Convert(Char(2),m.StateCode	             )
	,ZipCode		          = Convert(Char(5),m.ZipCode		         )    
	,m.BirthDate	  			            		
	,GenderCode	              = Convert(Char(1),m.Gender	             )
	,MemberRowEndDateTime	  = NULL   
	,Notes						 = ''
	,LookupMemberStatusId		 = 1   
	,SubScriberId				 = m.MEMBERID   
	,SeverityId					 = 0
	,Conditioncode				 = ''
	,RowCreatedSysUserId		 = 1	  
	,RowCreatedDateTime			 = Getdate()  
	,RowModifiedSysUserid		 = 1  
	,RowModifiedDateTime		 = Getdate()	  
	,ProjectId					 =  '' 
	,SysAgentId					 = 60 
	,LookupParticipantStatusId   = 1
	,TreatmentId				 = '' 
	,EmailAddress				 = NULL 
	,GroupName				  	 = ''
	,MaxAttemptDatetime		  	 = NULL
	,DNCDateTime				 = NULL 
	, HomePhone
	,CellPhone
	,NP = mp.FirstName + ' ' + Mp.Lastname 
	,AccountCreatedDateTime = m.RowCreatedDateTime
	,DeliveryDate				= ''
	--,ps.enrollmentsource


FROM Dermsl_Prod.dbo.[MEMBER]	 M 
	INNER JOIN Dermsl_Prod.dbo.LookupClient LC 
		ON m.LookupClientid = lc.LookupClientid 
	INNER JOIN Dermsl_Prod.dbo.MEMBERPreparer mp 
		ON m.MEMBERPreparerID = mp.MEMBERPreparerID
	LEFT JOIN  Dermsl_Prod.dbo.PREPARERSerial	ps
		ON	m.MEMBERID	=	ps.MEMBERID
Where lc.Clientname = 'XLHealth' and Convert(Date,m.RowcreatedDateTime) < Convert(Date,Getdate()) and m.RowCreatedDateTime >= '2016-06-08 15:44:09.977'
	--and (ps.enrollmentsource <> 2)		


/********************************************/

/*****************Pull from Derm for 7day and 30 day follow up*/



				Select  IndividualSysID = dm.Memberid
					, VisitSpecialtyCode	 = ''--Sum(isnull(FA.TotalSteps ,0)	)
					, VisitICDDescription	 = Sum(isnull(case when rulename = 'Frequency' and fa.TotalBouts >= lr.totalBouts then 1 else 0 end, 0)	)
					, VisitIcd9Code			 = Sum(isnull(Case when rulename = 'tenacity' then FA.TotalSteps else 0 end, 0)	)
					, VisitServiceCode		 = (sum(case when rulename = 'Frequency' then fa.incentiveAmount else 0 end	))
					, HospitalIcd9Code		 = Convert(Decimal(9,2),Sum(isnull(case when rulename = 'tenacity' then fa.incentiveAmount else 0 end	, 0)	) )
					, HospitalICDDescription = Sum(isnull(case when rulename = 'Tenacity' and fa.TotalSteps >= lr.TotalStepsMin then 1 else 0 end, 0)	)
					, HospitalServiceCode	 = cONVERT(dECIMAL(9,2),sum(isnull(fa.incentiveAmount, 0)	)  )
				FROM Dermsl_prod.dbo.Member DM 
					Inner join Dermsl_prod.dbo.LookupClient lc on dm.Lookupclientid = lc.LookupClientid and lc.Clientname =  'xlhealth'
					Left JOIn  Dermsl_prod.dbo.memberearnedIncentives FA  on dm.Memberid = fa.Memberid and fa.IncentiveDate between dm.ProgramStartDate and isnull(dm.CancelledDateTime,getdate())
					Left join  Dermsl_prod.dbo.LookupRule lr on fa.LookupRuleId = lr.LookupRuleid 
					lEFT JOIN Dermsl_prod.dbo.LookupRuleGroup lrg on lr.LookupRuleGroupid = lrg.LookupRuleGroupid
				  Where dm.memberid = 21183  and incentivedate >='20160101'
				Group by dm.Memberid


/***************************************************/
/*****For Migrating inactives***************/ 

If OBJECT_ID('tempdb..#MembersNotSynced') is not Null
Drop table #MembersNotSynced
select [IndividualSysID]			=	a.MemberID
	, [FirstName]					=	a.[FirstName]
	, [LastName]					=	a.[LastName]
	, [Address1]					=	a.[Address1]
	, [Address2]					=	a.[Address2]
	, [City]						=	a.[City]
	, [StateCode]					=	a.[StateCode]
	, [ZIPCode]						=	a.[ZIPCode]
	, [BirthDate]					=	a.[BirthDate]
	, [GenderCode]					=	a.Gender
	--, [MemberRowEndDateTime]		=	NULL
	, [Notes]						=	''
	, [LOOKUPMemberStatusID]		=	1
	, [SubscriberID]				=	a.MemberID
	, [SeverityID]					=	0
	, [ConditionCode]				=	''
	--, [RowCreatedSysUserID]			=	60
	--, [RowCreatedDateTime]			=	getdate()
	--, [RowModifiedSysUserID]		=	60
	--, [RowModifiedDateTime]			=	getdate()
	, [PROJECTID]					=	NULL -- (Select Projectid FROM provoqms_prod.dbo.Project  Where projectName = 'W&W Inconsistent Syncing' )
	, SYSAgentID					=	60
	, [LOOKUPParticipantStatusID]	=	1
	, [TreatmentID]					=	NULL
	, [EmailAddress]				=	d.email
	, [GroupName]					=	'XLHealth'
	--, [MaxAttemptDateTime]			=	NULL
	--, [DNCDateTime]					=	NULL
	,HomePhone						   = Homephone --dbo.RemoveNonNumericCharacters(HomePhone)
	,CellPhone						   = Cellphone --dbo.RemoveNonNumericCharacters(CellPhone)
	, LastLogDate					=	CONVERT(date, c.LastStepMinute)
	--, NbrofDaysIdle					=	DATEDIFF(day, c.LastStepMinute, Getdate())
	, RowCreatedDate				=	CONVERT(date, getdate())
	--, DaysinTable					=	0

from DERMSL_Prod.dbo.MEMBER	a
	Inner Join DERMSL_Prod.dbo.LOOKUPClient	b	On	a.LOOKUPClientID = b.LOOKUPClientID
	Inner Join [DERMSL_Prod].[dbo].[MemberStepMovementMetaData]	c	On	a.MEMBERID	=	c.MEMBERID
	Left Join DERMSL_Prod.dbo.SysUser	d	on	a.SYSUserID	=	d.SYSUserID
Where ClientName = 'XLHealth'
	and ActiveMemberFlag = 1
	and c.LastStepMinute is not null
	and DATEDIFF(day, c.LastStepMinute, Getdate()) >= 7
