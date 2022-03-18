use pdb_Allsavers_Research;

-- This process uses the Commercial RAF calculator to develop a list of HCC for members
-- There are two phases: 1) create the RAF tables and process; 2) pivot the resulting HCC for use
-- The HCC list is the other half of the claims view for YearMo

-- Build and execute Member RAF / Claim Year

if object_id(N'tempdb..#mbrBasis0') is not null
   drop table #mbrBasis0;

with mbrBasis as (  -- First need member manifest into working table
select distinct Member_DIMID, PolicyYear
  from MemberClaimDetailYY (nolock)
)

select distinct cd.Member_DIMID, cd.PolicyYear, xm.SystemID, AgeYear = cast(cd.PolicyYear as char(4))
     , PolEffDtSysID = d1.DtSysId, PolEndDtSysID = d2.DtSysId, m.MemberID, m.Age
     , gd.PolicyEffYearMo, gd.PolicyEndYearMo
  into #mbrBasis0
  from mbrBasis                          cd
  join MemberSummary            (nolock) ms on cd.Member_DIMID = ms.Member_DIMID
  join GroupDetailYY            (nolock) gd on ms.PolicyID     = gd.PolicyID
                                           and cd.PolicyYear   = gd.PolicyYear
  join ASM_xwalk_Member         (nolock) xm on cd.Member_DIMID = xm.Member_DIMID
  join AllSavers_Prod..Dim_Member (nolock)  m on xm.SystemID   = m.SystemID
  join AllSavers_Prod..Dim_Date (nolock) d1 on gd.PolicyEffDate = d1.FullDt
  join AllSavers_Prod..Dim_Date (nolock) d2 on gd.PolicyEndDate = d2.FullDt
;
 
create clustered index ucix_SID   on #mbrBasis0(SystemID);
create           index ucix_DIMID on #mbrBasis0(Member_DIMID);

--TP:  Select top 100 * from #mbrBasis0  where Member_DIMID in ('00542BF19820097EAF774B325F1FF615')
--TP:  select count(*)  from #mbrBasis0

-- Buildout the Person framework for the RAF calculator; default the Metel to Silver
-- Take note of the addition of policy year to the DIMID, all years are RAF'd at once
-- [process takes awhile...]

declare @AgeBaseDate date = (select Create_Date from AllSavers_Prod.sys.tables where name = 'Dim_Member');
--select @AgeBaseDate, DATEADD(yy,0-64,@AgeBaseDate)

if object_id(N'tempdb..#mbrBasis') is not null
   drop table #mbrBasis;

 select mb.Member_DIMID, mb.PolicyYear, mb.SystemID, mb.MemberID
      , UniqueMemberID = max(mb.Member_DIMID+'_'+mb.AgeYear)
	  , PolEffDtSysID  = max(mb.PolEffDtSysID)
	  , PolEndDtSysID  = max(mb.PolEndDtSysID)
      , GenderCd       = max(md.Gender)
	  , BirthDate      = max(DATEADD(yy,0-md.age,@AgeBaseDate)) --max(md.BirthDate)
	  , AgeLast        = max(md.Age) --datediff(yy,md.BirthDate,convert(date,mb.AgeYear+'-12-31',126)))
	  , Metel          = 'S'
	  , CSR_Indicator  = 0
  into #mbrBasis
  from #mbrBasis0                                mb
  join AllSavers_Prod..Dim_MemberDetail (nolock) md on mb.SystemID   = md.SystemID
                                                   and mb.MemberID   = md.MemberID
                                                   and md.YearMo between mb.PolicyEffYearMo and mb.PolicyEndYearMo
 group by mb.Member_DIMID, mb.PolicyYear, mb.SystemID, mb.MemberID
;

create clustered index ucix_MID   on #mbrBasis(MemberID);
create           index ucix_DIMID on #mbrBasis(Member_DIMID);

--TP:  select top 100 * from #mbrBasis where member_dimid = '00542BF19820097EAF774B325F1FF615'

