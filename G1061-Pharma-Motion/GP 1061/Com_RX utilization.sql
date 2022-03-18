/*** 
GP 1061 Pharmacy & Motion -- Comparison with Commercial members' RX consumption
Input databases:	MiniHPDM
Date Created: 08 May 2017
***/

--pull for the members
If (object_id('tempdb..#members') Is Not Null)
Drop Table #members
go

select top 10 percent a.*
into #members
from MiniHPDM..Dim_Member	a
inner join MiniHPDM..Dim_CustSegSysId	b	on	a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
where b.Hlth_Pln_Fund_Cd = 'FI'
	and (a.MM_2014 = 12
	or a.MM_2015 = 12
	or a.MM_2016 = 12)
order by newid()
--(653,592 row(s) affected)
create unique index uIx_Indv on #members (Indv_Sys_ID);


If (object_id('pdb_PharmaMotion..Commercial_Mbrs_RXutilization') Is Not Null)
Drop Table pdb_PharmaMotion..Commercial_Mbrs_RXutilization
go

select a.Indv_Sys_Id, c.YEAR_MO, a.Gdr_Cd, a.Age, a.MM_2014, a.MM_2015, a.MM_2016
	--spend
	, Analgesic_Antihistamine_Combination_Allow	= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANALGESIC AND ANTIHISTAMINE COMBINATION'    then b.Allw_Amt	else 0	end)
	, Analgesics_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANALGESICS'									then b.Allw_Amt	else 0	end)
	, Anesthetics_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANESTHETICS'								then b.Allw_Amt	else 0	end)
	, AntiObesityDrugs_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTI-OBESITY DRUGS'							then b.Allw_Amt	else 0	end)
	, Antiarthritics_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIARTHRITICS'								then b.Allw_Amt	else 0	end)
	, Antiasthmatics_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIASTHMATICS'								then b.Allw_Amt	else 0	end)
	, Antibiotics_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIBIOTICS'								then b.Allw_Amt	else 0	end)
	, Anticoagulants_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTICOAGULANTS'								then b.Allw_Amt	else 0	end)
	, Antidotes_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIDOTES'									then b.Allw_Amt	else 0	end)
	, AntiFungals_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIFUNGALS'								then b.Allw_Amt	else 0	end)
	, Antihistamine_Decongestant_Combination_Allow	= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINE AND DECONGESTANT COMBINATION'	then b.Allw_Amt	else 0	end)
	, Antihistamines_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINES'								then b.Allw_Amt	else 0	end)
	, Antihyperglycemics_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIHYPERGLYCEMICS'							then b.Allw_Amt	else 0	end)
	, Antiinfectives_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES'								then b.Allw_Amt	else 0	end)
	, AntiinfectivesMiscellaneous_Allow			= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES/MISCELLANEOUS'				then b.Allw_Amt	else 0	end)
	, Antineoplastics_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTINEOPLASTICS'							then b.Allw_Amt	else 0	end)
	, AntiparkinsonDrugs_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIPARKINSON DRUGS'						then b.Allw_Amt	else 0	end)
	, AntiplateletDrugs_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIPLATELET DRUGS'							then b.Allw_Amt	else 0	end)
	, Antivirals_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIVIRALS'									then b.Allw_Amt	else 0	end)
	, AutonomicDrugs_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'AUTONOMIC DRUGS'							then b.Allw_Amt	else 0	end)
	, Biologicals_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'BIOLOGICALS'								then b.Allw_Amt	else 0	end)
	, Blood_Allow								= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'BLOOD'										then b.Allw_Amt	else 0	end)
	, CardiacDrugs_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'CARDIAC DRUGS'								then b.Allw_Amt	else 0	end)
	, Cardiovascular_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'CARDIOVASCULAR'								then b.Allw_Amt	else 0	end)
	, CNSDrugs_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'CNS DRUGS'									then b.Allw_Amt	else 0	end)
	, ColonyStimulatingFactors_Allow			= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'COLONY STIMULATING FACTORS'					then b.Allw_Amt	else 0	end)
	, Contraceptives_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'CONTRACEPTIVES'								then b.Allw_Amt	else 0	end)
	, CoughColdPreparations_Allow				= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'COUGH/COLD PREPARATIONS'					then b.Allw_Amt	else 0	end)
	, Diagnostic_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'DIAGNOSTIC'									then b.Allw_Amt	else 0	end)
	, Diuretics_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'DIURETICS'									then b.Allw_Amt	else 0	end)
	, EENTPreps_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'EENT PREPS'									then b.Allw_Amt	else 0	end)
	, ElectCaloricH2O_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'ELECT/CALORIC/H2O'							then b.Allw_Amt	else 0	end)
	, Gastrointestinal_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'GASTROINTESTINAL'							then b.Allw_Amt	else 0	end)
	, Herbals_Allow								= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'HERBALS'									then b.Allw_Amt	else 0	end)
	, Hormones_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'HORMONES'									then b.Allw_Amt	else 0	end)
	, Immunosuppresant_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'IMMUNOSUPPRESANT'							then b.Allw_Amt	else 0	end)
	, MiscMedicalSuppliesDevicesNondrug_Allow	= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'MISC MEDICAL SUPPLIES, DEVICES, NON-DRUG'	then b.Allw_Amt	else 0	end)
	, MuscleRelaxants_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'MUSCLE RELAXANTS'							then b.Allw_Amt	else 0	end)
	, PreNatalVitamins_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'PRE-NATAL VITAMINS'							then b.Allw_Amt	else 0	end)
	, PhyscotherapeuticDrugs_Allow				= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'PSYCHOTHERAPEUTIC DRUGS'					then b.Allw_Amt	else 0	end)
	, SedativeHypnotics_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'SEDATIVE/HYPNOTICS'							then b.Allw_Amt	else 0	end)
	, SkinPreps_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'SKIN PREPS'									then b.Allw_Amt	else 0	end)
	, SmokingDeterrents_Allow					= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'SMOKING DETERRENTS'							then b.Allw_Amt	else 0	end)
	, ThyroidPreps_Allow						= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'THYROID PREPS'								then b.Allw_Amt	else 0	end)
	, Vitamins_Allow							= sum(case when d.Gnrc_Therapeutic_Clss_Desc = 'VITAMINS'									then b.Allw_Amt	else 0	end)
	--counts
	, Cnt_Analgesic_Antihistamine_Combination	= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANALGESIC AND ANTIHISTAMINE COMBINATION'     then d.NDC	end)
	, Cnt_Analgesics							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANALGESICS'									then d.NDC	end)
	, Cnt_Anesthetics							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANESTHETICS'									then d.NDC	end)
	, Cnt_AntiObesityDrugs						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTI-OBESITY DRUGS'							then d.NDC	end)
	, Cnt_Antiarthritics						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIARTHRITICS'								then d.NDC	end)
	, Cnt_Antiasthmatics						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIASTHMATICS'								then d.NDC	end)
	, Cnt_Antibiotics							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIBIOTICS'									then d.NDC	end)
	, Cnt_Anticoagulants						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTICOAGULANTS'								then d.NDC	end)
	, Cnt_Antidotes								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIDOTES'									then d.NDC	end)
	, Cnt_AntiFungals							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIFUNGALS'									then d.NDC	end)
	, Cnt_Antihistamine_Decongestant_Combination	= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINE AND DECONGESTANT COMBINATION'	then d.NDC	end)
	, Cnt_Antihistamines						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIHISTAMINES'								then d.NDC	end)
	, Cnt_Antihyperglycemics					= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIHYPERGLYCEMICS'							then d.NDC	end)
	, Cnt_Antiinfectives						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES'								then d.NDC	end)
	, Cnt_AntiinfectivesMiscellaneous			= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIINFECTIVES/MISCELLANEOUS'				then d.NDC	end)
	, Cnt_Antineoplastics						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTINEOPLASTICS'								then d.NDC	end)
	, Cnt_AntiparkinsonDrugs					= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIPARKINSON DRUGS'							then d.NDC	end)
	, Cnt_AntiplateletDrugs						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIPLATELET DRUGS'							then d.NDC	end)
	, Cnt_Antivirals							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ANTIVIRALS'									then d.NDC	end)
	, Cnt_AutonomicDrugs						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'AUTONOMIC DRUGS'								then d.NDC	end)
	, Cnt_Biologicals							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'BIOLOGICALS'									then d.NDC	end)
	, Cnt_Blood									= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'BLOOD'										then d.NDC	end)
	, Cnt_CardiacDrugs							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'CARDIAC DRUGS'								then d.NDC	end)
	, Cnt_Cardiovascular						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'CARDIOVASCULAR'								then d.NDC	end)
	, Cnt_CNSDrugs								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'CNS DRUGS'									then d.NDC	end)
	, Cnt_ColonyStimulatingFactors				= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'COLONY STIMULATING FACTORS'					then d.NDC	end)
	, Cnt_Contraceptives						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'CONTRACEPTIVES'								then d.NDC	end)
	, Cnt_CoughColdPreparations					= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'COUGH/COLD PREPARATIONS'						then d.NDC	end)
	, Cnt_Diagnostic							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'DIAGNOSTIC'									then d.NDC	end)
	, Cnt_Diuretics								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'DIURETICS'									then d.NDC	end)
	, Cnt_EENTPreps								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'EENT PREPS'									then d.NDC	end)
	, Cnt_ElectCaloricH2O						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'ELECT/CALORIC/H2O'							then d.NDC	end)
	, Cnt_Gastrointestinal						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'GASTROINTESTINAL'							then d.NDC	end)
	, Cnt_Herbals								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'HERBALS'										then d.NDC	end)
	, Cnt_Hormones								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'HORMONES'									then d.NDC	end)
	, Cnt_Immunosuppresant						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'IMMUNOSUPPRESANT'							then d.NDC	end)
	, Cnt_MiscMedicalSuppliesDevicesNondrug		= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'MISC MEDICAL SUPPLIES, DEVICES, NON-DRUG'	then d.NDC	end)
	, Cnt_MuscleRelaxants						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'MUSCLE RELAXANTS'							then d.NDC	end)
	, Cnt_PreNatalVitamins						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'PRE-NATAL VITAMINS'							then d.NDC	end)
	, Cnt_PhyscotherapeuticDrugs				= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'PSYCHOTHERAPEUTIC DRUGS'						then d.NDC	end)
	, Cnt_SedativeHypnotics						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'SEDATIVE/HYPNOTICS'							then d.NDC	end)
	, Cnt_SkinPreps								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'SKIN PREPS'									then d.NDC	end)
	, Cnt_SmokingDeterrents						= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'SMOKING DETERRENTS'							then d.NDC	end)
	, Cnt_ThyroidPreps							= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'THYROID PREPS'								then d.NDC	end)
	, Cnt_Vitamins								= count(distinct case when d.Gnrc_Therapeutic_Clss_Desc = 'VITAMINS'									then d.NDC	end)
into pdb_PharmaMotion..Commercial_Mbrs_RXutilization
from #members	a
inner join MiniHPDM..Fact_Claims	b	on	a.Indv_Sys_Id = b.Indv_Sys_Id
inner join MiniHPDM..Dim_Date		c	on	b.Dt_Sys_Id = c.DT_SYS_ID
inner join MiniHPDM..Dim_Drug_Class	d	on	b.NDC_Drg_Sys_Id = d.NDC_DRG_SYS_ID
where b.Srvc_Typ_Sys_Id = 4 -- pull for the RX claims only
	and c.YEAR_NBR in (2014, 2015, 2016)
group by a.Indv_Sys_Id, c.YEAR_MO, a.Gdr_Cd, a.Age, a.MM_2014, a.MM_2015, a.MM_2016
--(4147592 row(s) affected)