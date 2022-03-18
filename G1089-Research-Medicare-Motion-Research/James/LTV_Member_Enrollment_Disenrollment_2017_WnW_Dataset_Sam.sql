-------------------------------------------------------------
--1) Get acquisition channel for the lifetime
-------------------------------------------------------------
--summary of acquisition channel
--select a.SavvyHICN, b.Lifetime_ID,
--       max(case when CHNL_DESC in('EASE - FMO', 'FMO') then 1 else 0 end) as Chnl_FMO,
--	   max(case when CHNL_DESC in('EASE - ICA', 'ICA') then 1 else 0 end) as Chnl_ICA,
--	   max(case when CHNL_DESC in('EASE - ISR', 'ISR') then 1 else 0 end) as Chnl_ISR,
--	   max(case when CHNL_DESC in('EASE - Telesales', 'Phone') then 1 else 0 end) as Chnl_Phone,
--	   max(case when CHNL_DESC in('Internet', 'Web') then 1 else 0 end) as Chnl_Web
--into #channel
--from(
--	select SavvyHICN,
--		   case when Mnth = 'Jan' then Yr+'01' 
--				when Mnth = 'Feb' then Yr+'02' 
--				when Mnth = 'Mar' then Yr+'03' 
--				when Mnth = 'Apr' then Yr+'04' 
--				when Mnth = 'May' then Yr+'05' 
--				when Mnth = 'Jun' then Yr+'06' 
--				when Mnth = 'Jul' then Yr+'07' 
--				when Mnth = 'Aug' then Yr+'08' 
--				when Mnth = 'Sep' then Yr+'09' 
--				when Mnth = 'Oct' then Yr+'10' 
--				when Mnth = 'Nov' then Yr+'11' 
--				when Mnth = 'Dec' then Yr+'12' end as Year_Mo,
--			CHNL_DESC
--	from(
--		select a.SavvyHICN,
--				right(left(a.MEMBERSHIP_EFFECTIVE_DATE, 9), 4) as Yr,
--				left(right(left(a.MEMBERSHIP_EFFECTIVE_DATE, 9), 7), 3) as Mnth,
--				CHNL_DESC
--		from pdb_pdb_WalkandWin..TK_MR2765_PDP_MA_Member_Clean	as a 
--		where a.CHNL_DESC <> 'missing'
--		) as a
--	) as a 
--join pdb_pdb_WalkandWin..Member_Lifetime	as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo between b.Enroll_Year_Mo and b.Disenroll_Year_Mo
--group by a.SavvyHICN, b.Lifetime_ID
----155,071



-------------------------------------------------------------
--2) Get TRR enrollment reasons
-------------------------------------------------------------
--use M&R Finance order-of-operations logic to select the most relevant record for each transaction type and date
-- drop table #trr
select a.*
into #trr
from(
	select a.SavvyHICN,
			a.ContractNumber as Contr_Nbr,
			a.PlanBenefitPackageID as PBP,
			a.TransactionEffectiveDateCode,
			left(a.TransactionEffectiveDateCode, 6) as Year_Mo,
			a.TransactionTypeCode, c.TransactionTypeDescription,
			a.TransactionReplyCode, b.Title as TransactionReplyDescription,
			a.EnrollmentSource, d.EnrollmentSourceDescription,
			a.ElectionType, e.ElectionTypeDesc,
			a.DisenrollmentReasonCode, f.DisenrollmentReasonDesc,
			--a.MedicaidStatus, a.Disability, a.Hospice, a.InstitutionalNHC, a.ESRD, 
			ROW_NUMBER() over(partition by a.SavvyHICN, a.ContractNumber, a.PlanBenefitPackageID, a.TransactionTypeCode, a.TransactionEffectiveDateCode order by b.TransactionReplyCodeType, a.DateInFileName desc, a.TransactionReplyCode) as RN
	from pdb_WalkandWin..WnW_Dataset_Sam_TRR				as a 
	left join pdb_WalkandWin..TRR_TransactionReplyCode		as b	on a.TransactionReplyCode = b.TransactionReplyCode
	left join pdb_WalkandWin..TRR_TransactionTypeCode		as c	on a.TransactionTypeCode = c.TransactionTypeCode
	left join pdb_WalkandWin..TRR_EnrollmentSource			as d	on a.EnrollmentSource = d.EnrollmentSourceCode
	left join pdb_WalkandWin..TRR_ElectionType				as e	on a.ElectionType = e.ElectionTypeCode
	left join pdb_WalkandWin..TRR_DisenrollmentReasonCode	as f	on a.DisenrollmentReasonCode = f.DisenrollmentReasonCode
	where a.TransactionTypeCode in('01','51','53','54','60','61','62','71','74','80','81','82')
		and b.TransactionReplyCodeType in('A') --Accepted (not Rejected, Informational, Maintenance, or Failed)
	) as a
