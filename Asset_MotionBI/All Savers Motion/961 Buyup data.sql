use dermsl_prod;

/***Firt import this query to devsql14.dermreporting_dev.dbo.ASKATrioFITBuyups***/
IF object_Id ('tempdb.dbo.#TrioFITBuyups') is not null 
Drop table #TrioFITBuyups
--select m.MEMBERID,m.FirstName,m.LastName,s.Email,lrg.LOOKUPRuleGroupID,lrg.RuleGroupName,mt.TrioTransactionDate,mt.TrioTransactionvalue
--,p.ProductNumber,p.ProductName  , sod.Quantity
Select m.Memberid,RegistrationDate = m.RowCreatedDateTime, mt.TrioTransactionDate
into #TrioFITBuyups
        from MEMBER m 
        join MEMBERRuleGroup mrg on m.MEMBERID = mrg.MEMBERID 
        join LOOKUPRuleGroup lrg on mrg.LOOKUPRuleGroupID = lrg.LOOKUPRuleGroupID 
        join SYSUser s on m.SYSUserID = s.SYSUserID 
        join MemberTransaction mt on m.MEMBERID = mt.MemberID 
        join pdb_DermReporting.dbo.SalesOrderDetail sod on mt.SalesOrderID = sod.SalesOrderID 
        join Product p on sod.ProductID = p.ProductID 
where MemberTransactionTypeID = 2 
        and m.LOOKUPClientID in (147,50)
        and mrg.LOOKUPRuleGroupID not in (880,881)




/********


How many bought up using FIT credits
How many bought up using CC
How many have paired 961
FIT data
# of groups with multiple people on 961
Before and after results (939 vs 961)
All Savers vs Key Accounts
 

*********/


Select * FROM DermReporting_Dev..Shopifyorders


use dermreporting_dev
Drop table #Upgrades
Select  m.Memberid, m.RowCreatedDateTime as RegistrationDate, a.[Paid at] as TrioTransactionDate , PMethod = 'CC'  
Into #Upgrades 
 FROM DermReporting_Dev..Shopifyorders a 
inner join dermsl_prod.dbo.sysuser su on a.email = su.Email and a.[Fulfillment Status] = 'fulfilled'
inner join dermsl_prod.dbo.member m on su.sysuserid = m.sysuserid
Where [Lineitem sku] like '%961%Kit%' 
union		
Select *, PMethod = 'FITPts' FROM #TrioFITBuyups a  



Select Pmethod, count(*) FROM #Upgrades group by PMethod  ---Count of people who upgraded by Fitpoints or Credit card


/***1533 have upgraded, 29 of those from credit card sales****/

/****x out of x have paired the 961******/
Select  Pmethod,d.Model, UpgradeandPairedCount = Count(*) FROM #Upgrades a 
	Inner join Dermsl_prod.dbo.member b
		ON a.Memberid = b.memberid and b.LOOKUPClientID = 50 
	Inner join StreamlineDevices_Prod.dbo.Member sd 
		ON b.CustomerID = sd.CustomerID
	Inner join StreamlineDevices_Prod.dbo.memberdevice md
		On sd.Memberid = md.memberid and md.Active = 1 
	Inner join StreamlineDevices_Prod.dbo.Device d
		On md.DeviceID = d.DeviceID
		and d.model = '961'
Group by Pmethod, d.Model



Select LOOKUPClientID, count(*) 
FROM #Upgrades a 
	Inner join Dermsl_prod.dbo.member b
		ON a.Memberid = b.memberid and b.LOOKUPClientID in (175, 50 ) 

		group by LOOKUPClientID

/*****How long did it take to upgrade?***********/

Select  TimeToPair = Case when a.TrioTransactionDate is null then 'Never Paired'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) > 30 then '> 30 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 21 then '21 - 30 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 14 then '14 - 21 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 7 then '7 - 14 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 0 then '0 - 7 days'
							Else NULL END
,Count = Count(*) 
 FROM #Upgrades a 
	Inner join Dermsl_prod.dbo.member b
		ON a.Memberid = b.memberid 
Group by Case when a.TrioTransactionDate is null then 'Never Paired'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) > 30 then '> 30 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 21 then '21 - 30 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 14 then '14 - 21 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 7 then '7 - 14 days'
							when datediff(day,RegistrationDate,a.TrioTransactionDate) >= 0 then '0 - 7 days'
							Else NULL END
with rollup					

/*****Look at, for people who bought at least one month after reg, what the average steps are for before and after(2 weeks) from pair date.  x people.*******/


