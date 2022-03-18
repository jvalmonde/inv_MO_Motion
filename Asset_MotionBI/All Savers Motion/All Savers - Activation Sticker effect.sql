use Dermsl_reporting; 



/*****ActivationSticker**********/



Drop table #FirstorderforGroups 


 Select GroupId, Min(ActualShipDate) as ActualDeliveryDate 
 		Into #FirstorderforGroups 
FROM (
		Select groupid, Salesorderid,orderDate, ActualShipDate,ScheduledDeliveryDate, ActualDeliveryDate, ParentCustomer 
			,Customerid =  Customername   , SalesOrderStatusName
			,OrderQuantity= Sum(OrderQuantity)
			,Oid = Row_Number()Over(Partition by groupid order by ActualDeliverydate) 

		FROM pdb_DermReporting.dbo.Rpt_DeviceShipments
		Where Salesorderstatusname in('Delivered','New','released','shipped','Staged')
			and Parentcustomer = 'All Savers' --and s1.ActualDeliveryDate is not null 
		--and s1.salesorderid = 4963
		Group by Groupid,salesorderid,OrderDate, ActualShipDate,ScheduledDeliveryDate, ActualDeliveryDate,ParentCustomer, Customername,SalesorderStatusName
			
) a
Group by GroupId



			Left join #FirstorderforGroups fog
				On mgm.OfferCode  = fog.Groupid
go
If Object_Id('pdb_DermReporting.dbo.ActivationStickerRegistrations') is not null 
Drop table pdb_DermReporting.dbo.ActivationStickerRegistrations

Select a.DaysFromEligibility,a.Clientmemberid, a.TotalSteps, a.LookupRuleGroupid, isRegistered , a.ProgramStartDate, msd.RowCreatedDateTime
,Sample = case when a.ProgramStartDate = b.PeriodPolicyStartDate then 'New Employees of New Groups' else 'New Employees of Established Groups' end 
,DaysFromTrueEligibility = datediff(day,msd.RowCreatedDatetime,Date)
--,InitialCohort = Case when a.ProgramStartDate = b.PeriodPolicyStartDate and b.PeriodPolicyNumber = 1 then 1 else 0 end
,RecievedActivationSticker = case when msd.RowCreatedDateTime > '20160527' then 1 else 0 end 
,StickerJune = case when msd.RowCreatedDateTime between '20160528' and getdate()  and a.ProgramStartDate = '20160601' then 'StickerJune' 
						when RowCreatedDateTime between '20160428' and '20160520' and  a.ProgramStartDate = '20160501' then 'NoSticker-May' 
					when msd.RowCreatedDateTime between '20160501' and '20160520'  and a.ProgramStartDate = '20160601' then 'NoStickerJune' 
					when msd.RowCreatedDateTime >= '20160528'  and a.ProgramStartDate = '20160501' then 'StickerMay' 
					else 'Exclude' end 
into pdb_DermReporting.dbo.ActivationStickerRegistrations
FROM dbo.vwActivityForPreloadGroups a
	Inner join Dim_SESAllsaversPolicyYear b
		ON a.LookupRuleGroupid = b.LookupRulegroupid and PeriodPolicyNumber = 1 
	Inner join Dermsl_prod.dbo.Membersignupdata msd on a.Clientmemberid = msd.clientmemberid and msd.LookupRuleGroupid = a.LookupRuleGroupid
Where  b.LookupClientid = 50 
and a.ProgramStartdate in( '20160501' ,'20160601')
and datediff(day,IIF(msd.rowCreatedDatetime > msd.ProgramStartDate,msd.RowCreatedDatetime, msd.RowCreatedDatetime),Date) between 0 and 90
and a.Date	<= '20160707' 
and msd.RowCreatedDatetime >= msd.programstartdate




Select PeriodPolicyStartdate, sum(Registered)*1.00/sum(Eligible )  Rate 
FROM pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates Where DaysFromEligibility = 60
and PeriodPolicyStartdate between '20141001' and '20150930'
Group by PeriodPolicyStartdate
order by PeriodPolicyStartdate

use Dermsl_reporting;
go
If Object_Id('pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates') is not null 
Drop table pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates

Select mgm.LookupRuleGroupid
,ActivationSticker = Case when msd.GroupFirstShipDate > '20160601' then 1 else 0 end
, PeriodPolicyStartDate
,MonthIndex = 
Case when Datepart(Month,PeriodPolicyStartDate) = 1 then  1 
	 when Datepart(Month,PeriodPolicyStartDate) = 2 then  1.02
	 when Datepart(Month,PeriodPolicyStartDate) = 3 then  1.01
	 when Datepart(Month,PeriodPolicyStartDate) = 4 then  .962
	 when Datepart(Month,PeriodPolicyStartDate) = 5 then  .827
	 when Datepart(Month,PeriodPolicyStartDate) = 6 then  .922
	 when Datepart(Month,PeriodPolicyStartDate) = 7 then  .913
	 when Datepart(Month,PeriodPolicyStartDate) = 8 then  .875	
	 when Datepart(Month,PeriodPolicyStartDate) = 9 then  .797
	 when Datepart(Month,PeriodPolicyStartDate) = 10 then  .880
	 when Datepart(Month,PeriodPolicyStartDate) = 11 then  .925
	 when Datepart(Month,PeriodPolicyStartDate) = 12 then  .966
