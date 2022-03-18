use pdb_WalkandWin
go

IF object_id('StateCountyContractPlanEnrollment_CMS','U') IS NOT NULL
	DROP TABLE StateCountyContractPlanEnrollment_CMS;
select
	YearNbr,
	YearMo,
	ContractNbr					=	convert(varchar(14), [Contract Number]),
	PlanID						=	convert(varchar(5), [Plan ID]),
	SSACode						=	convert(varchar(5), [SSA State County Code]),
	FIPSCode					=	convert(varchar(5), [FIPS State County Code]),
	StateAbbr					=	convert(varchar(2), State),
	CountyName					=	convert(varchar(40), County),
	Enrollment					=	convert(int, case when Enrollment = '*' then 0 else Enrollment end),
	indEnrollmentLT10			=	case when Enrollment = '*' then 1 else 0 end
into StateCountyContractPlanEnrollment_CMS
from(
	select YearNbr = 2014, YearMo = 201401, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Enrollment_Info_2014_01 union all
	select YearNbr = 2015, YearMo = 201501, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Enrollment_Info_2015_01 union all
	select YearNbr = 2016, YearMo = 201601, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Enrollment_Info_2016_01 union all
	select YearNbr = 2017, YearMo = 201701, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Enrollment_Info_2017_01 union all
	select YearNbr = 2018, YearMo = 201801, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Enrollment_Info_2018_01
	) k
where Enrollment <> 0 
go
create clustered index cixContractNbr_PlanID on StateCountyContractPlanEnrollment_CMS(ContractNbr, PlanID);
create index ixFIPSCode on StateCountyContractPlanEnrollment_CMS(FIPSCode) include (YearMo, Enrollment);
go

IF object_id('StateCountyContractPlanInfo_CMS','U') IS NOT NULL
	DROP TABLE StateCountyContractPlanInfo_CMS;
select
	YearNbr,
	YearMo,
	ContractNbr					=	convert(varchar(14), [Contract ID]),
	PlanID						=	convert(varchar(5), [Plan ID]),
	OrgType						=	convert(varchar(50), [Organization Type]),
	PlanType					=	convert(varchar(50), [Plan Type]),
	indPartD					=	convert(varchar(5), [Offers Part D]),
	indSNPs						=	convert(varchar(5), [SNP Plan]),
	indEGHP						=	convert(varchar(5), [EGHP]),
	OrgName						=	convert(varchar(200), [Organization Name]),
	OrgMarketingName			=	convert(varchar(200), [Organization Marketing Name]),
	PlanName					=	convert(varchar(200), [Plan Name]),
	ParentOrg					=	convert(varchar(200), [Parent Organization]),
	EffectiveDate				=	convert(date, [Contract Effective Date])
into StateCountyContractPlanInfo_CMS
from(
	select YearNbr = 2014, YearMo = 201401, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Contract_Info_2014_01 union all
	select YearNbr = 2015, YearMo = 201501, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Contract_Info_2015_01 union all
	select YearNbr = 2016, YearMo = 201601, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Contract_Info_2016_01 union all
	select YearNbr = 2017, YearMo = 201701, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Contract_Info_2017_01 union all
	select YearNbr = 2018, YearMo = 201801, * from udb_sgrossinger.dbo.tmp_etl_CPSC_Contract_Info_2018_01
	) k
go
create clustered index cixContractNbr_PlanID on StateCountyContractPlanInfo_CMS(ContractNbr, PlanID);
go
