use pdb_ABW
go


if object_id ('pdb_ABW.dbo.HealthiestYou_Claims2015_AllSaversHYMembers') is not null
drop table pdb_ABW.dbo.HealthiestYou_Claims2015_AllSaversHYMembers
Select b.MemberID, b.PolicyID, b.SystemID, b.FamilyID
	,fc.ClaimNumber
	,As_ServiceTYP = st.ServiceTypeDescription
	,AS_Prov        = fc.ProviderSysID
	,AS_SrvcDt		=	dd.FullDt
	,AS_DiagCd		=	dc.DiagDecmCd
	,AS_DiagFst3	=	left(rtrim(ltrim(dc.DiagDecmCd)),3)	
	,AS_DiagDesc	=	dc.DiagDesc
	,AS_DiagDtl		=	dc.AHRQDiagDtlCatgyNm
	,AS_DiagGnl		=	dc.AHRQDiagGenlCatgyNm
	,AS_Service		=	case	when ServiceCodeLongDescription like '%emerg%'			then	'ER'
								when ServiceCodeLongDescription like '%urgent%'			then	'UC'
								when (
									ProcDesc like '%office%visit%'  
									or srvccatgydesc like '%evaluation%management%'
									)													then	'DR'
								when fc.ServiceTypeSysID = 4							then	'RX'
								else 'Others'
						end  
	,AS_Rx_Brnd		=	ndc.BrndNm
	,AS_Rx_Gnrc		=	ndc.GnrcNm
	,AllwAmt		=	Sum(fc.AllwAmt)
	,NetPd			=   sum(fc.PaidAmt)
	,AS_Rx_NDC		=	ndc.NDC
	,MemberType		=	Case When right(b.SystemID, 1) = 0 and Sbscr_Ind = 1 Then 'Primary' Else 'Dependent' End
  Into pdb_ABW.dbo.HealthiestYou_Claims2015_AllSaversHYMembers
From (Select Distinct AllSavers_familyID From pdb_ABW.dbo.HealthiestYou_Member Where InAllSavers = 1)	a
	Inner Join AllSavers_Prod.dbo.Dim_Member		b	on	a.AllSavers_familyID	=	b.FamilyID
	Inner join Allsavers_Prod.dbo.Fact_Claims		fc	on	b.MemberID			=	fc.MemberID
		 												and	b.PolicyID			=	fc.PolicyID
		 												and	b.SystemID			=	fc.SystemID
	Inner join Allsavers_Prod.dbo.Dim_Date			dd	on	fc.FromDtSysID		=	dd.DtSysId
	Inner join Allsavers_Prod.dbo.Dim_DiagnosisCode	dc	on	fc.DiagCdSysId		=	dc.DiagCdSysId
	Inner join Allsavers_Prod.dbo.Dim_ProcedureCode	pc	on	fc.ProcCdSysID		=	pc.procCdsysid
	Inner join allsavers_prod.dbo.Dim_ServiceCode	sc	on	fc.ServiceCodeSysID	=	sc.ServiceCodeSysID
	Inner join Allsavers_Prod.dbo.Dim_NDCDrug		ndc on	fc.NDCDrugSysID		=	ndc.NDCDrugSysID
	Inner join allsavers_prod.dbo.Dim_ServiceType st    on  fc.ServiceTypeSysID = st.ServiceTypeSysID
Where fc.RecordTypeSysID = 1
	and dd.YearNbr = 2015
Group by b.MemberID, b.PolicyID, b.SystemID, b.FamilyID
	, fc.ClaimNumber
	,st.ServiceTypeDescription
	,fc.ProviderSysID
	, dd.FullDt
	, dc.DiagDecmCd
	, left(rtrim(ltrim(dc.DiagDecmCd)),3)
	, dc.DiagDesc
	, dc.AHRQDiagDtlCatgyNm
	, dc.AHRQDiagGenlCatgyNm
	,case	when ServiceCodeLongDescription like '%emerg%'			then	'ER'
								when ServiceCodeLongDescription like '%urgent%'			then	'UC'
								when (
									ProcDesc like '%office%visit%'  
									or srvccatgydesc like '%evaluation%management%'
									)													then	'DR'
								when fc.ServiceTypeSysID = 4							then	'RX'
								else 'Others'
						end  
	, ndc.BrndNm
	, ndc.GnrcNm
	, ndc.NDC
	, b.Sbscr_Ind
Go



/*****Create flags to group claims together****/

Drop table #claimswithFlags
Select *
, ER = Max(Case when AS_Service = 'ER' then 1 else 0 end) over (partition by Memberid, As_SrvcDt) 
, DR = Max(Case when AS_Service = 'DR' then 1 else 0 end) over (partition by Memberid, As_SrvcDt)  
, UC = Max(Case when AS_Service = 'UC' then 1 else 0 end) over (partition by Memberid, As_SrvcDt) 
, IP = Max(Case when As_ServiceTYP = 'Inpatient' then 1 else 0 end) over (partition by Memberid, As_SrvcDt) 
into #claimswithFlags
FROM  pdb_ABW.dbo.HealthiestYou_Claims2015_AllSaversHYMembers



/****Sum of net paid for days wherein Er visit occured - excluding Er visits that culminate in Inpatient stay*****/
Select  Measure = 'Mean- NetPaid less 100th',	Avg(TotalAllw)
--Select * 

From
(	Select * ,N_TILE =  Ntile(100) over( order by TotalAllw )
	FROM 
	(
	Select MemberID, AS_SrvcDt, SUM(NetPd) as TotalAllw
	From #claimswithFlags
	Where IP = 0  and As_ServiceTYP <> 'Pharmacy' and ER = 1 
	Group By MemberID, AS_SrvcDt
	)	sub
) z
Where N_TILE < 96   

/*****UC - Not culminating in Inpatient stay - excluding pharmacy*****/

Select  Measure = 'Mean- NetPaid less 100th',	Avg(TotalAllw)
--Select * 

From
(	Select * ,N_TILE =  Ntile(100) over( order by TotalAllw )
	FROM 
	(
	Select MemberID, AS_SrvcDt, SUM(NetPd) as TotalAllw
	From #claimswithFlags
	Where IP = 0  and As_ServiceTYP <> 'Pharmacy' and UC = 1  --and Er = 0 
	Group By MemberID, AS_SrvcDt
	)	sub
) z
Where N_TILE < 96   

/***Dr - Not Culminating in Inpatient Cost***/
Select  Measure = 'Mean- NetPaid less 100th',	Avg(TotalAllw)
--Select * 

From
(	Select * ,N_TILE =  Ntile(100) over( order by TotalAllw )
	FROM 
	(
	Select MemberID, AS_SrvcDt,cf.AS_Prov, SUM(NetPd) as TotalAllw
	From #claimswithFlags cf
	Where IP = 0  and As_ServiceTYP <> 'Pharmacy' and DR = 1  and UC = 0 and ER = 0 
	Group By MemberID, AS_SrvcDt,cf.AS_Prov
	)	sub
) z
Where N_TILE < 96  
