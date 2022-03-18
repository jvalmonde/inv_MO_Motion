--USE pdb_DermReporting;
use pdb_allsavers_research;

DROP FUNCTION dbo.fnElapsedQtrDays
GO

CREATE FUNCTION dbo.fnElapsedQtrDays
(
  @BegDate date,
  @EndDate date
)
RETURNS @reTbl table (BegDate date, CurYear int, QtrNbr int, DayNbr int, Cur_Date date)

AS
BEGIN

declare @DD      int  = datediff(dd,@BegDate,@EndDate);
declare @QQ      int  = @DD/90;
declare @QQr     int  = @DD%90;

if @QQr > 0 set @QQ = @QQ + 1;

declare @QtrNbr int, @DayNbr int, @ElapsedDays int, @CurYear int;

select @QtrNbr = 1, @ElapsedDays = 0;

while @QtrNbr <= @QQ
begin
set @DayNbr = 1;
while @DayNbr <= 90
begin

if @DayNbr = 1 set @CurYear = year(DATEADD(dd,@ElapsedDays,@BegDate))

insert into @reTbl
select @BegDate, @CurYear, @QtrNbr, @DayNbr, DATEADD(dd,@ElapsedDays,@BegDate);

select @DayNbr = @DayNbr + 1, @ElapsedDays = @ElapsedDays + 1
end  -- while @DayNbr

set @QtrNbr = @QtrNbr + 1
end -- while @QtrNbr

RETURN
END  -- of f specification
GO

--select * from fnElapsedQtrDays('2014-05-13', '2015-04-13')  order by 1,2,3