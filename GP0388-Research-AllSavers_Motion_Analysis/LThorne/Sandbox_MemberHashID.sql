/* Dinking around with DIMID creation - thinking out loud with a keyboard to register thoughts */

SELECT MemberID, n = count(distinct SystemID)
  FROM [AllSavers_Prod].[dbo].[Dim_MemberDetail]
 where isnull(PolicyID,0) > 0
group by MemberID
having count(distinct SystemID) > 1
order by 2 desc
;

declare @mid  binary(16);
declare @hash binary(16);;
declare @chash varchar(32);
declare @rhash binary(16)

select @mid = cast(hashbytes('MD5',SSN+cast(birthdate as varchar(10))) as binary(16))
  FROM [AllSavers_Prod].[dbo].[Dim_Member]
 where MemberID = 271428
;

set @hash  = @mid 
set @chash = convert(varchar(32), @hash,2)
set @rhash = convert(binary(16),'0x'+@chash,1)

select @mid, @hash, @chash, len(@chash), @rhash

;

select top 1000
       MemberHash = cast(hashbytes('MD5',SSN+cast(birthdate as varchar(10))) as binary(16))
     , MemberRSID = convert(varchar(32), cast(hashbytes('MD5',SSN+cast(birthdate as varchar(10))) as binary(16)),2)
	 , SystemID
  FROM [AllSavers_Prod].[dbo].[Dim_Member]
 where MemberID > 0
