# RFM Segmentation Project

## Objectives
The goal of this project is to perform RFM (Retency, Frequency, Monetary) segmentation on customer transaction data. The segmentation aims to classify customers into distinct groups based on their purchasing behavior, allowing for more targeted marketing and customer relationship management strategies.

**Project Objectives:**
1. Calculate RFM metrics (Retency, Frequency, and Monetary Value) for each customer.
2. Assign scores to each RFM metric based on quartiles.
3. Concatenate RFM scores to create unique RFM segments.
4. Classify customers into defined segments (e.g., Loyal Customers, Potential Churners) based on their RFM scores.

## Methodology
This project is implemented using MySQL for data processing and segmentation, and Python for data visualization.

1. **Data Extraction**: Retrieve relevant customer information (e.g., customer name, city, country), sales frequency, and monetary value for analysis.
2. **Retency Calculation**: Calculate the retency metric by determining the days since the last purchase, based on the final date in the dataset.
3. **Score Calculation**: Use the `ntile` function to divide Retency, Frequency, and Monetary Value into quartiles, creating a score for each metric.
4. **RFM Segmentation**: Concatenate the scores to create unique RFM scores and assign customers to predefined segments.
5. **Data Visualization**: Visualize the customer segments and insights derived from the RFM analysis using Python libraries (e.g., Matplotlib, Seaborn) for enhanced analysis and presentation.

## SQL Code for RFM Segmentation

Below is the SQL code used for this project. The code is broken down into four Common Table Expressions (CTEs) for clarity and modularity:

### CTE1: Initial Aggregation
The first CTE (`cte1`) aggregates data by calculating Frequency (count of unique orders), Monetary Value (total sales), and retrieving the Last Order Date for each customer. It also fetches the final date from the dataset to assist with Retency calculation.

```sql
with cte1 as (
    select customername as customer_name, 
           count(distinct ordernumber) as frequency, 
           round(sum(sales), 2) as monetary_value,
           max(`orderdate.1`) as last_order_date, 
           (select max(`orderdate.1`) from rfm_data) as final_date, 
           city as city, 
           country as country
    from rfm_data
    group by customer_name, city, country
)
```

### CTE2: Retency Calculation
The second CTE (`cte2`) calculates the Retency metric for each customer. It finds the difference between the Final Date and the Last Order Date, adding 1 to ensure the last day is included.

```sql
cte2 as (
    select *, datediff(final_date, last_order_date) + 1 as recency
    from cte1
)
```

### CTE3: Scoring Each Metric
The third CTE (`cte3`) uses quartiles to score each metric (Retency, Frequency, and Monetary Value) based on customer data. Higher scores represent better customer behavior for each metric.

```sql
cte3 as (
    select *, 
           ntile(4) over(order by recency desc) as recency_score,
           ntile(4) over(order by frequency) as frequency_score,
           ntile(4) over(order by monetary_value) as monetary_score
    from cte2
)
```

### CTE4: RFM Score and Segment Assignment
The fourth CTE (`cte4`) concatenates the scores to create the RFM score for each customer. Finally, the SQL query assigns each customer to a specific segment based on their RFM score.

```sql
cte4 as (
    select *, concat(recency_score, frequency_score, monetary_score) as rfm_score
    from cte3
)

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
```

## Conclusion
This code provides a structured approach to RFM Segmentation, allowing for targeted customer analysis and engagement. The segments identified can be used to develop customized marketing strategies and enhance customer loyalty.
