/*** 
GP 1061 Pharmacy & Motion -- New Data Set (predicting motion enrollment)

Input databases:	AllSavers_Prod, pdb_AllSavers_Research

Date Created: 19 May 2017
***/

--pull for policies that offered motion & all the members in the policy
If (object_id('tempdb..#members') Is Not Null)
Drop Table #members
go

select b.MemberID, b.SystemID, b.PolicyID	--, b.Age, b.Gender	--, b.Sbscr_Ind
	, a.PolicyEffDate
	, a.PolicyEndDate
	, b.FamilyID								--added 06/16/2017
	, Mbr_PlanEffYrMo = min(b.YearMo)
	, Mbr_PlanEndYrMo = max(b.YearMo)
	, MM = count(distinct b.YearMo)
	, MM_2014 = count(distinct case when left(b.YearMo, 4) = 2014	then b.YearMo	end)
	, MM_2015 = count(distinct case when left(b.YearMo, 4) = 2015	then b.YearMo	end)
	, MM_2016 = count(distinct case when left(b.YearMo, 4) = 2016	then b.YearMo	end)
	, a.GroupName, a.GroupState, a.EnrolledMotionYM
into #members
from pdb_Allsavers_Research..GroupSummary		a
inner join Allsavers_Prod..Dim_MemberDetail		b	on	a.PolicyID = b.PolicyID
where EnrolledMotionYM > 0				--filter plans or groups with motion only
	and b.YearMo < 201701				--filter out 2017
	and b.YearMo >= 201401				--filter out previous years as motion was initially offered in 2014; added 05/25/2017
group by b.MemberID, b.SystemID, b.PolicyID
	, a.GroupName, a.GroupState, a.EnrolledMotionYM, a.PolicyEffDate, a.PolicyEndDate, b.FamilyID
having count(distinct b.YearMo) >= 12	--at least 12 member months in All Savers plan
--(133602 row(s) affected)
create unique index uIx_MemberID_SysID on #members (SystemID);

/*
select MemberID, count(*) from #members group by MemberID having count(*) > 1	--73; 1 MemberID can have several SystemIDs
select * from #members where MemberID in (202322, 340820) order by 1, PolicyEffDate	
select * from Allsavers_Prod..Dim_MemberDetail where MemberID = 23841
select * from Allsavers_Prod..Dim_Member where MemberID = 23841
--NOTES: members can have multiple SystemID in 1 PolicyID, members can have different Sbscr_Ind across time, members can have different Genders across time

--delete those members with multiple policies for now
If (object_id('tempdb..#members_multiplepolicies') Is Not Null)
Drop Table #members_multiplepolicies
go

select MemberID, PcyCnt = count(distinct PolicyID)
into #members_multiplepolicies
from #members
group by MemberID
having count(distinct PolicyID) > 1
--(4 row(s) affected)

delete from #members
where MemberID in (select MemberID from #members_multiplepolicies)
go
--(8 row(s) affected)
create unique index uIx_MemberID_SysID on #members (MemberID);
*/

--pull for the member's most recent details
If (object_id('tempdb..#members_fnl') Is Not Null)
Drop Table #members_fnl
go

select a.*, b.Age, b.Gender, b.Sbscr_Ind, b.Zip, c.St_Cd, c.MSA, c.County, d.CTY_NM
into #members_fnl
from #members	a
inner join Allsavers_Prod..Dim_Member	b	on	a.SystemID = b.SystemID
left join pdb_Rally..Zip_Census			c	on	b.Zip = c.Zip
left join MiniHPDM..Dim_Zip				d	on	b.Zip = d.ZIP_CD
--(131967 row(s) affected)
create unique index uIx_MemberID_SystemID on #members_fnl (MemberID, SystemID);

/*
select MemberiD, count(*) from #members group by MemberiD having count(*) > 1	--73
select * from #members where MemberID in (259828, 102725)	--different familyids
*/

--pull for all members enrolled in motion
If (object_id('tempdb..#members_motion') Is Not Null)
Drop Table #members_motion
go

select a.MemberID, a.SystemID, b.Member_DIMID, EnrolledMotion_YrMo = c.Year_Mo, DisenrolledMotion = c.LastEnrolled, Motion = 1
	, Mtn_PcyMM = datediff(mm, cast(cast(a.EnrolledMotionYM as varchar) + '01' as date), c.LastEnrolled)	--motion member months with respect to group policy & enrollment
	, c.FirstEnrolled
into #members_motion
from #members_fnl				a
inner join pdb_Allsavers_Research..ASM_xwalk_Member		b	on	a.SystemID = b.SystemID
inner join pdb_Allsavers_Research..DERMEnrollmentBasis	c	on	b.Member_DIMID = c.Member_DIMID
where c.Year_Mo <= 201607													--filter out members who first enrolled in motion in July 2016 onwards
--(31506 row(s) affected)
--(31426 row(s) affected); 06/16/2017 run
create unique index uIx_MemberID on #members_motion (SystemID);

--final member table
If (object_id('pdb_PharmaMotion..Member_v2') Is Not Null)
Drop Table pdb_PharmaMotion..Member_v2
go