Select -- a.Memberid, d.Model, d.rowCreatedDateTime as Pairdate
Upgrades = Count(Distinct a.Memberid),
AvgSteps2WkPriortoupgrade = Avg(Case when Incentivedate  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime   then totalSteps else null end)
,AvgSteps2WkPostupgrade = Avg(Case when Incentivedate  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)     then totalSteps else null end)
,LogPercent_2WkPriortoupgrade = Count(Case when Incentivedate  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Incentivedate  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then totalSteps else null end  )
,LogPercent_2WkPostupgrade = Count(Case when Incentivedate  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)    and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Incentivedate  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime ) then totalSteps else null end  )
 FROM #Upgrades a 
	Inner join Dermsl_prod.dbo.member b
		ON a.Memberid = b.memberid and b.LOOKUPClientID in( 50 ,147)
	Inner join StreamlineDevices_Prod.dbo.Member sd 
		ON b.CustomerID = sd.CustomerID
	Inner join (Select md.Memberid, d.RowCreatedDateTime, Rn = Row_number()Over(Partition by md.Memberid order by d.rowCreatedDatetime) 
				 FROM StreamlineDevices_Prod.dbo.memberdevice md 
				 Inner join StreamlineDevices_Prod.dbo.Device d On md.DeviceID = d.DeviceID where d.Model = 961) d
		On sd.Memberid = d.memberid and d.rn = 1  	
	Left join Dermsl_prod.dbo.MemberEarnedIncentives  mei
		On a.memberid = mei.memberid 
		and mei.IncentiveDate between dateadd(day,-14,d.rowCreateddatetime) and dateadd(day,14,d.rowcreatedDatetime)
	Inner join Dermsl_prod.dbo.Lookuprule lr 
		On mei.LOOKUPRuleID = lr.LOOKUPRuleID
		and lr.ruleName = 'tenacity'	
Where datediff(day,a.registrationDate, d.RowCreatedDateTime) >= 30    and datediff(day,d.RowCreatedDateTime, getdate()) >= 14 --and d.RowCreatedDateTime <= '20160525' --and mei.RowModifiedDateTime <= '20160525'


Select -- a.Memberid, d.Model, d.rowCreatedDateTime as Pairdate
AvgSteps2WkPriortoupgrade = Avg(Case when Incentivedate  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime   then totalSteps else null end)
,AvgSteps2WkPostupgrade = Avg(Case when Incentivedate  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)     then totalSteps else null end)
, AvgFpoints_2WkPriortoupgrade =  Sum((Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.FPoints else null end)   )*1.00/Sum((Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.PossibleFPoints else null end)   )
,AvgFpoints_2WkPostupgrade =     Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)   then  mei.FPoints else null end))*1.00/Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)   then  mei.PossibleFPoints else null end))
,AvgIpoints_2WkPriortoupgrade =  Sum((Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.IPoints else null end)   )*1.00/Sum((Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.PossibleIPoints else null end)   )
,AvgIpoints_2WkPostupgrade =     Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)   then  mei.IPoints else null end))*1.00/Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)   then  mei.PossibleIPoints else null end))
,AvgTpoints_2WkPriortoupgrade =  Sum((Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.TPoints else null end)   )*1.00/Sum((Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.PossibleTPoints else null end)   )
,AvgTpoints_2WkPostupgrade =     Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)   then  mei.TPoints else null end))*1.00/Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)   then  mei.PossibleTPoints else null end))
,LogPercent_2WkPriortoupgrade = Count(Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then totalSteps else null end  )
,LogPercent_2WkPostupgrade = Count(Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)    and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime ) then totalSteps else null end  )
,Count(Distinct m.Dermsl_memberid) Individuals
,Count(Distinct Case when Full_Dt between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime    and TotalSteps >= 300 then m.Dermsl_memberid else null end)  LoggersPrio
,Count(Distinct Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)    and TotalSteps >= 300 then m.Dermsl_memberid else null end) LoggersAfter
FROM #Upgrades a 
	Inner join Dermsl_prod.dbo.member b
		ON a.Memberid = b.memberid and b.LOOKUPClientID in( 50 ,175) 
	Inner join StreamlineDevices_Prod.dbo.Member sd 
		ON b.CustomerID = sd.CustomerID
	Inner join (Select md.Memberid, d.RowCreatedDateTime, Rn = Row_number()Over(Partition by md.Memberid order by d.rowCreatedDatetime) 
				 FROM StreamlineDevices_Prod.dbo.memberdevice md Inner join StreamlineDevices_Prod.dbo.Device d On md.DeviceID = d.DeviceID where d.Model = 961) d
		On sd.Memberid = d.memberid and d.rn = 1  
	Left join (pdb_DermReporting.dbo.Dim_member m inner join pdb_Dermreporting.dbo.vwProgramActivity_EnrolledDates  mei on m.account_id = mei.Account_ID)
		On a.memberid = m.Dermsl_memberid  
		and mei.Full_Dt between dateadd(day,-14,d.rowCreateddatetime) and dateadd(day,14,d.rowcreatedDatetime)
