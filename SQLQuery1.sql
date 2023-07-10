use ukppdb;
-------------------UK Post purchase cars table-----------------------------
with cte as
(
select 'audi' as car_type, * from audi
union
select 'merc' as car_type, * from merc
union
select 'cclass' as car_type, ID, model_ID, year, price, mileage, '0' as tax, '0' as mpg,
engineSize, transmission_ID, fuel_ID
from cclass
union
select 'hyundai' as car_type, * from hyndai
union
select 'bmw' as car_type, * from bmw
)
select * 
into #ukcars
from cte;
---------------------------------------------------------------------------
select * from #ukcars order by year;
---------------------------------------------------------------------------
------------------------bucket parameters----------------------------------
select year, min(price) as b0, min(price)+((max(price)-min(price))/3) as b1,
min(price)+(2*(max(price)-min(price))/3) as b2, 
max(price) as b3, min(mpg) as m0, min(mpg)+((max(mpg)-min(mpg))/3) as m1,
min(mpg)+(2*(max(mpg)-min(mpg))/3) as m2, 
max(mpg) as m3, min(engineSize) as e0, min(engineSize)+((max(engineSize)-min(engineSize))/3) as e1,
min(engineSize)+(2*(max(engineSize)-min(engineSize))/3) as e2, 
max(engineSize) as e3, min(tax) as t0, min(tax)+((max(tax)-min(tax))/3) as t1,
min(tax)+(2*(max(tax)-min(tax))/3) as t2, 
max(tax) as t3
into #carpeaks
from #ukcars
group by year
order by year;
drop table #carpeaks;
select * from #carpeaks
order by year;

select * from #ukcars where fuel_ID not in (2,3)
order by year, fuel_ID;

---------------------------------#ukppcd---------------------------------
select u.car_type,u.ID, m.model_name, u.year,u.price, u.mileage, 
u.tax, u.mpg, u.engineSize, t.transmission, f.fueltype, 
case when (u.price >= c.b0) and (u.price < c.b1) then 'low-end'
when (u.price >= c.b1) and (u.price < c.b2) then 'mid-tier'
when (u.price >= c.b2) and (u.price <= c.b3) then 'high-end'
end as car_segment
into uk_price_seg
from #ukcars u
left join #carpeaks c on u.year = c.year
left join models m on u.model_ID = m.model_ID
left join transmission t on u.transmission_ID = t.ID
left join fueltype f on u.fuel_ID = f.fuel_ID;