-- Now, Claims - use only encounter eligible (basis PlaceOfService)
-- Step 01, extract the associated claims requiring DX
--          this is policy year time bracketed

if object_id(N'tempdb..#clmBasis') is not null
   drop table #clmBasis;

select distinct mb.UniqueMemberID, mb.MemberID
     , mb.SystemID, fc.ClaimNumber, fc.SubNumber, fc.ClaimSet  -- what we need for effective claims correlation
	 , DiagnosisServiceDate = convert(date,dt.FullDt,126)
  into #clmBasis
  from #mbrBasis mb
  join AllSavers_Prod..Fact_Claims       (nolock) fc on mb.MemberID    = fc.MemberID
                                          and mb.SystemID = fc.SystemID
										  and fc.ClaimSeq = 1
                                          and fc.ServiceTypeSysID between 1 and 3          -- IP, OP, MD
	                                      and fc.FromDtSysID between mb.PolEffDtSysID and mb.PolEndDtSysID
                                          and fc.PlaceOfService in (11,20,21,22,23,24,25,26,31,32,33,34,49,50,51,52,53,54,55,56,57,61,62,71,72)
  join AllSavers_Prod..Dim_Date          (nolock) dt on fc.FromDtSysID = dt.DtSysId
;

create clustered index ucix_UID   on #clmBasis(UniqueMemberID);
create           index ucix_SidID on #clmBasis(SystemID,ClaimNumber,SubNumber,ClaimSet);

--TP:  select top 100 * from #clmBasis where  uniquememberid like '00542BF19820097EAF774B325F1FF615%'

go  -- reset namespace

-- OK, Construct the RAF calculation Feeds using a meta data driven cursorn


/*  Step 02 -- Score Wars!!

    Apparently, the 2016 Commercial RAF engine does not do ICD9; so, for those years
    where ICD9 is a concern, the 2015 engine must be used.

    Implementation uses a meta table driven cursor to loop through the developed data.
    ** This is mostly common code - exists in BMAS version, too !! **

*/

-- first off, a couple of housekeeping tasks
--    1. Reset the current RAF column to 0.0

-- First off, update the resulting RAF score to ClaimsDetail

update cd   -- reset the RAF value to the MemberClaimDetailYY table
   set RAF = 0.0
  from MemberClaimDetailYY cd
;

--    2. And recreate the HCC table

if exists(select * from pdb_Allsavers_Research.INFORMATION_SCHEMA.TABLES
           where TABLE_NAME = 'MemberHCCDetailYY' and TABLE_SCHEMA = 'DBO')
   drop table pdb_Allsavers_Research.DBO.MemberHCCDetailYY;