select a.MemberID, a.PolicyID, a.GroupName, a.GroupState, Grp_EnrolledMotionYM = a.EnrolledMotionYM, a.Age, a.Gender, a.Sbscr_Ind
	, Motion = isnull(c.Motion, 0)
	, Mbr_EnrolledMotionYM			= isnull(c.EnrolledMotion_YrMo, '')
	, Mbr_DisenrolledMotionDate		= isnull(c.DisenrolledMotion, '')
	, a.MM
	, a.PolicyEffDate	
	, a.PolicyEndDate
	, Mbr_PlanEffYM		= a.Mbr_PlanEffYrMo
	, Mbr_PlanEndYM		= a.Mbr_PlanEndYrMo
	, MM_2014			= a.MM_2014	
	, MM_2015			= a.MM_2015	
	, MM_2016			= a.MM_2016	
	, Mtn_PcyMM			= isnull(c.Mtn_PcyMM, 0)
	, a.Zip, a.CTY_NM, a.County, a.MSA, a.St_Cd
	, WithSteps						= NULL
    , Der_Mbr_EnrolledMotionYM		= NULL
    , Der_Mbr_DisenrolledMotionYM	= (case when format(c.DisenrolledMotion, 'yyyyMM') > format(a.PolicyEndDate, 'yyyyMM')	then format(a.PolicyEndDate, 'yyyyMM')	end)
    , Mbr_DisenrFlag				= (case when year(DisenrolledMotion) <> 2999 and format(DisenrolledMotion, 'yyyyMM') > format(a.PolicyEndDate, 'yyyyMM')	then 1	else 0	end)
    , Der_Mtn_PcyMM					= NULL
    , Der_Grp_EnrolledMotionYM		= (case when a.EnrolledMotionYM < format(a.PolicyEffDate, 'yyyyMM')	then format(a.PolicyEffDate, 'yyyyMM') else a.EnrolledMotionYM	end)
    , Grp_EnrolledMotionDate		= cast(cast(a.EnrolledMotionYM as varchar) + '01' as date)
    , Mbr_EnrolledMotionDate		= c.FirstEnrolled	
    , Mbr_DisenrolledMotionYM		= (case when format(c.DisenrolledMotion, 'yyyyMM') = '190001'	then NULL	else format(c.DisenrolledMotion, 'yyyyMM')	end)
    , PolicyEffYM					= format(PolicyEffDate, 'yyyyMM')
    , PolicyEndYM					= format(PolicyEndDate, 'yyyyMM')
    , Mbr_PlanEffDate				= NULL
    , Mbr_PlanEndDate				= NULL
    , Fst_StepDate					= NULL
    , Lst_StepDate					= NULL
    , RAF_2014						= NULL
    , RAF_2015						= NULL
    , RAF_2016						= NULL
    , c.Member_DIMID	
	, a.SystemID
	, a.FamilyID
into pdb_PharmaMotion..Member_v2
from #members_fnl	a
left join #members_motion					c	on	a.SystemID = c.SystemID
--where a.MemberID = 9796	--17244
--(131967 row(s) affected)
create unique index uIx_MemberID on pdb_PharmaMotion..Member_v2 (SystemID);

/* DON'T RUN THIS ON A NORMAL EXECUTION OF THE SCRIPT
--delete members whose all savers membership stared before 2014 & ends part of 2014
delete from pdb_PharmaMotion..Member_v2
where MemberID in (	select MemberID
					from	(
								select MemberID, MM, MM_2014, MM_2015, MM_2016
									, Total_MM = MM_2014 + MM_2015 + MM_2016
								from pdb_PharmaMotion..Member_v2
							) x
					where Total_MM < 12
)
*/
/* test queries
where a.MemberID in (110394, 103859)	--these members have weird motion enrollment & disenrollment data
where a.MemberID <> 23841				--this memberid had 2 Genders!
select MemberID, count(*) from pdb_PharmaMotion..Member_v2 group by MemberID having count(*) > 1
select * from pdb_PharmaMotion..Member_v2	where MOtion = 1 and Mbr_EnrolledMotion_YrMo <> MM_MinYM and Grp_EnrolledMotionYM <> Mbr_EnrolledMotion_YrMo
select * from pdb_PharmaMotion..Member_v2	where MemberID = 23841	---in (17244, 180499)	--= 19322
select * from #members where MemberID = 23841
select * from Allsavers_Prod..Dim_MemberDetail where MemberID = 164176
select MemberID, count(*) from pdb_PharmaMotion..Member_v2 group by MemberID having count(*) > 1
select * from pdb_PharmaMotion..Member_v2 where	MemberID = 10077
select * from pdb_PharmaMotion..Member_v2 where	Motion = 1
select * from Allsavers_Prod..Dim_Policy where PolicyID = 5400005290
select distinct Yearmo from Allsavers_Prod..Dim_Date where YearNbr = 2015
*/


If (object_id('pdb_PharmaMotion..tmp_MbrMos_v2') Is Not Null)
Drop Table pdb_PharmaMotion..tmp_MbrMos_v2
go

select distinct SystemID, MemberID
	, b.YearMo
	, Enrl_Plan					= case when b.YearMo between a.Mbr_PlanEffYM and a.Mbr_PlanEndYM	then 1	else 0 end
	, Enrl_Motion				= case when b.YearMo between a.Mbr_EnrolledMotionYM and Mbr_DisenrolledMotionYM	then 1	else 0 end
	, EnrlMotion_MonthInd		= case when (case when b.YearMo between a.Mbr_EnrolledMotionYM and a.Mbr_DisenrolledMotionYM	then 1	else 0 end) = 1 
											then datediff(mm, a.Mbr_EnrolledMotionDate, cast(b.YearMo + '01' as date)) 
											else 0	end
	, EnrlMotion_MonthInd_v2	= case when (case when b.YearMo between a.Mbr_EnrolledMotionYM and a.Mbr_DisenrolledMotionYM	then 1	else 0 end) = 1		--added 06/20/2017
											then datediff(mm, a.Mbr_EnrolledMotionDate, cast(b.YearMo + '01' as date))
										else datediff(mm, a.Mbr_EnrolledMotionDate, cast(b.YearMo + '01' as date)) 	end
	, PlcyEnrlMotion_MonthInd	= datediff(mm, cast(cast(a.Grp_EnrolledMotionYM as varchar) + '01' as date), cast(b.YearMo + '01' as date))
into pdb_PharmaMotion..tmp_MbrMos_v2
from pdb_PharmaMotion..Member_v2	a
inner join Allsavers_Prod..Dim_Date	b	on	b.YearMo between a.PolicyEffYM and a.PolicyEndYM
--where a.MemberID = 42649	--265193
--(2,549,198 row(s) affected); 2.12 minutes
create unique index uIx_MemberID_YM on pdb_PharmaMotion..tmp_MbrMos_v2 (SystemID, YearMo);

