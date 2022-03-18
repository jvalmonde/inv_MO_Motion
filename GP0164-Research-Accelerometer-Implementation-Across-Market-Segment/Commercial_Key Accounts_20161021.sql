/******************************************************************************************************
GRANT:  GP164- ACCELEROMETER IMPLEEMENTATION ACCROSS MARKET SEGMENT

******************************************************************************************************/

-------------------------------------------------------------------------------------------------------
--1.  KEY ACCOUNT GROUPS
-------------------------------------------------------------------------------------------------------
--Key Accounts as of Latest data load 201605:
Drop table #KeyAccount	;

SELECT  [Cust_Seg_Sys_Id]
      ,[Year_Mo]
      ,[Co_Id_Rllp]
      ,[Co_Nm]
      ,[Hlth_Pln_Fund_Cd]
      ,b.MKT_SEG_DESC
      ,b.MKT_SEG_RLLP_DESC
      ,[CompanyZip]
      ,[MbrCnt]		--Group Size
      ,[SbrCnt]
Into #KeyAccount
FROM MiniHPDM..Dim_CustSegSysId_Detail  as a 
Join MiniHPDM..Dim_Group_Indicator		as b	on a.Mkt_Seg_Cd=b.MKT_SEG_CD
Where Year_Mo = '201605'		--Latest year_month 
   and MKT_SEG_DESC = 'KEY ACCTS' 
   and CO_NM='UNITED HEALTHCARE'
   And Hlth_Pln_Fund_Cd in ('FI', 'ASO')
--15307
Create unique clustered index UCIx_CustSegSysId on #KeyAccount (Cust_Seg_Sys_Id)



--Market Name:
Drop table #UNET_Market_Latest	;

Select x.*
Into #UNET_Market_Latest
From (
	Select distinct MKT_NBR , MAJ_MKT_NM, MKT_NM
		,OID = Row_Number() over (partition by MKT_NBR Order by MKT_ROW_EFF_DT desc) -- return the Market Name of the most recent Effectivity date
	From udb_ztiangha..UNET_Market
) as X
Where x.OID = 1
--247

Create unique clustered index UCIx_MarktNbr on #UNET_Market_Latest (MKT_NBR)



--List of Current Key Accounts:
Drop table pdb_MarketSegment..Commercial_KeyAccounts_201605	;

Select a.* 
	,b.CUST_SEG_NM
	--,b.ZIP_CD
	,b.ORIG_EFF_DT		--How old was the group 
	,b.HLTH_PLN_REN_DT	 --The date the Customer Segment's group contract is next renewed
	,Group_Age = datediff(day, b.ORIG_EFF_DT	, '2016-05-31') / 365.25
	,b.SALE_OFC_MKT_NBR
	,b.MSTR_GRP_NM
	,b.MKT_SEG_CD
	,b.SIC_CD_SYS_ID
	,b.SIC_CD
	,b.GRP_SIZE_IND_SYS_ID
	,e.MAJ_MKT_NM
	,e.MKT_NM
	,c.Grp_Size_Desc
	,d.MSA
	,d.County
	,d.St_Cd	
Into pdb_MarketSegment..Commercial_KeyAccounts_201605
From #KeyAccount	as a
Join MiniHPDM..Dim_Customer_Segment				as b on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
Left join MiniHPDM..Dim_Group_Size_Indicator	as c on b.GRP_SIZE_IND_SYS_ID = c.GRP_SIZE_IND_SYS_ID
Left join pdb_MarketSegment..Zip_Census			as d on a.CompanyZip = d.Zip	
Left join #UNET_Market_Latest					as e on b.SALE_OFC_MKT_NBR = e.MKT_NBR
--15305
Create unique clustered index UCIx_CustSegSysID on 	pdb_MarketSegment..Commercial_KeyAccounts_201605 (Cust_Seg_Sys_Id)


--Select * from pdb_MarketSegment..Commercial_KeyAccounts_201605

--CHECKING GROUP COUNT:
SElect count(distinct Cust_Seg_Sys_Id)
From pdb_MarketSegment..Commercial_KeyAccounts_201605	
Where Hlth_Pln_Fund_Cd = 'FI' --14,058

SElect count(distinct Cust_Seg_Sys_Id)
From pdb_MarketSegment..Commercial_KeyAccounts_201605	
Where Hlth_Pln_Fund_Cd = 'ASO' --1247


Select distinct St_Cd , CUST_SEG_NM, MbrCnt , SbrCnt
From pdb_MarketSegment..Commercial_KeyAccounts_201605 
Where MbrCnt <> SbrCnt
	and ( St_Cd is not NULL and St_Cd not in ('AK' ,'HI', 'PR' ,'VI'))
	And Hlth_Pln_Fund_Cd = 'FI'

------------------------------------------------------------------------------------------------------------------------
--2 CURRENT MEMBERS
------------------------------------------------------------------------------------------------------------------------

--Key Accounts current members:
Drop table pdb_MarketSegment..Commercial_KeyAccounts_Mbrs_201605 	;