where a.RN = 1
--146,417

-- drop table #trr_enrollment
select * 
into #trr_enrollment
from(
	select *, ROW_NUMBER() over(partition by a.SavvyHICN, a.Year_Mo order by a.TransactionEffectiveDateCode asc, a.TransactionReplyCode) as RN2
	from #trr	as a
	where a.TransactionTypeCode in('60','61','62')
	) as a
where a.RN2 = 1
-- 86,778

-- drop table #trr_disenrollment
select a.*, isnull(b.Death_Flag, 0) as Death_Flag
into #trr_disenrollment
from(
	select *, ROW_NUMBER() over(partition by a.SavvyHICN, a.Year_Mo order by a.TransactionEffectiveDateCode desc, a.TransactionReplyCode) as RN2
	from #trr	as a
	where a.TransactionTypeCode in('51','53','54')
	) as a
left join(
	select distinct SavvyHICN, left(TransactionEffectiveDateCode, 6) as Year_Mo, 1 as Death_Flag
	from pdb_WalkandWin..WnW_Dataset_Sam_TRR
	where TransactionReplyCode in ('090', '092')
	) as b	on a.SavvyHICN = b.SavvyHICN and a.Year_Mo = b.Year_Mo
where a.RN2 = 1
-- 48,008


-- drop table pdb_WalkandWin..LTV_Member_Enrollment
select a.SavvyHICN, a.Lifetime_ID, a.Enroll_Year_Mo,
       x.Contr_Nbr, x.PBP,
   --    case when b.Chnl_FMO = 1		then 'FMO/ICA'
	  --      when b.Chnl_ICA = 1		then 'FMO/ICA'
			--when b.Chnl_ISR = 1		then 'ISR'
			--when b.Chnl_Phone = 1	then 'Telesales'
			--when b.Chnl_Web = 1		then 'Web' end as Acquisition_Channel,
	   c.TransactionTypeDescription as TransactionTypeDesc,
	   c.TransactionReplyDescription as TransactionReplyDesc,
	   c.EnrollmentSourceDescription as EnrollmentSourceDesc,
	   c.ElectionTypeDesc,
	   e.Age-(2016-left(a.Enroll_Year_Mo, 4)) as Estimated_Age
into pdb_WalkandWin..LTV_Member_Enrollment_2016_Pilot
from pdb_WalkandWin..LTV_Member_Lifetime_ID_2016_Pilot			as a 
join pdb_WalkandWin..LTV_Member_Month_2016_Pilot					as x	on a.SavvyHICN = x.SavvyHICN and a.Enroll_Year_Mo = x.Year_Mo
--left join #channel							as b	on a.SavvyHICN = b.SavvyHICN and a.Lifetime_ID = b.Lifetime_ID
left join #trr_enrollment					as c	on a.SavvyHICN = c.SavvyHICN and a.Enroll_Year_Mo = c.Year_Mo
left join MiniOV..SavvyID_to_SavvyHICN		as d	on a.SavvyHICN = d.SavvyHICN
left join MiniOV..Dim_Member				as e	on d.SavvyID = e.SavvyID
-- 50901

create unique index ix_x on pdb_WalkandWin..LTV_Member_Enrollment_2016_Pilot(SavvyHICN, Lifetime_ID)
create unique index ix_y on pdb_WalkandWin..LTV_Member_Enrollment_2016_Pilot(SavvyHICN, Enroll_Year_Mo)

