
select SavvyHICN, 	   
       year(RunDate) as Yr,
	   cast(year(RunDate) as varchar)+right('00'+cast(month(RunDate) as varchar),2) as Year_Mo, 
	   cast(RunDate as date) as Event_Date,
	   HCC, Flag
into #mor_unpivot
from pdb_WalkandWin..WnW_Dataset_Sam_MOR unpivot(Flag for HCC in(
       [DiseaseCoefficientsHCC1]
      ,[DiseaseCoefficientsHCC2]
      ,[DiseaseCoefficientsHCC5]
      ,[DiseaseCoefficientsHCC7]
      ,[DiseaseCoefficientsHCC8]
      ,[DiseaseCoefficientsHCC9]
      ,[DiseaseCoefficientsHCC10]
      ,[DiseaseCoefficientsHCC15]
      ,[DiseaseCoefficientsHCC16]
      ,[DiseaseCoefficientsHCC17]
      ,[DiseaseCoefficientsHCC18]
      ,[DiseaseCoefficientsHCC19]
      ,[DiseaseCoefficientsHCC21]
      ,[DiseaseCoefficientsHCC25]
      ,[DiseaseCoefficientsHCC26]
      ,[DiseaseCoefficientsHCC27]
      ,[DiseaseCoefficientsHCC31]
      ,[DiseaseCoefficientsHCC32]
      ,[DiseaseCoefficientsHCC33]
      ,[DiseaseCoefficientsHCC37]
      ,[DiseaseCoefficientsHCC38]
      ,[DiseaseCoefficientsHCC44]
      ,[DiseaseCoefficientsHCC45]
      ,[DiseaseCoefficientsHCC51]
      ,[DiseaseCoefficientsHCC52]
      ,[DiseaseCoefficientsHCC54]
      ,[DiseaseCoefficientsHCC55]
      ,[DiseaseCoefficientsHCC67]
      ,[DiseaseCoefficientsHCC68]
      ,[DiseaseCoefficientsHCC69]
      ,[DiseaseCoefficientsHCC70]
      ,[DiseaseCoefficientsHCC71]
      ,[DiseaseCoefficientsHCC72]
      ,[DiseaseCoefficientsHCC73]
      ,[DiseaseCoefficientsHCC74]
      ,[DiseaseCoefficientsHCC75]
      ,[DiseaseCoefficientsHCC77]
      ,[DiseaseCoefficientsHCC78]
      ,[DiseaseCoefficientsHCC79]
      ,[DiseaseCoefficientsHCC80]
      ,[DiseaseCoefficientsHCC81]
      ,[DiseaseCoefficientsHCC82]
      ,[DiseaseCoefficientsHCC83]
      ,[DiseaseCoefficientsHCC92]
      ,[DiseaseCoefficientsHCC95]
      ,[DiseaseCoefficientsHCC96]
      ,[DiseaseCoefficientsHCC100]
      ,[DiseaseCoefficientsHCC101]
      ,[DiseaseCoefficientsHCC104]
      ,[DiseaseCoefficientsHCC105]
      ,[DiseaseCoefficientsHCC107]
      ,[DiseaseCoefficientsHCC108]
      ,[DiseaseCoefficientsHCC111]
      ,[DiseaseCoefficientsHCC112]
      ,[DiseaseCoefficientsHCC119]
      ,[DiseaseCoefficientsHCC130]
      ,[DiseaseCoefficientsHCC131]
      ,[DiseaseCoefficientsHCC132]
      ,[DiseaseCoefficientsHCC148]
      ,[DiseaseCoefficientsHCC149]
      ,[DiseaseCoefficientsHCC150]
      ,[DiseaseCoefficientsHCC154]
      ,[DiseaseCoefficientsHCC155]
      ,[DiseaseCoefficientsHCC157]
      ,[DiseaseCoefficientsHCC158]
      ,[DiseaseCoefficientsHCC161]
      ,[DiseaseCoefficientsHCC164]
      ,[DiseaseCoefficientsHCC174]
      ,[DiseaseCoefficientsHCC176]
      ,[DiseaseCoefficientsHCC177]
	)) as Unpiv
where Flag = 'True'
-- 2,183,547


-- drop table pdb_WalkandWin..LTV_Member_Events_2016_Pilot
select SavvyHICN, Year_Mo, Event_Date, 
	   case when RN_Global = 1 then 'HCC Diagnosed' 
		    when RN_Year = 1 then 'HCC Documented' end as Event_Type,
	   b.HCCNbr as HCC_Nbr, b.TermLabel as HCC_Desc
into pdb_WalkandWin..LTV_Member_Events_2016_Pilot
from(
	select SavvyHICN, Year_Mo, Event_Date, HCC, 
		   row_number() over(partition by SavvyHICN, HCC, Yr order by Event_Date) as RN_Year,
		   row_number() over(partition by SavvyHICN, HCC order by Event_Date) as RN_Global
	from #mor_unpivot
	) as a
left join(
  select HCCNbr, TermLabel
  from RA_Medicare..ModelTerm
  where ModelID = 3
    and HCCNbr is not null
	) as b	on right(HCC, len(HCC)-len('DiseaseCoefficientsHCC')) = b.HCCNbr
where RN_Year = 1 or RN_Global = 1
-- 292572


create index ix_y on pdb_WalkandWin..LTV_Member_Events_2016_Pilot(SavvyHICN, Year_Mo)