Select distinct a.Co_Id_Rllp
      ,a.Co_Nm
      ,a.Hlth_Pln_Fund_Cd
      ,a.MKT_SEG_DESC
      ,a.MKT_SEG_RLLP_DESC
      ,a.CompanyZip
      ,a.MbrCnt  as Group_Size
      ,a.SbrCnt
      ,a.CUST_SEG_NM
      ,a.ORIG_EFF_DT
      ,a.Group_Age
      ,a.SALE_OFC_MKT_NBR
      ,a.MSTR_GRP_NM
      ,a.MKT_SEG_CD
      ,a.SIC_CD_SYS_ID
      ,a.SIC_CD
      ,a.GRP_SIZE_IND_SYS_ID
      ,a.MAJ_MKT_NM
      ,a.Grp_Size_Desc
      ,a.MSA	as SalesGrp_MSA
      ,a.County as SalesGrp_County
      ,a.St_Cd  as SalesGrp_StCd
	,b.*
	,c.MSA
	,c.County
	,c.St_Cd
Into pdb_MarketSegment..Commercial_KeyAccounts_Mbrs_201605 
From  pdb_MarketSegment..Commercial_KeyAccounts_201605	 as a
Join MiniHPDM..Summary_Indv_Demographic					as b on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id
Left join pdb_MarketSegment..Zip_Census					as c on b.Zip = c.Zip		--Member Zip
Where b.Year_Mo = '201605'
--3,158,387
--00:10:48
Create unique clustered index UCIx_Indv on pdb_MarketSegment..Commercial_KeyAccounts_Mbrs_201605    (Indv_Sys_Id)


---------------------------------------------------------------------------------------------

--Demographics
Select  Cust_Seg_Sys_Id
	,Avg_Age = AVG(Age)
	,Male= count(distinct case when Gdr_Cd = 'M' Then Indv_Sys_Id End )
	,[Male%]= count(distinct case when Gdr_Cd = 'M' Then Indv_Sys_Id End ) * 1.0 / count(distinct Indv_Sys_Id)
	,Female= count(distinct case when Gdr_Cd = 'F' Then Indv_Sys_Id End )
	,Same_MSA_MbrCnt = count(case when SalesGrp_MSA = MSA  Then Indv_Sys_Id End )
From pdb_MarketSegment..Commercial_KeyAccounts_Mbrs_201605 
Group by  Cust_Seg_Sys_Id


--Add the demogrpahics field
Alter table  pdb_MarketSegment..Commercial_KeyAccounts_201605
Add Avg_Age int , Male int , Female int , [Male%] dec(8,4) , Same_MSA_MbrCnt  int ;

Go

Update pdb_MarketSegment..Commercial_KeyAccounts_201605
Set Avg_Age = b.Avg_Age
	,Male	= b.Male
	,Female = b.Female
	,[Male%] = b.[Male%]
	,Same_MSA_MbrCnt = b.Same_MSA_MbrCnt
From pdb_MarketSegment..Commercial_KeyAccounts_201605		as A
Left Join  (
	Select  Cust_Seg_Sys_Id
		,Avg_Age = AVG(Age)
		,Male= count(distinct case when Gdr_Cd = 'M' Then Indv_Sys_Id End )
		,[Male%]= count(distinct case when Gdr_Cd = 'M' Then Indv_Sys_Id End ) * 1.0 / count(distinct Indv_Sys_Id)
		,Female= count(distinct case when Gdr_Cd = 'F' Then Indv_Sys_Id End )
		,Same_MSA_MbrCnt = count(case when SalesGrp_MSA = MSA  Then Indv_Sys_Id End )
	From pdb_MarketSegment..Commercial_KeyAccounts_Mbrs_201605 
	Group by  Cust_Seg_Sys_Id
	)
			as B	on a.Cust_Seg_Sys_Id = b.Cust_Seg_Sys_Id


--Select * from pdb_MarketSegment..Commercial_KeyAccounts_201605

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
--TOP MSA


Select OID = ROW_NUMBER() over( order by count(distinct Indv_Sys_Id) desc)
	,MSA
	,MbrCnt = sum(Group_Size)
	,SbrCnt = sum(SbrCnt)
	,Same_MSA_MbrCnt = (count(case when SalesGrp_MSA = MSA  Then Indv_Sys_Id End ) * 1.0 / sum(Group_Size)) * 100
	,Avg_Age = AVG(Age)
	,Male= count(distinct case when Gdr_Cd = 'M' Then Indv_Sys_Id End )
	,[Male%]= count(distinct case when Gdr_Cd = 'M' Then Indv_Sys_Id End ) * 1.0 / count(distinct Indv_Sys_Id)
	,Female= count(distinct case when Gdr_Cd = 'F' Then Indv_Sys_Id End )
	,CustSeg_CNt = count(distinct Cust_Seg_Sys_ID)
From pdb_MarketSegment..Commercial_KeyAccounts_Mbrs_201605 
Where Hlth_Pln_Fund_Cd = 'FI'
Group by MSA
Order by OID





Select top 100 * from pdb_MarketSegment..Commercial_KeyAccounts_201605
Select top 100 * from pdb_MarketSegment..Commercial_KeyAccounts_Mbrs_201605 

Select datepart(year,HLTH_PLN_REN_DT)
	,datepart(month,HLTH_PLN_REN_DT)
	, count(distinct Cust_Seg_Sys_Id) as Cnt
	,Hlth_Pln_Fund_Cd
From pdb_MarketSegment..Commercial_KeyAccounts_201605
Group by datepart(year,HLTH_PLN_REN_DT)
	,datepart(month,HLTH_PLN_REN_DT) ,Hlth_Pln_Fund_Cd
Order by Hlth_Pln_Fund_Cd


Select * from pdb_MarketSegment..Commercial_KeyAccounts_201605