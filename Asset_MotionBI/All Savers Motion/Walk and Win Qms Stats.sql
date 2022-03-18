Select ProjectName,Treatmentname
, [0 calls] = Count(Distinct Case when CallCount = 0   then Memberid else null end)
 , [1 call] = Count(Distinct Case when CallCount = 1 then Memberid else null end)
 , [2 calls] = Count(Distinct Case when CallCount = 2 then Memberid else null end)
 , [3 calls] = Count(Distinct Case when CallCount = 3 then Memberid else null end)
, [4+ calls] = Count(Distinct Case when CallCount >= 4 then Memberid else null end)
, TotalMembers = Count(Memberid)
FROM 
( Select Projectname,t.Treatmentname, m.memberid, CallCount= Count(Case when mcl.memberid is null then null else mcl.memberid end)
FROM project p 
	Inner join Member m on p.projectid = m.Projectid
	Inner join treatment t on m.TreatmentID = t.treatmentid
	Left join membercallLog mcl on m.Memberid = mcl.Memberid and mcl.LOOKUPCallStatusID <> '29'
Where p.ProjectID in 
(
186
,187
,188
,
)
	Group by Projectname,t.Treatmentname,  m.Memberid
) a 
group by ProjectName,Treatmentname


Select * FROM Project