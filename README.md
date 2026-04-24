# World-Layoffs-Data-Cleaning-SQL
 Performed end-to-end data cleaning on a global tech layoffs dataset using MySQL Workbench. 
# Key steps included: 
creating a staging table to preserve raw data, identifying and removing duplicate records using ROW_NUMBER() with PARTITION BY, standardizing inconsistent company names, industry labels, and country values using TRIM and string functions, converting date strings to proper DATE format using STR_TO_DATE(), populating NULL and blank values by self-joining on matching company records, and dropping redundant columns — resulting in a clean, structured dataset ready for exploratory analysis.
