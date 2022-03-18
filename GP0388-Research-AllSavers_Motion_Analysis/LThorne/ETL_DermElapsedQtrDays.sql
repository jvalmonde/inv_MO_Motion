use DERMSL_Prod;

-- This bit of resident magic  is used as an ETL input to pull back the member steps data from DERM.
-- the result is ETL.AS_DERM_ElapsedQtrDays, which is input the Longitudinal Day

declare @year char(4) = year(getdate());
declare @YearEnd date = cast(@year+'-12-31' as date);

with mbrBasis as (
SELECT m.Memberid, BegDate = me.StartDate, EndDate = isnull(me.EndDate,@YearEnd)
  FROM MEMBER            (nolock)           m
  join Member_Enrollment (nolock)           me on m.MemberID = me.Memberid
 where m.lookupclientID = 50 and m.ClientMEMBERID <> ''
   and m.LastName <> 'Admin' and len(m.ClientMemberID) >= 17
),   ElapsedDays as (
select mb.MemberID, mb.BegDate, ed.CurYear, ed.QtrNbr, DayNbr = 'Day_'+format(ed.DayNbr,'##')
     , TotalSteps = isnull(ma.TotalSteps,0)
  from mbrBasis                               mb
 cross apply (select * from pdb_DermReporting.dbo.fnElapsedQtrDays(mb.BegDate, mb.EndDate)) ed
  left join MEMBERAction (nolock)             ma on mb.MEMBERID = ma.Memberid
                                                and ed.Cur_Date = ma.QueryDate
)

select *
  from (select MemberID, BegDate, CurYear, QtrNbr, DayNbr, TotalSteps
          from ElapsedDays) a
 pivot (
       max(totalSteps)
       for DayNbr in (
	       [Day_1],[Day_2],[Day_3],[Day_4],[Day_5],[Day_6],[Day_7],[Day_8],[Day_9],[Day_10],[Day_11],[Day_12],
		   [Day_13],[Day_14],[Day_15],[Day_16],[Day_17],[Day_18],[Day_19],[Day_20],[Day_21],[Day_22],[Day_23],
		   [Day_24],[Day_25],[Day_26],[Day_27],[Day_28],[Day_29],[Day_30],[Day_31],[Day_32],[Day_33],[Day_34],
		   [Day_35],[Day_36],[Day_37],[Day_38],[Day_39],[Day_40],[Day_41],[Day_42],[Day_43],[Day_44],[Day_45],
		   [Day_46],[Day_47],[Day_48],[Day_49],[Day_50],[Day_51],[Day_52],[Day_53],[Day_54],[Day_55],[Day_56],
		   [Day_57],[Day_58],[Day_59],[Day_60],[Day_61],[Day_62],[Day_63],[Day_64],[Day_65],[Day_66],[Day_67],
		   [Day_68],[Day_69],[Day_70],[Day_71],[Day_72],[Day_73],[Day_74],[Day_75],[Day_76],[Day_77],[Day_78],
		   [Day_79],[Day_80],[Day_81],[Day_82],[Day_83],[Day_84],[Day_85],[Day_86],[Day_87],[Day_88],[Day_89],[Day_90]
	                      )
       ) p
 where 	   [Day_1]+[Day_2]+[Day_3]+[Day_4]+[Day_5]+[Day_6]+[Day_7]+[Day_8]+[Day_9]+[Day_10]+[Day_11]+[Day_12]+
		   [Day_13]+[Day_14]+[Day_15]+[Day_16]+[Day_17]+[Day_18]+[Day_19]+[Day_20]+[Day_21]+[Day_22]+[Day_23]+
		   [Day_24]+[Day_25]+[Day_26]+[Day_27]+[Day_28]+[Day_29]+[Day_30]+[Day_31]+[Day_32]+[Day_33]+[Day_34]+
		   [Day_35]+[Day_36]+[Day_37]+[Day_38]+[Day_39]+[Day_40]+[Day_41]+[Day_42]+[Day_43]+[Day_44]+[Day_45]+
		   [Day_46]+[Day_47]+[Day_48]+[Day_49]+[Day_50]+[Day_51]+[Day_52]+[Day_53]+[Day_54]+[Day_55]+[Day_56]+
		   [Day_57]+[Day_58]+[Day_59]+[Day_60]+[Day_61]+[Day_62]+[Day_63]+[Day_64]+[Day_65]+[Day_66]+[Day_67]+
		   [Day_68]+[Day_69]+[Day_70]+[Day_71]+[Day_72]+[Day_73]+[Day_74]+[Day_75]+[Day_76]+[Day_77]+[Day_78]+
		   [Day_79]+[Day_80]+[Day_81]+[Day_82]+[Day_83]+[Day_84]+[Day_85]+[Day_86]+[Day_87]+[Day_88]+[Day_89]+[Day_90]
           > 0
order by 1,2,3; 



/*  Not sure what this is on about, must have been important in the moment though...

select dt.DT_SYS_ID, dt.FULL_DT, dt.YEAR_NBR, Qtr_Nbr = dt.QUARTER_NBR
     , Qtr_Day = ROW_NUMBER() over(partition by dt.Year_Nbr, dt.Quarter_Nbr order by dt.Full_Dt)
  from pdb_DermReporting..ASM_YearMo (nolock) ym
  join pdb_DermReporting..dim_Date   (nolock) dt on ym.Year_Mo = dt.YEAR_MO


*/  