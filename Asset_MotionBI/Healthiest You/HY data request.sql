/***********************************************************************************************************************************************************

The numbers we need for the break even analysis:
-	Figure 3 from attached document for 2015
-	Figure 4 from attached document for 2015
-	Total Employee Member Months Jan 2015 to Dec 2015 (primaries)
-	Total Member Months Jan 2015 to Dec 2015 (primaries and dependents)
-	Total Number of Consults in 2015
-	Number of Scripts written in 2015
-	Number of Scripts filled in 2015
-	Based on survey data, an estimate of the number of visits that would have been PCP, urgent care, emergency department, and other.


INPUT TABLES:	pdb_ABW.dbo.HealthiestYou_MemberConsults2015
				pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult
				pdb_ABW.dbo.HealthiestYou_Member
				AllSavers_Prod.dbo.Dim_Member
				AllSavers_Prod.dbo.Dim_MemberDetail
				pdb_ABW.dbo.HealthiestYou_DrugCrosswalk

Script for input tables in Github: 

***********************************************************************************************************************************************************/ 
Use pdb_ABW
Go


/*********************************************
FIGURE 2
**********************************************/

-- Total Consults
Select Role, Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015	
Group By Role
Order By Role Desc
Go

-- Visits within 7 days from consult, by service
Select Role, AS_Service, Count(*)
From
(
	Select Distinct a.*
		, c.MemberID, c.AS_SrvcDt, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	IIF(a.Gender = 'Male', 'M', 'F')	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 7, a.Consult_Date)
	Where AS_Service in ('UC', 'DR', 'ER')
)	sub
Group By Role, AS_Service
Order By Role Desc
Go


/*********************************************
FIGURE 3
**********************************************/

-- match same diagnosis
--Drop Table #DiagMatch
Select AS_Service, Count(*)
From
(	
	-- Match by ICD 9 Code
	Select Distinct a.*
		, c.MemberID, c.AS_SrvcDt, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	IIF(a.Gender = 'Male', 'M', 'F')	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 7, a.Consult_Date)
	Where LEFT(a.Icd9Code, 3) = c.AS_ICD9_DiagFst3
		and a.Icd9Code <> ''
	
		UNION
	
	-- Match by ICD 10 Code
	Select Distinct a.*
		, c.MemberID, c.AS_SrvcDt, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	IIF(a.Gender = 'Male', 'M', 'F')	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 7, a.Consult_Date)
	Where a.ICd10Code = c.AS_ICD10_DiagCd
		and a.Icd10Code <> ''

)	sub
--Where AS_Service in ('UC', 'DR', 'ER')
Group By AS_Service
Go


/*********************************************
MEMBER MONTHS
**********************************************/

-- Employee MM and Member MM by YearMonth
select YearMonth	=	 YearMo
	, EnrolleeMM	=	Count(Distinct Case When MemberType = 'Primary' Then MEMBERID Else Null End)
	, MemberMM		=	Count(Distinct MEMBERID)
From
(
	Select Distinct MemberType	=	Case	When right(y.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary'
											When right(y.SystemID, 1) = 0 and x.MemberID = y.MemberID Then 'Primary' 
											Else 'Dependent' End
		, y.MemberID, y.YearMo
	From
	(
		Select Distinct b.MemberID, b.SystemID
		From
		(
			Select Distinct AllSavers_MemberID, AllSavers_familyID
			From pdb_ABW.dbo.HealthiestYou_Member
			where InAllSavers = 1
		)	a
			Join AllSavers_Prod.dbo.Dim_Member	b	on	a.AllSavers_familyID	=	b.FamilyID
	)	x
		Join AllSavers_Prod.dbo.Dim_MemberDetail	y	on	x.MemberID	=	y.MemberID
	Where y.YearMo between 201501 and 201512
)	c
Group By YearMo
Order By YearMo

-- Member Count and TOtal Member Months per MemberType
select MemberType
	, MemberCount	=	Count(Distinct MemberID)
	, MemberMonths	=	Count(YearMO)
From
(
	Select Distinct MemberType	=	Case	When right(y.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary'
											When right(y.SystemID, 1) = 0 and x.MemberID = y.MemberID Then 'Primary' 
											Else 'Dependent' End
		, y.MemberID, y.YearMo
	From
	(
		Select Distinct b.MemberID, b.SystemID
		From
		(
			Select Distinct AllSavers_MemberID, AllSavers_familyID
			From pdb_ABW.dbo.HealthiestYou_Member
			where InAllSavers = 1
		)	a
			Join AllSavers_Prod.dbo.Dim_Member	b	on	a.AllSavers_familyID	=	b.FamilyID
	)	x
		Join AllSavers_Prod.dbo.Dim_MemberDetail	y	on	x.MemberID	=	y.MemberID
	Where y.YearMo between 201501 and 201512
)	c
Group By MemberType
Order By MemberType


/*********************************************
# OF CONSULTS 2015
**********************************************/

-- Total Consults by Role
Select Role, Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015	
Group By Role
Order By Role Desc
Go

-- Total Consults by YearMonth
Select ConsultYearMonth, Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015	
Group By ConsultYearMonth
Order By ConsultYearMonth
Go

/*********************************************
SCRIPTS WRITTEN and FILLED
**********************************************/

-- Prescriptions Written
Select Role, Count(*)
From
(
	Select Distinct a.*
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015			a
	Where PrescriptionGiven = 'Yes'
)	sub
Group By Role
Order By Role Desc

-- Scripts Filled within 14 days from consult by Role
Select Role, Count(*)
From
(
	Select a.*
		, c.MemberID, c.AS_RX_NDC, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Left Join pdb_ABW.dbo.HealthiestYou_DrugCrosswalk				d	on	a.PrescriptionNames	=	d.HY_Rx_1
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	a.Gender 	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 14, a.Consult_Date)
																			and d.NDC	=	c.AS_Rx_NDC
	Where PrescriptionGiven = 'Yes'
)	sub
Group By ROle
Order By Role Desc

-- Scripts Filled within 14 days from consult by Service
Select AS_Service, Count(*)
From
(
	Select a.*
		, c.MemberID, c.AS_RX_NDC, c.AS_Service
	From pdb_ABW.dbo.HealthiestYou_MemberConsults2015					a
		Left Join pdb_ABW.dbo.HealthiestYou_DrugCrosswalk				d	on	a.PrescriptionNames	=	d.HY_Rx_1
		Inner Join pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult	c	On	a.AllSavers_familyID	=	c.FamilyID
																			and	a.Gender 	=	c.Gender
																			and	a.Age	=	c.Age
																			and c.AS_SrvcDt between a.Consult_Date and DATEADD(DAY, 14, a.Consult_Date)
																			and d.NDC	=	c.AS_Rx_NDC
	Where PrescriptionGiven = 'Yes'
)	sub
Group By AS_Service
Order By AS_Service Desc

--Select *
--From pdb_ABW.dbo.HealthiestYou_MemberConsults2015
--where PrescriptionGiven = 'YES'
--
--Select *
--From pdb_ABW.dbo.HealthiestYou_Claims2015_MemberswConsult
--Where AS_Service in ('ER', 'UC', 'DR')


/*********************************************
Survey Data Visits
**********************************************/

Select [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]
	, Total	=	Count(*)
From pdb_ABW.dbo.HealthiestYou_MemberConsults2015
--Where [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)] in
--	(
--	'Primary Care Physician',
--	'Urgent Care',
--	'Other',
--	'Emergency Room'
--	)
Group By [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]
Order By Total Desc