/*** 
GP 1061 Pharmacy & Motion -- RX breakdown per drug class
Input databases:	AllSavers_Prod, pdb_AllSavers_Research, pdb_PharmaMotion
Date Created: 04 May 2017
***/

If (object_id('pdb_PharmaMotion..MemberSummaryDrugClassAllw') Is Not Null)
Drop Table pdb_PharmaMotion..MemberSummaryDrugClassAllw
go

select a.MemberID, a.YearMo, a.Enrl_Motion, a.Step_Cnt, a.NoDays_wSteps
	, Analgesic_Antihistamine_Combination_Allow	= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANALGESIC AND ANTIHISTAMINE COMBINATION'    then b.AllwAmt	else 0	end)
	, Analgesics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANALGESICS'									then b.AllwAmt	else 0	end)
	, Anesthetics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANESTHETICS'								then b.AllwAmt	else 0	end)
	, AntiObesityDrugs_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTI-OBESITY DRUGS'							then b.AllwAmt	else 0	end)
	, Antiarthritics_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIARTHRITICS'								then b.AllwAmt	else 0	end)
	, Antiasthmatics_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIASTHMATICS'								then b.AllwAmt	else 0	end)
	, Antibiotics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIBIOTICS'								then b.AllwAmt	else 0	end)
	, Anticoagulants_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTICOAGULANTS'								then b.AllwAmt	else 0	end)
	, Antidotes_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIDOTES'									then b.AllwAmt	else 0	end)
	, AntiFungals_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIFUNGALS'								then b.AllwAmt	else 0	end)
	, Antihistamine_Decongestant_Combination_Allow	= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINE AND DECONGESTANT COMBINATION'	then b.AllwAmt	else 0	end)
	, Antihistamines_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINES'								then b.AllwAmt	else 0	end)
	, Antihyperglycemics_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHYPERGLYCEMICS'							then b.AllwAmt	else 0	end)
	, Antiinfectives_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES'								then b.AllwAmt	else 0	end)
	, AntiinfectivesMiscellaneous_Allow			= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES/MISCELLANEOUS'				then b.AllwAmt	else 0	end)
	, Antineoplastics_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTINEOPLASTICS'							then b.AllwAmt	else 0	end)
	, AntiparkinsonDrugs_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIPARKINSON DRUGS'						then b.AllwAmt	else 0	end)
	, AntiplateletDrugs_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIPLATELET DRUGS'							then b.AllwAmt	else 0	end)
	, Antivirals_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIVIRALS'									then b.AllwAmt	else 0	end)
	, AutonomicDrugs_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'AUTONOMIC DRUGS'							then b.AllwAmt	else 0	end)
	, Biologicals_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'BIOLOGICALS'								then b.AllwAmt	else 0	end)
	, Blood_Allow								= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'BLOOD'										then b.AllwAmt	else 0	end)
	, CardiacDrugs_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CARDIAC DRUGS'								then b.AllwAmt	else 0	end)
	, Cardiovascular_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CARDIOVASCULAR'								then b.AllwAmt	else 0	end)
	, CNSDrugs_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CNS DRUGS'									then b.AllwAmt	else 0	end)
	, ColonyStimulatingFactors_Allow			= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'COLONY STIMULATING FACTORS'					then b.AllwAmt	else 0	end)
	, Contraceptives_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CONTRACEPTIVES'								then b.AllwAmt	else 0	end)
	, CoughColdPreparations_Allow				= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'COUGH/COLD PREPARATIONS'					then b.AllwAmt	else 0	end)
	, Diagnostic_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'DIAGNOSTIC'									then b.AllwAmt	else 0	end)
	, Diuretics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'DIURETICS'									then b.AllwAmt	else 0	end)
	, EENTPreps_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'EENT PREPS'									then b.AllwAmt	else 0	end)
	, ElectCaloricH2O_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ELECT/CALORIC/H2O'							then b.AllwAmt	else 0	end)
	, Gastrointestinal_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'GASTROINTESTINAL'							then b.AllwAmt	else 0	end)
	, Herbals_Allow								= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'HERBALS'									then b.AllwAmt	else 0	end)
	, Hormones_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'HORMONES'									then b.AllwAmt	else 0	end)
	, Immunosuppresant_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'IMMUNOSUPPRESANT'							then b.AllwAmt	else 0	end)
	, MiscMedicalSuppliesDevicesNondrug_Allow	= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'MISC MEDICAL SUPPLIES, DEVICES, NON-DRUG'	then b.AllwAmt	else 0	end)
	, MuscleRelaxants_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'MUSCLE RELAXANTS'							then b.AllwAmt	else 0	end)
	, PreNatalVitamins_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'PRE-NATAL VITAMINS'							then b.AllwAmt	else 0	end)
	, PhyscotherapeuticDrugs_Allow				= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'PSYCHOTHERAPEUTIC DRUGS'					then b.AllwAmt	else 0	end)
	, SedativeHypnotics_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'SEDATIVE/HYPNOTICS'							then b.AllwAmt	else 0	end)
	, SkinPreps_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'SKIN PREPS'									then b.AllwAmt	else 0	end)
	, SmokingDeterrents_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'SMOKING DETERRENTS'							then b.AllwAmt	else 0	end)
	, ThyroidPreps_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'THYROID PREPS'								then b.AllwAmt	else 0	end)
	, Vitamins_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'VITAMINS'									then b.AllwAmt	else 0	end)
