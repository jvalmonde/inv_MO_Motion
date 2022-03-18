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
     , PolEffDtSysID = d1.DtSysId, PolEndDtSysID = d2.DtSysId, m.MemberID
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

--TP:  Select top 100 * from #mbrBasis0  where Member_DIMID in ('582375FCA6E050A415F6E30FF9511B02','ED6748E1B8184AC6F628682777772FB9')
--TP:  select count(*)  from #mbrBasis0

-- Buildout the Person framework for the RAF calculator; default the Metel to Silver
-- Take note of the addition of policy year to the DIMID, all years are RAF'd at once
-- [process takes awhile...]

if object_id(N'tempdb..#mbrBasis') is not null
   drop table #mbrBasis;

 select mb.Member_DIMID, mb.PolicyYear, mb.SystemID, mb.MemberID
      , UniqueMemberID = max(mb.Member_DIMID+'_'+mb.AgeYear)
	  , PolEffDtSysID  = max(mb.PolEffDtSysID)
	  , PolEndDtSysID  = max(mb.PolEndDtSysID)
      , GenderCd       = max(md.Gender)
	  , BirthDate      = max(md.BirthDate)
	  , AgeLast        = max(datediff(yy,md.BirthDate,convert(date,mb.AgeYear+'-12-31',126)))
	  , Metel          = 'S'
	  , CSR_Indicator  = 0
  into #mbrBasis
  from #mbrBasis0                                mb
  join AllSavers_Prod..Dim_MemberDetail (nolock) md on mb.SystemID   = md.SystemID
                                                   and mb.MemberID   = md.MemberID
                                                   and mb.PolicyYear = md.YearMo/100
 group by mb.Member_DIMID, mb.PolicyYear, mb.SystemID, mb.MemberID
;

create clustered index ucix_MID   on #mbrBasis(MemberID);
create           index ucix_DIMID on #mbrBasis(Member_DIMID);

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'Person')
   drop table pdb_Allsavers_Research.etl.Person;

select UniqueMemberID, GenderCd, BirthDate, AgeLast, Metel, CSR_Indicator
  into etl.Person
  from #mbrBasis
;

--create unique clustered index ucix_UMID on etl.Person (UniqueMemberID);

/* TP to determine non-Unique Key Value
select UniqueMemberID
  from etl.Person
 group by UniqueMemberID
having count(uniquememberid) > 1
*/

--TP:  Select top 100 * from etl.person where uniquememberid = '1288C81E5CD90D21C5E8AB97B05640A9_2015'

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
;

--- EXEC RAF Calc

set nocount on  -- don't need the messages

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'RA_Com_I_MetalScores_RAF')
   drop table pdb_Allsavers_Research.dbo.RA_Com_I_MetalScores_RAF,
              pdb_Allsavers_Research.dbo.RA_Com_J_MetalScoresPivoted_RAF,
			  pdb_Allsavers_Research.dbo.RA_Com_K_ModelTerms_RAF;
 
exec RA_Commercial_2016.dbo.spRAFDiagInput 'pdb_Allsavers_Research.etl.Person', 
                                           'pdb_Allsavers_Research.etl.Diagnosis', 
										   'pdb_Allsavers_Research','RAF'
;
set nocount off

create clustered index ucix_DIMID on RA_Com_I_MetalScores_RAF(UniqueMemberID);
create unique index ucix_DIMID    on RA_Com_J_MetalScoresPivoted_RAF(UniqueMemberID);
create clustered index ucix_DIMID on RA_Com_K_ModelTerms_RAF(UniqueMemberID);

go  -- reset namespace

-- phase II, assemble the HCC table after the RAF creates the details

declare @ModelVersion varchar(32) = 'Silver';  -- default metal level in use

-- First off, update the resulting RAF score to ClaimsDetail

update cd   -- Update the RAF value to the MemberClaimDetailYY table
   set RAF = ra.TotalScore
  from MemberClaimDetailYY cd
  join RA_Com_I_MetalScores_RAF ra on cd.Member_DIMID = left(ra.UniqueMemberID,32)
                                  and cd.PolicyYear    = cast(right(ra.UniqueMemberID,4) as int)
								  and ra.ModelVersion = @ModelVersion
;

-- And now extract and pivot the HCC into table form by policy year

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'MemberHCCDetailYY')
   drop table pdb_Allsavers_Research.dbo.MemberHCCDetailYY;
 
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

select *, DateLastGeneration = GETDATE()
  into MemberHCCDetailYY
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
