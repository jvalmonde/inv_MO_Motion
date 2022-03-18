> #### Author: Susan Mehle
> #### Description: Identify what ModelCategoryID(s) a member should be associated with
> ####  Other Code
>   * NGIS - [RA_Commercial_2016] Stored Procedure [dbo].[spRAFDiagInput]
> 
> #####  Input
>   * research-00: INV_motion.raf_Model
>   * research-00: INV_motion.raf_ModelCategory
>   * research-00: NV_motion.GRA252_raf_Person2015
> 
> ####  Output
>   * research-00: INV_motion.RA_Com_A_IdentifyModelCategory

```SQL

  CREATE OR REPLACE TABLE INV_motion.tmp_A_IdentifyModelCategory AS

  WITH vwIdentifyModelCategory AS (SELECT a.ModelID, b.ModelCategoryID, b.AgeStart, b.AgeEnd
                                     FROM INV_motion.raf_Model AS a 
                                     INNER JOIN INV_motion.raf_ModelCategory b ON a.ModelID = b.ModelID)

  SELECT DISTINCT UniqueMemberID, ModelID, ModelCategoryID							
    FROM INV_motion.GRA252_raf_Person a 
    INNER JOIN vwIdentifyModelCategory b ON a.age Between b.AgeStart AND b.AgeEnd
```