--added 06/20/2017
update pdb_PharmaMotion..MemberSummary_v2
set EnrlMotion_MonthInd = b.EnrlMotion_MonthInd_v2
from pdb_PharmaMotion..MemberSummary_v2	a
inner join pdb_PharmaMotion..tmp_MbrMos_v2	b	on	a.SystemID = b.SystemID
												and a.YearMo = b.YearMo
/*
select *
from	(
select MemberID
	, Min_MtnYM = min(EnrlMotion_MonthInd)
	, Max_MtnYM = max(EnrlMotion_MonthInd)
from pdb_PharmaMotion..tmp_MbrMos_v2
group by MemberID
having max(Enrl_Motion) = 1
		) x
where Min_MtnYM >= -6 --and Min_MtnYM < 0
	and Max_MtnYM >= 5

select * from pdb_PharmaMotion..tmp_MbrMos_v2 where MemberID = 130451 order by YearMo
*/

--------------------------
--Build Member Summary table
--------------------------
--count of distinct NDCs per drug class
If (object_id('tempdb..#NDC_Cnt') Is Not Null)
Drop Table #NDC_Cnt
go

select a.SystemID, a.YearMo
	, Cnt_Analgesic_Antihistamine_Combination	= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANALGESIC AND ANTIHISTAMINE COMBINATION'     then d.NDC	end)
	, Cnt_Analgesics							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANALGESICS'									then d.NDC	end)
	, Cnt_Anesthetics							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANESTHETICS'									then d.NDC	end)
	, Cnt_AntiObesityDrugs						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTI-OBESITY DRUGS'							then d.NDC	end)
	, Cnt_Antiarthritics						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIARTHRITICS'								then d.NDC	end)
	, Cnt_Antiasthmatics						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIASTHMATICS'								then d.NDC	end)
	, Cnt_Antibiotics							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIBIOTICS'									then d.NDC	end)
	, Cnt_Anticoagulants						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTICOAGULANTS'								then d.NDC	end)
	, Cnt_Antidotes								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIDOTES'									then d.NDC	end)
	, Cnt_AntiFungals							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIFUNGALS'									then d.NDC	end)
	, Cnt_Antihistamine_Decongestant_Combination	= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINE AND DECONGESTANT COMBINATION'	then d.NDC	end)
	, Cnt_Antihistamines						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINES'								then d.NDC	end)
	, Cnt_Antihyperglycemics					= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHYPERGLYCEMICS'							then d.NDC	end)
	, Cnt_Antiinfectives						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES'								then d.NDC	end)
	, Cnt_AntiinfectivesMiscellaneous			= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES/MISCELLANEOUS'				then d.NDC	end)
	, Cnt_Antineoplastics						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTINEOPLASTICS'								then d.NDC	end)
	, Cnt_AntiparkinsonDrugs					= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIPARKINSON DRUGS'							then d.NDC	end)
	, Cnt_AntiplateletDrugs						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIPLATELET DRUGS'							then d.NDC	end)
	, Cnt_Antivirals							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIVIRALS'									then d.NDC	end)
	, Cnt_AutonomicDrugs						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'AUTONOMIC DRUGS'								then d.NDC	end)
	, Cnt_Biologicals							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'BIOLOGICALS'									then d.NDC	end)
	, Cnt_Blood									= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'BLOOD'										then d.NDC	end)
	, Cnt_CardiacDrugs							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'CARDIAC DRUGS'								then d.NDC	end)
	, Cnt_Cardiovascular						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'CARDIOVASCULAR'								then d.NDC	end)
	, Cnt_CNSDrugs								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'CNS DRUGS'									then d.NDC	end)
	, Cnt_ColonyStimulatingFactors				= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'COLONY STIMULATING FACTORS'					then d.NDC	end)
	, Cnt_Contraceptives						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'CONTRACEPTIVES'								then d.NDC	end)
	, Cnt_CoughColdPreparations					= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'COUGH/COLD PREPARATIONS'						then d.NDC	end)
	, Cnt_Diagnostic							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'DIAGNOSTIC'									then d.NDC	end)
	, Cnt_Diuretics								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'DIURETICS'									then d.NDC	end)
	, Cnt_EENTPreps								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'EENT PREPS'									then d.NDC	end)
	, Cnt_ElectCaloricH2O						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'ELECT/CALORIC/H2O'							then d.NDC	end)
	, Cnt_Gastrointestinal						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'GASTROINTESTINAL'							then d.NDC	end)
	, Cnt_Herbals								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'HERBALS'										then d.NDC	end)
	, Cnt_Hormones								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'HORMONES'									then d.NDC	end)
	, Cnt_Immunosuppresant						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'IMMUNOSUPPRESANT'							then d.NDC	end)
	, Cnt_MiscMedicalSuppliesDevicesNondrug		= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'MISC MEDICAL SUPPLIES, DEVICES, NON-DRUG'	then d.NDC	end)
	, Cnt_MuscleRelaxants						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'MUSCLE RELAXANTS'							then d.NDC	end)
	, Cnt_PreNatalVitamins						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'PRE-NATAL VITAMINS'							then d.NDC	end)
	, Cnt_PhyscotherapeuticDrugs				= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'PSYCHOTHERAPEUTIC DRUGS'						then d.NDC	end)
	, Cnt_SedativeHypnotics						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SEDATIVE/HYPNOTICS'							then d.NDC	end)
	, Cnt_SkinPreps								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SKIN PREPS'									then d.NDC	end)
	, Cnt_SmokingDeterrents						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SMOKING DETERRENTS'							then d.NDC	end)
	, Cnt_ThyroidPreps							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'THYROID PREPS'								then d.NDC	end)
	, Cnt_Vitamins								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'VITAMINS'									then d.NDC	end)
into #NDC_Cnt
from pdb_PharmaMotion..tmp_MbrMos_v2	a
inner join AllSavers_Prod..Fact_Claims	b	on	a.SystemID = b.SystemID
inner join AllSavers_Prod..Dim_Date		c	on	b.FromDtSysID = c.DtSysId
											and a.YearMo = c.YearMo
