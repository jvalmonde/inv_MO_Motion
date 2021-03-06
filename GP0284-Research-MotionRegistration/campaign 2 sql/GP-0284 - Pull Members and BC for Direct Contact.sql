/****** Script for SelectTopNRows command from SSMS  ******/

SELECT lrg.RuleGroupname, a.*  , Separator = '****************************', de.firstname, de.Lastname, de.HomePhone, awgm.CompanyContactName, FullCompanyContactName, CompanyContactEmail = awgm.Email, CompanyContactPhone = awgm.PhoneNumber
  FROM [pdb_AllSaversRegistration].[dbo].[AllSaversMailing_GroupstoCall] a 
	Inner join Dermsl_prod.dbo.memberSignupdata de 
		ON a.LookupruleGroupid = de.LookupRuleGroupid  and de.ActiveFlag = 1 
	Inner join pdb_DermReporting.dbo.Dim_LookupRuleGroup lrg 
		ON de.LookupRuleGroupid = lrg.LookupRuleGroupid 
	left join (select * , RN = Row_Number()over(Partition by policyid order by loadDate desc) FROM pdb_Dermreporting.dbo.ASIC_Wellness_Group_Motion ) awgm
		ON lrg.RuleGroupOfferCode = awgm.PolicyID
		and awgm.Rn = 1 
order by ruleGroupname 