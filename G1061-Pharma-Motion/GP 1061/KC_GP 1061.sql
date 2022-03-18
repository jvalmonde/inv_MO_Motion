/*** 
GP 1061 Pharmacy & Motion
Input databases:	AllSavers_Prod, pdb_AllSavers_Research
Date Created: 17 April 2017
***/

--pull for all members enrolled in motion
If (object_id('tempdb..#members_motion') Is Not Null)
Drop Table #members_motion
go

select d.MemberID, EnrolledMotion_YrMo = b.Year_Mo, DisenrolledMotion = b.LastEnrolled, d.Age, d.Gender, d.MM_2014, d.MM_2015, d.MM_2016
into #members_motion
from pdb_Allsavers_Research..MemberSummary				a
inner join pdb_Allsavers_Research..DERMEnrollmentBasis	b	on	a.Member_DIMID = b.Member_DIMID
inner join pdb_Allsavers_Research..ASM_xwalk_Member		c	on	a.Member_DIMID = c.Member_DIMID
inner join Allsavers_Prod..Dim_Member					d	on	c.SystemID = d.SystemID
where a.EnrolledMotion = 1
--(52396 row(s) affected)
--45622
create unique index uIx_MemberID on #members_motion (MemberID);

/*
select *
from pdb_Allsavers_Research..DERMEnrollmentBasis
select *
from #members_motion
--where MemberID in (268033, 401916, 66455)
where MemberID = 388402
*/

--pull for the 20% sample of members not enrolled in motion
If (object_id('tempdb..#members_nonmotion') Is Not Null)
Drop Table #members_nonmotion
go

select /*top 20 percent*/ a.MemberID, a.Age, a.Gender, a.MM_2014, a.MM_2015, a.MM_2016
--into #members_nonmotion
from	(--133,674
			select a.MemberID, a.Age, a.Gender, a.MM_2014, a.MM_2015, a.MM_2016
			from Allsavers_Prod..Dim_Member	a
			inner join AllSavers_Prod..Dim_Policy	c	on	a.PolicyID = c.PolicyID
			where (a.MM_2014 = 12
				or a.MM_2015 = 12
				or a.MM_2016 = 12)
				and c.ProductCode = 'SI'
				and left(c.YearMo, 4) in ('2014', '2015', '2016')
			group by a.MemberID, a.Age, a.Gender, a.MM_2014, a.MM_2015, a.MM_2016
		)			a
left join #members_motion				b	on	a.MemberID = b.MemberID
where b.MemberID is null
order by newid()
--(20753 row(s) affected)

--select * from #members_nonmotion where MemberID = 93420

--final member table
If (object_id('pdb_PharmaMotion..GP1061_Member') Is Not Null)
Drop Table pdb_PharmaMotion..GP1061_Member
go

select MemberID, EnrolledMotion_YrMo, DisenrolledMotion, Age = Age - 1, Gender, MM_2014, MM_2015, MM_2016
into pdb_PharmaMotion..GP1061_Member
from #members_motion
union
select MemberID, EnrolledMotion_YrMo = '', DisenrolledMotion = '', Age = Age - 1, Gender, MM_2014, MM_2015, MM_2016
from #members_nonmotion
--(73,149 row(s) affected)
create unique index uIx_MemberID on pdb_PharmaMotion..GP1061_Member (MemberID);

/*
select count(*), count(distinct MemberID)
from pdb_PharmaMotion..GP1061_Member
where MemberID = 93436	--201512	2016-12-12
*/

-----------------------------------
--add Member's address data
--Date Created: 27 April  2017
-----------------------------------
--total members: 73,148
If (object_id('tempdb..#mbr_location') Is Not Null)
Drop Table #mbr_location
go

select a.MemberID, b.Zip, c.St_Cd, c.MSA, c.County, d.CTY_NM
into #mbr_location
from pdb_PharmaMotion..Member	a
inner join AllSavers_Prod..Dim_Member	b	on	a.MemberID = b.MemberID
inner join pdb_Rally..Zip_Census		c	on	b.Zip = c.Zip
inner join MiniHPDM..Dim_Zip			d	on	b.Zip = d.ZIP_CD
--(73064 row(s) affected)
create unique index uIx_MemberID on #mbr_location (MemberID);