inner join AllSavers_Prod..Dim_NDCDrug	d	on	b.NDCDrugSysID = d.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class		e	on	d.NDC = e.NDC
where e.Gnrc_Therapeutic_Clss_Desc is not null
	and e.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
	and b.ServiceTypeSysID = 4
	--and a.SystemID = 54000015550000100
	--and a.YearMo = 201611
group by a.SystemID, a.YearMo
having sum(b.AllwAmt) > 0
--(721,221 row(s) affected); 4.32 minutes
--(697,868 row(s) affected); 4.07 minutes
create unique index uIx_MemberID_YrMo on #NDC_Cnt (SystemID, YearMo);

---------------------------------
--Utilization
---------------------------------
If (object_id('tempdb..#utilization') Is Not Null)
Drop Table #utilization
go

select SystemID, YearMo
	, IP_Allow = sum(IP_Allow)
	, OP_Allow = sum(OP_Allow)
	, DR_Allow = sum(DR_Allow)
	, ER_Allow = sum(ER_Allow)
	, RX_Allow = sum(RX_Allow)
	, Total_Allow = sum(IP_Allow) + sum(OP_Allow) + sum(DR_Allow) + sum(ER_Allow) + sum(RX_Allow)
	
	--visit counts
	, IP_Visits		= sum(IP_Visits	)
	, IP_Days		= sum(IP_Days	)
	, OP_Visits		= sum(OP_Visits	)
	, DR_Visits		= sum(DR_Visits	)
	, ER_Visits		= sum(ER_Visits	)
	, RX_Scripts	= sum(RX_Scripts)
into #utilization
from	(
			select a.SystemID, a.YearMo, b.ClaimNumber
				--allow amounts
				, IP_Allow = sum(case when d.ServiceTypeCd = 'IP'									then b.AllwAmt	else 0	end)
				, OP_Allow = sum(case when d.ServiceTypeCd = 'OP' and b.PlaceOfService <> 23		then b.AllwAmt	else 0	end)
				, DR_Allow = sum(case when d.ServiceTypeCd = 'DR' 									then b.AllwAmt	else 0	end)
				, ER_Allow = sum(case when d.ServiceTypeCd = 'OP' and b.PlaceOfService = 23 and e.ServiceCodeLongDescription = 'Emergency Room Facility'		then b.AllwAmt	else 0	end)
				, RX_Allow = sum(case when d.ServiceTypeCd = 'RX' 									then b.AllwAmt	else 0	end)
				--, Total_Allow = sum(b.AllwAmt)	--will not be equal to adding service types (IP, OP, etc.) since there are other services offered like Dental, etc.
				
				--visit counts
				, IP_Visits	= count(distinct case when d.ServiceTypeCd = 'IP' and b.AdmitCnt = 1		then b.FromDtSysID	end)
				, IP_Days	= sum(case when d.ServiceTypeCd = 'IP' and b.AdmitCnt = 1					then b.DayCnt	else 0	end)
				, OP_Visits	= count(distinct case when d.ServiceTypeCd = 'OP' 							then b.FromDtSysID	end)
				, DR_Visits	= count(distinct case when d.ServiceTypeCd = 'DR' 							then b.FromDtSysID	end)
				, ER_Visits	= count(distinct case when e.ServiceCodeLongDescription = 'Emergency Room Facility'		then b.FromDtSysID	end)
				, RX_Scripts	= sum(case when d.ServiceTypeCd = 'RX' 						then b.ScriptCnt	else 0	end)
			from pdb_PharmaMotion..tmp_MbrMos_v2		a
			inner join AllSavers_Prod..Fact_Claims		b	on	a.SystemID = b.SystemID
			inner join AllSavers_Prod..Dim_Date			c	on	b.FromDtSysID = c.DtSysId
															and a.YearMo = c.YearMo
			inner join AllSavers_Prod..Dim_ServiceType	d	on	b.ServiceTypeSysID = d.ServiceTypeSysID
			inner join AllSavers_Prod..Dim_ServiceCode	e	on	b.ServiceCodeSysID = e.ServiceCodeSysID
			--where a.SystemID = 54000034830002801
			group by a.SystemID, a.YearMo, b.ClaimNumber
			having sum(b.AllwAmt) > 0	--filter claims with negative or zero allow amounts
	) z
group by SystemID, YearMo
--filter claims with negative or zero allow amounts
having sum(IP_Allow) > 0
	or sum(OP_Allow) > 0
	or sum(DR_Allow) > 0
	or sum(ER_Allow) > 0
	or sum(RX_Allow) > 0
--(953,231 row(s) affected); 1.27 minutes
--(927,455 row(s) affected); 2.36 minutes
create unique index uIx_MemberID_YrMo on #utilization (SystemID, YearMo);
select * from #utilization where Total_Allow < 0

