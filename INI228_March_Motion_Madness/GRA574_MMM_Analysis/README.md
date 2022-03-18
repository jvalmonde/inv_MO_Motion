# <a name="top"></a> [GRA-574 MMM Analysis](https://rndtools.uhgrd.com/Project/Grant/574) 
>**Project:** [INV-MO](https://rndtools.uhgrd.com/Project/InvestmentProject/3)\
>**Teams:** [March Motion Madness](https://teams.microsoft.com/l/channel/19%3a8d6d0d14e66c4579a42e5d5492c87736%40thread.skype/March%2520Motion%2520Madness?groupId=d85ec9b2-d97a-4ef8-bf7f-ff6b963faa4a&tenantId=3bc7f8d7-06e7-46d2-b735-7a42c23b5235)\
>**Initiative:** [INI-228 March Motion Madness](https://rndtools.uhgrd.com/Project/Initiative/228)
---
### Table of Contents
  1. [Research Questions](#questions)
  1. [Existing Code](#code)
  1. [Resources](#resources)
  1. [Team](#team)
  1. [Study Population](#population)
     1. [Inclusion Criteria](#inclusion)
     1. [Exclusion Criteria](#exclusion)
     1. [Definitions](#definitions)
  1. [Data Dictionary](#dict)
  1. [Notes](#notes)
  1. [Issue List](#issues)
  1. [Decision Tracker](#decisions)
---
### Research Questions specific to grant<a name="questions"></a>  [^Back to Top](#top)
  1.  How did the earnings change Motion participation within UHG R&D? (see metrics in #3)
  1.  What was the impact of the “pulse” event on completion of frequency goals and on the number of people who achieved a full pay-out during the week of the promotion?
  1.  Did the event have any discernable (statistical dif, meaningful business dif) impact on motion program participation for the weeks in March following the program compared to Jan-Feb and compared to March 2018?
      * Active days per participant
      * Total steps per participant per day
      * Frequency goal achievement
      * Proportion of participants achieving all goals
      * Total incentives paid as a proportion of potential incentives
---
### Resources <a name="resources"></a>  [^Back to Top](#top)
Environment | Database | Schema
-- | -- | --
GCP | research-00 | INV_motion
---
### Team <a name="team"></a>  [^Back to Top](#top)
* Scientist(s): Wes Carter
* Research Director: Steve Bunnell
* Customer/PM: Abe Reddy
* Analyst: Susan Mehle
---  
### Study Population <a name="population"></a>  [^Back to Top](#top)

#### Inclusion Criteria: <a name="inclusion"></a>
* SavvySherpa/UHG R&D Member
* Enrolled between 1/1/2017 and 3/31/2019

#### Definitions <a name="definitions"></a>
* **<term>** = <definition>
---

### Data Dictionary <a name="dict"></a>  [^Back to Top](#top)
####Row Level Description
* Each row represents one day for one member

####Data Elements

Name | Description | Type
-- | -- | --
memberid | Unique identifier for the list of members who signed up for the motion program | Integer
membersignupdataid | 	Unique identifier for the list of members eligible for the motion program | Integer
indv_sys_id | TBD - CLAIMS | Integer
gendercode | Gender of the member in M or F format | "M" or "F" or <i>Null</i>
birthyear | Birth year of the member | Integer
zip_code  | Zip code of the member | String
programstartdate | Indicates the start date of the member in the program | Date
cancelleddatetime | Indicates the end date of the member in the program | Date




### Notes <a name="notes"></a>  [^Back to Top](#top)
* Who, what, when, where, why
---
### Issues <a name="issues"></a>  [^Back to Top](#top)
Issue | Owner | Opened | Closed | Resolution
-- | -- | -- | -- | --
Issue | Owner | Date | Date | Description
---
### Decision Tracker <a name="decisions"></a>  [^Back to Top](#top)
Decision | Date | Reason for decision
-- | -- | -- 
Decision | Date | Description
