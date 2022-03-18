/****** [HealthiestYou_UHG_2015_CONSULTS] ******/

SELECT [FileCreationDateTime]	=	CONVERT(DATETIME, LEFT([File Creation DateTime], 10) +  ' ' + RIGHT([File Creation DateTime], 8))
      ,[InteractionNumber]		=	CONVERT(varchar(10), [Interaction Number])
      ,[IsAdvice]				=	CONVERT(varchar(3), IsAdvice)
      ,[EmployerClientName]		=	CONVERT(varchar(13), [Employer ClientName])
      ,[MemberID]				=	CONVERT(varchar(20), [Member ID])
      ,[UserID]					=	CONVERT(bigint, [User ID])
      ,[ParentMemberID]			=	CONVERT(varchar(20), [Parent Member ID])
      ,[ParentUserID]			=	CONVERT(bigint, [Parent User ID])
      ,[Role]					=	CONVERT(varchar(9), [Role])
      ,[DateOfService]			=	CONVERT(date, [Date Of Service])
      ,[CallStartDate]			=	CONVERT(date, [Call Start Date])
      ,[CallStartTime]			=	CONVERT(time(0), [Call Start Time])
      ,[CallEndDate]			=	CONVERT(date, [Call End Date])
      ,[CallEndTime]			=	CONVERT(time(0), [Call End Time])
      ,[ConsultLengthOfTime]	=	CONVERT(time(0), [Consult Length Of Time])
      ,[ConsultationType]		=	CONVERT(varchar(5), [Consultation Type])
      ,[MedicalorBH]			=	CONVERT(varchar(7), [Medical_or_BH])
      ,[ConsultationMethod]		=	CONVERT(varchar(16), [Consultation Method])
      ,[CPTBillingCode]			=	CONVERT(int, [CPT Billing Code])
      ,[Diagnosis]				=	CONVERT(varchar(55), [Diagnosis])
      ,[Icd9Code]				=	CONVERT(varchar(30), [Icd9 Code])	
      ,[ICD10Code]				=	CONVERT(varchar(30), [ICD10 Code])
      ,[ChargeAmount]			=	CONVERT(decimal(9,2), IIF([Charge Amount] = '', NULL, [Charge Amount]))
      ,[CustomerTransactionAmt]	=	CONVERT(decimal(9,2), IIF([Customertransactionamt] = '', NULL, [Customertransactionamt]))
      ,[CopayAmount]			=	CONVERT(decimal(9,2), IIF([Copay Amount] = '', NULL, [Copay Amount]))
      ,[TransactionType]		=	CONVERT(varchar(5), [Transaction Type])
      ,[CodedChiefComplaint1Provider]	=	CONVERT(varchar(5), [Coded Chief Complaint1 Provider])
      ,[PrescriptionGiven]				=	CONVERT(varchar(3), [Prescription_Given])	
      ,[PrescriptionGivenCount]			=	CONVERT(smallint, [Prescription_Given_Count])
      ,[Reporting1]						=	CONVERT(varchar(10), [Reporting1])
      ,[ParentReporting1]				=	CONVERT(varchar(10), [Parent_Reporting1])
      ,[Reporting2]						=	CONVERT(varchar(25), [Reporting2])
      ,[Parent_Reporting2]				=	CONVERT(varchar(25), [Parent_Reporting2])
      ,[Reporting3]						=	CONVERT(varchar(5), Reporting3)
      ,[Reporting4]						=	CONVERT(varchar(5), Reporting4)
      ,[PrescriptionNames]				=	CONVERT(varchar(55), [Prescription Names])
      ,[BusinessUnit]					=	CONVERT(varchar(5), [Business Unit])
      ,[UserCreationDateTime]			=	CONVERT(datetime, [User creation_date])
      ,[ManuallyAdded]					=	CONVERT(varchar(3), [Manually Added])
      ,[PaymentType]					=	CONVERT(varchar(5), [Payment Type])
      ,[SurveyResponseIndicator]		=	CONVERT(varchar(3), [Survey Response Indicator])
      ,[SubscriberID]					=	CONVERT(varchar(9), [Subscriber ID])
      ,[Address1]						=	CONVERT(varchar(36), [Address1])
      ,[Address2]						=	CONVERT(varchar(20), [Address2])
      ,[City]							=	CONVERT(varchar(20), [City])
      ,[State]							=	CONVERT(varchar(20), [State])
      ,[ConsultState]					=	CONVERT(char(2), [Consult State])
      ,[ZipCode]						=	CONVERT(char(5), [Zip Code])
      ,[ConsultationRatingfromSurvey]	=	CONVERT(varchar(9), [Consultation Rating from Survey])
      ,[How_likely_are_you_to_use_MDLIVE_in_the_future?]											=	CONVERT(tinyint, IIF([How likely are you to use MDLIVE in the future?] = '', NULL, [How likely are you to use MDLIVE in the future?]))
      ,[Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]		=	CONVERT(varchar(32), [Redirect question response (If MDLIVE wasn't available; where would you have gone?)])
      ,[Referral_question_response_(How likely are you to refer a friend or colleague to MDLIVE?)]	=	CONVERT(tinyint, IIF([Referral question response (How likely are you to refer a friend or colleague to MDLIVE?)] = '', NULL, [Referral question response (How likely are you to refer a friend or colleague to MDLIVE?)]))
      ,[Gender]							=	CONVERT(varchar(6), Gender)
      ,[Age]							=	CONVERT(tinyint, age)
      ,[WaitTime]						=	CONVERT(datetime, IIF([Wait Time] = '', NULL, [Wait Time]))
      ,[VisitStartTime]					=	CONVERT(time(0), [Visit Start Time])
      ,[VisitEndTimes]					=	CONVERT(time(0), [Visit End Times])
      ,[CancelledConsultationIndicator]	=	CONVERT(tinyint, IIF([Cancelled Consultation Indicator] = '', NULL, [Cancelled Consultation Indicator]))
      ,[InitialVisitDate]				=	CONVERT(date, [Initial Visit Date])
      ,[NumberOfDiagnosisPerEncounter]	=	CONVERT(int, [Number of Diagnosis per encounter])
      ,[NumberOfPrescriptionsPerEncounter]	=	CONVERT(int, [Number of Prescriptions per encounter])
      ,[PharmacyName]					=	CONVERT(varchar(37), [Pharmacy Name])
      ,[PharmacyState]					=	CONVERT(varchar(20), [Pharmacy State])
      ,[PharmacyCity]					=	CONVERT(varchar(22), [Pharmacy City])
      ,[PharmacyZip]					=	CONVERT(varchar(9), [Pharmacy Zip])
      ,[DateOfRegistration]				=	CONVERT(date, [Date of Registration])
  Into [pdb_ABW].[dbo].[HealthiestYou_UHG_2015_CONSULTS]
FROM [pdb_ABW].[dbo].[HealthiestYou_UHG_2015_CONSULTS_ETL]



/****** [HealthiestYou_UHG_2016_CONSULTS] ******/

Select [FileCreationDateTime]																		=	CONVERT(DATETIME, LEFT([File Creation DateTime], 10) +  ' ' + RIGHT([File Creation DateTime], 8))
	, [InteractionNumber]																			=	CONVERT(varchar(10), [Interaction Number])
	, [IsAdvice]																					=	CONVERT(varchar(3), IsAdvice)
	, [EmployerClientName]																			=	CONVERT(varchar(13), [Employer ClientName])
	, [MemberID]																					=	CONVERT(varchar(20), [Member ID])
	, [UserID]																						=	CONVERT(bigint, [User ID])
	, [ParentMemberID]																				=	CONVERT(varchar(20), [Parent Member ID])
	, [ParentUserID]																				=	CONVERT(bigint, [Parent User ID])
	, [Role]																						=	CONVERT(varchar(9), [Role])
	, [DateOfService]																				=	CONVERT(date, [Date Of Service])
	, [CallStartDate]																				=	CONVERT(date, [Call Start Date])
	, [CallStartTime]																				=	CONVERT(time(0), [Call Start Time])
	, [CallEndDate]																					=	CONVERT(date, Replace([Call End Date], '1/0/1900', '01/01/1900'))
	, [CallEndTime]																					=	CONVERT(time(0), [Call End Time])
	, [ConsultLengthOfTime]																			=	CONVERT(time(0), [Consult Length Of Time])
	, [ConsultationType]																			=	CONVERT(varchar(5), [Consultation Type])
	, [MedicalorBH]																					=	CONVERT(varchar(7), [Medical_or_BH])
	, [ConsultationMethod]																			=	CONVERT(varchar(16), [Consultation Method])
	, [CPTBillingCode]																				=	CONVERT(int, [CPT Billing Code])
	, [Diagnosis]																					=	CONVERT(varchar(55), [Diagnosis])
	, [Icd9Code]																					=	CONVERT(varchar(30), [Icd9 Code])	
	, [ICD10Code]																					=	CONVERT(varchar(30), [ICD10 Code])
	, [ChargeAmount]																				=	CONVERT(decimal(9,2), IIF([Charge Amount] = '', NULL, [Charge Amount]))
	, [CustomerTransactionAmt]																		=	CONVERT(decimal(9,2), IIF([Customertransactionamt] = '', NULL, [Customertransactionamt]))
	, [CopayAmount]																					=	CONVERT(decimal(9,2), IIF([Copay Amount] = '', NULL, [Copay Amount]))
	, [TransactionType]																				=	CONVERT(varchar(5), [Transaction Type])
	, [CodedChiefComplaint1Provider]																=	CONVERT(varchar(5), [Coded Chief Complaint1 Provider])
	, [PrescriptionGiven]																			=	CONVERT(varchar(3), [Prescription_Given])	
	, [PrescriptionGivenCount]																		=	CONVERT(smallint, [Prescription_Given_Count])
	, [Reporting1]																					=	CONVERT(varchar(10), [Reporting1])
	, [ParentReporting1]																			=	CONVERT(varchar(10), [Parent_Reporting1])
	, [Reporting2]																					=	CONVERT(varchar(25), [Reporting2])
	, [ParentReporting2]																			=	CONVERT(varchar(25), [Parent_Reporting2])
	, [Reporting3]																					=	CONVERT(varchar(5), Reporting3)
	, [Reporting4]																					=	CONVERT(varchar(5), Reporting4)
	, [PrescriptionNames]																			=	CONVERT(varchar(55), [Prescription Names])
	, [BusinessUnit]																				=	CONVERT(varchar(5), [Business Unit])
	, [UserCreationDate]																			=	CONVERT(datetime, [User creation_date])
	, [ManuallyAdded]																				=	CONVERT(varchar(3), [Manually Added])
	, [PaymentType]																					=	CONVERT(varchar(5), [Payment Type])
	, [SurveyResponseIndicator]																		=	CONVERT(varchar(3), [Survey Response Indicator])
	, [SubscriberID]																				=	CONVERT(varchar(9), [Subscriber ID])
	, [Address1]																					=	CONVERT(varchar(36), [Address1])
	, [Address2]																					=	CONVERT(varchar(20), [Address2])
	, [City]																						=	CONVERT(varchar(20), [City])
	, [State]																						=	CONVERT(varchar(20), [State])
	, [ConsultState]																				=	CONVERT(char(2), [Consult State])
	, [ZipCode]																						=	CONVERT(char(5), [Zip Code])
	, [ConsultationRatingfromSurvey]																=	CONVERT(varchar(9), [Consultation Rating from Survey])
	, [How_likely_are_you_to_use_MDLIVE_in_the_future?]												=	CONVERT(tinyint, IIF([How likely are you to use MDLIVE in the future?] = '', NULL, [How likely are you to use MDLIVE in the future?]))
	, [Redirect_question_response_(If MDLIVE wasn't available; where would you have gone?)]			=	CONVERT(varchar(32), [Redirect question response (If MDLIVE wasn't available; where would you have gone?)])
	, [Referral_question_response_(How likely are you to refer a friend or colleague to MDLIVE?)]	=	CONVERT(tinyint, IIF([Referral question response (How likely are you to refer a friend or colleague to MDLIVE?)] = '', NULL, [Referral question response (How likely are you to refer a friend or colleague to MDLIVE?)]))
	, [Gender]																						=	CONVERT(varchar(6), Gender)
	, [Age]																							=	CONVERT(tinyint, age)
	, [WaitTime]																					=	CONVERT(datetime, IIF([Wait Time] = '', NULL, [Wait Time]))
	, [VisitStartTime]																				=	CONVERT(time(0), [Visit Start Time])
	, [VisitEndTimes]																				=	CONVERT(time(0), [Visit End Times])
	, [CancelledConsultationIndicator]																=	CONVERT(tinyint, IIF([Cancelled Consultation Indicator] = '', NULL, [Cancelled Consultation Indicator]))
	, [InitialVisitDate]																			=	CONVERT(date, [Initial Visit Date])
	, [NumberofDiagnosisperEncounter]																=	CONVERT(int, [Number of Diagnosis per encounter])
	, [NumberofPrescriptionsperEncounter]															=	CONVERT(int, [Number of Prescriptions per encounter])
	, [PharmacyName]																				=	CONVERT(varchar(37), [Pharmacy Name])
	, [PharmacyState]																				=	CONVERT(varchar(20), [Pharmacy State])
	, [PharmacyCity]																				=	CONVERT(varchar(22), [Pharmacy City])
	, [PharmacyZip]																					=	CONVERT(varchar(9), [Pharmacy Zip])
	, [DateofRegistration]																			=	CONVERT(date, [Date of Registration])
  Into [pdb_ABW].[dbo].[HealthiestYou_UHG_2016_CONSULTS]
FROM [pdb_ABW].[dbo].[HealthiestYou_UHG_2016_CONSULTS_ETL]


/****** [HealthiestYou_HYUHG_SAVVY] ******/

SELECT [_id]		=	CONVERT(varchar(25), [_id])
	, [Group]		=	CONVERT(varchar(10), [Group])
	, [SubGroup]	=	CONVERT(varchar(11), [SubGroup])
	, [ExigoID]		=	CONVERT(varchar(9), [ExigoID])
	, [First]		=	CONVERT(varchar(15), [First])
	, [Last]		=	CONVERT(varchar(25), [Last])
	, [State]		=	CONVERT(char(2), [State])
	, [DOB]			=	CONVERT(date, DOB)
	, [Status]		=	CONVERT(varchar(9), [Status])
	, [Effective]	=	CONVERT(Date, effective)
  Into [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY]
FROM [pdb_ABW].[dbo].[HealthiestYou_HYUHG_SAVVY_ETL]
