/*
Note that James had different scripts for the 2016 and 2017 (LTV) Pilots. My scripts will run both.

Done:
	*LTV_Member_Month_2016_Pilot
		--relies on WnW_Dataset_Sam_sg2016, which I get from the current version of DEVSQL14.pdb_WalkandWin.dbo.WnW_Dataset_Sam. Accurate?
		James script:	LTV_Member_Month_WnW_Dataset_Sam2.sql
		Seth scripts:	01_GetMemberList.sql
						02_CombinedfHelperTables_Pilot.sql
						03_LTV_Member_Month_tables.sql

	LTV_Member_Lifetime_ID_2016_Pilot
		James script:	LTV_Member_Lifetime_ID_WnW_Dataset_Sam.sql
		Seth script:	04_LTV_Member_Lifetime_ID_tables.sql
		depends on:		LTV_Member_Month_2016_Pilot

	LTV_Member_Enrollment_2016_Pilot
		--WnW_Dataset_Sam_TRR is as of 9/19/2017. updated enough?
		James script:	LTV_Member_Enrollment_Disenrollment_2017_WnW_Dataset_Sam.sql
		Seth script:	05_LTV_Member_Enrollment_Disenrollment_tables.sql
		depends on:		LTV_Member_Lifetime_ID_2016_Pilot		
						LTV_Member_Month_2016_Pilot			
						WnW_Dataset_Sam_TRR

	LTV_Member_Disenrollment_2016_Pilot
		James script:	LTV_Member_Enrollment_Disenrollment_2017_WnW_Dataset_Sam.sql
		Seth script:	05_LTV_Member_Enrollment_Disenrollment_tables.sql
		depends on:		LTV_Member_Lifetime_ID_2016_Pilot		
						LTV_Member_Month_2016_Pilot			
						WnW_Dataset_Sam_TRR

	LTV_Member_Lifetime_2016_Pilot
		James script:	LTV_Member_Lifetime_2017_WnW_Dataset_Sam.sql
		Seth Script:	06_LTV_Member_Lifetime_tables.sql
		depends on:		LTV_Member_Lifetime_ID_2016_Pilot
						LTV_Member_Enrollment_2016_Pilot

	LTV_Member_Demographics_2016_Pilot
		--WnW_Dataset_Sam_MMR is as of 9/19/2017. updated enough?
		James script:	LTV_Member_Demographics_2017_WnW_Dataset_Sam.sql
		Seth Script:	07_LTV_Member_Demographics_tables
		depends on:		LTV_Member_Lifetime_ID_2016_Pilot		
						WnW_Dataset_Sam_MMR

	New_Member_Information_2016_Pilot
		James script:	New to UHC Members_WnW_Dataset_Sam.sql
		Seth script:	08_New_Member_Information_tables.sql

	RAF_2016_Pilot
		James script:	<it's complicated>
		Seth script:	09_RAF_tables.sql

*/




select *
from INFORMATION_SCHEMA.COLUMNS
where COLUMN_NAME like '%2016%' and TABLE_NAME like '%ORIGINAL%'

select *
from INFORMATION_SCHEMA.TABLES
where TABLE_NAME like '%PILOT%ORIGINAL%' 



