use pdb_Allsavers_Research;

-- Sandbox dinking around figuring out PolicyYear stuff

SELECT distinct top 1000 ms.Member_DIMID
	 , PolicyYear = p1.PolicyYR, md.YearMo, p1.MinDtSysID, p1.MaxDtSysID
  FROM MemberSummary                       ms
  join ASM_xwalk_Member                    xm on ms.Member_DIMID = xm.Member_DIMID  -- filter on the member basis for project
  join AllSavers_Prod..Dim_MemberDetail    md on xm.SystemID     = md.SystemID and isnull(md.PolicyID,0) > 0
                                                                                    -- must have a policy, and for the YearMo
  join ASM_YearMo                          ym on md.YearMo       = ym.YearMo        -- filter on the YearMo spread for project
  join AllSavers_Prod..Dim_Policy          dp on ms.PolicyID     = dp.PolicyID and md.yearmo = dp.yearmo
 cross apply (select PolicyYR = p0.YearMo/100, p0.MinDtSysID, p0.MaxDtSysID
                from AllSavers_Prod..Dim_Policy (nolock) p0
               where p0.PolicyID = dp.PolicyID and p0.PolicyYear = dp.PolicyYear
			     and p0.PolicyMonth = ((dp.PolicyYear-1)*12)+1
			 ) p1
 order by 1,2,3
