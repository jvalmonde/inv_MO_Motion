/*** 
GP 1061 Pharmacy & Motion -- Member Summary
Input databases:	AllSavers_Prod, pdb_AllSavers_Research
Date Created: 17 April 2017
***/

--create member months
If (object_id('pdb_PharmaMotion..tmp_MbrMos') Is Not Null)
Drop Table pdb_PharmaMotion..tmp_MbrMos
go

select a.MemberID, b.YearMo, Month_Ind = case when EnrolledMotion_YrMo <> '' and EnrolledMotion_YrMo <= b.YearMo and year(a.DisenrolledMotion) = 2999	then 1
												when EnrolledMotion_YrMo <> '' and EnrolledMotion_YrMo <= b.YearMo and format(a.DisenrolledMotion, 'yyyyMM') >= b.YearMo	then 1	else 0	end
into pdb_PharmaMotion..tmp_MbrMos
from pdb_PharmaMotion..Member	a
inner join AllSavers_Prod..Dim_Date		b	on	b.YearNbr in (2014, 2015, 2016)
where 1=1
--filter only those members with motion enrollment with at least 1 year All Savers'plan enrollment for the period
	and (a.MM_2014 = 12
	or a.MM_2015 = 12
	or a.MM_2016 = 12)
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
	, Cnt_PreNatalVitamins						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'PRE-NATAL VITAMINS'							then d.NDC	end)
	, Cnt_PhyscotherapeuticDrugs				= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'PSYCHOTHERAPEUTIC DRUGS'						then d.NDC	end)
	, Cnt_SedativeHypnotics						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SEDATIVE/HYPNOTICS'							then d.NDC	end)
	, Cnt_SkinPreps								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SKIN PREPS'									then d.NDC	end)
	, Cnt_SmokingDeterrents						= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'SMOKING DETERRENTS'							then d.NDC	end)
	, Cnt_ThyroidPreps							= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'THYROID PREPS'								then d.NDC	end)
	, Cnt_Vitamins								= count(distinct case when e.Gnrc_Therapeutic_Clss_Desc = 'VITAMINS'									then d.NDC	end)
into #NDC_Cnt
from pdb_PharmaMotion..Member	a
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

---------------------------------
--Utilization
---------------------------------
If (object_id('tempdb..#utilization') Is Not Null)
Drop Table #utilization
go

select a.MemberID, c.YearMo
	--allow amounts
	, IP_Allow = sum(case when d.ServiceTypeCd = 'IP'									then b.AllwAmt	else 0	end)
	, OP_Allow = sum(case when d.ServiceTypeCd = 'OP' and b.PlaceOfService <> 23		then b.AllwAmt	else 0	end)
	, DR_Allow = sum(case when d.ServiceTypeCd = 'DR' 									then b.AllwAmt	else 0	end)
	, ER_Allow = sum(case when d.ServiceTypeCd = 'OP' and b.PlaceOfService = 23 and e.ServiceCodeLongDescription = 'Emergency Room Facility'		then b.AllwAmt	else 0	end)
	, RX_Allow = sum(case when d.ServiceTypeCd = 'RX' 									then b.AllwAmt	else 0	end)
	--, Total_Allow = sum(b.AllwAmt)
	
	--visit counts
	, IP_Visits	= count(distinct case when d.ServiceTypeCd = 'IP' and b.AdmitCnt = 1		then b.FromDtSysID	end)
	, IP_Days	= sum(case when d.ServiceTypeCd = 'IP' and b.AdmitCnt = 1					then b.DayCnt	else 0	end)
	, OP_Visits	= count(distinct case when d.ServiceTypeCd = 'OP' 							then b.FromDtSysID	end)
	, DR_Visits	= count(distinct case when d.ServiceTypeCd = 'DR' 							then b.FromDtSysID	end)
	, ER_Visits	= count(distinct case when e.ServiceCodeLongDescription = 'Emergency Room Facility'		then b.FromDtSysID	end)
	, RX_Scripts	= sum(case when d.ServiceTypeCd = 'RX' 						then b.ScriptCnt	else 0	end)
into #utilization
from pdb_PharmaMotion..Member		a
inner join AllSavers_Prod..Fact_Claims		b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date			c	on	b.FromDtSysID = c.DtSysId
inner join AllSavers_Prod..Dim_ServiceType	d	on	b.ServiceTypeSysID = d.ServiceTypeSysID
inner join AllSavers_Prod..Dim_ServiceCode	e	on	b.ServiceCodeSysID = e.ServiceCodeSysID
where c.YearNbr in  (2014, 2015, 2016)
--where a.MemberID = 126430
--	and c.YearMo = 201608
group by a.MemberID, c.YearMo
--(488534 row(s) affected); 1.19 minutes
create unique index uIx_MemberID_YrMo on #utilization (MemberID, YearMo);

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
     ) IncentiveBasis
group by MemberID, Year_Mo
--(225604 row(s) affected)
create clustered index ucix_MemberID on #IncentiveBasis (MemberID);


If (object_id('tempdb..#fitgoalsincentives') Is Not Null)
Drop Table #fitgoalsincentives
go