CREATE TABLE [DBO].[MemberHCCDetailYY](
	[Member_DIMID] [varchar](32) NULL,
	[PolicyYear] [int] NULL,
	[RAF] [decimal](7, 3) NULL,
	[HCC001] [tinyint] NULL,
	[HCC002] [tinyint] NULL,
	[HCC003] [tinyint] NULL,
	[HCC004] [tinyint] NULL,
	[HCC006] [tinyint] NULL,
	[HCC008] [tinyint] NULL,
	[HCC009] [tinyint] NULL,
	[HCC010] [tinyint] NULL,
	[HCC011] [tinyint] NULL,
	[HCC012] [tinyint] NULL,
	[HCC013] [tinyint] NULL,
	[HCC018] [tinyint] NULL,
	[HCC019] [tinyint] NULL,
	[HCC020] [tinyint] NULL,
	[HCC021] [tinyint] NULL,
	[HCC023] [tinyint] NULL,
	[HCC026] [tinyint] NULL,
	[HCC027] [tinyint] NULL,
	[HCC028] [tinyint] NULL,
	[HCC029] [tinyint] NULL,
	[HCC030] [tinyint] NULL,
	[HCC034] [tinyint] NULL,
	[HCC035] [tinyint] NULL,
	[HCC036] [tinyint] NULL,
	[HCC037] [tinyint] NULL,
	[HCC038] [tinyint] NULL,
	[HCC041] [tinyint] NULL,
	[HCC042] [tinyint] NULL,
	[HCC045] [tinyint] NULL,
	[HCC046] [tinyint] NULL,
	[HCC047] [tinyint] NULL,
	[HCC048] [tinyint] NULL,
	[HCC054] [tinyint] NULL,
	[HCC055] [tinyint] NULL,
	[HCC056] [tinyint] NULL,
	[HCC057] [tinyint] NULL,
	[HCC061] [tinyint] NULL,
	[HCC062] [tinyint] NULL,
	[HCC063] [tinyint] NULL,
	[HCC064] [tinyint] NULL,
	[HCC066] [tinyint] NULL,
	[HCC067] [tinyint] NULL,
	[HCC068] [tinyint] NULL,
	[HCC069] [tinyint] NULL,
	[HCC070] [tinyint] NULL,
	[HCC071] [tinyint] NULL,
	[HCC073] [tinyint] NULL,
	[HCC074] [tinyint] NULL,
	[HCC075] [tinyint] NULL,
	[HCC081] [tinyint] NULL,
	[HCC082] [tinyint] NULL,
	[HCC087] [tinyint] NULL,
	[HCC088] [tinyint] NULL,
	[HCC089] [tinyint] NULL,
	[HCC090] [tinyint] NULL,
	[HCC094] [tinyint] NULL,
	[HCC096] [tinyint] NULL,
	[HCC097] [tinyint] NULL,
	[HCC102] [tinyint] NULL,
	[HCC103] [tinyint] NULL,
	[HCC106] [tinyint] NULL,
	[HCC107] [tinyint] NULL,
	[HCC108] [tinyint] NULL,
	[HCC109] [tinyint] NULL,
	[HCC110] [tinyint] NULL,
	[HCC111] [tinyint] NULL,
	[HCC112] [tinyint] NULL,
	[HCC113] [tinyint] NULL,
	[HCC114] [tinyint] NULL,
	[HCC115] [tinyint] NULL,
	[HCC117] [tinyint] NULL,
	[HCC118] [tinyint] NULL,
	[HCC119] [tinyint] NULL,
	[HCC120] [tinyint] NULL,
	[HCC121] [tinyint] NULL,
	[HCC122] [tinyint] NULL,
	[HCC125] [tinyint] NULL,
	[HCC126] [tinyint] NULL,
	[HCC127] [tinyint] NULL,
	[HCC128] [tinyint] NULL,
	[HCC129] [tinyint] NULL,
	[HCC130] [tinyint] NULL,
	[HCC131] [tinyint] NULL,
	[HCC132] [tinyint] NULL,
	[HCC135] [tinyint] NULL,
	[HCC137] [tinyint] NULL,
	[HCC138] [tinyint] NULL,
	[HCC139] [tinyint] NULL,
	[HCC142] [tinyint] NULL,
	[HCC145] [tinyint] NULL,
	[HCC146] [tinyint] NULL,
	[HCC149] [tinyint] NULL,
	[HCC150] [tinyint] NULL,
	[HCC151] [tinyint] NULL,
	[HCC153] [tinyint] NULL,
	[HCC154] [tinyint] NULL,
	[HCC156] [tinyint] NULL,
	[HCC158] [tinyint] NULL,
	[HCC159] [tinyint] NULL,
	[HCC160] [tinyint] NULL,
	[HCC161] [tinyint] NULL,
	[HCC162] [tinyint] NULL,
	[HCC163] [tinyint] NULL,
	[HCC183] [tinyint] NULL,
	[HCC184] [tinyint] NULL,
	[HCC187] [tinyint] NULL,
	[HCC188] [tinyint] NULL,
	[HCC203] [tinyint] NULL,
	[HCC204] [tinyint] NULL,
	[HCC205] [tinyint] NULL,
	[HCC207] [tinyint] NULL,
	[HCC208] [tinyint] NULL,
	[HCC209] [tinyint] NULL,
	[HCC217] [tinyint] NULL,
	[HCC226] [tinyint] NULL,
	[HCC227] [tinyint] NULL,
	[HCC242] [tinyint] NULL,
	[HCC243] [tinyint] NULL,
	[HCC244] [tinyint] NULL,
	[HCC245] [tinyint] NULL,
	[HCC246] [tinyint] NULL,
	[HCC247] [tinyint] NULL,
	[HCC248] [tinyint] NULL,
	[HCC249] [tinyint] NULL,
	[HCC251] [tinyint] NULL,
	[HCC253] [tinyint] NULL,
	[HCC254] [tinyint] NULL,
	[DateLastGeneration] [datetime] NOT NULL
)

