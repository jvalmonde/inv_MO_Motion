USE [pdb_DermReporting]
GO
/****** Object:  StoredProcedure [dbo].[DSelect_WalkandWin_ShippingReport]    Script Date: 9/28/2016 9:49:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[DSelect_WalkandWin_ShippingReport]

As


Begin


/***** StartDate and EndDate *****/
DECLARE @StartDate datetime	= '20160916'
--(
--Select StartDate	=	CONVERT(Datetime, (CONVERT(varchar(10), DATEADD(day, DiffDays, CurrentDate)) + ' ' + '17:00:00.000') )
--From
--(
--	Select CurrentDate	=	CONVERT(Date, FULL_DT)--, DATEADD(Day, -7, FULL_DT)
--		, DiffDays	=	CASE	When DAY_ABBR_CD	= 'FRI' Then -1			
--								When DAY_ABBR_CD	= 'SAT' Then -2
--								When DAY_ABBR_CD	= 'SUN' Then -3
--								When DAY_ABBR_CD	= 'MON' Then -4
--								When DAY_ABBR_CD	= 'TUE' Then -5
--								When DAY_ABBR_CD	= 'WED' Then -6
--								When DAY_ABBR_CD	= 'THU' Then -7
--								Else 0
--						END
--	From pdb_DermReporting.dbo.Dim_Date
--	Where FULL_DT = CONVERT(date, getdate())
--)	sub
--)
	
DECLARE @EndDate datetime =  Getdate()
--(Select  CONVERT(Datetime, (CONVERT(varchar(10), DATEADD(Day, 7, CONVERT(Date, @StartDate))) + ' ' + '16:59:59.000')	))


/*** For QMS Disposition ***/
-- Inbound Sign-Up Call
Declare @WelcomeCallTreatment int = (Select T.Treatmentid 
FROM ProvoQMS_Prod.dbo.Project P
	INNER JOIN ProvoQMS_Prod.dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN ProvoQMS_Prod.dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'W&W Inbound Sign-Up Call'	)
Print(@WelcomeCallTreatment)

Declare @WelcomeCallTreatment2 int = 
(
Select T.Treatmentid 
FROM ProvoQMS_Prod.dbo.Project P
	INNER JOIN ProvoQMS_Prod.dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN ProvoQMS_Prod.dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'Inbound call return queue'	
)
Print(@WelcomeCallTreatment2)

--Select * FROM Provoqms_prod.dbo.Treatment where Treatmentid = 316

-- ProjectID
Declare @WelcomeCallProject int = (Select P.Projectid 
FROM ProvoQMS_Prod.dbo.Project P
	INNER JOIN ProvoQMS_Prod.dbo.PROJECTTreatment pt ON P.PROJECTID = pt.PROJECTID 
	INNER JOIN ProvoQMS_Prod.dbo.TREATMENT         T	on pt.Treatmentid = t.Treatmentid
Where P.ProjectName = 'W&W Welcome Calls' and T.TreatmentName = 'W&W Inbound Sign-Up Call'	)
Print (@WelcomeCallProject)

If Object_Id('tempdb..#QMSTreatment') is not null 
DROP TABLE #QMSTreatment

Select Distinct  IndividualSysId, firstname, Lastname, Address1, Address2, City, StateCode, Zipcode, Birthdate, GenderCode, EmailAddress

Into #QMSTreatment 
	from  ProvoQMS_Prod.dbo.vMember					as a
	Where a.PROJECTID	=	@WelcomeCallProject
	  and a.TreatmentId in ( @WelcomeCallTreatment,@WelcomeCallTreatment2)
--and Firstname = 'Linda' and Lastname = 'Bixler'



If Object_Id('tempdb..#qms_response') is not null 
DROP TABLE #qms_response
Select qt.*, sub.ResponseText
  into #qms_response