--added: 6/27/2017
--handling of claim reversals & excluding negative allow amounts
update pdb_PharmaMotion..MemberSummary_v2
set Analgesic_Antihistamine_Combination		  = isnull(c.Cnt_Analgesic_Antihistamine_Combination	, 0)
	, Analgesics							  =	isnull(c.Cnt_Analgesics							, 0)
	, Anesthetics							  =	isnull(c.Cnt_Anesthetics							, 0)
	, AntiObesityDrugs						  =	isnull(c.Cnt_AntiObesityDrugs						, 0)
	, Antiarthritics						  =	isnull(c.Cnt_Antiarthritics						, 0)
	, Antiasthmatics						  =	isnull(c.Cnt_Antiasthmatics						, 0)
	, Antibiotics							  =	isnull(c.Cnt_Antibiotics							, 0)
	, Anticoagulants						  =	isnull(c.Cnt_Anticoagulants						, 0)
	, Antidotes								  =	isnull(c.Cnt_Antidotes								, 0)
	, AntiFungals							  =	isnull(c.Cnt_AntiFungals							, 0)
	, Antihistamine_Decongestant_Combination  =	isnull(c.Cnt_Antihistamine_Decongestant_Combination, 0)
	, Antihistamines						  =	isnull(c.Cnt_Antihistamines						, 0)
	, Antihyperglycemics					  =	isnull(c.Cnt_Antihyperglycemics					, 0)
	, Antiinfectives						  =	isnull(c.Cnt_Antiinfectives						, 0)
	, AntiinfectivesMiscellaneous			  =	isnull(c.Cnt_AntiinfectivesMiscellaneous			, 0)
	, Antineoplastics						  =	isnull(c.Cnt_Antineoplastics						, 0)
	, AntiparkinsonDrugs					  =	isnull(c.Cnt_AntiparkinsonDrugs					, 0)
	, AntiplateletDrugs						  =	isnull(c.Cnt_AntiplateletDrugs						, 0)
	, Antivirals							  =	isnull(c.Cnt_Antivirals							, 0)
	, AutonomicDrugs						  =	isnull(c.Cnt_AutonomicDrugs						, 0)
	, Biologicals							  =	isnull(c.Cnt_Biologicals							, 0)
	, Blood									  =	isnull(c.Cnt_Blood									, 0)
	, CardiacDrugs							  =	isnull(c.Cnt_CardiacDrugs							, 0)
	, Cardiovascular						  =	isnull(c.Cnt_Cardiovascular						, 0)
	, CNSDrugs								  =	isnull(c.Cnt_CNSDrugs								, 0)
	, ColonyStimulatingFactors				  =	isnull(c.Cnt_ColonyStimulatingFactors				, 0)
	, Contraceptives						  =	isnull(c.Cnt_Contraceptives						, 0)
	, CoughColdPreparations					  =	isnull(c.Cnt_CoughColdPreparations					, 0)
	, Diagnostic							  =	isnull(c.Cnt_Diagnostic							, 0)
	, Diuretics								  =	isnull(c.Cnt_Diuretics								, 0)
	, EENTPreps								  =	isnull(c.Cnt_EENTPreps								, 0)
	, ElectCaloricH2O						  =	isnull(c.Cnt_ElectCaloricH2O						, 0)
	, Gastrointestinal						  =	isnull(c.Cnt_Gastrointestinal						, 0)
	, Herbals								  =	isnull(c.Cnt_Herbals								, 0)
	, Hormones								  =	isnull(c.Cnt_Hormones								, 0)
	, Immunosuppresant						  =	isnull(c.Cnt_Immunosuppresant						, 0)
	, MiscMedicalSuppliesDevicesNondrug		  =	isnull(c.Cnt_MiscMedicalSuppliesDevicesNondrug		, 0)
	, MuscleRelaxants						  =	isnull(c.Cnt_MuscleRelaxants						, 0)
	, PreNatalVitamins						  =	isnull(c.Cnt_PreNatalVitamins						, 0)
	, PhyscotherapeuticDrugs				  =	isnull(c.Cnt_PhyscotherapeuticDrugs				, 0)
	, SedativeHypnotics						  =	isnull(c.Cnt_SedativeHypnotics						, 0)
	, SkinPreps								  =	isnull(c.Cnt_SkinPreps								, 0)
	, SmokingDeterrents						  =	isnull(c.Cnt_SmokingDeterrents						, 0)
	, ThyroidPreps							  =	isnull(c.Cnt_ThyroidPreps							, 0)
	, Vitamins								  =	isnull(c.Cnt_Vitamins								, 0)
    , IP_Allow								  = isnull(b.IP_Allow		, 0)
    , OP_Allow								  = isnull(b.OP_Allow		, 0)
    , DR_Allow								  = isnull(b.DR_Allow		, 0)
    , ER_Allow								  = isnull(b.ER_Allow		, 0)
    , RX_Allow								  = isnull(b.RX_Allow		, 0)
    , Total_Allow							  = isnull(b.Total_Allow, 0)
    , IP_Visits								  = isnull(b.IP_Visits		, 0)
    , IP_Days								  = isnull(b.IP_Days		, 0)
    , OP_Visits								  = isnull(b.OP_Visits		, 0)
    , DR_Visits								  = isnull(b.DR_Visits		, 0)
    , ER_Visits								  = isnull(b.ER_Visits		, 0)
    , RX_Scripts							  = isnull(b.RX_Scripts	, 0)
from pdb_PharmaMotion..MemberSummary_v2	a
left join #utilization					b	on	a.SystemID = b.SystemID
											and a.YearMo = b.YearMo
left join #NDC_Cnt						c	on	a.SystemID = c.SystemID
											and a.YearMo = c.YearMo
--(2549198 row(s) affected)

---------------------------------
--pull for the steps
---------------------------------
if object_id('tempdb..#IncentiveBasis') is not null
   drop table #IncentiveBasis;

select MemberID, Year_Mo
     , ttlIncentiveEarnedForMonth   = sum(TotalIncentiveEarned)
     , Frequency_ttlIncentiveEarned = max(case when IncentiveType = 'Frequency' then TotalIncentiveEarned else 0.00 end)
     , Frequency_ttlIncentiveSteps  = max(case when IncentiveType = 'Frequency' then TotalSteps else 0 end)
     , Frequency_ttlIncentiveBouts  = max(case when IncentiveType = 'Frequency' then TotalBouts else 0 end)
     , Intensity_ttlIncentiveEarned = max(case when IncentiveType = 'Intensity' then TotalIncentiveEarned else 0.00 end)
     , Intensity_ttlIncentiveSteps  = max(case when IncentiveType = 'Intensity' then TotalSteps else 0 end)
     , Intensity_ttlIncentiveBouts  = max(case when IncentiveType = 'Intensity' then TotalBouts else 0 end)
     , Tenacity_ttlIncentiveEarned  = max(case when IncentiveType = 'Tenacity'  then TotalIncentiveEarned else 0.00 end)
     , Tenacity_ttlIncentiveSteps   = max(case when IncentiveType = 'Tenacity'  then TotalSteps else 0 end)
     , Tenacity_ttlIncentiveBouts   = max(case when IncentiveType = 'Tenacity'  then TotalBouts else 0 end)
