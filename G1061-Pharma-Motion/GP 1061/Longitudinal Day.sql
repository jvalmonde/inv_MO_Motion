/*** 
GP 1061 Pharmacy & Motion -- Longitudinal day pivoted

Input databases:	AllSavers_Prod, pdb_AllSavers_Research

Date Created: 15 June 2017
***/

--create index ix_Member_DIMID on pdb_PharmaMotion..Member_v2 (Member_DIMID);

--select count(*) from pdb_PharmaMotion..Member_v2 where Motion = 1	--31,506

if object_id('tempdb..#dailysteps') is not null
   drop table #dailysteps;

select a.MemberID, a.Member_DIMID, a.SystemID
	, e.BegDate, e.CurYear, e.QtrNbr
	, [Day_1],[Day_2],[Day_3],[Day_4],[Day_5],[Day_6],[Day_7],[Day_8],[Day_9],[Day_10],[Day_11],[Day_12],
	  [Day_13],[Day_14],[Day_15],[Day_16],[Day_17],[Day_18],[Day_19],[Day_20],[Day_21],[Day_22],[Day_23],
	  [Day_24],[Day_25],[Day_26],[Day_27],[Day_28],[Day_29],[Day_30],[Day_31],[Day_32],[Day_33],[Day_34],
	  [Day_35],[Day_36],[Day_37],[Day_38],[Day_39],[Day_40],[Day_41],[Day_42],[Day_43],[Day_44],[Day_45],
	  [Day_46],[Day_47],[Day_48],[Day_49],[Day_50],[Day_51],[Day_52],[Day_53],[Day_54],[Day_55],[Day_56],
	  [Day_57],[Day_58],[Day_59],[Day_60],[Day_61],[Day_62],[Day_63],[Day_64],[Day_65],[Day_66],[Day_67],
	  [Day_68],[Day_69],[Day_70],[Day_71],[Day_72],[Day_73],[Day_74],[Day_75],[Day_76],[Day_77],[Day_78],
	  [Day_79],[Day_80],[Day_81],[Day_82],[Day_83],[Day_84],[Day_85],[Day_86],[Day_87],[Day_88],[Day_89],[Day_90]  
into #dailysteps
from pdb_PharmaMotion..Member_v2	a
inner join pdb_Allsavers_Research..ASM_xwalk_Member				b	on	a.Member_DIMID = b.Member_DIMID
inner join pdb_Allsavers_Research.etl.DERM_xwalk_Member			c	on	b.SystemID = c.aSystemid
inner join pdb_Allsavers_Research.etl.AS_DERM_Members			d	on	d.ClientMEMBERID = c.dSystemID
inner join pdb_Allsavers_Research.etl.AS_DERM_ElapsedQtrDays	e	on	e.MemberID = d.MEMBERID
--(33698 row(s) affected)
create index uIx_MemberID on #dailysteps (SystemID, Member_DIMID);

select count(distinct Member_DIMID), count(distinct SystemID)  from #dailysteps	--28105

/** UPIVOT **/
If (object_id('pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted') Is Not Null)
Drop Table pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted
go

DECLARE @query AS NVARCHAR(MAX);

DECLARE @cols AS NVARCHAR(MAX);

select @cols = STUFF(
								(SELECT distinct ',' + QUOTENAME(name)
								  from tempdb.sys.columns where object_id = object_id('tempdb..#dailysteps')
								 -- where table_name = 'dailysteps'
									AND name <> 'MemberID' 
									and name <> 'SystemID' 
									AND name <> 'Member_DIMID' 
									AND name <> 'BegDate'
									and name <> 'CurYear'
									And name <> 'QtrNbr'
								  FOR XML PATH(''), TYPE
								 ).value('.', 'NVARCHAR(MAX)') 
							, 1, 1, ''
							);

