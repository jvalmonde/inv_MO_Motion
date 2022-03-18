USE pdb_WalkandWin /*...on DBSEP3832*/
GO


--Original tables had a bunch of stuff in them. We don't need that stuff...

IF object_id('RAF_2016_Pilot','U') IS NOT NULL
	DROP TABLE RAF_2016_Pilot;
select 
	a.SavvyHICN
	,max(OriginalReasonForEntitlement) as OREC
	,max(case when left(PaymentDateYM,4) = 2013 then RiskAdjusterFactorA end) as RAFMMR_2013
	,max(case when left(PaymentDateYM,4) = 2014 then RiskAdjusterFactorA end) as RAFMMR_2014
	,max(case when left(PaymentDateYM,4) = 2015 then RiskAdjusterFactorA end) as RAFMMR_2015
	,max(case when left(PaymentDateYM,4) = 2016 then RiskAdjusterFactorA end) as RAFMMR_2016
	,max(case when left(PaymentDateYM,4) = 2017 then RiskAdjusterFactorA end) as RAFMMR_2017
into RAF_2016_Pilot
from 
	CombinedMember_sg				a
	join CMSMMR_Subset_20180313		b	on	a.SavvyHICN		=	b.SavvyHICN
where
	a.is2016		=	1
group by 
	a.SavvyHICN
go
create clustered index cixSavvyHICN on RAF_2016_Pilot(SavvyHICN)
go

IF object_id('RAF_2017_Pilot','U') IS NOT NULL
	DROP TABLE RAF_2017_Pilot;
select 
	a.SavvyHICN
	,max(OriginalReasonForEntitlement) as OREC
	,max(case when left(PaymentDateYM,4) = 2013 then RiskAdjusterFactorA end) as RAFMMR_2013
	,max(case when left(PaymentDateYM,4) = 2014 then RiskAdjusterFactorA end) as RAFMMR_2014
	,max(case when left(PaymentDateYM,4) = 2015 then RiskAdjusterFactorA end) as RAFMMR_2015
	,max(case when left(PaymentDateYM,4) = 2016 then RiskAdjusterFactorA end) as RAFMMR_2016
	,max(case when left(PaymentDateYM,4) = 2017 then RiskAdjusterFactorA end) as RAFMMR_2017
into RAF_2017_Pilot
from 
	CombinedMember_sg				a
	join CMSMMR_Subset_20180313		b	on	a.SavvyHICN		=	b.SavvyHICN
where
	a.is2017		=	1
group by 
	a.SavvyHICN
go
create clustered index cixSavvyHICN on RAF_2017_Pilot(SavvyHICN)
go
