use pdb_Allsavers_Research;

--Buildout of dbo.Longitudinal_Day; Step 2
--    Step 1 is ETL_DermElapsedQtrDays, which is etl step run in cloud

if exists(select OBJECT_ID from pdb_Allsavers_Research.sys.objects where name = 'Longitudinal_Day')
   drop table pdb_Allsavers_Research.dbo.Longitudinal_Day;
 
select ax.Member_DIMID
     , ed.BegDate, ed.CurYear, ed.QtrNbr,
       [Day_1],[Day_2],[Day_3],[Day_4],[Day_5],[Day_6],[Day_7],[Day_8],[Day_9],[Day_10],[Day_11],[Day_12],
       [Day_13],[Day_14],[Day_15],[Day_16],[Day_17],[Day_18],[Day_19],[Day_20],[Day_21],[Day_22],[Day_23],
       [Day_24],[Day_25],[Day_26],[Day_27],[Day_28],[Day_29],[Day_30],[Day_31],[Day_32],[Day_33],[Day_34],
       [Day_35],[Day_36],[Day_37],[Day_38],[Day_39],[Day_40],[Day_41],[Day_42],[Day_43],[Day_44],[Day_45],
       [Day_46],[Day_47],[Day_48],[Day_49],[Day_50],[Day_51],[Day_52],[Day_53],[Day_54],[Day_55],[Day_56],
       [Day_57],[Day_58],[Day_59],[Day_60],[Day_61],[Day_62],[Day_63],[Day_64],[Day_65],[Day_66],[Day_67],
       [Day_68],[Day_69],[Day_70],[Day_71],[Day_72],[Day_73],[Day_74],[Day_75],[Day_76],[Day_77],[Day_78],
       [Day_79],[Day_80],[Day_81],[Day_82],[Day_83],[Day_84],[Day_85],[Day_86],[Day_87],[Day_88],[Day_89],[Day_90]
     , DateLastGeneration = GETDATE()
  into Longitudinal_Day
  from etl.AS_DERM_ElapsedQtrDays        ed
  join etl.AS_DERM_Members      (nolock) dm on ed.Memberid       = dm.MEMBERID   -- Memberid
  join etl.DERM_xwalk_Member    (nolock) dx on dm.ClientMEMBERID = dx.dSystemID  -- xwalk to
  join ASM_xwalk_Member         (nolock) ax on dx.aSystemid      = ax.SystemID   -- DIMID
 order by 1,2
;

create clustered index ucix_DIMID on pdb_Allsavers_Research..Longitudinal_Day (Member_DIMID);