-- Now, on with the show...

declare @RAF_Meta table (ID int identity(1,1), EngineYear char(4), BegEngYY char(4), EndEngYY Char(4));

insert into @RAF_Meta
select '2015', '2014', '2015' union all
select '2016', '2016', '2018'
;

declare @EngineYear char(4), @BegEngYY char(4), @EndEngYY char(4);
declare @ModelVersion varchar(32) = 'Silver';  -- default metal level in use

declare c1 cursor for
select EngineYear, BegEngYY, EndEngYY from @RAF_Meta order by id

open c1
fetch next from c1 into @EngineYear, @BegEngYY, @EndEngYY

while @@FETCH_STATUS = 0
begin

/* TP
declare @EngineYear char(4), @BegEngYY char(4), @EndEngYY char(4);
declare @ModelVersion varchar(32) = 'Silver';  -- default metal level in use
select @EngineYear = '2015', @BegEngYY = '2014', @EndEngYY = '2015'
*/

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'Person')
   drop table pdb_Allsavers_Research.etl.Person;

select UniqueMemberID, GenderCd, BirthDate, AgeLast, Metel, CSR_Indicator
  into etl.Person
  from #mbrBasis
 where right(UniqueMemberID,4) between @BegEngYY and @EndEngYY
;

--create unique clustered index ucix_UMID on etl.Person (UniqueMemberID);

/* TP to determine non-Unique Key Value
select UniqueMemberID
  from etl.Person
 group by UniqueMemberID
having count(uniquememberid) > 1
*/

--TP:  Select top 100 * from etl.person where uniquememberid = '1288C81E5CD90D21C5E8AB97B05640A9_2015'

-- Step 02 - fetch DX and build DX table

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'Diagnosis')
   drop table pdb_Allsavers_Research.etl.Diagnosis;
 
select distinct cb.UniqueMemberID
     , ICDCd    = dx.DiagCd
	 , ICDVerCD = fd.ICDVersionCode
	 , cb.DiagnosisServiceDate
  into etl.Diagnosis
  from #clmBasis cb
  join AllSavers_Prod..Fact_Diagnosis    (nolock) fd on cb.SystemID    = fd.SystemID
                                                    and cb.ClaimNumber = fd.ClaimNumber
													and cb.SubNumber   = fd.SubNumber
													and cb.ClaimSet    = fd.ClaimSet
  join AllSavers_Prod..Dim_DiagnosisCode (nolock) dx on fd.DiagCdSysID = dx.DiagCdSysId 
	                                                and dx.DiagDesc <> 'UNKNOWN DIAGNOSIS'
 where right(cb.UniqueMemberID,4) between @BegEngYY and @EndEngYY
;

--- EXEC RAF Calc

set nocount on  -- don't need the messages

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'RA_Com_I_MetalScores_RAF')
   drop table pdb_Allsavers_Research.dbo.RA_Com_I_MetalScores_RAF,
              pdb_Allsavers_Research.dbo.RA_Com_J_MetalScoresPivoted_RAF,
			  pdb_Allsavers_Research.dbo.RA_Com_K_ModelTerms_RAF;
 
if @EngineYear = '2015' 
   exec RA_Commercial_2015.dbo.spRAFDiagInput 'pdb_Allsavers_Research.etl.Person', 
                                              'pdb_Allsavers_Research.etl.Diagnosis', 
                                              'pdb_Allsavers_Research','RAF'
