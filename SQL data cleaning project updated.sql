--STANDARDIZE DATE format

SELECT SaleDate, CONVERT (Date,SaleDate)
FROM PortfolioProject..NVHousing


UPDATE NVHousing
SET SaleDate = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT (Date, SaleDate)
FROM PortfolioProject..NVHousing

ALTER TABLE NVHousing
ADD SaleDateConverted Date;

UPDATE NVHousing
SET SaleDateConverted = CONVERT (Date,SaleDate)

--POPULATE PROPERTY ADDRESS DATA

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL (a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NVHousing a	JOIN PortfolioProject..NVHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL (a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NVHousing a	JOIN PortfolioProject..NVHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL


--BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (Address, City, State)

SELECT SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1) AS [Address]
	, SUBSTRING (PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN (PropertyAddress)) AS [Address]
FROM PortfolioProject..NVHousing


ALTER TABLE NVHousing
ADD PropertySplitAddress Nvarchar (255);

UPDATE NVHousing
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress) -1)


ALTER TABLE NVHousing
ADD PropertySplitCity Nvarchar (255);

UPDATE NVHousing
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX (',', PropertyAddress) +1, LEN (PropertyAddress))


SELECT PARSENAME (REPLACE(OwnerAddress, ',','.'), 3)
	, PARSENAME (REPLACE(OwnerAddress, ',','.'), 2)
	, PARSENAME (REPLACE(OwnerAddress, ',','.'), 1)
FROM PortfolioProject..NVHousing

ALTER TABLE NVHousing
ADD OwnerSplitAddress Nvarchar (255);

UPDATE NVHousing
SET OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress, ',','.'), 3)


ALTER TABLE NVHousing
ADD OwnerSplitCity Nvarchar (255);

UPDATE NVHousing
SET OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE NVHousing
ADD OwnerSplitState Nvarchar (255);

UPDATE NVHousing
SET OwnerSplitState = PARSENAME (REPLACE(OwnerAddress, ',','.'), 1)



--CHANGE Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD

SELECT DISTINCT (SoldAsVacant), COUNT (SoldAsVacant)
FROM PortfolioProject..NVHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
	, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NVHousing


UPDATE NVHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NVHousing



--REMOVE DUPLICATES

WITH RowNumCTE AS (
SELECT *
	, ROW_NUMBER () OVER (PARTITION BY 
	ParcelID, 
	PropertyAddress,
	SalePrice, 
	SaleDate,
	LegalReference
ORDER BY  UniqueID) row_num

FROM PortfolioProject..NVHousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress




--DELETED UNUSED COLUMNS

SELECT *
FROM PortfolioProject..NVHousing

ALTER TABLE PortfolioProject..NVHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
