# SHG-Analysis
This repo contains the files and scripts used in my attempt at the Splendor Hotel Group Analysis. The idea behind this project is to demonstrate my SQL, Tableau, business intelligence skills.

![SHG dashboard](https://github.com/TobyTobi/SHG-Analysis/assets/102298244/eaa6a46c-afff-436d-88fe-1f258d9c2b75)


The full interactive dashboard can be found [here](https://public.tableau.com/app/profile/tobiloba.babajide/viz/SHGDashboard_17012996593220/Revenue)

## ANALYTICS APPROACH
### DATA COLLECTION
The dataset was made available by Uchenna Splendor along with the Project brief [here](https://drive.google.com/drive/folders/1fVXLsP4nvgJJ4kxiUx92Dk8KUJtEgJTQ)

### DATA PROCESSING
SQL Server (SSMS) was used for the processing, cleaning, and data analysis in this project to extract initial insights and answers to the questions in the project brief.
The data was imported into the already created database using the Import data option:

![image](https://github.com/TobyTobi/SHG-Analysis/assets/102298244/495fd7e4-44d1-4e3f-b704-9a2a8ec9fa21)


### DATA CLEANING
Several steps were taken to clean the data including:
1. Replacing null values to prevent data loss
2. Correcting spellings of several values to allow for consistency
3. Changing necessary data formats
4. Correcting wrong values
5. Checking for duplicates

### DATA ANALYSIS
Then, I went ahead to answer the business questions that were posed in the Project brief using several SQL fucntions:
1. Aggregate functions e.g. ```COUNT()```and ```SUM()```
2. Window functions e.g. ```ROW_NUMBER()```
3. Date functions e.g. ```YEAR()``` and ```MONTH()```
4. Common Table Expressions (CTE)
5. Logical functions e.g. ```CASE WHEN```
6. Mathematical functions e.g. ```ROUND()```
7. Joins
8. String Concatenation

### BUSINESS DASHBOARD CREATION
Finally, I created the business intelligence dashboard using Tableau where I made use of the following features:
1. Parameter actions to create filters
2. Navigation buttons to move between dashboard pages
3. Custom shapes and icons
4. BANs creation for easy-to-understand KPIs
5. Color selection
6. Calculated fields e.g. conditional logic, date functions
