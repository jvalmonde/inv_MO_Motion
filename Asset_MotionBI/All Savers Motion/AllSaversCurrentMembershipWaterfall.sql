/****** Script for SelectTopNRows command from SSMS  ******/

Select AllSaversHealthPlanMembers = sum(AllSaversHealthPlanMembers)
,AllSaversMotionEligibles		 = sum(AllSaversMotionEligibles)
,AllSavesMotionRegistered         = sum(AllSavesMotionRegistered)
FROM 
(SELECT 
Policyid
,AllSaversHealthPlanMembers		  = Count(*)
,AllSaversMotionEligibles         = Max(lc.eligibles)
,AllSavesMotionRegistered         = Max(lc.Registered)
FROM [pdb_ABW].[dbo].[MotionClients] lc
	Inner join allsAvers_prod.dbo.Dim_memberDetailFinancial dm on Replace(lc.OfferCode ,'-','00') = dm.PolicyID
	and dm.YearMo = 201611 and InsuredFlag = 1 
Group by Policyid 
) a


Select AllSaversHealthPlanMembers = sum(AllSaversHealthPlanMembers)
,AllSaversMotionEligibles		 = sum(AllSaversMotionEligibles)
FROM 
(SELECT 
Policyid
,AllSaversHealthPlanMembers		  = Count(*)
,AllSaversMotionEligibles         = Max(lc.eligibles)
  FROM [pdb_ABW].[dbo].[MotionClients] lc
	Inner join allsAvers_prod.dbo.Dim_memberDetail dm on Replace(lc.OfferCode ,'-','00') = dm.PolicyID
	and dm.YearMo = 201611 and InsuredFlag = 1 
Group by Policyid 
) a

Select sum(eligibles), sum(registered) FROM   [pdb_ABW].[dbo].[MotionClients] where lookupClientid = 175