select mc.MemberID, a.*
into #fitgoalsincentives
from	(--211,305
			select ax.SystemID, ma.Year_Mo, Step_Cnt = ma.TotalSteps, NoDays_wSteps = ma.NbrDayWalked	--use these fields instead of getting from Longitudinal_Day
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
			group by ax.SystemID, ma.Year_Mo, ma.TotalSteps, ma.NbrDayWalked
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
join AllSavers_Prod..Dim_Member		dmbr	on	a.SystemID = dmbr.SystemID
join pdb_PharmaMotion..Member		mc		on dmbr.MemberID = mc.MemberID
--(210779 row(s) affected)
create unique index uIx_MemberID_YrMo on #fitgoalsincentives (MemberID, Year_Mo);

---------------------------------
--policy & product code details
---------------------------------
If (object_id('tempdb..#policy_dets') Is Not Null)
Drop Table #policy_dets
go

select a.MemberID, a.YearMo, c.ProductCode, c.ALSMarket, c.MarketSegment, c.GroupSize, Enrl_Plan = 1
into #policy_dets
from pdb_PharmaMotion..tmp_MbrMos	a
inner join AllSavers_Prod..Dim_MemberDetail	b	on	a.MemberID = b.MemberID
												and a.YearMo = b.YearMo
inner join AllSavers_Prod..Dim_Policy		c	on	b.PolicyID = c.PolicyID
												and b.YearMo = c.YearMo
group by a.MemberID, a.YearMo, c.ProductCode, c.ALSMarket, c.MarketSegment, c.GroupSize
--(1091945 row(s) affected)
create unique index uIx_MemberID_YrMo on #policy_dets (MemberID, YearMo);

--motion month indicator
If (object_id('tempdb..#motion_monthind') Is Not Null)
Drop Table #motion_monthind
go

select b.MemberID, b.YearMo
	, EnrlMotion_MonthInd = case when a.Motion = 1	then datediff(mm, cast(a.EnrolledMotion_YrMo + '01' as date), cast(b.YearMo + '01' as date))	else 0	end
into #motion_monthind
from pdb_PharmaMotion..Member	a
inner join pdb_PharmaMotion..tmp_MbrMos	b	on	a.MemberID = b.MemberID
--(1823832 row(s) affected)
create unique index uIx_MemberID_YrMo on #motion_monthind (MemberID, YearMo);

--------------------------------
--build the member summary table
---------------------------------
If (object_id('pdb_PharmaMotion..MemberSummary') Is Not Null)
Drop Table pdb_PharmaMotion..MemberSummary
go

select a.MemberID, a.YearMo, Enrl_Motion = a.Month_Ind
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
	, Step_Cnt								  = isnull(c.Step_Cnt, 0)
	, NoDays_wSteps							  = isnull(c.NoDays_wSteps, 0)
	, d.Enrl_Plan
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
    , ttlIncentiveEarnedForMonth
    , Frequency_ttlIncentiveSteps
    , Frequency_ttlIncentiveBouts
    , Frequency_ttlIncentiveEarned
    , Intensity_ttlIncentiveSteps
    , Intensity_ttlIncentiveBouts
    , Intensity_ttlIncentiveEarned
    , Tenacity_ttlIncentiveSteps
    , Tenacity_ttlIncentiveBouts
    , Tenacity_ttlIncentiveEarned
    , f.EnrlMotion_MonthInd
into pdb_PharmaMotion..MemberSummary
from pdb_PharmaMotion..tmp_MbrMos	a
left join #NDC_Cnt					b	on	a.MemberID = b.MemberID
										and a.YearMo = b.YearMo
left join #fitgoalsincentives		c	on	a.MemberID = c.MemberID
										and a.YearMo = c.Year_Mo
left join #policy_dets				d	on	a.MemberID = d.MemberID
										and a.YearMo = d.YearMo
left join #utilization				e	on	a.MemberID = e.MemberID
										and a.YearMo = e.YearMo
inner join #motion_monthind			f	on	a.MemberID = f.MemberID
										and a.YearMo = f.YearMo
--(1823832 row(s) affected)

--add flags on those members whose policies belong to the 4 States ('PA', 'WI', 'DE', 'MO')
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

select c.MemberID, b.PolicyID	
into #questionablembrs
from #questionable_policies	a
inner join AllSavers_Prod..Dim_Member	b	on	a.PolicyID = b.PolicyID
inner join pdb_PharmaMotion..MemberSummary_cont	c	on	b.MemberID = c.MemberID
where Enrl_Motion = 1
	and Step_Cnt > 0
	and ttlIncentiveEarnedForMonth > 0
group by c.MemberID, b.PolicyID
--(461 row(s) affected)
create unique index uIx_MemberID_PolicyID on #questionablembrs (MemberID, PolicyID);

alter table pdb_PharmaMotion..Member
	add Flag_PolicyIDin4St smallint
go

update pdb_PharmaMotion..Member
set Flag_PolicyIDin4St = case when b.MemberID is not null	then	1 else 0	end
from pdb_PharmaMotion..Member	a
left join #questionablembrs		b	on	a.MemberID = b.MemberID


alter table pdb_PharmaMotion..MemberSummary
	add Flag_PolicyIDin4St smallint
go

update pdb_PharmaMotion..MemberSummary
set Flag_PolicyIDin4St = case when b.MemberID is not null	then	1 else 0	end
from pdb_PharmaMotion..MemberSummary	a
left join #questionablembrs				b	on	a.MemberID = b.MemberID