else NULL end 
,QuarterIndex =  case when  Datepart(Month,PeriodPolicyStartDate) between 1 and 3 then 1
				when  Datepart(Month,PeriodPolicyStartDate) between 4 and 6 then 2
				when  Datepart(Month,PeriodPolicyStartDate) between 7 and 9 then 3
				when  Datepart(Month,PeriodPolicyStartDate) between 10 and 12 then 4 ELSE null end 
,DaysFromEligibility = DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date)
,DaysFromEligibility_ShipDate = DateDiff(Day,IIF(PeriodPolicyStartDate > fog.ActualDeliveryDate, PeriodPolicyStartDate, ActualDeliveryDate), v.Date), Registered = sum(v.isRegistered), Count(*) as Eligible 
into pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates 
FROM 
(select  PeriodPolicyStartDate, LookupruleGroupid, Offercode
, RN = row_Number()over(Partition by LookupRulegroupid order by YearMonth), Registered, Eligibles 
FROM Motion_by_Group_by_Month Where periodPolicyNumber = 1 and  LookupClientid = 50  )  mgm 
	Inner join vwActivityForPreloadGroups v   
		ON mgm.LookupRuleGroupid = v.LookupRuleGroupid 
		and mgm.Rn = 1  and v.ProgramStartDate = mgm.PeriodPolicyStartDate
	Inner join (Select LookupRuleGroupid, Min(Convert(Date,rowCreatedDatetime)) as GroupFirstShipDate FROM Dermsl_prod.dbo.Membersignupdata group by LookupRuleGroupid) msd 
		on  msd.LookupRuleGroupid = v.LookupRuleGroupid
	Left join #FirstorderforGroups fog
		On mgm.OfferCode  = fog.Groupid
--Where msd.rowCreatedDatetime between  dateadd(day, -7 ,v.ProgramStartDate ) and msd.ProgramStartDate
Group by mgm.LookupRuleGroupid
, PeriodPolicyStartdate,DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date)
,DateDiff(Day,IIF(PeriodPolicyStartDate > fog.ActualDeliveryDate, PeriodPolicyStartDate, ActualDeliveryDate), v.Date)
,Case when msd.GroupFirstShipDate > '20160601' then 1 else 0 end



--If Object_Id('pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple') is not null 
--Drop table pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple

Select DatePart(Year,PeriodPolicyStartDate) as StartYear, DatePart(Month,PeriodPolicystartdate) as StartMonth, DaysFromeligibility, Registered = sum(registered), Eligible = Sum(Eligible), RegistrationRate = Convert(int,(sum(registered)*1.00/sum(Eligible)) *100)
--into pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple  
FRom
	(
	Select mgm.LookupRuleGroupid
	,ActivationSticker = Case when msd.GroupFirstShipDate > '20160601' then 1 else 0 end
	, PeriodPolicyStartDate
	,DaysFromEligibility = DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date), Registered = sum(v.isRegistered), Count(*) as Eligible 
	FROM 
		(select  PeriodPolicyStartDate, LookupruleGroupid
		, RN = row_Number()over(Partition by LookupRulegroupid order by YearMonth), Registered, Eligibles FROM Motion_by_Group_by_Month Where periodPolicyNumber = 1 and  LookupClientid = 50  
		)  mgm 
			Inner join vwActivityForPreloadGroups v   
				ON mgm.LookupRuleGroupid = v.LookupRuleGroupid 
				and mgm.Rn = 1  and v.ProgramStartDate = mgm.PeriodPolicyStartDate
			Inner join (Select LookupRuleGroupid, Min(Convert(Date,rowCreatedDatetime)) as GroupFirstShipDate FROM Dermsl_prod.dbo.Membersignupdata group by LookupRuleGroupid) msd 
				on  msd.LookupRuleGroupid = v.LookupRuleGroupid
	Group by mgm.LookupRuleGroupid, PeriodPolicyStartdate,DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date),Case when msd.GroupFirstShipDate > '20160601' then 1 else 0 end
	) z
group by  DatePart(Year,PeriodPolicyStartDate) , DatePart(Month,PeriodPolicystartdate) , DaysFromeligibility
order by startmonth, DaysFromEligibility


Select * FROM pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple
Select StartMonth, Avg(RegistrationRate) 
FROM pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple Where (StartYear*100) + StartMonth between 201410 and 201509 and DaysFromEligibility in(30,60,90)  
Group by Startmonth  with rollup
order by Startmonth


Select StartYearQ = case when  StartMonth between 1 and 3 then 1
				when  StartMonth between 4 and 6 then 2
				when  StartMonth between 7 and 9 then 3
				when  StartMonth between 10 and 12 then 4 ELSE null end
