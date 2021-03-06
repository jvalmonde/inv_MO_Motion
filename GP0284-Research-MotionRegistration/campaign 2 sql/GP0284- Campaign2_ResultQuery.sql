/****** Script for SelectTopNRows command from SSMS  ******/

use pdb_AllSaversRegistration;
go 
Create procedure dbo.DirectMailList_Campaign2_Registrations_update

as  

Drop table dbo.DirectMailList_Campaign2_Registrations
SELECT a.*, b.ClientMEMBERID, isregistered = msd.AccountVerifiedFlag, msd.AccountVerifiedDateTime, registeredBeforeMailing = Iif(isnull(msd.AccountVerifiedDatetime,'20161231') < '20160615' ,1,0)
Into dbo.DirectMailList_Campaign2_Registrations
  FROM [pdb_AllSaversRegistration].[dbo].[DirectMailList_Campaign2_TreatmentGroups] a 
	Inner join pdb_AllSaversRegistration.dbo.DirectMailList_Campaign2 b
		ON a.LookupRuleGroupid = b.LookupRulegroupid
	Inner join Dermsl_prod.dbo.Membersignupdata msd 
		ON b.ClientMEMBERID = msd.clientmemberid