alter table pdb_PharmaMotion..Member
	add Zip			varchar(5)
		, Cty_Nm	varchar(28)
		, County	varchar(25)
		, MSA		varchar(60)
		, St_Cd		varchar(2)
go

update pdb_PharmaMotion..Member
set Zip			= b.Zip	
	, Cty_Nm	= b.Cty_Nm
	, County	= b.County
	, MSA		= b.MSA	
	, St_Cd		= b.St_Cd	
from pdb_PharmaMotion..Member	a
left join #mbr_location			b	on	a.MemberID = b.MemberID

-----------------------------------
--add Member's subscriber indicator
--Date Created: 03 May  2017
-----------------------------------
If (object_id('tempdb..#mbr_sbscrind') Is Not Null)
Drop Table #mbr_sbscrind
go

select a.MemberID, b.Sbscr_Ind
into #mbr_sbscrind
from pdb_PharmaMotion..Member	a
inner join AllSavers_Prod..Dim_Member	b	on	a.MemberID = b.MemberID
--(73148 row(s) affected)
create unique index uIx_MemberID on #mbr_sbscrind (MemberID);

alter table pdb_PharmaMotion..Member
	add Sbscr_Ind smallint
go

update pdb_PharmaMotion..Member
set Sbscr_Ind = b.Sbscr_Ind
from pdb_PharmaMotion..Member	a
inner join #mbr_sbscrind		b	on	a.MemberID = b.MemberID

select sum(Sbscr_Ind) from pdb_PharmaMotion..Member	--54,485


If (object_id('pdb_PharmaMotion..tmp_MbrMos') Is Not Null)
Drop Table pdb_PharmaMotion..tmp_MbrMos
go

select a.MemberID, b.YearMo, Month_Ind = case when EnrolledMotion_YrMo <> '' and EnrolledMotion_YrMo <= b.YearMo and year(a.DisenrolledMotion) = 2999	then 1
												when EnrolledMotion_YrMo <> '' and EnrolledMotion_YrMo <= b.YearMo and format(a.DisenrolledMotion, 'yyyyMM') >= b.YearMo	then 1	else 0	end
into pdb_PharmaMotion..tmp_MbrMos
from pdb_PharmaMotion..GP1061_Member	a
inner join AllSavers_Prod..Dim_Date		b	on	b.YearNbr in (2014, 2015, 2016)
--where a.MemberID = 93451	--149411, 268033
group by a.MemberID, b.YearMo, a.EnrolledMotion_YrMo, a.DisenrolledMotion
--(2,633,364 row(s) affected); 2.40 minutes
create unique clustered index ucIx_MemberID_YrMo on pdb_PharmaMotion..tmp_MbrMos (MemberID, YearMo);

--count of distinct NDCs per drug class
If (object_id('tempdb..#NDC_Cnt') Is Not Null)
Drop Table #NDC_Cnt
go

select a.MemberID, c.YearMo
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
	--, Cnt_NoGenericTherapeuticClassCode			= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'NO GENERIC THERAPEUTIC CLASS CODE'			then d.NDC	end)
	, Cnt_PreNatalVitamins						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'PRE-NATAL VITAMINS'							then d.NDC	end)
	, Cnt_PhyscotherapeuticDrugs				= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'PSYCHOTHERAPEUTIC DRUGS'						then d.NDC	end)
	, Cnt_SedativeHypnotics						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SEDATIVE/HYPNOTICS'							then d.NDC	end)
	, Cnt_SkinPreps								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SKIN PREPS'									then d.NDC	end)
	, Cnt_SmokingDeterrents						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SMOKING DETERRENTS'							then d.NDC	end)
	, Cnt_ThyroidPreps							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'THYROID PREPS'								then d.NDC	end)
	--, Cnt_UnclassifiedDrugProducts				= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'UNCLASSIFIED DRUG PRODUCTS'					then d.NDC	end)
	, Cnt_Vitamins								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'VITAMINS'									then d.NDC	end)