, Avg(RegistrationRate) 
FROM pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRatesSimple Where (StartYear*100) + StartMonth between 201410 and 201509 and DaysFromEligibility in(30,60,90)  
Group by case when  StartMonth between 1 and 3 then 1
				when  StartMonth between 4 and 6 then 2
				when  StartMonth between 7 and 9 then 3
				when  StartMonth between 10 and 12 then 4 ELSE null end  with rollup
order by case when  StartMonth between 1 and 3 then 1
				when  StartMonth between 4 and 6 then 2
				when  StartMonth between 7 and 9 then 3
				when  StartMonth between 10 and 12 then 4 ELSE null end


If Object_Id('pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates_Quarter') is not null 
Drop table pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates_Quarter

Select mgm.LookupRuleGroupid, StartYear = datePart(Year,PeriodPolicyStartdate)
,QuarterIndex =  case when  Datepart(Month,PeriodPolicyStartDate) between 1 and 3 then 1.18
				when  Datepart(Month,PeriodPolicyStartDate) between 4 and 6 then .93
				when  Datepart(Month,PeriodPolicyStartDate) between 7 and 9 then .86
				when  Datepart(Month,PeriodPolicyStartDate) between 10 and 12 then 1 ELSE null end

,Quarter =  case when  Datepart(Month,PeriodPolicyStartDate) between 1 and 3 then 1
				when  Datepart(Month,PeriodPolicyStartDate) between 4 and 6 then 2
				when  Datepart(Month,PeriodPolicyStartDate) between 7 and 9 then 3
				when  Datepart(Month,PeriodPolicyStartDate) between 10 and 12 then 4 ELSE null end 
,DaysFromEligibility = DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date), Registered = sum(v.isRegistered), Count(*) as Eligible 
into pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates_Quarter 
FROM 
(select  PeriodPolicyStartDate, LookupruleGroupid
, RN = row_Number()over(Partition by LookupRulegroupid order by YearMonth), Registered, Eligibles 
FROM Motion_by_Group_by_Month Where periodPolicyNumber = 1 and  LookupClientid = 50  )  mgm 
	Inner join vwActivityForPreloadGroups v   
		ON mgm.LookupRuleGroupid = v.LookupRuleGroupid 
		and mgm.Rn = 1  and v.ProgramStartDate = mgm.PeriodPolicyStartDate
	Left join (Select LookupRuleGroupid, Min(Convert(Date,rowCreatedDatetime)) as GroupFirstShipDate FROM Dermsl_prod.dbo.Membersignupdata group by LookupRuleGroupid) msd 
	on  msd.LookupRuleGroupid = v.LookupRuleGroupid
--Where msd.rowCreatedDatetime between  dateadd(day, -7 ,v.ProgramStartDate ) and msd.ProgramStartDate
Group by mgm.LookupRuleGroupid,datePart(Year,PeriodPolicyStartdate),
case when  Datepart(Month,PeriodPolicyStartDate) between 1 and 3 then 1.18
				when  Datepart(Month,PeriodPolicyStartDate) between 4 and 6 then .93
				when  Datepart(Month,PeriodPolicyStartDate) between 7 and 9 then .86
				when  Datepart(Month,PeriodPolicyStartDate) between 10 and 12 then 1 ELSE null end
, case when  Datepart(Month,PeriodPolicyStartDate) between 1 and 3 then 1
				when  Datepart(Month,PeriodPolicyStartDate) between 4 and 6 then 2
				when  Datepart(Month,PeriodPolicyStartDate) between 7 and 9 then 3
				when  Datepart(Month,PeriodPolicyStartDate) between 10 and 12 then 4 ELSE null end ,DateDiff(Day,IIF(PeriodPolicyStartDate > GroupFirstShipDate, PeriodPolicyStartDate, GroupFirstShipDate), v.Date)

Select Distinct StartYear, Quarter, DaysFRomEligibility FROM pdb_DermReporting.dbo.ActivationStickerRegistrations_GroupRates_Quarter order by StartYear, Quarter, DaysFRomEligibility 


Select mgm.*
FROM 
(select  PeriodPolicyStartDate, LookupruleGroupid
, RN = row_Number()over(Partition by LookupRulegroupid order by YearMonth), Registered, Eligibles 
FROM Motion_by_Group_by_Month Where periodPolicyNumber = 1 and  LookupClientid = 50  )  mgm 
	Inner join vwActivityForPreloadGroups v   
		ON mgm.LookupRuleGroupid = v.LookupRuleGroupid 
		and mgm.Rn = 1  and v.ProgramStartDate = mgm.PeriodPolicyStartDate
	Inner join (Select LookupRuleGroupid, Min(Convert(Date,rowCreatedDatetime)) as GroupFirstShipDate FROM Dermsl_prod.dbo.Membersignupdata group by LookupRuleGroupid) msd 
	on  msd.LookupRuleGroupid = v.LookupRuleGroupid
Where PeriodPolicyStartDate >= '20160901'