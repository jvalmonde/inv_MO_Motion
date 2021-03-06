use pdb_Allsavers_Research;

declare @ModelVersion varchar(32) = 'Silver';

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
SELECT UniqueMemberID, HCC = Term, UsedInCalc
  from RA_Com_K_ModelTerms_RAF (nolock)
 where 1=1
   and modelversion = @ModelVersion
   and usedincalc   = 1
   and left(term,3) = 'HCC'
), expandIT as (
SELECT tm.UniqueMemberID, hc.HCC
  from HCCBasis  hc
 cross apply( select distinct UniqueMemberID from mbrHCCBasis) tm
)

--TP:  select * from expandit order by 1,2

--SELECT hc.UniqueMemberID, hc.HCC, UsedInCalc = isnull(mhb.usedincalc,0)
--  from expandit  hc
--  left join mbrHCCBasis mhb on hc.UniqueMemberID = mhb.UniqueMemberID and hc.HCC = mhb.HCC

select *
  from (SELECT hc.UniqueMemberID, hc.HCC, UsedInCalc = isnull(mhb.usedincalc,0)
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


/*  Use below to generate list of HCC for Pivot Action


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
