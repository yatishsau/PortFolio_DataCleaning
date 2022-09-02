use PortfolioProject;

/*---------------------------------------------------------
cleaning data in SQL Queries.
---------------------------------------------------------*/

select * from NashvilleHousingData


/*---------------------------------------------------------
standardize sale date format
---------------------------------------------------------*/

alter table NashvilleHousingData
alter column SaleDate date

/*---------------------------------------------------------
Populate property address data
---------------------------------------------------------*/
--select * from NashvilleHousingData 
--where PropertyAddress is null

update a
set a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from NashvilleHousingData a
join NashvilleHousingData b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is null

/*---------------------------------------------------------
Breaking out PropertyAddress in individual (Address, city, state) columns.
---------------------------------------------------------*/

select * from NashvilleHousingData 

--select SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) [Prop_Address]
--		, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) Prop_city
--from NashvilleHousingData 

alter table NashvilleHousingData 
add Property_Address nvarchar(100);

update NashvilleHousingData 
set Property_Address = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1);

alter table NashvilleHousingData 
add Property_City nvarchar(100);

update NashvilleHousingData 
set Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress));


/*---------------------------------------------------------
Breaking out OwnerAddress in individual (Address, city, state) columns.
---------------------------------------------------------*/
select PARSENAME(replace(owneraddress,',','.'),3)
		,PARSENAME(replace(owneraddress,',','.'),2)
		,PARSENAME(replace(owneraddress,',','.'),1)
from NashvilleHousingData

alter table NashvilleHousingData
add Owner_address nvarchar(250);

update NashvilleHousingData
set Owner_address = PARSENAME(replace(owneraddress,',','.'),3);

alter table NashvilleHousingData
add Owner_City nvarchar(250);

update NashvilleHousingData
set Owner_City = PARSENAME(replace(owneraddress,',','.'),2);

alter table NashvilleHousingData
add Owner_State nvarchar(250);

update NashvilleHousingData
set Owner_State = PARSENAME(replace(owneraddress,',','.'),1);

select * from NashvilleHousingData

/*---------------------------------------------------------
Change Y and N to Yes and No in "sold as Vacant".
---------------------------------------------------------*/

select distinct soldasvacant, COUNT(soldasvacant)
from NashvilleHousingData
group by SoldAsVacant
order by 2;

select SoldAsVacant
		,case when SoldAsVacant ='Y' then 'Yes'
			when SoldAsVacant ='N' then 'No'
			else SoldAsVacant
			end
from NashvilleHousingData
where SoldAsVacant in ('Y','N')

update NashvilleHousingData
set
SoldAsVacant =  case when SoldAsVacant ='Y' then 'Yes'
				when SoldAsVacant ='N' then 'No'
				else SoldAsVacant
				end

/*---------------------------------------------------------
Remove Duplicates.
---------------------------------------------------------*/
with RowNumCTE as (
					select *,
							ROW_NUMBER() over (
							partition by parcelid
										,propertyaddress
										,saleprice
										,saledate
										,legalreference
										order by uniqueid) rn
					from NashvilleHousingData
				)
delete
from RowNumCTE
where rn > 1

--select *
--from RowNumCTE
--where rn > 1

/*---------------------------------------------------------
Delete the unused columns.
---------------------------------------------------------*/

--deleting Owneraddress,propertyaddress as we have already split these columns in individual columns.
alter table NashvilleHousingData
drop column Owneraddress,propertyaddress

select * from NashvilleHousingData