SELECT @query = '
select MemberID, SystemID, Member_DIMID, BegDate, CurYear, QtrNbr, convert(smallint,replace(Col, ''Day_'','''')) as Day, Steps
into pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted
from (
select MemberID, SystemID, Member_DIMID, BegDate, CurYear, QtrNbr, ' + @cols + '
from #dailysteps
) as sub1
unpivot
(
Steps 
for Col in (' + @cols + ')
) as unpiv';

EXECUTE(@query);
--(7,444,980 row(s) affected)

--select * from pdb_PharmaMotion..Longitudinal_Day_Pivoted where memberID = 12747

If (object_id('pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted_dt') Is Not Null)
Drop Table pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted_dt
go

select *
	, Day_Adjusted = row_number() over(partition by MemberID order by CurYear, QtrNbr, Day)
	, Full_Dt = dateadd(dd, (row_number() over(partition by MemberID order by CurYear, QtrNbr, Day))-1, BegDate)
into pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt
from pdb_PharmaMotion..Longitudinal_Day_Pivoted
--where MemberID = 162491
--(7,444,980 row(s) affected)
create index uIx_MemberID_Dt on pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt (SystemID, Member_DIMID, Full_Dt);

/*
select *
from pdb_Allsavers_Research..DERMEnrollmentBasis
where Member_DIMID = '92847A428B016CF9BAA0E9D81B4306B8'

select *
from #dailysteps
--where MemberID = 95899	--50655
where SystemID = 54000025060000900
order by BegDate, QtrNbr

select SystemID, count(*)	--68
--select MemberID, count(*)
from	(
			select MemberID, SystemID, Member_DIMID, BegDate
			from #dailysteps
			group by MemberID, SystemID, Member_DIMID, BegDate
		) z
group by SystemID
having count(*) > 1
--40

select *
from pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt
where MemberID = 418339
order by BegDate, Day_Adjusted

select count(distinct Member_DIMID)	--28,105
from  pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt

select count(distinct Member_DIMID)	--23,681
from pdb_PharmaMotion..Member_v2
where WithSteps = 1

--select distinct a.Member_DIMID, BegDate, c.*
select case when sum(Step_Cnt) > 0	then count(distinct SystemID)	end
	, case when sum(Step_Cnt) = 0	then count(distinct SystemID)	end
select *
from	(
			select d.MemberID, d.SystemID, d.YearMo, d.Enrl_Motion, d.Step_Cnt
			--select count(distinct b.SystemID)
			from pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt	a
			left join	(
							select *
							from pdb_PharmaMotion..Member_v2
							where WithSteps = 1
						)				b	on	a.Member_DIMID = b.Member_DIMID
			--inner join pdb_Allsavers_Research..DERMEnrollmentBasis	c	on	a.Member_DIMID = c.Member_DIMID
			--															and a.BegDate = c.FirstEnrolled			--4424
			inner join pdb_PharmaMotion..MemberSummary_v2			d	on	a.SystemID = d.SystemID
			where b.Member_DIMID is null
			--where a.SystemID = 54000051550000100
			group by d.MemberID, d.SystemID, d.YearMo, d.Enrl_Motion, d.Step_Cnt
		) z
where Step_Cnt = 0
--having sum(Step_Cnt) = 0
order by d.SystemID, d.YearMo

select *
from pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt
where SystemID = 54000051550000100
order by full_Dt

select format(BegDate, 'yyyyMM')
	, count(distinct Member_DIMID)
from	(
select a.Member_DIMID, BegDate
from pdb_PharmaMotion..Longitudinal_Day_Pivoted_dt	a
left join	(
				select *
				from pdb_PharmaMotion..Member_v2
				where WithSteps = 1
			)				b	on	a.Member_DIMID = b.Member_DIMID
								and a.BegDate = b.Mbr_EnrolledMotionDate
--inner join 
where b.Member_DIMID is null
group by a.Member_DIMID, BegDate
--order by 1, 2
		) z
group by format(BegDate, 'yyyyMM')
*/

If (object_id('tempdb..#memberstatus') Is Not Null)
Drop Table #memberstatus
go

select SystemID, Full_Dt
	, Member_Status = case when (sum(Steps) over(partition by MemberID, SystemID, Member_DIMID, BegDate order by Full_Dt rows between 7 preceding and current row)) >= 300	then 'Active'
							when (sum(Steps) over(partition by MemberID, SystemID, Member_DIMID, BegDate order by Full_Dt rows between current row and unbounded following)) is null	then 'Cancelled'	else 'Not Active'	end
into #memberstatus
from pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted_dt
--where MemberID = 85223
--where Member_DIMID = 'E1ED57881DC10FDABED09B3D2F690F5A'
order by Full_Dt
--(7,444,980 row(s) affected)
create index ix_SystemID_Dt on #memberstatus (SystemID, Full_Dt);

alter table pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted_dt
	add Member_Status varchar(15)
go

update pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted_dt
set Member_Status = b.Member_Status
from pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted_dt	a
inner join #memberstatus								b	on	a.SystemID = b.SystemID
															and a.Full_Dt = b.Full_Dt
--(7444980 row(s) affected)

select *
from pdb_PharmaMotion.dbo.Longitudinal_Day_Pivoted_dt