;

if @EngineYear = '2016' 
   exec RA_Commercial_2016.dbo.spRAFDiagInput 'pdb_Allsavers_Research.etl.Person', 
                                              'pdb_Allsavers_Research.etl.Diagnosis', 
                                              'pdb_Allsavers_Research','RAF'
;
set nocount off

create clustered index ucix_DIMID on RA_Com_I_MetalScores_RAF(UniqueMemberID);
create unique index ucix_DIMID    on RA_Com_J_MetalScoresPivoted_RAF(UniqueMemberID);
create clustered index ucix_DIMID on RA_Com_K_ModelTerms_RAF(UniqueMemberID);

-- phase II, assemble the HCC table after the RAF creates the details

-- First off, update the resulting RAF score to ClaimsDetail

update cd   -- Update the RAF value to the MemberClaimDetailYY table
   set RAF = ra.TotalScore
  from MemberClaimDetailYY cd
  join RA_Com_I_MetalScores_RAF ra on cd.Member_DIMID = left(ra.UniqueMemberID,32)
                                  and cd.PolicyYear    = cast(right(ra.UniqueMemberID,4) as int)
								  and ra.ModelVersion = @ModelVersion
;

-- And now extract and pivot the HCC into table form by policy year

--if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'MemberHCCDetailYY')
--   drop table pdb_Allsavers_Research.dbo.MemberHCCDetailYY;
 
with HCCBasis as (
SELECT distinct HCC = Term
  FROM RA_Commercial_2016.dbo.ModelHCC (nolock)
 where ModelCategoryID in (select ModelCategoryID 
                             from RA_Commercial_2016.dbo.ModelCategory (nolock)
							where ModelID = (select ModelID
							                   from RA_Commercial_2016.dbo.Model (nolock)
											  where ModelVersion = @ModelVersion
											)
						  )
), mbrHCCBasis as (
SELECT mt.UniqueMemberID, RAF = ra.TotalScore, HCC = mt.Term, mt.UsedInCalc
  from RA_Com_K_ModelTerms_RAF  (nolock) mt
  join RA_Com_I_MetalScores_RAF (nolock) ra on mt.UniqueMemberID = ra.UniqueMemberID
                                           and mt.ModelVersion   = ra.ModelVersion
 where 1=1
   and mt.modelversion = @ModelVersion
   and mt.usedincalc   = 1
   and left(mt.term,3) = 'HCC'
), expandIT as (
SELECT tm.UniqueMemberID, tm.RAF, hc.HCC
  from HCCBasis  hc
 cross apply( select distinct UniqueMemberID, RAF from mbrHCCBasis) tm
)

insert into MemberHCCDetailYY
select *, DateLastGeneration = GETDATE()
  from (SELECT Member_DIMID  = left(hc.UniqueMemberID,32)
             , PolicyYear    = cast(right(hc.UniqueMemberID,4) as int)
             , hc.RAF, hc.HCC, UsedInCalc = isnull(mhb.usedincalc,0)
          from expandit  hc
          left join mbrHCCBasis mhb on hc.UniqueMemberID = mhb.UniqueMemberID and hc.HCC = mhb.HCC) a
 pivot (
       max(UsedInCalc)
       for HCC in (
           [HCC001],[HCC002],[HCC003],[HCC004],[HCC006],[HCC008],[HCC009],[HCC010],[HCC011],[HCC012],[HCC013],
           [HCC018],[HCC019],[HCC020],[HCC021],[HCC023],[HCC026],[HCC027],[HCC028],[HCC029],[HCC030],[HCC034],
           [HCC035],[HCC036],[HCC037],[HCC038],[HCC041],[HCC042],[HCC045],[HCC046],[HCC047],[HCC048],[HCC054],
           [HCC055],[HCC056],[HCC057],[HCC061],[HCC062],[HCC063],[HCC064],[HCC066],[HCC067],[HCC068],[HCC069],
           [HCC070],[HCC071],[HCC073],[HCC074],[HCC075],[HCC081],[HCC082],[HCC087],[HCC088],[HCC089],[HCC090],
           [HCC094],[HCC096],[HCC097],[HCC102],[HCC103],[HCC106],[HCC107],[HCC108],[HCC109],[HCC110],[HCC111],
           [HCC112],[HCC113],[HCC114],[HCC115],[HCC117],[HCC118],[HCC119],[HCC120],[HCC121],[HCC122],[HCC125],
           [HCC126],[HCC127],[HCC128],[HCC129],[HCC130],[HCC131],[HCC132],[HCC135],[HCC137],[HCC138],[HCC139],
           [HCC142],[HCC145],[HCC146],[HCC149],[HCC150],[HCC151],[HCC153],[HCC154],[HCC156],[HCC158],[HCC159],
           [HCC160],[HCC161],[HCC162],[HCC163],[HCC183],[HCC184],[HCC187],[HCC188],[HCC203],[HCC204],[HCC205],
           [HCC207],[HCC208],[HCC209],[HCC217],[HCC226],[HCC227],[HCC242],[HCC243],[HCC244],[HCC245],[HCC246],
           [HCC247],[HCC248],[HCC249],[HCC251],[HCC253],[HCC254]	                      )
       ) p

