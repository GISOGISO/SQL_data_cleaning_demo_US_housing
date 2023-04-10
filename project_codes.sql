
-- 1. create database and load data into MySQL table

create database if not exists nashville_housing_db;
use nashville_housing_db;

	DROP TABLE IF EXISTS nashville_housing_table;
    CREATE TABLE nashville_housing_table (
  UniqueID int,
  ParcelID varchar(255),
  LandUse varchar(255),
  PropertyAddress varchar(255),
  SaleDate date,
  SaleDate2 date,
  SalePrice decimal(10,2),
  LegalReference varchar(255),
  SoldAsVacant varchar(255),
  OwnerName varchar(255),
  OwnerAddress varchar(255),
  Acreage decimal(10,2),
  TaxDistrict varchar(255),
  LandValue decimal(10,2),
  BuildingValue decimal(10,2),
  TotalValue decimal(10,2),
  YearBuilt int,
  Bedrooms int,
  FullBath int,
  HalfBath int
);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Nashville_Housing_Data.csv' 
INTO TABLE nashville_housing_table 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
;

-- 2. data checking
select * from nashville_housing_table
;

-- 3. data preprocessing
ALTER TABLE nashville_housing_table
DROP COLUMN saledate,
CHANGE COLUMN saledate2 saledate date;
DELETE FROM nashville_housing_table WHERE UniqueID = '0';

UPDATE nashville_housing_table
SET saledate = NULL
WHERE saledate = 0000-00-00;

-- 4. Populate Property Address data
-- a. assign null value to all empty strings

UPDATE nashville_housing_table
SET PropertyAddress = NULL
WHERE PropertyAddress = ''
;
-- b. Populate Property Address data
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress) 
From nashville_housing_table a
JOIN nashville_housing_table b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
    Where a.PropertyAddress is null
;

Update nashville_housing_table a
JOIN nashville_housing_table b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
    SET a.PropertyAddress = COALESCE(a.PropertyAddress,b.PropertyAddress)
Where a.PropertyAddress is null
;


-- 5. Break down Address into Individual Columns (Address, City, State)
-- a. breakdown property address

ALTER TABLE nashville_housing_table
Add Property_Address Nvarchar(255);
Update nashville_housing_table
SET Property_Address = SUBSTRING(PropertyAddress, 1, LOCATE('|', PropertyAddress) -1 )
;

ALTER TABLE nashville_housing_table
Add Property_City Nvarchar(255);
Update nashville_housing_table
SET Property_City = SUBSTRING(PropertyAddress, LOCATE('|', PropertyAddress) + 1 , LENGTH(PropertyAddress))
;

-- b. breakdown owner address

ALTER TABLE nashville_housing_table
Add Owner_Address Nvarchar(255);
Update nashville_housing_table
SET Owner_Address = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, '|', 1), '|', -1)
;

ALTER TABLE nashville_housing_table
Add Owner_City Nvarchar(255);
Update nashville_housing_table
SET Owner_City = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, '|', 2), '|', -1)
;

ALTER TABLE nashville_housing_table
Add Owner_State Nvarchar(255);
Update nashville_housing_table
SET Owner_State = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, '|', 3), '|', -1)
;


-- 6. Clean the "Sold as Vacant" field by consolidating all values to Yes/No

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From nashville_housing_table
;

Update nashville_housing_table
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
;

-- 7. Remove Duplicates

DELETE FROM nashville_housing_table
WHERE UniqueID NOT IN (
  SELECT * FROM (
    SELECT MIN(UniqueID)
    FROM nashville_housing_table
    GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
  ) AS t
);

select * from nashville_housing_table;

-- 8. Delete Unused Columns

ALTER TABLE nashville_housing_table
DROP COLUMN TaxDistrict
;








