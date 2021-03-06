/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  a.[SavvyHICN]
	  ,b.[PilotType]
	  ,b.Incentive_Group
      ,[Invite_Flag]
      ,[Welcome_Flag]
      ,[Registered_Flag]
      ,[ActivatedTrio_Flag]
      ,[Lifetime_ID]
      ,[Enroll_Year_Mo]
      ,[Disenroll_Year_Mo]
      ,[Total_MM]
      ,[Plan_Cnt]
      ,[Total_Revenue]
      ,[Total_Cost]
      ,[Total_Value]
      ,[Enroll_Flag]
      ,[Disenroll_Flag]
      ,[Lifetime_Flag]
      ,[New_Member_Status]
      ,[Lifetime_Type]
into  [pdb_GP1026_WalkandWin_Research].[res].[LTV_Member_Lifetime2]

  FROM [pdb_GP1026_WalkandWin_Research].[res].[LTV_Member_Lifetime] as a
  join [pdb_GP1026_WalkandWin_Research].[final].[GP1026_WnW_Member_Details] as b on convert(varchar,a.savvyhicn) = b.savvyhicn


  select distinct savvyhicn from [pdb_GP1026_WalkandWin_Research].[res].[LTV_Member_Lifetime]