fetch next from c1 into @EngineYear, @BegEngYY, @EndEngYY
end
close c1
deallocate c1
;

create clustered index ucix_DIMID on MemberHCCDetailYY(Member_DIMID);

/*  Use below to generate list of HCC for Pivot Action whenever the model changes


declare @ModelVersion varchar(32) = 'Silver';

SELECT distinct HCC = '['+rtrim(Term)+'],'
  FROM RA_Commercial_2016.dbo.ModelHCC
 where ModelCategoryID in (select ModelCategoryID 
                             from RA_Commercial_2016.dbo.ModelCategory
							where ModelID = (select ModelID
							                   from RA_Commercial_2016.dbo.Model
											  where ModelVersion = @ModelVersion
											)
						  );

[HCC001],[HCC002],[HCC003],[HCC004],[HCC006],[HCC008],[HCC009],[HCC010],[HCC011],[HCC012],[HCC013],
[HCC018],[HCC019],[HCC020],[HCC021],[HCC023],[HCC026],[HCC027],[HCC028],[HCC029],[HCC030],[HCC034],
[HCC035],[HCC036],[HCC037],[HCC038],[HCC041],[HCC042],[HCC045],[HCC046],[HCC047],[HCC048],[HCC054],
[HCC055],[HCC056],[HCC057],[HCC061],[HCC062],[HCC063],[HCC064],[HCC066],[HCC067],[HCC068],[HCC069],
[HCC070],[HCC071],[HCC073],[HCC074],[HCC075],[HCC081],[HCC082],[HCC087],[HCC088],[HCC089],[HCC090],
[HCC094],[HCC096],[HCC097],[HCC102],[HCC103],[HCC106],[HCC107],[HCC108],[HCC109],[HCC110],[HCC111],
[HCC112],[HCC113],[HCC114],[HCC115],[HCC117],[HCC118],[HCC119],[HCC120],[HCC121],[HCC122],[HCC125],
[HCC126],[HCC127],[HCC128],[HCC129],[HCC130],[HCC131],[HCC132],[HCC135],[HCC137],[HCC138],[HCC139],
[HCC142],[HCC145],[HCC146],[HCC149],[HCC150],[HCC151],[HCC153],[HCC154],[HCC156],[HCC158],[HCC159],
[HCC160],[HCC161],[HCC162],[HCC163],[HCC183],[HCC184],[HCC187],[HCC188],[HCC203],[HCC204],[HCC205],
[HCC207],[HCC208],[HCC209],[HCC217],[HCC226],[HCC227],[HCC242],[HCC243],[HCC244],[HCC245],[HCC246],
[HCC247],[HCC248],[HCC249],[HCC251],[HCC253],[HCC254]

*/
