USE pdb_Allsavers_Research;

IF OBJECT_ID ('vwMemberClaimsYY', 'V') IS NOT NULL
   DROP VIEW dbo.vwMemberClaimsYY
GO

CREATE View dbo.vwMemberClaimsYY
as

SELECT -- MemberSummary
       ms.Member_DIMID, cd.ClaimYear, cd.[Year]

	   , ms.MM, MM_Year = case when cd.ClaimYear = 2014 then ms.MM2014
	                           when cd.ClaimYear = 2015 then ms.MM2015
							   when cd.ClaimYear = 2016 then ms.MM2016
							   else 9999 end
	   -- MemberHCCDetailYY
	 , ra.RAF
     , HCC001 = isnull(hc.HCC001,0)
     , HCC002 = isnull(hc.HCC002,0)
     , HCC003 = isnull(hc.HCC003,0)
     , HCC004 = isnull(hc.HCC004,0)
     , HCC006 = isnull(hc.HCC006,0)
     , HCC008 = isnull(hc.HCC008,0)
     , HCC009 = isnull(hc.HCC009,0)
     , HCC010 = isnull(hc.HCC010,0)
     , HCC011 = isnull(hc.HCC011,0)
     , HCC012 = isnull(hc.HCC012,0)
     , HCC013 = isnull(hc.HCC013,0)
     , HCC018 = isnull(hc.HCC018,0)
     , HCC019 = isnull(hc.HCC019,0)
     , HCC020 = isnull(hc.HCC020,0)
     , HCC021 = isnull(hc.HCC021,0)
     , HCC023 = isnull(hc.HCC023,0)
     , HCC026 = isnull(hc.HCC026,0)
     , HCC027 = isnull(hc.HCC027,0)
     , HCC028 = isnull(hc.HCC028,0)
     , HCC029 = isnull(hc.HCC029,0)
     , HCC030 = isnull(hc.HCC030,0)
     , HCC034 = isnull(hc.HCC034,0)
     , HCC035 = isnull(hc.HCC035,0)
     , HCC036 = isnull(hc.HCC036,0)
     , HCC037 = isnull(hc.HCC037,0)
     , HCC038 = isnull(hc.HCC038,0)
     , HCC041 = isnull(hc.HCC041,0)
     , HCC042 = isnull(hc.HCC042,0)
     , HCC045 = isnull(hc.HCC045,0)
     , HCC046 = isnull(hc.HCC046,0)
     , HCC047 = isnull(hc.HCC047,0)
     , HCC048 = isnull(hc.HCC048,0)
     , HCC054 = isnull(hc.HCC054,0)
     , HCC055 = isnull(hc.HCC055,0)
     , HCC056 = isnull(hc.HCC056,0)
     , HCC057 = isnull(hc.HCC057,0)
     , HCC061 = isnull(hc.HCC061,0)
     , HCC062 = isnull(hc.HCC062,0)
     , HCC063 = isnull(hc.HCC063,0)
     , HCC064 = isnull(hc.HCC064,0)
     , HCC066 = isnull(hc.HCC066,0)
     , HCC067 = isnull(hc.HCC067,0)
     , HCC068 = isnull(hc.HCC068,0)
     , HCC069 = isnull(hc.HCC069,0)
     , HCC070 = isnull(hc.HCC070,0)
     , HCC071 = isnull(hc.HCC071,0)
     , HCC073 = isnull(hc.HCC073,0)
     , HCC074 = isnull(hc.HCC074,0)
     , HCC075 = isnull(hc.HCC075,0)
     , HCC081 = isnull(hc.HCC081,0)
     , HCC082 = isnull(hc.HCC082,0)
     , HCC087 = isnull(hc.HCC087,0)
     , HCC088 = isnull(hc.HCC088,0)
     , HCC089 = isnull(hc.HCC089,0)
     , HCC090 = isnull(hc.HCC090,0)
     , HCC094 = isnull(hc.HCC094,0)
     , HCC096 = isnull(hc.HCC096,0)
     , HCC097 = isnull(hc.HCC097,0)
     , HCC102 = isnull(hc.HCC102,0)
     , HCC103 = isnull(hc.HCC103,0)
     , HCC106 = isnull(hc.HCC106,0)
     , HCC107 = isnull(hc.HCC107,0)
     , HCC108 = isnull(hc.HCC108,0)
     , HCC109 = isnull(hc.HCC109,0)
     , HCC110 = isnull(hc.HCC110,0)
     , HCC111 = isnull(hc.HCC111,0)
     , HCC112 = isnull(hc.HCC112,0)
     , HCC113 = isnull(hc.HCC113,0)
     , HCC114 = isnull(hc.HCC114,0)
     , HCC115 = isnull(hc.HCC115,0)
     , HCC117 = isnull(hc.HCC117,0)
     , HCC118 = isnull(hc.HCC118,0)
     , HCC119 = isnull(hc.HCC119,0)
     , HCC120 = isnull(hc.HCC120,0)
     , HCC121 = isnull(hc.HCC121,0)
     , HCC122 = isnull(hc.HCC122,0)
     , HCC125 = isnull(hc.HCC125,0)
     , HCC126 = isnull(hc.HCC126,0)
     , HCC127 = isnull(hc.HCC127,0)
     , HCC128 = isnull(hc.HCC128,0)
     , HCC129 = isnull(hc.HCC129,0)
     , HCC130 = isnull(hc.HCC130,0)
     , HCC131 = isnull(hc.HCC131,0)
     , HCC132 = isnull(hc.HCC132,0)
     , HCC135 = isnull(hc.HCC135,0)
     , HCC137 = isnull(hc.HCC137,0)
     , HCC138 = isnull(hc.HCC138,0)
     , HCC139 = isnull(hc.HCC139,0)
     , HCC142 = isnull(hc.HCC142,0)
     , HCC145 = isnull(hc.HCC145,0)
     , HCC146 = isnull(hc.HCC146,0)
     , HCC149 = isnull(hc.HCC149,0)
     , HCC150 = isnull(hc.HCC150,0)
     , HCC151 = isnull(hc.HCC151,0)
     , HCC153 = isnull(hc.HCC153,0)
     , HCC154 = isnull(hc.HCC154,0)
     , HCC156 = isnull(hc.HCC156,0)
     , HCC158 = isnull(hc.HCC158,0)
     , HCC159 = isnull(hc.HCC159,0)
     , HCC160 = isnull(hc.HCC160,0)
     , HCC161 = isnull(hc.HCC161,0)
     , HCC162 = isnull(hc.HCC162,0)
     , HCC163 = isnull(hc.HCC163,0)
     , HCC183 = isnull(hc.HCC183,0)
     , HCC184 = isnull(hc.HCC184,0)
     , HCC187 = isnull(hc.HCC187,0)
     , HCC188 = isnull(hc.HCC188,0)
     , HCC203 = isnull(hc.HCC203,0)
     , HCC204 = isnull(hc.HCC204,0)
     , HCC205 = isnull(hc.HCC205,0)
     , HCC207 = isnull(hc.HCC207,0)
     , HCC208 = isnull(hc.HCC208,0)
     , HCC209 = isnull(hc.HCC209,0)
     , HCC217 = isnull(hc.HCC217,0)
     , HCC226 = isnull(hc.HCC226,0)
     , HCC227 = isnull(hc.HCC227,0)
     , HCC242 = isnull(hc.HCC242,0)
     , HCC243 = isnull(hc.HCC243,0)
     , HCC244 = isnull(hc.HCC244,0)
     , HCC245 = isnull(hc.HCC245,0)
     , HCC246 = isnull(hc.HCC246,0)
     , HCC247 = isnull(hc.HCC247,0)
     , HCC248 = isnull(hc.HCC248,0)
     , HCC249 = isnull(hc.HCC249,0)
     , HCC251 = isnull(hc.HCC251,0)
     , HCC253 = isnull(hc.HCC253,0)
     , HCC254 = isnull(hc.HCC254,0)
       -- MemberClaimDetailYY
	 , RX_AllwAmt, RX_PaidAmt, IP_AllwAmt, IP_PaidAmt
     , OP_AllwAmt, OP_PaidAmt, ER_AllwAmt, ER_PaidAmt, MD_AllwAmt, MD_PaidAmt, OtherAllwAmt, OtherPaidAmt
     , PaidAmt, AllwAmt, IP_Visits, IP_Days, OP_Visits, MD_Visits, ER_Visits
  from MemberSummary            ms
  left join MemberClaimDetailYY cd on ms.Member_DIMID = cd.Member_DIMID
  left join MemberHCCDetailYY   hc on cd.Member_DIMID = hc.Member_DIMID
                                  and cd.ClaimYear    = hc.ClaimYear
 outer apply (SELECT RAF = SilverTotalScore FROM RA_Com_J_MetalScoresPivoted_RAF
               where UniqueMemberID = ms.Member_DIMID+'_'+cast(cd.ClaimYear as char(4))
             ) ra
;

GO  -- end of view definition


select top 100 * from vwMemberClaimsYY order by 1