select * into ukcd from #ukppcd;
---------------------------------------------------------------------------
----------------Market size----------------------------
select car_segment, year, sum(price) as market_size
from #ukppcd
group by car_segment, year
order by car_segment, year;
----------------Brand Market size----------------------
select car_type, car_segment, year, sum(price) as market_size
from #ukppcd
group by car_type, car_segment, year
order by car_type, car_segment, year;
----------------Market size of brands as of 2020-----------------------------
select car_type, concat((sum(price)/1000000),' Mn') as market_size_crr
from #ukppcd
where year='2020'
group by car_type
order by  sum(price) desc;
----------------Avg number of cars sold per year--------------------------
select car_type, avg(cars_sold) as cars_p_year
from (select car_type, year, count(price) as cars_sold from #ukppcd group by car_type, year) c
group by car_type
order by  avg(cars_sold) desc;
--------------------------------------------------------------------------
select distinct car_type from #ukppcd;
--------------------------------------------------------------------------
select f.fueltype, u.year, sum(u.price) as market
from #ukppcd u 
left join fueltype f on u.fuel_ID = f.fuel_ID
group by f.fueltype, u.year
order by f.fueltype, u.year;
create view uk_fuel_price_change
as
select Year, 
round(100*((lead(Petrol) over(order by Year))-Petrol)/Petrol,2) as petrol_price_hike, 
round(100*((lead(Deisel) over(order by Year))-Deisel)/Deisel,2) as Diesel_price_hike 
from ukfp;
select * from uk_fuel_price_change;
create view uk_ycs
as 
select car_segment, year, count(*) as cars_sold
from ukcd 
group by car_segment, year;
drop procedure uk_ycs;
----------------------fuel type sales--------------------------
select u.*, f.fueltype 
into #ukfppd
from #ukppcd u 
left join fueltype f on u.fuel_ID = f.fuel_ID
select fuel_ID, fueltype, count(*) as car_sales
from #ukfppd
where year = '2019'
group by fuel_ID, fueltype
order by count(*) desc;
select fueltype, year, count(*) as car_sales
from #ukfppd
group by fueltype, year
order by fueltype, year;

-------------------Petrol, Deisel, Hybrid tax--------------
select fueltype, year, 
avg(tax) as avg_road_tax, count(*) as car_sales
from #ukfppd
group by fueltype, year
order by fueltype, year;
-----------------------------------------------------------
select * from #ukppcd u left join ukfp f on u.year= f.Year;
select u.car_type, u.car_segment, u.year, u.price,
case when fuel_ID = 1 then (u.mileage/u.mpg)*f.Deisel*4.546
when fuel_ID in (5,3) then (u.mileage/u.mpg)*f.Petrol*4.546
when fuel_ID = 4 then 

from #ukppcd u left join ukfp f on u.year = f.Year;

------------------------------------------------------------
select u.car_type,u.ID, u.model_ID, u.year,u.price, u.mileage, 
u.tax, u.mpg, u.engineSize, u.transmission_ID, u.fuel_ID, 
case when (u.mpg >= c.m0) and (u.mpg < c.m1) then 'sport'
when (u.mpg >= c.m1) and (u.mpg < c.m2) then 'commuter'
when (u.mpg >= c.m2) and (u.mpg <= c.m3) then 'eco'
end as car_segment
into #ukmpgsd
from #ukppcd u left join #carpeaks c on u.year= c.year;
select * from #ukmpgsd;
select u.car_segment, f.fueltype, u.year, 
avg(u.mpg) as avg_mpg, count(u.ID) as car_sales, avg(u.price) as avg_car_price
from #ukmpgsd u left join fueltype f on u.fuel_ID = f.fuel_ID
group by u.car_segment, f.fueltype, u.year
order by u.car_segment, f.fueltype, u.year;

select * from uk_fuel_prices;
------------------------------------------------------------
select u.car_type as brand, u.ID, m.model_name, u.year, u.price, u.mileage, 
u.tax, u.mpg, u.engineSize, t.transmission, f.fueltype, u.car_segment
into ukucd
from  #ukmpgsd u left join models m on u.model_ID = m.model_ID
left join transmission t on u.transmission_ID = t.ID
left join fueltype f on u.fuel_ID = f.fuel_ID;
------------------------------------------------------------
drop table ukucd;
------------------------------------------------------------
select * from ukucd;
select * from uk_fuel_prices;
----1. Total cars sold by brands-----------------------------------------------------------
create view brand_vol
as
select brand, count(*) as total_car_sales from ukucd group by brand;
----2. Total sales made by brands--------------------------------------------------------
create view brand_sales
as
select brand, round(sum(price)/100000,2) as brand_sales_mn
from ukucd
group by brand;
----3. 
select * from brand_sales;
select brand, year, count(*) as total_car_sales 
from ukucd 
group by brand, year 
order by brand, year;
---------------------------------------------------------------------
with cte
as
(
select brand, model_name, avg(mpg) as mileage, count(*) as car_sales,
ROW_NUMBER() over(partition by brand order by count(*) desc) as rnk
from ukucd
group by brand, model_name
)
select brand, model_name, mileage, car_sales, Rnk
from cte
where rnk <=10
order by brand,rnk;

---3. Segment cars on the basis of their price-----------------------
select u.car_type,u.ID, m.model_name, u.year,u.price, u.mileage, 
u.tax, u.mpg, u.engineSize, t.transmission, f.fueltype, 
case when (u.price >= c.b0) and (u.price < c.b1) then 'low-end'
when (u.price >= c.b1) and (u.price < c.b2) then 'mid-tier'
when (u.price >= c.b2) and (u.price <= c.b3) then 'high-end'
end as car_segment
into uk_price_seg
from #ukcars u
left join #carpeaks c on u.year = c.year
left join models m on u.model_ID = m.model_ID
left join transmission t on u.transmission_ID = t.ID
left join fueltype f on u.fuel_ID = f.fuel_ID;

select * from uk_price_seg;
------3.a Price change across segments over the years-----------------
create view seg_sales
as
with cte2
as
(
select year,
case when car_segment like 'low_end' then price_in_k else 0 end as low_end,
case when car_segment like 'mid_tier' then price_in_k else 0 end as mid_tier,
case when car_segment like 'high_end' then price_in_k else 0 end as high_end
from uk_price_seg
)
select year, sum(low_end) as low_end, sum(mid_tier) as mid_tier,
sum(high_end) as high_end
from cte2
group by year;

------3.b Volume sold change across segments over the years-----------
create view seg_vol
as
with cte2
as
(
select year,
case when car_segment like 'low_end' then 1 else 0 end as low_end,
case when car_segment like 'mid_tier' then 1 else 0 end as mid_tier,
case when car_segment like 'high_end' then 1 else 0 end as high_end
from uk_price_seg
)
select year, sum(low_end) as low_end_vol, sum(mid_tier) as mid_tier_vol,
sum(high_end) as high_end_vol
from cte2
group by year
----------3.c.a %change in sales across years-------------------------
select * from seg_sales order by year;
select year, 
lead(low_end) over(order by year)- low_end as low_end_sg,
lead(mid_tier) over(order by year)- mid_tier as mid_tier_sg,
lead(high_end) over(order by year)- high_end as high_end_sg
from seg_sales
order by year;
------3.c Segments who have seen significant jump over their price---- 
select * from seg_sales;
select * from uk_price_seg;

with model_tbl as
(
select model_name, fueltype, sum(price_in_k) as total_sales, count(ID) as models_sold, avg(price_in_k) as avg_price,
avg(mileage) as avg_mileage, round(avg(engineSize),2) as avg_engine_size
from uk_price_seg
group by model_name, fueltype
)
select model_name, fueltype, total_sales, models_sold, avg_price, avg_mileage, avg_engine_size,
ROW_NUMBER() over( order by total_sales desc, models_sold desc, avg_price, avg_mileage, avg_engine_size desc) as model_rank
into #model_top_5
from model_tbl
order by ROW_NUMBER() over( order by total_sales desc, models_sold desc, avg_price, avg_mileage, avg_engine_size desc);

select * from #model_top_5
where model_rank<6;
