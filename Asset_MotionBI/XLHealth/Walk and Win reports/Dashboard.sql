use provoqms_prod;

/********Dig into qms/ses to find the members who were sent usb/hub and who has had/not had the welcome call and look at engagement*****/



/****The following tables need to be created from prd-02 ---This is done in the idlememberscallqueue refresh(In the task named "Move tables from Aws to Devsql14 for processing")  this package runs hourly throughout the day. ***/
/****Need to import these tables to the database for reporting:
Dermls_Prod.dbo.WalkandWin_Enrollment  ---> provoqms_Reporting.dbo.WalkandWinEnrollmentCopy
Dermsl_Prod.dbo.Member  --->  provoqms_Reporting.dbo.DermMemberCopy\
Select   m.memberid , SyncingNow = mAx(Case when Incentivedate > DateAdd(Day,-7,getdate()) then 1 else 0 end) 
FROM Member m inner join memberEarnedIncentives mei on m.memberid = mei.Memberid and m.LookupClientid = 125 
 Where TotalSteps >= 300 group by mmemberid   ---DermSync_Copy
******/

If Object_Id('tempdb.dbo.#WalkandWin') is not null 
Drop table #WalkandWin
Select  b.ClientMEMBERID,Dermsl_memberid =  b.memberid, w.* 
into #WalkandWin
FROM provoqms_Reporting.dbo.DermMemberCopy b
	Left join provoqms_Reporting.dbo.WalkandWinEnrollmentCopy w on b.Firstname = w.Fst_Nm and b.Lastname = w.Lst_nm
Where b.LookupClientid = 125 and b.RowCreatedDateTime between '20160501' and  DateAdd(Day,-14,getdate()) and StateCode <> 'MN'



---Determine how many chose usb/hub.
Select responseText, WelcomecallSuccess, Enrolled =  Count(*), Eversynced =  sum(Syncing) , CurrentlySyncing =  Sum(SyncingNow)
FROM 
(
Select  m.Firstname, m.memberid,vm.IndividualSysId, vm.StateCode
,WelcomeCallReach = mcl.Memberid, responseText = convert(varchar(100),csr.ResponseText), csd.ScriptText,Syncing = Case when acc.memberid  is not null then 1 else 0 end  
,Syncingnow =   SyncingNow
,WelcomeCallSuccess = Case when mcl.Memberid is not null then 'Yes' else 'No' end
FROM provoqms_Reporting.dbo.DermMemberCopy m 
			Left join vmember vm 
				On m.memberid = vm.Individualsysid  and vm.TreatmentID in (304,305,316) 
			left join (Select Distinct memberid from membercalllog mcl where mcl.LookupCallStatusid in(16, 2)) mcl
				On vm.memberid = mcl.memberid 
			Left join Treatment t
				On vm.Treatmentid = t.treatmentid
			Left join ( #WalkandWin w
							inner join vmember v on w.Savvyid = v.IndividualSysid
							inner join  CALLScriptParticipant csp  on v.memberid = csp.memberid
							inner join CALLScriptResponse csr On csp.CALLScriptResponseID = csr.CALLScriptResponseID
							inner join CALLScriptDetail csd ON csr.CALLScriptDetailID = csd.CALLScriptDetailID  
															and Convert(Varchar(max),ScriptText) = 'All right, thanks. Do you have a computer with an internet connection that you use at least once a week?  ')
					 
				On m.memberid = w.Dermsl_Memberid

			Left join provoqms_reporting.dbo.DermSync_Copy acc
				On m.memberid = acc.memberid
Where m.LookupClientid = 125-- 
and m.StateCode = 'IN'
and m.rowCreatedDatetime <= DateAdd(Day,-14,getdate())
) a
Group by responseText, WelcomecallSuccess 
Order by ResponseText, WelcomeCallSuccess 
 
							 

/*****For NC************/

Select responseText, WelcomecallSuccess, Count(*), sum(Syncing) , Sum(SyncingNow)
FROM 
(
Select  m.Firstname, m.memberid,vm.IndividualSysId, vm.StateCode
,WelcomeCallReach = mcl.Memberid, responseText = convert(varchar(100),csr.ResponseText), csd.ScriptText
,Syncing = Case when acc.memberid  is not null then 1 else 0 end
,Syncingnow =   SyncingNow
,WelcomeCallSuccess = Case when mcl.Memberid is not null then 'Yes' else 'No' end
FROM provoqms_Reporting.dbo.DermMemberCopy m 
			Left join vmember vm 
				On m.memberid = vm.Individualsysid  and vm.TreatmentID in (304,305,316) 
			left join (Select Distinct memberid from membercalllog mcl where mcl.LookupCallStatusid in(16, 2)) mcl
				On vm.memberid = mcl.memberid 
			Left join Treatment t
				On vm.Treatmentid = t.treatmentid
			Left join ( #WalkandWin w
							inner join vmember v on w.Savvyid = v.IndividualSysid
							inner join  CALLScriptParticipant csp  on v.memberid = csp.memberid
							inner join CALLScriptResponse csr On csp.CALLScriptResponseID = csr.CALLScriptResponseID
							inner join CALLScriptDetail csd ON csr.CALLScriptDetailID = csd.CALLScriptDetailID  
															and Convert(Varchar(max),ScriptText) = 'All right, thanks. Do you have a computer with an internet connection that you use at least once a week?  ')
					 
				On m.memberid = w.Dermsl_Memberid

			Left join provoqms_reporting.dbo.DermSync_Copy acc
				On m.memberid = acc.memberid
Where m.LookupClientid = 125-- 
and m.StateCode = 'NC'
and m.rowCreatedDatetime <= DateAdd(Day,-14,getdate())
) a
Group by responseText, WelcomecallSuccess 
Order by ResponseText, WelcomeCallSuccess 

