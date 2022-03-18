
/*

	Date Started: 9/9/2016

	We’re looking for a general sense of response rates, so maybe a mix of surveys from different contexts would be best. Could we fill out this table?

	Table Columns:
	Survey	Sent	Responses	Response Rate

	Server: DEVSQL17

	Tables: Survey_Prod

*/


Use Survey_Prod;

Select ds.SurveyName
	--,dc.CollectorName
	,COUNT(distinct dr.RespondentID) as Responses
from Dim_Survey			ds
Join Dim_Collector		dc on dc.SurveyID = ds.SurveyID
Join Dim_Respondent		dr on dr.CollectorID = dc.CollectorID
Group by ds.SurveyName
	--,dc.CollectorName
Order by Responses desc
;


Select ds.*, dr.*
from Dim_Survey			ds
Join Dim_Collector		dc on dc.SurveyID = ds.SurveyID
Join Dim_Respondent		dr on dr.CollectorID = dc.CollectorID

LEFT(Case when  replace(replace(Substring(Emailid,0, charindex('E',Emailid, 2) ),'E',''),'Target=','')  = '' then replace (emailid,'E','')  else replace(replace(Substring(Emailid,0, charindex('E',Emailid, 2) ),'E',''),'Target=','') end,3) in ('109','116','185','205','206','214','251','252','256')



Use DERMSL_Prod;

Select EmailTypeDescription
	,COUNT(distinct SurveyCode) as Survey_Count
from (
	Select distinct e.EmailSubject
		,e.EmailDescription
		,et.EmailTypeDescription
		,el.EmailTo
		,el.EmailFrom
		,el.EmailSent
		,el.EmailLogID
		,s.EmailID
		,s.SurveyCode
	from EmailType		et
	Join Email			e	on e.EmailTypeID = et.EmailTypeID
	Join EmailLog		el	on el.EmailID = e.EmailID
	Join Survey			s	on s.MemberID = el.MemberID
	where 1=1
		and s.EmailID in (109,116,185,205,214,256)

	-- 54,908 rows returned
	) a
Group by EmailTypeDescription
;





-- MemberID is DERMSL_prodID



use survey_prod;

-- drop table #ResponseList;

Select Distinct a.SurveyName
	,Surveycode = CONVERT(int,Surveycode)
	, EmailNum = CONVERT(int,LEFT(Case when  replace(replace(Substring(Emailid,0, charindex('E',Emailid, 2) ),'E',''),'Target=','')  = '' then replace (emailid,'E','')  else replace(replace(Substring(Emailid,0, charindex('E',Emailid, 2) ),'E',''),'Target=','') end,3))
into #ResponseList
FROM
(
              Select Emailid = 
              
                                         substring(Customdata, charindex('E',Customdata,0),100)
			 ,Surveycode = substring(Customdata,0, charindex('E',Customdata,0))

              ,b.CollectorName
              ,CustomData
			  ,c.SurveyName
              FROM Dim_Respondent a
                     Inner join Dim_Collector b
                           ON a.CollectorID = b.CollectorID 
                     inner join Dim_Survey c
                           On b.SurveyID = c.SurveyID
              --Where startdate >= '20150101'
              and a.CustomData like '%E%' 
) a
where IsNumeric(surveycode) = 1; 

 
Delete from #ResponseList where IsNumeric(surveycode) = 0;



--Use DERMSL_Prod;
Select * from DermReporting_Dev.dbo.R where EmailNum = 206

Select *
from DEVSQL14.DERMSL_Prod.dbo.EmailType


Select EmailID
	,EmailDescription
	,EmailTypeDescription
	,EmailSubject
	,ClientName
	,SendCnt = COUNT(distinct Case when SendSuccess = 1 then SurveySent else null end)
	,Response = COUNT(distinct SurveyResponse)
from (
	Select distinct e.EmailSubject
		,e.EmailDescription
		,et.EmailTypeDescription
		,el.EmailTo
		,el.EmailFrom
		,el.EmailSent
		,el.EmailLogID
		,el.SendSuccess
		,el.MemberID
		,s.EmailID
		,rl.SurveyCode as SurveyResponse
		,rl.SurveyName
		,s.SurveyCode as SurveySent
		,lc.ClientName
	from DEVSQL14.DERMSL_Prod.dbo.EmailType		et
	Join DEVSQL14.DERMSL_Prod.dbo.Email			e	on e.EmailTypeID = et.EmailTypeID
													and e.EmailDescription not like '%Reminder%'
	Join DEVSQL14.DERMSL_Prod.dbo.EmailLog		el	on el.EmailID = e.EmailID
	Join DEVSQL14.DERMSL_Prod.dbo.Survey		s	on s.MemberID = el.MemberID
												and s.EmailID = el.EmailID
												and CAST(el.EmailSent as date) = CAST(s.RowCreatedDateTime as date)
												and CAST(el.EmailSent as date) >= '2016-01-01'
	Left Join DermReporting_Dev.dbo.ResponseList						rl  on rl.EmailNum = s.EmailID
												and rl.Surveycode = s.Surveycode
	Join DEVSQL14.DERMSL_Prod.dbo.MEMBER		m	on s.MemberID = m.MEMBERID
	Join DEVSQL14.DERMSL_Prod.dbo.LOOKUPClient	lc	on m.LOOKUPClientID = lc.LOOKUPClientID
													and lc.ClientName in ('All savers motion','Key Accounts UHCM','Cashman','Savvy HatTrick')
	) a
Group by EmailID
	,EmailDescription
	,EmailTypeDescription
	,EmailSubject
	,ClientName
;




Select distinct e.*, s.*

Select m.*
from DEVSQL14.DERMSL_Prod.dbo.EmailType		et
	Join DEVSQL14.DERMSL_Prod.dbo.Email			e	on e.EmailTypeID = et.EmailTypeID
	Join DEVSQL14.DERMSL_Prod.dbo.EmailLog		el	on el.EmailID = e.EmailID
	Join DEVSQL14.DERMSL_Prod.dbo.Survey		s	on s.MemberID = el.MemberID
												and CAST(el.EmailSent as date) = CAST(s.RowCreatedDateTime as date)
												and CAST(el.EmailSent as date) >= '2016-01-01'
	Left Join DermReporting_Dev.dbo.ResponseList					rl  on rl.EmailNum = s.EmailID
												and rl.Surveycode = s.Surveycode
	Join DEVSQL14.DERMSL_Prod.dbo.MEMBER		m	on s.MemberID = m.MEMBERID
	--Join DEVSQL14.DERMSL_Prod.dbo.LOOKUPClient	lc	on m.LOOKUPClientID = lc.LOOKUPClientID
Where e.EmailID = 206