into pdb_PharmaMotion..MemberSummaryDrugClassAllw
from pdb_PharmaMotion..MemberSummary_cont	a
inner join AllSavers_Prod..Fact_Claims		b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date			c	on	b.FromDtSysID = c.DtSysId
												and a.YearMo = c.YearMo
inner join AllSavers_Prod..Dim_NDCDrug		d	on	b.NDCDrugSysID = d.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class			e	on	d.NDC = e.NDC
where e.Gnrc_Therapeutic_Clss_Desc is not null
	and e.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
group by a.MemberID, a.YearMo, a.Enrl_Motion, a.Step_Cnt, a.NoDays_wSteps
--(326298 row(s) affected)
create unique index uIx_MemberID_YrMo on pdb_PharmaMotion..MemberSummaryDrugClassAllw (MemberID, YearMo); 

select *
from pdb_PharmaMotion..MemberSummaryDrugClassAllw

--new data set, allowed amount per drug class
--Date: 24 May 2017
If (object_id('pdb_PharmaMotion..MemberSummaryDrugClassAllw_v2') Is Not Null)
Drop Table pdb_PharmaMotion..MemberSummaryDrugClassAllw_v2
go

select a.SystemID, a.MemberID, a.YearMo, a.Enrl_Plan, a.Enrl_Motion, a.EnrlMotion_MonthInd, a.PlcyEnrlMotion_MonthInd
	, a.Step_Cnt, a.NoDays_wSteps
	, Analgesic_Antihistamine_Combination_Allow	= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANALGESIC AND ANTIHISTAMINE COMBINATION'    then b.AllwAmt	else 0	end)
	, Analgesics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANALGESICS'									then b.AllwAmt	else 0	end)
	, Anesthetics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANESTHETICS'								then b.AllwAmt	else 0	end)
	, AntiObesityDrugs_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTI-OBESITY DRUGS'							then b.AllwAmt	else 0	end)
	, Antiarthritics_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIARTHRITICS'								then b.AllwAmt	else 0	end)
	, Antiasthmatics_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIASTHMATICS'								then b.AllwAmt	else 0	end)
	, Antibiotics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIBIOTICS'								then b.AllwAmt	else 0	end)
	, Anticoagulants_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTICOAGULANTS'								then b.AllwAmt	else 0	end)
	, Antidotes_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIDOTES'									then b.AllwAmt	else 0	end)
	, AntiFungals_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIFUNGALS'								then b.AllwAmt	else 0	end)
	, Antihistamine_Decongestant_Combination_Allow	= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINE AND DECONGESTANT COMBINATION'	then b.AllwAmt	else 0	end)
	, Antihistamines_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINES'								then b.AllwAmt	else 0	end)
	, Antihyperglycemics_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIHYPERGLYCEMICS'							then b.AllwAmt	else 0	end)
	, Antiinfectives_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES'								then b.AllwAmt	else 0	end)
	, AntiinfectivesMiscellaneous_Allow			= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES/MISCELLANEOUS'				then b.AllwAmt	else 0	end)
	, Antineoplastics_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTINEOPLASTICS'							then b.AllwAmt	else 0	end)
	, AntiparkinsonDrugs_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIPARKINSON DRUGS'						then b.AllwAmt	else 0	end)
	, AntiplateletDrugs_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIPLATELET DRUGS'							then b.AllwAmt	else 0	end)
	, Antivirals_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ANTIVIRALS'									then b.AllwAmt	else 0	end)
	, AutonomicDrugs_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'AUTONOMIC DRUGS'							then b.AllwAmt	else 0	end)
	, Biologicals_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'BIOLOGICALS'								then b.AllwAmt	else 0	end)
	, Blood_Allow								= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'BLOOD'										then b.AllwAmt	else 0	end)
	, CardiacDrugs_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CARDIAC DRUGS'								then b.AllwAmt	else 0	end)
	, Cardiovascular_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CARDIOVASCULAR'								then b.AllwAmt	else 0	end)
	, CNSDrugs_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CNS DRUGS'									then b.AllwAmt	else 0	end)
	, ColonyStimulatingFactors_Allow			= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'COLONY STIMULATING FACTORS'					then b.AllwAmt	else 0	end)
	, Contraceptives_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'CONTRACEPTIVES'								then b.AllwAmt	else 0	end)
	, CoughColdPreparations_Allow				= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'COUGH/COLD PREPARATIONS'					then b.AllwAmt	else 0	end)
	, Diagnostic_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'DIAGNOSTIC'									then b.AllwAmt	else 0	end)
	, Diuretics_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'DIURETICS'									then b.AllwAmt	else 0	end)
	, EENTPreps_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'EENT PREPS'									then b.AllwAmt	else 0	end)
	, ElectCaloricH2O_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'ELECT/CALORIC/H2O'							then b.AllwAmt	else 0	end)
	, Gastrointestinal_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'GASTROINTESTINAL'							then b.AllwAmt	else 0	end)
	, Herbals_Allow								= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'HERBALS'									then b.AllwAmt	else 0	end)
	, Hormones_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'HORMONES'									then b.AllwAmt	else 0	end)
	, Immunosuppresant_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'IMMUNOSUPPRESANT'							then b.AllwAmt	else 0	end)
	, MiscMedicalSuppliesDevicesNondrug_Allow	= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'MISC MEDICAL SUPPLIES, DEVICES, NON-DRUG'	then b.AllwAmt	else 0	end)
	, MuscleRelaxants_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'MUSCLE RELAXANTS'							then b.AllwAmt	else 0	end)
	, PreNatalVitamins_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'PRE-NATAL VITAMINS'							then b.AllwAmt	else 0	end)
	, PhyscotherapeuticDrugs_Allow				= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'PSYCHOTHERAPEUTIC DRUGS'					then b.AllwAmt	else 0	end)
	, SedativeHypnotics_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'SEDATIVE/HYPNOTICS'							then b.AllwAmt	else 0	end)
	, SkinPreps_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'SKIN PREPS'									then b.AllwAmt	else 0	end)
	, SmokingDeterrents_Allow					= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'SMOKING DETERRENTS'							then b.AllwAmt	else 0	end)
	, ThyroidPreps_Allow						= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'THYROID PREPS'								then b.AllwAmt	else 0	end)
	, Vitamins_Allow							= sum(case when e.Gnrc_Therapeutic_Clss_Desc = 'VITAMINS'									then b.AllwAmt	else 0	end)
	, a.Der_Enrl_Motion, a.Der_Enrl_MonthInd, a.Der_PlcyEnrlMotion_MonthInd, a.Der_Enrl_Motion_w300, a.Der_Enrl_MonthInd_w300	--added 06/26/2017
