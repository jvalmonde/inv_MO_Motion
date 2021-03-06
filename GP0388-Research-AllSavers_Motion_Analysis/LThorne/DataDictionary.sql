/****** Script for SelectTopNRows command from SSMS  ******/
select Table_Name, Column_Name, Data_Type
  from pdb_allsavers_research.information_schema.columns
 where table_schema = 'dbo'
   and left(Table_Name,4) not in ('ASM_','DERM','RA_C')
 order by Table_Name, column_name, ordinal_position