into #NDC_Cnt
from pdb_PharmaMotion..GP1061_Member	a
inner join AllSavers_Prod..Fact_Claims	b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date		c	on	b.FromDtSysID = c.DtSysId
inner join AllSavers_Prod..Dim_NDCDrug	d	on	b.NDCDrugSysID = d.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class		e	on	d.NDC = e.NDC
where c.YearNbr in (2014, 2015, 2016)
	and e.Gnrc_Therapeutic_Clss_Desc is not null
	and e.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
group by a.MemberID, c.YearMo
--(380,301 row(s) affected); 3.36 minutes
create unique index uIx_MemberID_YrMo on #NDC_Cnt (MemberID, YearMo);

--select * from #NDC_Cnt

---------------------------------
--pull for the steps
---------------------------------
/*
select count(distinct Member_DIMID)	--45,968
from pdb_Allsavers_Research..Longitudinal_Day_Pivoted
select count(distinct a.Member_DIMID)	--45,750
from pdb_Allsavers_Research..MemberSummary	a
inner join pdb_Allsavers_Research..Longitudinal_Day_Pivoted	b	on	a.Member_DIMID = b.Member_DIMID
where a.EnrolledMotion = 1
NOTES:
1) There are some members in MemberSummary who are flagged as enrolled in motion, that are not in the Longitudinal tables
2) There are some members who are in Longitudinal_Day but not in Longitudinal_Month
*/

--build the step table per day, YearMo
If (object_id('tempdb..#steps_data') Is Not Null)
Drop Table #steps_data
go

select c.MemberID, Year_Mo
	, Step_Cnt		= sum(Steps)
	, NoDays_wSteps	= count(distinct Full_Dt)
into #steps_data
from	(--5,268,806 rows; use Day_Adjusted instead of Day
			select a.Member_DIMID, b.BegDate, b.Day, b.Day_Adjusted, Full_Dt = dateadd(dd, b.Day_Adjusted-1, b.BegDate), Year_Mo = cast(format(dateadd(dd, b.Day_Adjusted-1, b.BegDate), 'yyyyMM') as int)
				, b.Steps
			from pdb_Allsavers_Research..MemberSummary	a
			inner join pdb_Allsavers_Research..Longitudinal_Day_Pivoted	b	on	a.Member_DIMID = b.Member_DIMID
			where a.EnrolledMotion = 1
				--and a.Member_DIMID = '000247D1B044D300F515245A8F9D4164'	--'0000946611278A15E77F2A3B350CD8CA' '000247D1B044D300F515245A8F9D4164'
				and b.Steps >= 300	--member is considered active in motion
		) a
inner join pdb_Allsavers_Research..ASM_xwalk_Member	b	on	a.Member_DIMID = b.Member_DIMID
inner join Allsavers_Prod..Dim_Member				c	on	b.SystemID = c.SystemID
group by c.MemberID, Year_Mo
--(113,567 row(s) affected)
--(255069 row(s) affected)
create unique index uIx_MemberID on #steps_data (MemberID, Year_Mo);

/*
select *, count(*)
from (
select a.Member_DIMID, b.BegDate
from pdb_Allsavers_Research..MemberSummary	a
inner join pdb_Allsavers_Research..Longitudinal_Day_Pivoted	b	on	a.Member_DIMID = b.Member_DIMID
where a.EnrolledMotion = 1
group by a.Member_DIMID, b.BegDate
	) x
group by Member_DIMID, BegDate
having count(*) > 1
*/


---------------------------------
--policy & product code details
---------------------------------
If (object_id('tempdb..#policy_dets') Is Not Null)
Drop Table #policy_dets
go

select a.MemberID, a.YearMo, c.ProductCode, c.ALSMarket, c.MarketSegment, c.GroupSize
into #policy_dets
from pdb_PharmaMotion..tmp_MbrMos	a
inner join AllSavers_Prod..Dim_MemberDetail	b	on	a.MemberID = b.MemberID
												and a.YearMo = b.YearMo