From
 #QMSTreatment qt Left join
		(
			select a.IndividualSysID, a.MEMBERID, a.PROJECTID, a.TreatmentID, a.Notes, a.EmailAddress,
				   d.SequenceNumber, d.ScriptText, 
				   b.ParticipantResponseText, 
				   c.ResponseText,
				   --CONVERT(VARCHAR(50), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_ProvoQMS'), NULL, a.EncryptedFirstName)) As FirstName,
				   --CONVERT(VARCHAR(50), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_ProvoQMS'), NULL, a.EncryptedLastName)) As LastName,
				   --CONVERT(VARCHAR(40), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_ProvoQMS'), NULL, a.EncryptedAddress1)) As Address1,
				   --CONVERT(VARCHAR(40), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_ProvoQMS'), NULL, a.EncryptedAddress2)) As Address2,
				   --CAST(CONVERT(VARCHAR(25), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_ProvoQMS'), NULL, a.EncryptedBirthDate)) AS DATETIME) As BirthDate,
				   a.City, a.StateCode, a.ZIPCode, a.GenderCode,
				   f.FirstName, f.LastName, f.Address1, f.Address2, f.Birthdate,
					ROW_NUMBER() Over(Partition By a.IndividualSysID Order By e.LastCallDateTime Desc) as OID
				--g.StatusCode as  CallDisposition, 
				--f.DispositionDescription as ProjectDisposition
			from  ProvoQMS_Prod.dbo.Member					as a
			left join ProvoQMS_Prod..CALLScriptParticipant	as b	on a.MEMBERID = b.MemberID 
			left join ProvoQMS_Prod..CALLScriptResponse		as c	on b.CALLScriptResponseID = c.CALLScriptResponseID
			left join ProvoQMS_Prod..CALLScriptDetail		as d	on c.CALLScriptDetailID = d.CALLScriptDetailID 
			join ProvoQMS_Prod..MEMBERCallLog				as e	on a.MEMBERID = e.MEMBERID
			Join ProvoQMS_Prod.dbo.vMember					as f	on a.MEMBERID	=	f.MEMBERID
			--left join ProvoQMS_PRod..PROJECTDisposition		as f	on e.PROJECTDispositionID = f.PROJECTDispositionID
			--left join ProvoQMS_Prod..LOOKUPCallStatus		as g	on e.LOOKUPCallStatusID = g.LOOKUPCallStatusID
			Where a.PROJECTID	=	@WelcomeCallProject
			  and a.TreatmentId in ( @WelcomeCallTreatment,@WelcomeCallTreatment2)
			  and CALLScriptID in (226,239)
			  and d.SequenceNumber = 11
		)	sub
	 on sub.IndividualSysID = qt.IndividualSysID and  (OID = 1 )
--order by IndividualSysID

--Select * From #qms_response where lastname = 'Bixler'
--Select * FROM provoqms_Prod.dbo.vMember where lastname = 'Bixler' and firstname = 'Linda'


/*** NEW ENROLLMENTS ***/
If Object_Id('tempdb..#NewEnrollments') is not null 
DROP TABLE #NewEnrollments
Select *
	, Enrollment		=	Case When EnrollmentSource = 2 Then 'IVR/DM' Else 'NP' End
	--, LastThursday5PM	=	@StartDate
	--, [Today4:59PM]		=	@EndDate
  Into #NewEnrollments
From Dermreporting_Dev.dbo.PreparerSerialCopy a
Where EnrollDate	between @StartDate		-- previous thursday 5:00 PM
					and @EndDate			-- current thursday 4:59 PM
	and EnrollDate Is Not Null
--Order By EnrollDate Desc

	UNION

Select *
	, Enrollment		=	Case When EnrollmentSource = 2 Then 'IVR/DM' Else 'NP' End
	--, LastThursday5PM	=	@StartDate
	--, [Today4:59PM]		=	@EndDate
From DermReporting_Dev.dbo.PreparerSerialCopy
Where RowCreatedDateTime	between @StartDate		-- previous thursday 5:00 PM
						and @EndDate			-- current thursday 4:59 PM
	and EnrollDate Is Not Null
--Order By EnrollDate Desc

-- Select * From #NewEnrollments


/*** OUTPUT ***/
Select PreparerID		=	a.MEMBERPreparerID
	, PreparerName		=	a.Firstname + ' ' + a.Lastname
	, SerialNumber		=	a.Serial
	, a.MEMBERID, b.FirstName, b.LastName, b.HomePhone, b.CellPhone, b.Address1, b.Address2, b.City, b.ZipCode, b.StateCode
	, EnrollDate = isnull(a.EnrollDate, b.AccountCreatedDateTime)
	, a.EnrollmentSource
	--, a.Enrollment
	, Enrollment		=	ISNULL(Case	When d.IndividualSysID is not null and d.EmailAddress like '%IVR%'	Then 'IVR'
										When d.IndividualSysID is not null and d.EmailAddress like '%Mail%'	Then 'Direct Mail'
										when a.EnrollmentSource = 2 and d.IndividualSysid is null then 'DM/IVR - URL not used'
										When a.AccountCreatedDateTime is null then 'No Enrollment Data' Else NULL
									End, Case When a.EnrollmentSource = 3 or a.EnrollmentSource Is Null Then 'NP' ELse NUll End)
	, TreatmentGroup	=	ISNULL(Case	When d.IndividualSysID is not null and d.EmailAddress like 'Extrinsic%'	Then 'Extrinsic'
										When d.IndividualSysID is not null and d.EmailAddress like 'Intrinsic%'	Then 'Intrinsic'
										When a.EnrollmentSource = 3 or a.EnrollmentSource Is Null and a.AccountCreatedDateTime is not null Then 'NP'
									when a.AccountCreatedDateTime is  null Then 'No Enrollment Data'
										Else NULL
									End, Case When a.EnrollmentSource = 3 or a.EnrollmentSource Is Null and a.AccountCreatedDateTime is not null Then 'NP'
									when a.AccountCreatedDateTime is  null Then 'No Enrollment Data' ELse NUll End)
	
	, QMSResponse		=	d.ResponseText		-- Disposition from QMS. Response is either "Yes - USB Key" or "No - Sync Station"
From DermReporting_Dev.dbo.Provoqms_NewMembersandEnrollmentdataforShippingreport	b
	Left Join #NewEnrollments	a
		On	a.MEMBERID	=	b.IndividualSysID
	Left Join #qms_response	d
		On	b.FirstName		=	d.FirstName
		and	b.LastName		=	d.LastName
		and	b.BirthDate		=	d.BirthDate
		and b.GenderCode	=	d.GenderCode
Where 1 = 1 
and b.AccountCreatedDateTime between @StartDate and @EndDate

Select * FROM #qms_response where lastname = 'Hammonds'




End


