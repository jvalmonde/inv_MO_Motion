--lists total sizes for every table in a database
USE pdb_DermFraud;
Select * FROM Signaturedatatemp
Select * Into SignatureDatatemp FROM signatureData where Startdatetime >= '20160101'
Select * Into SignatureDatatempArchive FROM signatureData where Startdatetime < '20160101'

Truncate table Signaturedata

set identity_insert signaturedata on;
Insert into Signaturedata
([SignatureDataLogID]
      ,[Customerid]
      ,[DataHeaderid]
      ,[StartDateTime]
      ,[RowID]
      ,[Ax]
      ,[Ay]
      ,[Az]
      ,[DeviceId]
      ,[FirmwareVersion]
	  )

Select 
[SignatureDataLogID]
      ,[Customerid]
      ,[DataHeaderid]
      ,[StartDateTime]
      ,[RowID]
      ,[Ax]
      ,[Ay]
      ,[Az]
      ,[DeviceId]
      ,[FirmwareVersion]
FROM SignaturedataTemp

Truncate table SignatureDatatemp


Truncate Table udb_ghyatt.dbo.Signaturedata_march where startdateTime >= '20160301'



Select * FROM pdb_DermFraud.dbo.SignatureSample where Dataheaderid in(792143
,912686)




/****** Script for SelectTopNRows command from SSMS  ******/
SELECT Date = Convert(Date,[StartDateTime])
     ,Count(Distinct DataHeaderid) as Cnt
  FROM [pdb_DermFraud].[dbo].[SignatureData]
  Where StartDateTime between '20160101' and '20160801'
  Group by Convert(Date,StartdateTime)
  Order by Date

  
  
  
  Select FirmwareVersion, Avg(Cnt), Avg(Mx)
  FROM 
  (
  SELECT FirmwareVersion,Dataheaderid
     ,Count(*) as Cnt, Max(RowId) as Mx
  FROM [pdb_DermFraud].[dbo].[SignatureData]
  Group by FirmwareVersion,Dataheaderid
  ) a
  Group by FirmwareVersion