into #IncentiveBasis
from (select distinct a.MEMBERID, a.Year_Mo, IncentiveType = r.RuleName, IncentiveUOM = i.LabelName
      	 , TotalIncentiveEarned = a.IncentiveAmount, a.TotalSteps,a.TotalBouts
      	 , maxPossibleIncentiveForMonth = ym.DaysInMonth * r.IncentiveAmount
      	 , RequiredToEarnIncentive_Steps = r.TotalStepsMin,  RequiredToEarnIncentive_Minutes = r.TotalMinutes
      	 , RequiredToEarnIncentive_Bouts = r.TotalBouts
        FROM pdb_Allsavers_Research.ETL.AS_DERM_MemberEarnedIncentives a
        join pdb_Allsavers_Research..ASM_YearMo                        ym on a.Year_Mo            = ym.Year_Mo
        join pdb_Allsavers_Research.etl.AS_DERM_LookupRule             r on a.LOOKUPRuleID       = r.LOOKUPRuleID
																		and r.RuleName in ('Frequency','Intensity','Tenacity')
        join pdb_Allsavers_Research.ETL.AS_DERM_RuleGroups             g on r.LOOKUPRuleGroupID  = g.LOOKUPRuleGroupID
        join pdb_Allsavers_Research.ETL.AS_DERM_IncentiveLabel         i on g.LOOKUPIncentiveLabelID = i.LookupIncentiveLabelID
		--where a.MEMBERID = 27428
     ) IncentiveBasis
group by MemberID, Year_Mo
--(225604 row(s) affected)
create clustered index ucix_MemberID on #IncentiveBasis (MemberID);


If (object_id('tempdb..#fitgoalsincentives') Is Not Null)
Drop Table #fitgoalsincentives
go

select a.*
into #fitgoalsincentives
from	(--211,305
			select ax.SystemID, ma.MEMBERID, ma.Year_Mo, Step_Cnt = ma.TotalSteps, NoDays_wSteps = ma.NbrDayWalked	--use these fields instead of getting from Longitudinal_Day
				, ib.ttlIncentiveEarnedForMonth
				, ib.Frequency_ttlIncentiveEarned
				, ib.Frequency_ttlIncentiveSteps 
				, ib.Frequency_ttlIncentiveBouts 
				, ib.Intensity_ttlIncentiveEarned
				, ib.Intensity_ttlIncentiveSteps 
				, ib.Intensity_ttlIncentiveBouts
				, ib.Tenacity_ttlIncentiveEarned
				, ib.Tenacity_ttlIncentiveSteps 
				, ib.Tenacity_ttlIncentiveBouts
			from pdb_Allsavers_Research.etl.AS_DERM_MemberAction          ma
			join pdb_Allsavers_Research..ASM_YearMo                       ym on ma.Year_Mo        = ym.Year_Mo
			join pdb_Allsavers_Research.etl.AS_DERM_Members      (nolock) dm on ma.Memberid       = dm.MEMBERID   -- Memberid
			join pdb_Allsavers_Research.etl.DERM_xwalk_Member    (nolock) dx on dm.ClientMEMBERID = dx.dSystemID  -- xwalk to
			join pdb_Allsavers_Research..ASM_xwalk_Member        (nolock) ax on dx.aSystemid      = ax.SystemID   -- DIMID
			join #IncentiveBasis										  ib on ma.MEMBERID = ib.MEMBERID
																		  	 and ma.Year_mo = ib.Year_Mo
			--where ax.SystemID = 54000051550000100
			group by ax.SystemID, ma.MEMBERID, ma.Year_Mo, ma.TotalSteps, ma.NbrDayWalked
				, ib.ttlIncentiveEarnedForMonth
				, ib.Frequency_ttlIncentiveEarned
				, ib.Frequency_ttlIncentiveSteps 
				, ib.Frequency_ttlIncentiveBouts 
				, ib.Intensity_ttlIncentiveEarned
				, ib.Intensity_ttlIncentiveSteps 
				, ib.Intensity_ttlIncentiveBouts
				, ib.Tenacity_ttlIncentiveEarned
				, ib.Tenacity_ttlIncentiveSteps 
				, ib.Tenacity_ttlIncentiveBouts
		) a
--join AllSavers_Prod..Dim_Member				dmbr	on	a.SystemID = dmbr.SystemID
--join pdb_PharmaMotion..tmp_MbrMos_v2		mc		on dmbr.MemberID = mc.MemberID
--													and a.Year_Mo = mc.YearMo
join #members_motion						mc		on	a.SystemID = mc.SystemID
--where mc.MemberID = 161629
--(162,884 row(s) affected)
create unique index uIx_MemberID_YrMo on #fitgoalsincentives (SystemID, Year_Mo);

---------------------------------
--policy & product code details
---------------------------------
If (object_id('tempdb..#policy_dets') Is Not Null)
Drop Table #policy_dets
go

select a.SystemID, a.YearMo, c.PolicyID, c.ProductCode, c.ALSMarket, c.MarketSegment, c.GroupSize
into #policy_dets
from pdb_PharmaMotion..tmp_MbrMos_v2	a
inner join AllSavers_Prod..Dim_MemberDetail	b	on	a.SystemID = b.SystemID
												and a.YearMo = b.YearMo
inner join AllSavers_Prod..Dim_Policy		c	on	b.PolicyID = c.PolicyID
												and b.YearMo = c.YearMo
group by a.SystemID, a.YearMo, c.PolicyID, c.ProductCode, c.ALSMarket, c.MarketSegment, c.GroupSize
--(2,340,415 row(s) affected)
create unique index uIx_MemberID_YrMo on #policy_dets (SystemID, YearMo);

--add flags on those members whose policies belong to the 4 States ('PA', 'WI', 'DE', 'MO') that were no longer offered with Motion
If (object_id('tempdb..#questionable_policies') Is Not Null)
Drop Table #questionable_policies
go

