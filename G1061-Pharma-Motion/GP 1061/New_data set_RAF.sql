/*** 
GP 1061 Pharmacy & Motion -- RAF (additional fields for the New data set)

Input databases:	AllSavers_Prod, RA_Commercial_2014, 2015, 2016, pdb_PharmaMotion

Date Created: 12 June 2017
***/

--------------------
--2014
--------------------
If (object_id('tempdb..#member_2014') Is Not Null)
Drop Table #member_2014
go

select UniqueMemberID = MemberID
	, GenderCd = Gender
	, BirthDate = dateadd(yy, -(Age), '12-31-2014')
	, AgeLast = (Age-3)
into #member_2014
from pdb_PharmaMotion..Member_v2
where MM_2014 >= 6
--(3,089 row(s) affected)
create unique index uIx_MemberID on #member_2014 (UniqueMemberID);


If (object_id('tempdb..#diag_2014') Is Not Null)
Drop Table #diag_2014
go

select UniqueMemberID = a.MemberID
	, ICDCd = c.DiagCd
	, a.DiagnosisServiceDate
into #diag_2014
from	(
			select b.MemberID 
				, DiagnosisServiceDate	= c.FullDt
				, b.ClaimNumber, b.SubNumber, b.ClaimSet
			From	#member_2014									as	a
			inner join AllSavers_Prod..Fact_Claims					as	b	on	a.UniqueMemberID = b.MemberID
			inner join AllSavers_Prod..Dim_Date						as	c	on	b.FromDtSysID = c.DtSysId
			where c.YearNbr = 2014
				and b.ServiceTypeSysID < 4
			group by b.MemberID 
				, c.FullDt
				, b.ClaimNumber, b.SubNumber, b.ClaimSet
		)	a
inner join AllSavers_Prod..Fact_Diagnosis		b	on	a.MemberID = b.MemberID
													and a.ClaimNumber = b.ClaimNumber
													and a.ClaimSet = b.ClaimSet
													and a.SubNumber = b.SubNumber
inner join AllSavers_Prod..Dim_DiagnosisCode	c	on	b.DiagCdSysId = c.DiagCdSysId
where b.DiagnosisNbr in (1,2,3)
group by a.MemberID, c.DiagCd, a.DiagnosisServiceDate
--(19,834 row(s) affected)
--(19,720 row(s) affected)
create index cIx_ID on #diag_2014 (UniqueMemberID);

--select count(distinct UniqueMemberID) from #diag_2014	--2058; 2054

exec RA_Commercial_2014.dbo.spRAFDiagInput
	 @InputPersonTable = '#member_2014'		--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = '#diag_2014'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_PharmaMotion'
	,@OutputSuffix = '2014'
go

--------------------
--2015
--------------------
If (object_id('tempdb..#member_2015') Is Not Null)
Drop Table #member_2015
go

select UniqueMemberID = MemberID
	, GenderCd = Gender
	, BirthDate = dateadd(yy, -(Age), '12-31-2015')
	, AgeLast = (Age-2)
into #member_2015
from pdb_PharmaMotion..Member_v2
where MM_2015 >= 6
--(71,205 row(s) affected)
create unique index uIx_MemberID on #member_2015 (UniqueMemberID);

If (object_id('tempdb..#diag_2015') Is Not Null)
Drop Table #diag_2015
go

select UniqueMemberID = a.MemberID
	, ICDCd = c.DiagCd
	, IcdVerCd = c.ICD_ver_cd
	, a.DiagnosisServiceDate
into #diag_2015
from	(
			select b.MemberID 
				, DiagnosisServiceDate	= c.FullDt
				, b.ClaimNumber, b.SubNumber, b.ClaimSet
			From	#member_2015									as	a
			inner join AllSavers_Prod..Fact_Claims					as	b	on	a.UniqueMemberID = b.MemberID
			inner join AllSavers_Prod..Dim_Date						as	c	on	b.FromDtSysID = c.DtSysId
			where c.YearNbr = 2015
				and b.ServiceTypeSysID < 4
			group by b.MemberID 
				, c.FullDt
				, b.ClaimNumber, b.SubNumber, b.ClaimSet
		)	a
inner join AllSavers_Prod..Fact_Diagnosis		b	on	a.MemberID = b.MemberID
													and a.ClaimNumber = b.ClaimNumber
													and a.ClaimSet = b.ClaimSet
													and a.SubNumber = b.SubNumber
inner join AllSavers_Prod..Dim_DiagnosisCode	c	on	b.DiagCdSysId = c.DiagCdSysId
where b.DiagnosisNbr in (1,2,3)
group by a.MemberID, c.DiagCd, c.ICD_ver_cd, a.DiagnosisServiceDate
--(767,822 row(s) affected)
--(769,020 row(s) affected)
create index cIx_ID on #diag_2015 (UniqueMemberID);

