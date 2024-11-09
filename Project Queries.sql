SELECT * FROM rfm_segmentation.rfm_data;

update rfm_data
set `ORDERDATE.1` = str_to_date(`ORDERDATE.1`, '%d/%m/%Y');

select * from rfm_data;



-- Begin the Analysis

select * from rfm_data;

with cte1 as (
    -- Selects customer name, calculates frequency as count of unique order numbers, monetary value as total sales,
    -- identifies the last order date for each customer, and fetches the final date in the data for recency calculation.
    select customername as customer_name, 
           count(distinct ordernumber) as frequency, 
           round(sum(sales), 2) as monetary_value,
           max(`orderdate.1`) as last_order_date, 
           (select max(`orderdate.1`) from rfm_data) as final_date, 
           city as city, 
           country as country
    from rfm_data
    group by customer_name, city, country
), 

cte2 as (
    -- Adds a new column to calculate retency for each customer by finding the difference between the final date 
    -- and the customer's last order date, adding 1 to include the last day.
    select *, datediff(final_date, last_order_date) + 1 as retency
    from cte1
),

cte3 as (
    -- Creates retency, frequency, and monetary scores for each customer by dividing the dataset into quartiles.
    -- Higher scores imply better customer metrics for retency, frequency, and monetary value.
    select *, 
           ntile(4) over(order by retency desc) as retency_score,
           ntile(4) over(order by frequency) as frequency_score,
           ntile(4) over(order by monetary_value) as monetary_score
    from cte2
),

cte4 as (
    -- Concatenates the retency, frequency, and monetary scores into a combined RFM score for each customer.
    select *, concat(retency_score, frequency_score, monetary_score) as rfm_score
    from cte3
)

-- Final selection includes assigning each customer to an RFM segment based on their RFM score.
-- Classifies customers into segments like 'Loyal Customers', 'Potential Churners', etc., based on specific RFM score patterns.
select *, 
    case 
        when rfm_score in ('414', '314','424','434','444','324','334') then 'Loyal Customers'
        when rfm_score in ('113', '124', '214') then 'Potential Churners'
        when rfm_score in ('411', '422') then 'New Customers'
        when rfm_score in ('314', '244') then 'Big Spenders'
        when rfm_score in ('134', '244') then 'Can’t Lose Them'
        else 'Other' -- Fallback for any RFM scores that don't match the specified patterns
    end as segment
from cte4;