select *
into #questionable_policies
from [pdb_Allsavers_Research].[dbo].[GroupSummary]
where GroupState in ('PA', 'WI', 'DE', 'MO')
	and EnrolledMotionYM > 0
--(50 row(s) affected)
create unique index uIx_PolicyID on #questionable_policies (PolicyID);

--pull for the members under these policies
If (object_id('tempdb..#questionablembrs') Is Not Null)
Drop Table #questionablembrs
go

select b.systemID, b.PolicyID	
into #questionablembrs
from #questionable_policies	a
inner join pdb_PharmaMotion..Member_v2	b	on	a.PolicyID = b.PolicyID
where Motion = 1
group by b.systemID, b.PolicyID
--(656 row(s) affected)
create unique index uIx_MemberID_PolicyID on #questionablembrs (systemID, PolicyID);


If (object_id('pdb_PharmaMotion..MemberSummary_v2') Is Not Null)
Drop Table pdb_PharmaMotion..MemberSummary_v2
go

select a.MemberID, a.YearMo, a.Enrl_Plan, a.Enrl_Motion, a.EnrlMotion_MonthInd, a.PlcyEnrlMotion_MonthInd
	, d.PolicyID
	, d.ProductCode
	, d.ALSMarket
	, d.MarketSegment
	, d.GroupSize
	, Analgesic_Antihistamine_Combination	  = isnull(b.Cnt_Analgesic_Antihistamine_Combination	, 0)
	, Analgesics							  =	isnull(b.Cnt_Analgesics							, 0)
	, Anesthetics							  =	isnull(b.Cnt_Anesthetics							, 0)
	, AntiObesityDrugs						  =	isnull(b.Cnt_AntiObesityDrugs						, 0)
	, Antiarthritics						  =	isnull(b.Cnt_Antiarthritics						, 0)
	, Antiasthmatics						  =	isnull(b.Cnt_Antiasthmatics						, 0)
	, Antibiotics							  =	isnull(b.Cnt_Antibiotics							, 0)
	, Anticoagulants						  =	isnull(b.Cnt_Anticoagulants						, 0)
	, Antidotes								  =	isnull(b.Cnt_Antidotes								, 0)
	, AntiFungals							  =	isnull(b.Cnt_AntiFungals							, 0)
	, Antihistamine_Decongestant_Combination  =	isnull(b.Cnt_Antihistamine_Decongestant_Combination, 0)
	, Antihistamines						  =	isnull(b.Cnt_Antihistamines						, 0)
	, Antihyperglycemics					  =	isnull(b.Cnt_Antihyperglycemics					, 0)
	, Antiinfectives						  =	isnull(b.Cnt_Antiinfectives						, 0)
	, AntiinfectivesMiscellaneous			  =	isnull(b.Cnt_AntiinfectivesMiscellaneous			, 0)
	, Antineoplastics						  =	isnull(b.Cnt_Antineoplastics						, 0)
	, AntiparkinsonDrugs					  =	isnull(b.Cnt_AntiparkinsonDrugs					, 0)
	, AntiplateletDrugs						  =	isnull(b.Cnt_AntiplateletDrugs						, 0)
	, Antivirals							  =	isnull(b.Cnt_Antivirals							, 0)
	, AutonomicDrugs						  =	isnull(b.Cnt_AutonomicDrugs						, 0)
	, Biologicals							  =	isnull(b.Cnt_Biologicals							, 0)
	, Blood									  =	isnull(b.Cnt_Blood									, 0)
	, CardiacDrugs							  =	isnull(b.Cnt_CardiacDrugs							, 0)
	, Cardiovascular						  =	isnull(b.Cnt_Cardiovascular						, 0)
	, CNSDrugs								  =	isnull(b.Cnt_CNSDrugs								, 0)
	, ColonyStimulatingFactors				  =	isnull(b.Cnt_ColonyStimulatingFactors				, 0)
	, Contraceptives						  =	isnull(b.Cnt_Contraceptives						, 0)
	, CoughColdPreparations					  =	isnull(b.Cnt_CoughColdPreparations					, 0)
	, Diagnostic							  =	isnull(b.Cnt_Diagnostic							, 0)
	, Diuretics								  =	isnull(b.Cnt_Diuretics								, 0)
	, EENTPreps								  =	isnull(b.Cnt_EENTPreps								, 0)
	, ElectCaloricH2O						  =	isnull(b.Cnt_ElectCaloricH2O						, 0)
	, Gastrointestinal						  =	isnull(b.Cnt_Gastrointestinal						, 0)
	, Herbals								  =	isnull(b.Cnt_Herbals								, 0)
	, Hormones								  =	isnull(b.Cnt_Hormones								, 0)
	, Immunosuppresant						  =	isnull(b.Cnt_Immunosuppresant						, 0)
	, MiscMedicalSuppliesDevicesNondrug		  =	isnull(b.Cnt_MiscMedicalSuppliesDevicesNondrug		, 0)
	, MuscleRelaxants						  =	isnull(b.Cnt_MuscleRelaxants						, 0)
	, PreNatalVitamins						  =	isnull(b.Cnt_PreNatalVitamins						, 0)
	, PhyscotherapeuticDrugs				  =	isnull(b.Cnt_PhyscotherapeuticDrugs				, 0)
	, SedativeHypnotics						  =	isnull(b.Cnt_SedativeHypnotics						, 0)
	, SkinPreps								  =	isnull(b.Cnt_SkinPreps								, 0)
	, SmokingDeterrents						  =	isnull(b.Cnt_SmokingDeterrents						, 0)
	, ThyroidPreps							  =	isnull(b.Cnt_ThyroidPreps							, 0)
	, Vitamins								  =	isnull(b.Cnt_Vitamins								, 0)
	--, Step_Cnt								  = isnull(c.Step_Cnt, 0)
	--, NoDays_wSteps							  = isnull(c.NoDays_wSteps, 0)
    , IP_Allow								  = isnull(e.IP_Allow		, 0)
    , OP_Allow								  = isnull(e.OP_Allow		, 0)
    , DR_Allow								  = isnull(e.DR_Allow		, 0)
    , ER_Allow								  = isnull(e.ER_Allow		, 0)
    , RX_Allow								  = isnull(e.RX_Allow		, 0)
    , Total_Allow							  = (isnull(e.IP_Allow, 0) + isnull(e.OP_Allow, 0) + isnull(e.DR_Allow, 0) + isnull(e.RX_Allow, 0) + isnull(e.ER_Allow, 0))
    , IP_Visits								  = isnull(e.IP_Visits		, 0)
    , IP_Days								  = isnull(e.IP_Days		, 0)
    , OP_Visits								  = isnull(e.OP_Visits		, 0)
    , DR_Visits								  = isnull(e.DR_Visits		, 0)
    , ER_Visits								  = isnull(e.ER_Visits		, 0)
    , RX_Scripts							  = isnull(e.RX_Scripts	, 0)
    , ttlIncentiveEarnedForMonth			  = isnull(c.ttlIncentiveEarnedForMonth, 0)
    , Frequency_ttlIncentiveSteps			  = isnull(c.Frequency_ttlIncentiveSteps, 0)
    , Frequency_ttlIncentiveBouts			  = isnull(c.Frequency_ttlIncentiveBouts, 0)
    , Frequency_ttlIncentiveEarned			  = isnull(c.Frequency_ttlIncentiveEarned, 0)
    , Intensity_ttlIncentiveSteps			  = isnull(c.Intensity_ttlIncentiveSteps, 0)
    , Intensity_ttlIncentiveBouts			  = isnull(c.Intensity_ttlIncentiveBouts, 0)
    , Intensity_ttlIncentiveEarned			  = isnull(c.Intensity_ttlIncentiveEarned, 0)
    , Tenacity_ttlIncentiveSteps			  = isnull(c.Tenacity_ttlIncentiveSteps, 0)
    , Tenacity_ttlIncentiveBouts			  = isnull(c.Tenacity_ttlIncentiveBouts, 0)
    , Tenacity_ttlIncentiveEarned			  = isnull(c.Tenacity_ttlIncentiveEarned, 0)
	, Flag_PolicyIDin4St	= case when f.SystemID is not null	then	1 else 0	end
	, a.SystemID