--select count(distinct UniqueMemberID) from #diag_2015	--53098; 53434

exec RA_Commercial_2015.dbo.spRAFDiagInput
	 @InputPersonTable = '#member_2015'		--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = '#diag_2015'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_PharmaMotion'
	,@OutputSuffix = '2015'
go

--------------------
--2016
--------------------
If (object_id('tempdb..#member_2016') Is Not Null)
Drop Table #member_2016
go

select UniqueMemberID = MemberID
	, GenderCd = Gender
	, BirthDate = dateadd(yy, -(Age), '12-31-2016')
	, AgeLast = (Age-1)
into #member_2016
from pdb_PharmaMotion..Member_v2
where MM_2016 >= 6
--(120,485 row(s) affected)
create unique index uIx_MemberID on #member_2016 (UniqueMemberID);

If (object_id('tempdb..#diag_2016') Is Not Null)
Drop Table #diag_2016
go

select UniqueMemberID = a.MemberID
	, ICDCd = c.DiagCd
	, IcdVerCd = c.ICD_ver_cd
	, a.DiagnosisServiceDate
--into #diag_2016
from	(
			select b.MemberID 
				, DiagnosisServiceDate	= c.FullDt
				, b.ClaimNumber, b.SubNumber, b.ClaimSet
			From	#member_2016									as	a
			inner join AllSavers_Prod..Fact_Claims					as	b	on	a.UniqueMemberID = b.MemberID
			inner join AllSavers_Prod..Dim_Date						as	c	on	b.FromDtSysID = c.DtSysId
			where c.YearNbr = 2016
				and b.ServiceTypeSysID < 4
			group by b.MemberID 
				, c.FullDt
				, b.ClaimNumber, b.SubNumber, b.ClaimSet
		)	a
inner join AllSavers_Prod..Fact_Diagnosis		b	on	a.MemberID = b.MemberID
													and a.ClaimNumber = b.ClaimNumber
													and a.ClaimSet = b.ClaimSet
													and a.SubNumber = b.SubNumber
inner join AllSavers_Prod..Dim_DiagnosisCode	c	on	b.DiagCdSysId = c.DiagCdSysId
where b.DiagnosisNbr in (1,2,3)
	and a.MemberID = 261594
group by a.MemberID, c.DiagCd, c.ICD_ver_cd, a.DiagnosisServiceDate
--(1,523,472 row(s) affected)
--(1,536,760 row(s) affected)
create index cIx_ID on #diag_2016 (UniqueMemberID);

--select count(distinct UniqueMemberID) from #diag_2016	--92668; 93578

exec RA_Commercial_2015.dbo.spRAFDiagInput
	 @InputPersonTable = '#member_2016'		--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@InputDiagTable = '#diag_2016'	--Requires fully qualified name (i.e. DatabaseName.Schema.TableName)
	,@OutputDatabase = 'pdb_PharmaMotion'
	,@OutputSuffix = '2016'
go


--------------------------
--create Member updated table
--Date Created: 03 August 2017
--fact diagnosis issue
--------------------------
If (object_id('pdb_PharmaMotion..Member_updt') Is Not Null)
Drop Table pdb_PharmaMotion..Member_updt
go

select *
into pdb_PharmaMotion..Member_updt
from pdb_PharmaMotion..Member_v2
--(131,967 row(s) affected)
create unique index uIx_ID on pdb_PharmaMotion..Member_updt (SystemID, MemberID);

update pdb_PharmaMotion..Member_updt
set RAF_2014	= isnull(b.SilverTotalScore, 0)
	, RAF_2015	= isnull(c.SilverTotalScore, 0)
	, RAF_2016	= isnull(d.SilverTotalScore, 0)
from pdb_PharmaMotion..Member_updt	a
left join pdb_PharmaMotion..RA_Com_Q_MetalScoresPivoted_2014	b	on	a.MemberID = b.UniqueMemberID
left join pdb_PharmaMotion..RA_Com_J_MetalScoresPivoted_2015	c	on	a.MemberID = c.UniqueMemberID
left join pdb_PharmaMotion..RA_Com_J_MetalScoresPivoted_2016	d	on	a.MemberID = d.UniqueMemberID

/*
select * from pdb_PharmaMotion..Member_updt

select avg(RAF_2014), avg(RAF_2015), avg(RAF_2016) 
from pdb_PharmaMotion..Member_updt

select avg(RAF_2014), avg(RAF_2015), avg(RAF_2016) 
from pdb_PharmaMotion..Member_v2
*/

