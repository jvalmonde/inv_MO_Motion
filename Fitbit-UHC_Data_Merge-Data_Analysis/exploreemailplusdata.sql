use pdb_UHCEmails_DS
go

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT DISTINCT
	EmailAddress, 
	AfterThePlus = case when EmailAddress like '%+%_%@%' then SUBSTRING(EmailAddress, CHARINDEX('+', EmailAddress) + 1, CHARINDEX('@', EmailAddress) - CHARINDEX('+', EmailAddress) - 1) else '' end, 
	Domain = lower(case when EmailAddress like '%@%' then SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, 999) else '' end)
into #k
  FROM [pdb_UHCEmails_DS].[dbo].[EmailLookupFile]
  

select count(*), count(distinct EmailAddress) from #k 

select Domain, count(*) ct from #k group by Domain order by count(*) desc
select AfterThePlus, count(*) ct from #k group by AfterThePlus order by count(*) desc
select AfterThePlus, Domain, count(*) ct from #k where AfterThePlus <> '' group by AfterThePlus, Domain order by count(*) desc

select Domain, count(*), 2. * count(*) / sum(count(*)) over() from #k 
--where AfterThePlus <> '' 
group by Domain with rollup order by count(*) desc


