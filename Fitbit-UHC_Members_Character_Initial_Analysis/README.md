Notes regarding Motion/Fitbit-UHC Members:  Characterization & Initial Analysis
November 2018

This initiative was launched to explore characteristics of members who have an email registered with Fitbit and to determine if a 
comparison group of members not registered with Fitbit could be created.  
This new database will be available for future enhancements/exploration once more Fitbit data becomes available.
Link to Initiative on R&D Tools: https://rndtools.uhgrd.com/Project/Initiative/159

Databases Used:
pdb_UHCEmails, 
MiniHPDM, 
Census, 
GeocodeRepo, 
RA_Commercial_2016, 
CHOS

We began by utilizing a database already created by Seth Grossinger from a previous Motion initiative (Fitbit-UHC_Data_Merge-Data_Analysis):
https://code.savvysherpa.com/SavvysherpaResearch/inv_MO_Motion/blob/master/Fitbit-UHC_Data_Merge-Data_Analysis/analyzeFitbitMatchdata_final.sql
      

We started by taking the main table (pdb_UHCEmails.dbo-Member_Continuous_2017_HPDM_Summary) and added new variables to fulfill 
specific data requirements.  The code for the additional characteristics that were created is located here (author: Lindsay Nelson):
https://code.savvysherpa.com/SavvysherpaResearch/inv_MO_Motion/tree/master/Fitbit-UHC_Members_Character_Initial_Analysis

The majority of new tables in pdb_UHCEmails are actually staging/working tables.  
The new master table by which to start any future work is called pdb_UHCEmails..Mem_Cont_2017_HPDM_NewPop.  
The data dictionary provides descriptions for each of the variables in this table.  
For RAF data, a second tab is included which describes the supplemental RAF tables created for this project: 
  pdb_UHCEmails..MM2016_RAF and pdb_UHCEmails..MM2017_RAF.

Files on GitHub which describe how fields in Mem_Cont_2017_HPDM_NewPop were created:
1) UHCFitBit_NewSamplePop.sql -> describes how the new member sample was created.
2) UHCFitBit_CHOS_Data.sql -> Contains code used to create the supplemental table containing Consumer Health Ownership Segmentation (CHOS) data (pdb_UHCEmails..CHOSData).  The fields in this table were then used to calculate some of the new variables in the master NewPop table.
3) UHCFitBit_DB2_Hypt_Flgs.sql -> Code that was used to create Type 2 Diabetes and Hypertension disease flags
4) UHCFitBit_Dep_Anx_Flgs.sql -> Code that was used to create Depression/Anxiety flags.
5) UHCFitBit_EnrollTenure.sql->  Code that produced enrollment related fields
6) UHCFitBit_GiniIndex.sql->  Code that pulled in Gini Index of Income Inequality for main population by zip code
7) UHCFitBit_MedianIncome_Zip_Geo.sql-> Median Census variables produced two ways: linked by zip and linked by Geo-Block
8) UHCFitBit_OthHCCFlgs.sql -> Code that produced additional disease flags
9) UHCFitBit_RAFScores.sql -> Code used to create MM2016_RAF and MM2017_RAF tables
10) UHCFitBit_ZipCd_EduAttain_Census.sql -> Code used to create Educational Attainment census categories (linked by zip code)

Data Requirements

We have several additional UHC member data elements that we would like to add to pdb_UHCEmails, either into existing tables or as new tables. The addition of data will improve our ability to create a comparison group (of UHC non-Fitbit users) that is similar to our population of UHC Fitbit users. In doing so, we can move closer to measuring the causal impact of Fitbit ownership on health care utilization, overall and within condition segments.

N = 14,196,324

1.	2017 RAF and HCCs (Use RA_Commercial_2017) – New table
2.	2016 RAF and HCCs (Use RA_Commercial_2016), for members that were continuously enrolled in 2016 – New table
3.	2017 and 2016 Flags for the following chronic diseases of interest

Type 2 Diabetes
Definition: At least 2 diabetes diagnoses at least 15 days apart
Must have at least 90% of diabetes diagnoses as type 2 

Hypertension
Definition: At least one diagnosis in AHRQ_DTL_CATGY_CD = 098 or 099 (Use Dim_Diagnosis_Code)

Depression and Anxiety
Definition: 1 or more of the following prescriptions filled:
Selective Serotonin Reuptake Inhibitor (Citalopram, Escitalopram, Paroxetine, Sertraline, Fluoxetine, Fluvoxamine)
Serotonin-norepinephrine Reuptake Inhibitor (Venlafaxine, Desvenlafaxine)
Tricyclic Antidepressants (Trimipramine)
Other (Bupropion, Mirtazapine)

OR any depression or anxiety diagnosis

Rheumatoid Arthritis and Specified Autoimmune Disorders 
Definition: Use HCC 056

COPD
Definition: Use HCC 160

Congestive Heart Failure
Definition: Use HCC 130

4. Enrollment tenure prior to Jan 2017 (in three ways as specified below)
Number of months of enrollment in 2016, 
Total previous months of enrollment, 
Number of consecutive months of enrollment leading up to Jan 2017 (Count of monthly membership during last consecutive enrollment period prior to 2017)

5. Zip Code and State

6. Socioeconomic variables based on census data and member zip code (start with socioeconomic score -link by ZipCode)

7. Median income (by Zip and by GeoBlock)

8. Educational Attainment by Zip

9. Gini Index scores by Zip

10. Consumer Health Ownership Segmentation (CHOS) data
