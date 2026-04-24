-- DATA CLEANING


SELECT *
FROM layoffs;

-- 1. Removing Duplicates
-- 2. Standardize Data
-- 3. Null/Blank Values
-- 4. Removing Any unnecessary columns


##INSTEAD OF EDITING WITH THE RAW DATA FILE, WE CAN MAKE A COPY OF THAT IN THE FOLLOWING MANNER:

CREATE TABLE layoffs_staging
LIKE layoffs;       -- CREATES THE COLUMNS FOR THE TABLE

INSERT layoffs_staging
SELECT *
FROM layoffs;-- COPIES AND INSERTS THE VALUE FROM THE RAW TABLE TO THIS TABLE


SELECT *
FROM layoffs_staging;

-- ------------------------------------------------------------------------------------------------
-- 1. Removing Duplicates:

# CREATING ROW NUMBERS - 
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num #date is a keyword in mysql, that is why it is in backsticks.
FROM layoffs_staging;

#IF ANY ROW NUMBER IS GRATER THAN OR EQUAL TO 2, THEN THERE IS A DUPLICATE. 

#CREATING A CTE:
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num #date is a keyword in mysql, that is why it is in backsticks.
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- let's just look at oda to confirm
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda'
;
-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate
-- -------------------------------XX------
## we cann0t directly delete the duplicates from the CTEs in MySQL, unline MSS or PostgreSQL
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE 
FROM duplicate_cte
WHERE row_num > 1;   #ERROR: The Target table duplicate_cte of the delete is NOT UPDATABLE.
-- -------------------------------XX------

#Therefore, to delete the dulicates :
-- We can make a filter on the row_num of the layoffs_staging, copy it in a different table, and delete the duplicated where row_num >1.

CREATE TABLE `layoffs_staging2` (               ##WE CREATED THIS CREATE TABLE CODE BY GOING TO SCHEMAS --> WORLD_LAYOFFS-->TABLES-->LAYOFFS_STAGING-->(RIGHT CLICK) COPY TO CLIPBOARD --> CREATE STATEMENT.
  `company` text,
  `location` text,     
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT                                    ##WE ADDED THIS ROW_NUM HERE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num #date is a keyword in mysql, that is why it is in backsticks.
FROM layoffs_staging;


SELECT *
FROM layoffs_staging2
WHERE row_num > 1;
##NOW WE'RE GOING TO DELETE THESE DUPLICATES.

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;

-- ------------------------------------------------------------------------------------------------

#2. STANDARDIZING THE DATA (Finding issues and fxing it)

-- There are some unwanted white spaces in some company names-- lt's fix it.

SELECT company, TRIM(company) company_updated
FROM layoffs_staging2;

-- Now we need to update the table.

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Taking a look at the industries column

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1
; -- We found out there are null values, spaces, and 3 mentions of a same industry, Crypto, CrypptoCurrency, Crypto Currency

-- Dealing with cryptos first. Finding out the flaws and updating the table.
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; 

-- Now we're looking at other columns.
SELECT *
FROM layoffs_staging2;

-- Looking at country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;  #Found a discrepancy regarding United States.
-- Fixing the problem:

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) #This Trailing deletes the '.' character present at the end of the word.
FROM layoffs_staging2
ORDER BY 1;

#Updating the error in the table
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; 

SELECT *
FROM layoffs_staging2;

-- Now, if we see the date column, in the layoffs_staging2 table under schemas, we can see that it is in a text format. which is not good, If we are gooing to do time- series stuff.

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')   #This will convert the data type of the dates , from text to date. Also it is going to be formatting the date.
FROM layoffs_staging2;

-- Updating the date format to the table:
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
-- Though the date looks like in a date format, if we still click on date column it shouws up as a text category, so to fix that:

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; #Now the date column is in a date data type.

-- ---------------------------------------------------------------------------------------------------------------------------------------
#3. Working with NULL/ BLANK VALUES :

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT t1.industry,t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;


UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

#Now there are some of the companys which have total_laid_off and percentage_laid_off as NULL values. Though it is a controversial decision, we're going to delete the rows which have values as null.

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

##DELETIGN THOSE ROWS:
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;