-- drop table pdb_WalkandWin..LTV_Member_Disenrollment_2016_Pilot
select a.SavvyHICN, a.Lifetime_ID, a.Disenroll_Year_Mo,
       x.Contr_Nbr, x.PBP,
	   c.TransactionTypeDescription as TransactionTypeDesc,
	   c.TransactionReplyDescription as TransactionReplyDesc,
	   c.DisenrollmentReasonDesc,
	   case when c.Death_Flag = 1 then 'Death'
	        when c.DisenrollmentReasonCode in('05', '06', '61', '64', '65', '93') then 'Loss of Eligibility'
			when c.DisenrollmentReasonCode in('07') then 'For Cause'
			--when c.DisenrollmentReasonCode in('08') then 'Death'
			when c.DisenrollmentReasonCode in('09') then 'CMS Initiated Termination'
			when c.DisenrollmentReasonCode in('11', '63') then 'Voluntary Disenrollment or Opt-Out'
			when c.DisenrollmentReasonCode in('13', '18', '50') then 'Switched Plans or Rollover'
			when c.DisenrollmentReasonCode in('62', '91') then 'Failure to Pay'
			when c.DisenrollmentReasonCode in('92') then 'Relocation' 
			when c.TransactionReplyCode in('014') then 'Switched Plans or Rollover'
			when c.TransactionReplyCode in('018') then 'Automatic Disenrollment'
			when c.TransactionReplyCode in ('090', '092') then 'Death'
			when c.TransactionReplyCode in ('131') then 'Voluntary Disenrollment or Opt-Out'
			when c.TransactionReplyCode in ('197') then 'Loss of Eligibility'
			when c.TransactionReplyCode in ('293') then 'Failure to Pay'
			else 'Other/Unknown'
			end as DerivedDisenrollmentReason,	
	   c.Death_Flag,
	   e.Age-(2016-left(a.Disenroll_Year_Mo, 4)) as Estimated_Age
into pdb_WalkandWin..LTV_Member_Disenrollment_2016_Pilot
from pdb_WalkandWin..LTV_Member_Lifetime_ID_2016_Pilot			as a 
join pdb_WalkandWin..LTV_Member_Month_2016_Pilot					as x	on a.SavvyHICN = x.SavvyHICN and a.Disenroll_Year_Mo = x.Year_Mo
left join #trr_disenrollment				as c	on a.SavvyHICN = c.SavvyHICN and a.Disenroll_Year_Mo = c.Year_Mo
left join MiniOV..SavvyID_to_SavvyHICN		as d	on a.SavvyHICN = d.SavvyHICN
left join MiniOV..Dim_Member				as e	on d.SavvyID = e.SavvyID
-- 50901

create unique index ix_x on pdb_WalkandWin..LTV_Member_Disenrollment_2016_Pilot(SavvyHICN, Lifetime_ID)
create unique index ix_y on pdb_WalkandWin..LTV_Member_Disenrollment_2016_Pilot(SavvyHICN, Disenroll_Year_Mo)




--Validation
/*
select left(Enroll_Year_Mo, 4) as Yr,
	   count(*),
       --sum(case when Acquisition_Channel is not null then 1 else 0 end)*1.0/count(*) as AC_Rate,
	   sum(case when TransactionTypeDesc is not null then 1 else 0 end)*1.0/count(*) as TType_Rate,
	   sum(case when ElectionTypeDesc is not null then 1 else 0 end)*1.0/count(*) as ET_Rate,
	   sum(case when Estimated_Age is not null then 1 else 0 end)*1.0/count(*) as Age_Rate
from pdb_WalkandWin..LTV_Member_Enrollment
group by left(Enroll_Year_Mo, 4)
order by 1


select left(Disenroll_Year_Mo, 4) as Yr,
	   count(*),
	   sum(case when TransactionTypeDesc is not null then 1 else 0 end)*1.0/count(*) as TType_Rate,
	   sum(case when DisenrollmentReasonDesc is not null then 1 else 0 end)*1.0/count(*) as DR_Rate,
	   sum(case when Estimated_Age is not null then 1 else 0 end)*1.0/count(*) as Age_Rate
from pdb_WalkandWin..LTV_Member_Disenrollment
group by left(Disenroll_Year_Mo, 4)
order by 1
*/