inner join AllSavers_Prod..Dim_Policy		c	on	b.PolicyID = c.PolicyID
												and b.YearMo = c.YearMo
--where b.PolicyID is null
group by a.MemberID, a.YearMo, c.ProductCode, c.ALSMarket, c.MarketSegment, c.GroupSize
--(1091945 row(s) affected)
create unique index uIx_MemberID_YrMo on #policy_dets (MemberID, YearMo);

/* NOTES
1) MemberID = 174106, had 2 rows per YearMo due to different Ages, all the rest the same
select MemberID, YearMo, count(*)
from #policy_dets
group by MemberID, YearMo
having count(*) > 1
select count(distinct MemberID)	--73148
from #policy_dets
where MemberID = 174106
select distinct a.MemberID	--388402
from pdb_PharmaMotion..tmp_MbrMos	a
left join #policy_dets				b	on	a.MemberID = b.MemberID
where b.MemberID is null
--1 row
2) MemberID = 388402, was enrolled in motion in 201612 but the AllSavers enrollment started 201701; remove from population
delete from pdb_PharmaMotion..tmp_MbrMos
where MemberID = 388402
--(36 row(s) affected)
delete from pdb_PharmaMotion..GP1061_Member
where MemberID = 388402
--(1 row(s) affected)
*/


---------------------------------
--build the final table
---------------------------------
If (object_id('pdb_PharmaMotion..GP1061_MemberSummary') Is Not Null)
Drop Table pdb_PharmaMotion..GP1061_MemberSummary
go

