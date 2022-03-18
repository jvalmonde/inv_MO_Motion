/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [SavvyHICN]
      ,[Lifetime_ID]
      ,left([Year_Mo],4) as Yr
      ,sum([Total_MA_Amt]						) as [Aggregated_Total_MA_Amt]						
      ,sum([Total_D_Amt]					   )  as [Aggregated_Total_D_Amt]					   
      ,sum([Total_CMS_Amt]					   )  as [Aggregated_Total_CMS_Amt]					   
      ,sum([Total_MA_IP_Cost]				   )  as [Aggregated_Total_MA_IP_Cost]				   
      ,sum([Total_MA_OP_Cost]				   )  as [Aggregated_Total_MA_OP_Cost]				   
      ,sum([Total_MA_DR_Cost]				   )  as [Aggregated_Total_MA_DR_Cost]				   
      ,sum([Total_MA_Derived_IP_Cost]		   )  as [Aggregated_Total_MA_Derived_IP_Cost]		   
      ,sum([Total_MA_Derived_OP_Cost]		   )  as [Aggregated_Total_MA_Derived_OP_Cost]		   
      ,sum([Total_MA_Derived_DR_Cost]		   )  as [Aggregated_Total_MA_Derived_DR_Cost]		   
      ,sum([Total_MA_Derived_ER_Cost]		   )  as [Aggregated_Total_MA_Derived_ER_Cost]		   
      ,sum([Total_MA_Derived_DME_Cost]		   )  as [Aggregated_Total_MA_Derived_DME_Cost]		   
      ,sum([Total_MA_Cost]					   )  as [Aggregated_Total_MA_Cost]					   
      ,sum([Total_D_Cost]					   )  as [Aggregated_Total_D_Cost]					   
      ,sum([Total_Claims_Cost]				   )  as [Aggregated_Total_Claims_Cost]				   
      ,sum([Total_MA_OOP]					   )  as [Aggregated_Total_MA_OOP]					   
      ,sum([Total_D_OOP]					   )  as [Aggregated_Total_D_OOP]					   
      ,sum([Total_OOP]						   )  as [Aggregated_Total_OOP]						   
      ,sum([Rx_Rebate_Amt_Full]				   )  as [Aggregated_Rx_Rebate_Amt_Full]				   
      ,sum([Rx_Rebate_Amt_40Percent]		   )  as [Aggregated_Rx_Rebate_Amt_40Percent]		   
      ,sum([LICS_Amt]						   )  as [Aggregated_LICS_Amt]						   
      ,sum([Reinsurance_Amt]				   )  as [Aggregated_Reinsurance_Amt]				   
      ,sum([Premium_C_Amt]					   )  as [Aggregated_Premium_C_Amt]					   
      ,sum([Premium_D_Amt]					   )  as [Aggregated_Premium_D_Amt]					   
      ,sum([TotaL_Premium_Amt]				   )  as [Aggregated_TotaL_Premium_Amt]				   
      ,sum([Total_Revenue]					   )  as [Aggregated_Total_Revenue]					   
      ,sum([Total_Cost_40Percent_Rebate]	   )  as [Aggregated_Total_Cost_40Percent_Rebate]	   
      ,sum([Total_Cost_Full_Rebate]			   )  as [Aggregated_Total_Cost_Full_Rebate]			   
      ,sum([Total_Cost_NoRebate]			   )  as [Aggregated_Total_Cost_NoRebate]			   
      ,sum([Total_Value_40Percent_Rebate]	   )  as [Aggregated_Total_Value_40Percent_Rebate]	   
      ,sum([Total_Value_Full_Rebate]		   )  as [Aggregated_Total_Value_Full_Rebate]		   
      ,sum([Total_Value_NoRebate]			   )  as [Aggregated_Total_Value_NoRebate]			   
      ,max([Top5_Prcnt_2014]				   )  as [Aggregated_Top5_Prcnt_2014]				   
      ,max([Top5_Prcnt_2015]				   )  as [Aggregated_Top5_Prcnt_2015]				   
      ,max([Top5_Prcnt_2016]				   )  as [Aggregated_Top5_Prcnt_2016]	
	  into  [pdb_WalkandWin].[dbo].[LTV_Member_Month_092017_Aggregated]			   
  FROM [pdb_WalkandWin].[dbo].[LTV_Member_Month_092017]
  group by [SavvyHICN]
      ,[Lifetime_ID]
      ,left([Year_Mo],4) 