Where datediff(day,a.registrationDate, d.RowCreatedDateTime) >= 30   and datediff(day,d.RowCreatedDateTime, getdate()) >= 14
--group by  a.Memberid,d.rowCreatedDateTime

Having Count(Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then totalSteps else null end  ) > 0 


/**************************************************/


/*****Look at, for people who bought at least one month after reg, what the average steps are for before and after(4 weeks) from pair date.  568 people.*******/


Select -- a.Memberid, d.Model, d.rowCreatedDateTime as Pairdate
 AvgSteps4WkPriortoupgrade = Avg(Case when Full_dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime   then totalSteps else null end)
,AvgSteps4WkPostupgrade = Avg(Case when    Full_dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)     then totalSteps else null end)

 ,AvgFpoints_4WkPriortoupgrade =  Sum((Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.FPoints else null end)   )*1.00/Sum((Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.PossibleFPoints else null end)   )
,AvgFpoints_4WkPostupgrade =     Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)   then  mei.FPoints else null end))*1.00/Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)   then  mei.PossibleFPoints else null end))
,AvgIpoints_4WkPriortoupgrade =  Sum((Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.IPoints else null end)   )*1.00/Sum((Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.PossibleIPoints else null end)   )
,AvgIpoints_4WkPostupgrade =     Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)   then  mei.IPoints else null end))*1.00/Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)   then  mei.PossibleIPoints else null end))
,AvgTpoints_4WkPriortoupgrade =  Sum((Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.TPoints else null end)   )*1.00/Sum((Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime then mei.PossibleTPoints else null end)   )
,AvgTpoints_4WkPostupgrade =     Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)   then  mei.TPoints else null end))*1.00/Sum((Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)   then  mei.PossibleTPoints else null end))
,LogPercent_4WkPriortoupgrade = Count(Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime then totalSteps else null end  )
,LogPercent_4WkPostupgrade = Count(Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime)    and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,28,d.rowCreateddatetime ) then totalSteps else null end  )
,Count(Distinct m.Dermsl_memberid) Individuals
,Count(Distinct Case when Full_Dt between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime    and TotalSteps >= 300 then m.Dermsl_memberid else null end)  LoggersPrio
,Count(Distinct Case when Full_Dt  between d.RowCreatedDateTime and  dateadd(day,14,d.rowCreateddatetime)    and TotalSteps >= 300 then m.Dermsl_memberid else null end) LoggersAfter
FROM #Upgrades a 
	Inner join Dermsl_prod.dbo.member b
		ON a.Memberid = b.memberid and b.LOOKUPClientID in( 50 ,175) 
	Inner join StreamlineDevices_Prod.dbo.Member sd 
		ON b.CustomerID = sd.CustomerID
	Inner join (Select md.Memberid, d.RowCreatedDateTime, Rn = Row_number()Over(Partition by md.Memberid order by d.rowCreatedDatetime) 
				 FROM StreamlineDevices_Prod.dbo.memberdevice md Inner join StreamlineDevices_Prod.dbo.Device d On md.DeviceID = d.DeviceID where d.Model = 961) d
		On sd.Memberid = d.memberid and d.rn = 1  
	Left join (pdb_DermReporting.dbo.Dim_member m inner join pdb_Dermreporting.dbo.vwProgramActivity_EnrolledDates  mei on m.account_id = mei.Account_ID)
		On a.memberid = m.Dermsl_memberid  
		and mei.Full_Dt between dateadd(day,-28,d.rowCreateddatetime) and dateadd(day,28,d.rowcreatedDatetime)
Where datediff(day,a.registrationDate, d.RowCreatedDateTime) >= 30   and datediff(day,d.RowCreatedDateTime, getdate()) >= 28
--group by  a.Memberid,d.rowCreatedDateTime

Having Count(Case when Full_Dt  between dateadd(day,-28,d.rowCreateddatetime) and d.RowCreatedDateTime and TotalSteps >= 300 then totalSteps else null end)*1.00/count( Case when Full_Dt  between dateadd(day,-14,d.rowCreateddatetime) and d.RowCreatedDateTime then totalSteps else null end  ) > 0 