select a.MemberID, a.YearMo, a.Month_Ind
	, d.ProductCode
	, d.ALSMarket
	, d.MarketSegment
	, d.GroupSize
	, Cnt_Analgesic_Antihistamine_Combination	  = isnull(b.Cnt_Analgesic_Antihistamine_Combination	, 0)
	, Cnt_Analgesics							  =	isnull(b.Cnt_Analgesics							, 0)
	, Cnt_Anesthetics							  =	isnull(b.Cnt_Anesthetics							, 0)
	, Cnt_AntiObesityDrugs						  =	isnull(b.Cnt_AntiObesityDrugs						, 0)
	, Cnt_Antiarthritics						  =	isnull(b.Cnt_Antiarthritics						, 0)
	, Cnt_Antiasthmatics						  =	isnull(b.Cnt_Antiasthmatics						, 0)
	, Cnt_Antibiotics							  =	isnull(b.Cnt_Antibiotics							, 0)
	, Cnt_Anticoagulants						  =	isnull(b.Cnt_Anticoagulants						, 0)
	, Cnt_Antidotes								  =	isnull(b.Cnt_Antidotes								, 0)
	, Cnt_AntiFungals							  =	isnull(b.Cnt_AntiFungals							, 0)
	, Cnt_Antihistamine_Decongestant_Combination  =	isnull(b.Cnt_Antihistamine_Decongestant_Combination, 0)
	, Cnt_Antihistamines						  =	isnull(b.Cnt_Antihistamines						, 0)
	, Cnt_Antihyperglycemics					  =	isnull(b.Cnt_Antihyperglycemics					, 0)
	, Cnt_Antiinfectives						  =	isnull(b.Cnt_Antiinfectives						, 0)
	, Cnt_AntiinfectivesMiscellaneous			  =	isnull(b.Cnt_AntiinfectivesMiscellaneous			, 0)
	, Cnt_Antineoplastics						  =	isnull(b.Cnt_Antineoplastics						, 0)
	, Cnt_AntiparkinsonDrugs					  =	isnull(b.Cnt_AntiparkinsonDrugs					, 0)
	, Cnt_AntiplateletDrugs						  =	isnull(b.Cnt_AntiplateletDrugs						, 0)
	, Cnt_Antivirals							  =	isnull(b.Cnt_Antivirals							, 0)
	, Cnt_AutonomicDrugs						  =	isnull(b.Cnt_AutonomicDrugs						, 0)
	, Cnt_Biologicals							  =	isnull(b.Cnt_Biologicals							, 0)
	, Cnt_Blood									  =	isnull(b.Cnt_Blood									, 0)
	, Cnt_CardiacDrugs							  =	isnull(b.Cnt_CardiacDrugs							, 0)
	, Cnt_Cardiovascular						  =	isnull(b.Cnt_Cardiovascular						, 0)
	, Cnt_CNSDrugs								  =	isnull(b.Cnt_CNSDrugs								, 0)
	, Cnt_ColonyStimulatingFactors				  =	isnull(b.Cnt_ColonyStimulatingFactors				, 0)
	, Cnt_Contraceptives						  =	isnull(b.Cnt_Contraceptives						, 0)
	, Cnt_CoughColdPreparations					  =	isnull(b.Cnt_CoughColdPreparations					, 0)
	, Cnt_Diagnostic							  =	isnull(b.Cnt_Diagnostic							, 0)
	, Cnt_Diuretics								  =	isnull(b.Cnt_Diuretics								, 0)
	, Cnt_EENTPreps								  =	isnull(b.Cnt_EENTPreps								, 0)
	, Cnt_ElectCaloricH2O						  =	isnull(b.Cnt_ElectCaloricH2O						, 0)
	, Cnt_Gastrointestinal						  =	isnull(b.Cnt_Gastrointestinal						, 0)
	, Cnt_Herbals								  =	isnull(b.Cnt_Herbals								, 0)
	, Cnt_Hormones								  =	isnull(b.Cnt_Hormones								, 0)
	, Cnt_Immunosuppresant						  =	isnull(b.Cnt_Immunosuppresant						, 0)
	, Cnt_MiscMedicalSuppliesDevicesNondrug		  =	isnull(b.Cnt_MiscMedicalSuppliesDevicesNondrug		, 0)
	, Cnt_MuscleRelaxants						  =	isnull(b.Cnt_MuscleRelaxants						, 0)
	, Cnt_PreNatalVitamins						  =	isnull(b.Cnt_PreNatalVitamins						, 0)
	, Cnt_PhyscotherapeuticDrugs				  =	isnull(b.Cnt_PhyscotherapeuticDrugs				, 0)
	, Cnt_SedativeHypnotics						  =	isnull(b.Cnt_SedativeHypnotics						, 0)
	, Cnt_SkinPreps								  =	isnull(b.Cnt_SkinPreps								, 0)
	, Cnt_SmokingDeterrents						  =	isnull(b.Cnt_SmokingDeterrents						, 0)
	, Cnt_ThyroidPreps							  =	isnull(b.Cnt_ThyroidPreps							, 0)
	, Cnt_Vitamins								  =	isnull(b.Cnt_Vitamins								, 0)
	, Step_Cnt									  = isnull(c.Step_Cnt, 0)
	, NoDays_wSteps								  = isnull(c.NoDays_wSteps, 0)
into pdb_PharmaMotion..GP1061_MemberSummary
from pdb_PharmaMotion..tmp_MbrMos	a
left join #NDC_Cnt					b	on	a.MemberID = b.MemberID
										and a.YearMo = b.YearMo
left join #steps_data				c	on	a.MemberID = c.MemberID
										and a.YearMo = c.Year_Mo
left join #policy_dets				d	on	a.MemberID = d.MemberID
										and a.YearMo = d.YearMo
--(2,633,328 row(s) affected)

--update step data
--Date: 04/24/2017
update pdb_PharmaMotion..MemberSummary
set Step_Cnt			= isnull(b.Step_Cnt, 0)
	, NoDays_wSteps		= isnull(b.NoDays_wSteps, 0)
from pdb_PharmaMotion..MemberSummary	a
left join #steps_data					b	on	a.MemberID = b.MemberID
											and a.YearMo = b.Year_Mo

select *
from pdb_PharmaMotion..MemberSummary