into pdb_PharmaMotion..MemberSummaryDrugClassAllw_v2
from pdb_PharmaMotion..MemberSummary_v2	a
inner join AllSavers_Prod..Fact_Claims		b	on	a.MemberID = b.MemberID
inner join AllSavers_Prod..Dim_Date			c	on	b.FromDtSysID = c.DtSysId
												and a.YearMo = c.YearMo
inner join AllSavers_Prod..Dim_NDCDrug		d	on	b.NDCDrugSysID = d.NDCDrugSysID
inner join MiniHPDM..Dim_Drug_Class			e	on	d.NDC = e.NDC
where e.Gnrc_Therapeutic_Clss_Desc is not null
	and e.Gnrc_Therapeutic_Clss_Desc not in ('NO GENERIC THERAPEUTIC CLASS CODE', 'UNCLASSIFIED DRUG PRODUCTS')
	and b.ServiceTypeSysID = 4
group by a.SystemID, a.MemberID, a.YearMo, a.Enrl_Plan, a.Enrl_Motion, a.EnrlMotion_MonthInd, a.PlcyEnrlMotion_MonthInd
	, a.Step_Cnt, a.NoDays_wSteps
	, a.Der_Enrl_Motion, a.Der_Enrl_MonthInd, a.Der_PlcyEnrlMotion_MonthInd, a.Der_Enrl_Motion_w300, a.Der_Enrl_MonthInd_w300
having sum(b.AllwAmt) > 0
--(697,868 row(s) affected)
create unique index uIx_MemberID_YrMo on pdb_PharmaMotion..MemberSummaryDrugClassAllw_v2 (SystemID, MemberID, YearMo); 

select * from pdb_PharmaMotion..MemberSummaryDrugClassAllw_v2 where SystemID = 54000046930002500 order by 3