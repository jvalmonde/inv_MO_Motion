/****** Script for SelectTopNRows command from SSMS  ******/
/****Member Report for Key Account UHOne****/

  Select  PolicyNumber = b.Offercode
  , a.ProgramStartdate
  ,b.RuleGroupname
  ,Membername
  ,Clientmemberid as SystemID 
  ,Relationship = Right(Clientmemberid , 2) 
  ,isRegistered = Case when AccountVerifiedFlag = 1 then 'Yes' else 'No' end 
  ,DateofEnrollment = AccountVerifiedDatetime 
  FROM Dermsl_Prod.dbo.MemberSignupdata a
	Inner join Dermsl_PRod.dbo.LookupRuleGroup b
		ON a.LookupRUleGroupid = b.LookupRuleGroupid
	Inner join Dermsl_Prod.dbo.LookupClient c 
		On b.LookupClientid = c.LookupClientid  
  Where  c.Clientname = 'Key Accounts UHCM' and a.ActiveFlag = 1  and Rulegroupname not like
  '%Key%Accounts%Test%'