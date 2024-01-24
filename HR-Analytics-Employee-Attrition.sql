
--Display Top 5 in Table HR-Employee 
SELECT TOP 5 * FROM [dbo].[HR-Employee-Attrition] ;


--------Display SOME  kpi---------------------

--Total Num of Employee 
SELECT COUNT([EmployeeNumber]) AS NumberOfEMP FROM [dbo].[HR-Employee-Attrition] ;

----Number of Employee Atrrition 
SELECT CASE WHEN [Attrition] ='Yes'
      THEN  COUNT([Attrition]) 	 
	  END
	  AS 'Total Employee Atrrition' 
FROM [dbo].[HR-Employee-Attrition]
GROUP BY [Attrition]
;

----SUM Monthly Income for all Employees 
SELECT CAST(SUM([MonthlyIncome]) AS nvarchar(MAX)) +' $' AS 'Total Monthly Income'
FROM [dbo].[HR-Employee-Attrition];

----Avarage Precent Salary Hike 
SELECT CAST(AVG([PercentSalaryHike]) AS nvarchar(MAX)) +' %' AS 'Avarage Precent Salary Hike'
FROM [dbo].[HR-Employee-Attrition];
---------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------INSIGHTS
----------------count employees attrition based on age 
SELECT 
  CASE 
    WHEN [Age] <= 18 THEN 'Under 18' 
    WHEN [Age] BETWEEN 19 AND 40 THEN '19-40' 
    ELSE 'Over 40' 
  END AS 'Age Group', 
  COUNT(*) AS 'Total Employee Attrition' 
FROM [dbo].[HR-Employee-Attrition] 
WHERE [Attrition] = 'Yes'
GROUP BY 
  CASE 
    WHEN [Age] <= 18 THEN 'Under 18' 
    WHEN [Age] BETWEEN 19 AND 40 THEN '19-40' 
    ELSE 'Over 40' 
  END;

  ------- count attrition of employees based on Businedd travel and gender 
  WITH BT_AND_GENDER 
  AS
  (
  SELECT [BusinessTravel] ,[Gender],[Attrition]
  FROM [dbo].[HR-Employee-Attrition] 
  WHERE [Attrition] = 'Yes' 
  )SELECT * FROM BT_AND_GENDER
  PIVOT
      (
	  COUNT([Attrition])
	  FOR [BusinessTravel] IN([Travel_Rarely],[Travel_Frequently])
	  
	  
	  ) AS pivot_table


----------------Number of employee attrition based on department 
GO
CREATE VIEW V_Attrition_EachDEP
AS
	SELECT  [Department], [Attrition]
	FROM [dbo].[HR-Employee-Attrition]
	WHERE [Attrition] = 'Yes';
GO

DECLARE @COLUMNS NVARCHAR(MAX) = '';
DECLARE @DynamicSQL NVARCHAR(MAX);
DECLARE @Title NVARCHAR(MAX) = 'Employee Attrition Report FOR Each Department';
-- Generate the list of unique columns
WITH UniqueDepartments AS (
    SELECT DISTINCT [Department]
    FROM [dbo].[HR-Employee-Attrition]
)
SELECT @COLUMNS += QUOTENAME( [Department]) + ','
FROM UniqueDepartments
ORDER BY [Department];

SET @COLUMNS = LEFT(@COLUMNS, LEN(@COLUMNS) - 1);

-- Build the dynamic SQL statement
SET @DynamicSQL = '

SELECT  ''' + @Title + ''' AS Title, * 
FROM  V_Attrition_EachDEP

PIVOT (
    COUNT([Attrition])
    FOR [Department] IN (' + @COLUMNS + ')
) AS pivot_table;';

-- Execute the dynamic SQL with parameters
EXEC sp_executesql @DynamicSQL;


----------------------------------------------------
--------Num Of attrition based on EducationField and Education
GO
alter FUNCTION FN_Geteducationlevel ()
RETURNS TABLE 
AS 
RETURN
     (
	 SELECT  EducationField , Attrition ,Education 
	 FROM [HR-Employee-Attrition]
	 WHERE Attrition ='Yes'
	 );
GO
alter PROCEDURE sp_DisplayTotalAttritionPer
AS 
BEGIN
    DECLARE @TABLE TABLE(EducationField NVARCHAR(MAX), Attrition CHAR(20), LevelEducation NVARCHAR(MAX)) 

    INSERT INTO @TABLE
    SELECT EducationField, Attrition, Education AS'LevelEducation'
    FROM FN_Geteducationlevel()
    SELECT *
    FROM @TABLE
    PIVOT
    ( 
        COUNT(Attrition)
        FOR EducationField IN ([Human Resources], [Life Sciences], [Marketing], [Medical], [Technical Degree], [Other])
    ) AS PivotTable;
END;

----EXECUTE PROCEDURE 
EXEC dbo.sp_DisplayTotalAttritionPer


---------------------------------------------------
---Attrition Employee Based On Marital Status 
GO
CREATE VIEW v_attritionOfMaritalStatus
AS 
(
SELECT [MaritalStatus],COUNT([Attrition]) as 'Number Of Attrition'
FROM [dbo].[HR-Employee-Attrition]
WHERE [Attrition]='Yes'
GROUP BY [MaritalStatus] 
);

SELECT * FROM v_attritionOfMaritalStatus;


----------------------------------------------------------------------------------------------
------ Total Num Of employee Attrition Per Jop Role 
With CTE_Getdata
AS (
SELECT   [EmployeeNumber],[Attrition]AS 'Attrition_Employees',[JobRole]
FROM [dbo].[HR-Employee-Attrition]


)
SELECT * FROM CTE_Getdata
PIVOT(
COUNT([EmployeeNumber])
FOR [JobRole] IN([Sales Executive] ,[Research Scientist],
                 [Laboratory Technician],[Manufacturing Director],[Healthcare Representative],
				 [Manager],[Human Resources] )

) AS PIVOT_TABLE


-------------------------------------------------------------------------------------------------------------------------------------
----Attrition_Employees by DistanceFromHome
WITH CTE_DISTANCE AS
(select [Attrition] AS 'Attriation_Employees' , [EmployeeNumber], CASE   
                     WHEN [DistanceFromHome] BETWEEN 1 AND 10 THEN 'Near'
					 WHEN [DistanceFromHome] BETWEEN 11 AND 19 THEN 'Far'
					 ELSE  'Very Far'
					 END AS 'DistanceFromHome'
FROM [dbo].[HR-Employee-Attrition] )
SELECT * FROM CTE_DISTANCE
PIVOT
(
COUNT([EmployeeNumber])
FOR DistanceFromHome IN ([Near],[Far],[Very Far])

)AS PIVOT_TABLE
--------------------------------------------------------------
----Attrition_Employees by WorkLifeBalance

WITH CTE_Balance AS
(select [Attrition] AS 'Attriation_Employees' , [EmployeeNumber], CASE [WorkLifeBalance]  
                     WHEN 1   THEN 'Bad'
					 WHEN 2 THEN 'Average'
					 WHEN 3 THEN 'Good'
					 else 'Excellent'
					 END AS 'WorkLifeBalance'
FROM [dbo].[HR-Employee-Attrition] )
SELECT * FROM CTE_Balance
PIVOT
(
COUNT([EmployeeNumber])
FOR WorkLifeBalance IN ([Good],[Average],[Excellent],[Bad])

)AS PIVOT_TABLE
