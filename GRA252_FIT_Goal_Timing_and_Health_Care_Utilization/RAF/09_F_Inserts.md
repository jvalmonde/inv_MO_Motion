```sql
--=========GroupTier8
INSERT INV_motion.tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src)

SELECT DISTINCT			
 a.UniqueMemberID				
,a.ModelCategoryID				
,GETModelGroupID				
,d.Term				
,d.Coefficient				
,"GroupTier8" Src
FROM INV_motion.tmp_D_HCC a				
  INNER JOIN INV_motion.tmp_E_AgeEdits b ON  a.UniqueMemberID = b.UniqueMemberID AND a.ModelCategoryID = b.ModelCategoryID	
  INNER JOIN INV_motion.raf_GroupTier8 c ON c.HAVEModelAgeID = b.EditedModelAgeID AND c.HAVEModelHCCID = a.ModelHCCID	
  INNER JOIN INV_motion.raf_ModelGroup d ON d.ModelGroupID = c.GETModelGroupID;
  
 --=========GroupTier7 
INSERT INV_motion.tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src)

SELECT DISTINCT			
 a.UniqueMemberID				
,a.ModelCategoryID				
,GETModelGroupID				
,c.Term				
,c.Coefficient				
,"GroupTier7" Src
FROM INV_motion.tmp_E_AgeEdits a
  INNER JOIN INV_motion.raf_GroupTier7 b ON a.EditedModelAgeID = b.HaveModelAgeID 
  INNER JOIN INV_motion.raf_ModelGroup c ON c.ModelGroupID = b.GETModelGroupID;
  
   --=========GroupTier1
   INSERT INV_motion.tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src)

SELECT DISTINCT			
 a.UniqueMemberID				
,a.ModelCategoryID				
,GETModelGroupID				
,c.Term				
,c.Coefficient				
,"GroupTier1" Src
FROM INV_motion.tmp_D_HCC a
  INNER JOIN INV_motion.raf_GroupTier1 b ON a.ModelHCCID = b.HAVEModelHCCID 
  INNER JOIN INV_motion.raf_ModelGroup c ON c.ModelGroupID = b.GETModelGroupID;
  
  
   --=========GroupTier3
   INSERT INV_motion.tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src)

SELECT DISTINCT			
 a.UniqueMemberID				
,a.ModelCategoryID				
,c.GETModelGroupID				
,d.Term				
,d.Coefficient				
,"GroupTier3" Src
FROM INV_motion.tmp_F_Group a
  INNER JOIN INV_motion.tmp_F_Group b ON a.UniqueMemberID = b.UniqueMemberID AND a.ModelCategoryID = b.ModelCategoryID AND a.GETModelGroupID <> b.GETModelGroupID
  INNER JOIN INV_motion.raf_GroupTier3 c ON c.HAVE1ModelGroupID = a.GETModelGroupID AND c.HAVE2ModelGroupID = b.GETModelGroupID
  INNER JOIN INV_motion.raf_ModelGroup d ON d.ModelGroupID = c.GETModelGroupID;
  
--=========GroupTier4
  INSERT INV_motion.tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src)

SELECT DISTINCT			
 a.UniqueMemberID				
,a.ModelCategoryID				
,c.GETModelGroupID				
,d.Term				
,d.Coefficient				
,"GroupTier4" Src
FROM INV_motion.tmp_F_Group a
  INNER JOIN INV_motion.raf_GroupTier4 c ON c.HAVEModelGroupID = a.GETModelGroupID 
  INNER JOIN INV_motion.raf_ModelGroup d ON d.ModelGroupID = c.GETModelGroupID;
  
  
--=========GroupTier5
INSERT INV_motion.tmp_F_Group (UniqueMemberID, ModelCategoryID, GETModelGroupID, Term, Coefficient, Src)

SELECT DISTINCT			
 a.UniqueMemberID				
,a.ModelCategoryID				
,b.GETModelGroupID				
,c.Term				
,c.Coefficient				
,"GroupTier5" Src
FROM INV_motion.tmp_F_Group a
  INNER JOIN INV_motion.raf_GroupTier5 b ON a.GETModelGroupID = b.HAVEModelGroupID		
  INNER JOIN INV_motion.raf_ModelGroup c ON c.ModelGroupID = b.GETModelGroupID		
Where a.UniqueMemberID NOT IN					
		(--Check to make sure that a Member does not have a disqualifying ModelGroupID			
		Select a.UniqueMemberID			
		From INV_motion.tmp_F_Group a		
				inner join INV_motion.raf_GroupTier5 b	
					on a.GETModelGroupID = b.DONOTHAVEModelGroupID
		) ;	
  
 
  ```