into pdb_PharmaMotion..MemberSummary_v2
from pdb_PharmaMotion..tmp_MbrMos_v2	a
left join #NDC_Cnt						b	on	a.SystemID = b.SystemID
											and a.YearMo = b.YearMo
left join #fitgoalsincentives			c	on	a.SystemID = c.SystemID
											and a.YearMo = c.Year_Mo
left join #policy_dets					d	on	a.SystemID = d.SystemID
											and a.YearMo = d.YearMo
left join #utilization					e	on	a.SystemID = e.SystemID
											and a.YearMo = e.YearMo
left join #questionablembrs				f	on	a.SystemID = f.SystemID
--(2,549,198 row(s) affected)
create unique clustered index ucIx_MemberID_YM on pdb_PharmaMotion..MemberSummary_v2 (SystemID, YearMo);

select *
from pdb_PharmaMotion..MemberSummary_v2
--where MemberID = 265193
where SystemID = 54000051550000100

--update Step counts & no. of days walked referencing Longitudinal table instead
update pdb_PharmaMotion..MemberSummary_v2
set Step_Cnt = isnull(b.Step_Cnt, 0)
	, NoDays_wSteps = isnull(b.NoDays_wSteps, 0)
from pdb_PharmaMotion..MemberSummary_v2	a
left join	(
				select SystemID, Year_Mo
					, Step_Cnt = sum(Steps)
					, NoDays_wSteps = count(distinct case when Steps > 0	then Full_Dt	end)
				from	(
							select *
								, Year_Mo = format(Full_Dt, 'yyyyMM')
							from pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt
						) z
				group by SystemID, Year_Mo
			) b	on	a.SystemID = b.SystemID
				and a.YearMo = b.Year_Mo
--(2,549,198 row(s) affected)

------------------------------
--add 06/16/2017
--Policy,Family Table
------------------------------
If (object_id('pdb_PharmaMotion..FamilySummary') Is Not Null)
Drop Table pdb_PharmaMotion..FamilySummary
go

select PolicyID, FamilyID, Coverage, DependentCnt
into pdb_PharmaMotion..FamilySummary
from	(
			select b.PolicyID, b.FamilyID, b.Coverage, b.DependentCnt
				, OID = row_number() over(partition by b.PolicyID, b.FamilyID order by b.EarliestEffectiveDate desc)
			from pdb_Allsavers_Research..GroupSummary	a
			inner join Allsavers_Prod..Fact_Coverage	b	on	a.PolicyID = b.PolicyID
			where EnrolledMotionYM > 0									--filter plans or groups with motion only
				and year(b.EarliestEffectiveDate) in (2014, 2015, 2016)
		) z
where OID = 1
--(153,726 row(s) affected)
create unique index uIx_PolicyFamID on pdb_PharmaMotion..FamilySummary (PolicyID, FamilyID);


If (object_id('pdb_PharmaMotion..PolicyIDSummary') Is Not Null)
Drop Table pdb_PharmaMotion..PolicyIDSummary
go

select PolicyID, YearMo, EnrolledEmployees, EligibileEmployees
into pdb_PharmaMotion..PolicyIDSummary
from	(
			select PolicyID, YearMo, EnrolledEmployees, EligibileEmployees
				, OID = row_number() over(partition by PolicyID order by YearMo desc)
			from AllSavers_Prod..Dim_Policy
			--where PolicyID = 5400000355
			where left(YearMo, 4) in (2014, 2015, 2016)
				and (EnrolledEmployees is not null
				or EligibileEmployees is not null)
		) z
where OID = 1
--where PolicyID = 5400000355
--(7687 row(s) affected)
create unique index uIx_PolicyID on pdb_PharmaMotion..PolicyIDSummary (PolicyID);
