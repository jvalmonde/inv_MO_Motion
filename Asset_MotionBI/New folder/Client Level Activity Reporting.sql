Select YearMonth,
TotalEligible  = sum(Eligibles),
RegistrationPercent = SUM(Registered)*1.00		 /sum(Eligibles),
PercentActive       = SUM(PercentActiveDays)*1.00/sum(TotalDays),
Frequency_Percentearned = sum(F)*1.00/sum(PossibleF), 
Intensity_Percentearned = sum(I)*1.00/sum(PossibleI),
Tenacity_Percentearned =  sum(T)*1.00/sum(PossibleT),
AllGoals_PercentEaned   = sum(F+I+T)*1.00/sum(PossibleF + PossibleI + PossibleT),
AllGoals_PercentEaned_WithCredits   = sum(Total)*1.00/sum(PossibleF + PossibleI + PossibleT)


 FROM Motion_by_Group_by_month
Where Clientname= 'Key Accounts' 
Group by Yearmonth 
order by YearMonth

Select * FROM   Motion_by_Group_by_month