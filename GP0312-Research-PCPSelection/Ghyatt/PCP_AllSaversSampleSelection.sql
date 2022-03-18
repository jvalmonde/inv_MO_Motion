use pdb_Dermreporting;
go 
Alter procedure dbo.GP312_GroupSelectionandAssignment 
as 
begin 
set nocount on ;

 /*******Declare groups to withhold from this treatment, will need to add new groups monthly. Stratify by Group age, group size and group registration rate***************/
If object_Id('[pdb_abw].dbo.TreatmentGroups') is not null 
Drop table pdb_abw.dbo.TreatmentGroups
 Select LookupRuleGroupid
 , a.GroupEligibleSize
 , a.GroupAge
 , GroupRegistrationRate
 , MotionStartdate
 ,AllSaversStartDate,
StateCd,
	 a.Eligibles
	 ,a.Registered 
	 ,Treatment  = Case when NTILE(2) over(Partition by   a.GroupEligibleSize, a.GroupAge, GroupRegistrationRate order by Newid()) = 1 then 'T' else 'C' end 
into pdb_abw.dbo.TreatmentGroups
 FROM 
	(
	 Select a.LookupRuleGroupid, 
	 Eligibles
	 ,Registered
	 ,a.State as Statecd
	,GroupEligibleSize = Ntile(10) over(order by Eligibles) 
	,GroupRegistrationRate = Ntile(10) over(order by Registered *1.00/Eligibles) 
	,GroupAge              = NTILE(10) over(order by Datediff(day,StartDate,getdate()))
	,MotionStartdate = StartDate
	,AllSaversStartDate = c.AllSaversStart
	,Rn = Row_number() over(Partition by a.Lookuprulegroupid order by a.YearMonth desc)
	  FROM Motion_by_Group_by_Month  a
		Inner join (Select LookupRuleGroupid, Min(PeriodPolicyStartDate) as StartDate From Motion_by_group_by_month Group by LookupRulegroupid) b
			on a.LookupRuleGroupid = b.LookupRuleGroupid
		Left join (Select Policyid, Min(YearMo) as StartYearMo, Min(Convert(Date,Convert(Varchar,YearMo) + '01')) as AllSaversStart From Devsql10.AllSavers_Prod.dbo.Dim_Policy dp Group by Policyid) c
			On replace(a.Offercode,'-','00') = c.Policyid
	 where Clientname = 'All Savers Motion'  and a.yearmonth >= '201606'  --use yearmonth of current data.
	 and not exists ( Select * FROM Devsql10.pdb_AllSavers_PcpSelection.dbo.TreatmentGroups tg where a.Lookuprulegroupid = tg.LookupruleGroupId)
	 ) a
Where rn = 1  and StateCd Not in('Ca','Nj','MA')

Select * FROM pdb_abw.dbo.TreatmentGroups

End 


go

Alter procedure  dbo.GP312_MemberSelectionandAssignment
as 
begin 
set nocount on ;

 /****next step will be to add the members of those groups that are renewing or starting in June so that we can mail out. 
  Can set the rule as >= June and <= today + 20****/
 If Object_Id('pdb_abw.dbo.TreatmentMembers') is not null
 Drop table pdb_abw.dbo.TreatmentMembers

 Select tg.Treatment
 ,de.Clientmemberid
 ,tg.LookupRulegroupid 
 , tg.Eligibles as Trio_GroupEligibles
 , Trio_GroupRegistered = tg.Registered
 , Trio_GroupAgeDecile = tg.GroupAge
 , Trio_StartDate = tg.MotionStartdate
 , AllSavers_StartDate =isnull(tg.AllSaversStartDate,tg.MotionStartdate)
 , GroupEligibleSizeDecil =  tg.GroupEligibleSize
 , GroupRegistrationRateDecile = tg.GroupRegistrationRate
 ,de.LOOKUPClientID 
 ,de.ActiveFlag
 ,de.Birthdate
 ,de.Gendercode
 ,de.Firstname
 ,de.Lastname
 ,de.AddressLine
 ,de.City
 ,de.StateCode
 ,de.ZipCode
,Phone = dbo.RemoveNonNumericCharacters(de.HomePhone)
 ,de.ProgramStartDate
 ,TriomotionRegistered = de.AccountVerifiedFlag
 ,TrioMotionRegistrationDate = de.AccountVerifiedDateTime
 , RunDate = Getdate()
Into pdb_abw.dbo.TreatmentMembers 
   FROM Dermsl_prod.dbo.MemberSignupdata  de 
	Inner join Devsql10.pdb_AllSavers_PCPSelection.dbo.TreatmentGroups tg
		ON de.LookupRuleGroupid = tg.LookupRuleGroupid
 where (Programstartdate between '20160801' and dateadd(day,20,Getdate())  or ProgramStartdate between '20150801' and dateadd(day,60,'20150801') ) and de.ActiveFlag = 1 
 and isnull(CancelledDatetime,getdate() + 60)  >= getdate() + 60 
 and datediff(year,Birthdate,getdate()) > 18 
 and Right(Clientmemberid,2) = '00'
 and not exists(Select * FROM Devsql10.pdb_AllSavers_PCPSelection.dbo.TreatmentMembers tm where de.clientmemberid = tm.clientmemberid)
 and len(dbo.RemoveNonNumericCharacters(de.HomePhone)) = 10 
 Select * FROM pdb_abw.dbo.TreatmentMembers





 ENd 


Select Treatment = iif(Treatment = 'T' , 'Treatment' , 'Control'  )
, EmployerGroups = Count(distinct a.LookupRuleGroupid) , Members = Count(Distinct Clientmemberid) 
FROM 
( 
Select a.*, c.ClientMEMBERID
FROM Devsql10.pdb_AllSavers_PCPSelection.dbo.TreatmentGroups a 
Inner join Devsql10.pdb_AllSavers_PCPSelection.dbo.TreatmentMembers c on a.LookupRuleGroupid = c.LookupruleGroupid
) a 
--where  --StateCd in ('CA','NJ','MA')
group by iif(Treatment = 'T' , 'Treatment' , 'Control'  )
order by count(*) desc
