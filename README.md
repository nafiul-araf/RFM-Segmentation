# RFM Segmentation Project

## Objectives
The goal of this project is to perform RFM (Retency, Frequency, Monetary) segmentation on customer transaction data. The segmentation aims to classify customers into distinct groups based on their purchasing behavior, allowing for more targeted marketing and customer relationship management strategies.

**Project Objectives:**
1. Calculate RFM metrics (Retency, Frequency, and Monetary Value) for each customer.
2. Assign scores to each RFM metric based on quartiles.
3. Concatenate RFM scores to create unique RFM segments.
4. Classify customers into defined segments (e.g., Loyal Customers, Potential Churners) based on their RFM scores.

## Methodology
This project is implemented using `MySQL` for data processing and segmentation, and Python for data visualization.

1. **Data Extraction**: Retrieve relevant customer information (e.g., customer name, city, country), sales frequency, and monetary value for analysis.
2. **Retency Calculation**: Calculate the retency metric by determining the days since the last purchase, based on the final date in the dataset.
3. **Score Calculation**: Use the `ntile` function to divide Retency, Frequency, and Monetary Value into quartiles, creating a score for each metric.
4. **RFM Segmentation**: Concatenate the scores to create unique RFM scores and assign customers to predefined segments.
5. **Data Visualization**: Visualize the customer segments and insights derived from the RFM analysis using Python libraries (e.g., `Matplotlib`, `Seaborn`, `Plotly`) for enhanced analysis and presentation.

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

# Data Visualization and Analysis

The aim is to analyze customer data segmented by different characteristics to uncover trends, retention risks, and revenue drivers. The visualizations use heatmaps and geographic maps to highlight customer behavior patterns by segment and country.

## Purpose

The provided code performs the following tasks:
1. Aggregates customer data by segment to visualize behavior patterns for frequency, monetary value, and recency.
2. Bins customer counts to allow for easier comparison across categories.
3. Visualizes segment-wise and country-wise customer metrics using heatmaps and scatter geo maps, providing insights into where strategic engagement efforts should be focused.

---

### Segment-wise Heatmap Visualization

This section of the code aggregates data by customer segment and rounds the values to two decimal points. It then creates a combined heatmap to display recency, frequency, and monetary value for each segment, binned by customer count categories.

```python
# Aggregating data by segment and rounding to two decimal places 
segment_df = df.groupby('segment').agg({
    'recency': 'mean',
    'frequency': 'mean',
    'monetary_value': 'mean',
    'customer_name': 'count'
}).reset_index()
segment_df.rename(columns={'customer_name': 'customer_count'}, inplace=True)
segment_df[['recency', 'frequency', 'monetary_value']] = segment_df[['recency', 'frequency', 'monetary_value']].round(2)

# Bin the customer counts into categories 
segment_df['customer_count_bin'] = pd.cut(segment_df['customer_count'], bins=5, labels=False)

# Melt the DataFrame to long format for combined heatmap
melted_df = segment_df.melt(id_vars=['segment', 'customer_count_bin'],
                            value_vars=['recency', 'frequency', 'monetary_value'],
                            var_name='metric',
                            value_name='value')

# Pivot the table to have customer count bins as columns, segment and metric as indices 
pivot_table = melted_df.pivot_table(index=['segment', 'metric'], columns='customer_count_bin', values='value')

# Plot the combined heatmap
plt.figure(figsize=(14, 10))
sns.heatmap(pivot_table, cmap="YlGnBu", annot=True, fmt=".2f", linewidths=0.5, cbar_kws={'label': 'Metric Value'})
plt.title("Combined Segment-wise Heatmap of Recency, Frequency, and Monetary Value")
plt.xlabel("Customer Count Bin")
plt.ylabel("Segment and Metric")
plt.show()
```
![Heatmap](https://github.com/nafiul-araf/RFM-Segmentation/blob/main/Heatmap.png)

#### Summary Interpretation of Updated Segment-wise Heatmap

This heatmap provides a high-level overview of customer behavior for different segments in terms of **recency**, **frequency**, and **monetary value**:

- **Loyal Customers**: Highly engaged with high monetary value, indicating significant revenue contributions.
- **Big Spenders**: Noted for high spending levels but with less frequent transactions.
- **New Customers**: Recent engagement with lower monetary contributions, mainly concentrated in certain countries.
- **Potential Churners**: Characterized by high recency and low frequency, highlighting a need for re-engagement.

The color intensity correlates with monetary value, guiding where to focus retention strategies.

### Country-wise Segment Map Visualization
In this section, customer data is aggregated by country and segment, then visualized on a scatter geo map. This allows for the visualization of customer segments by country, with key metrics such as recency, frequency, and monetary value presented through hover data for easy access.

```python
# Calculate aggregate metrics by country (or city)
location_df = df.groupby(['country', 'segment']).agg({
    'recency': 'mean',
    'frequency': 'mean',
    'monetary_value': 'mean',
    'customer_name': 'count'
}).reset_index()
location_df.rename(columns={'customer_name': 'customer_count'}, inplace=True)

# Map with Segment Information by Country
fig = px.scatter_geo(location_df, locations="country", locationmode="country names",
                     size="frequency", color="segment",  # Color by segment
                     hover_name="country",
                     hover_data={
                         "monetary_value": ':.2f',
                         "frequency": ':.2f',
                         "recency": ':.2f',
                         "segment": True  # Show segment in hover data
                     },
                     title="Map with Segment Information by Country",
                     size_max=30)

# Customize the map appearance
fig.update_geos(showcoastlines=True, coastlinecolor="Black", showland=True, landcolor="lightgrey")
fig.update_layout(
    legend_title_text='Customer Segment',
    geo=dict(projection_type="natural earth")
)

fig.show()
```
![Map](https://github.com/nafiul-araf/RFM-Segmentation/blob/main/Map.png)

#### Summary Interpretation of Country-wise Customer Segments

This geographic visualization highlights variations in customer engagement by country:

- **Loyal Customers**: Found across multiple countries, with Spain displaying especially high frequency and monetary values.
- **Big Spenders**: Particularly prevalent in the USA, contributing substantial monetary value with moderate frequency.
- **New Customers**: Primarily based in Belgium, showing recent but lower-value engagement.
- **Potential Churners**: Found in countries like France, Switzerland, and the USA, displaying high recency and lower frequency, indicating a risk of disengagement.

This map enables targeted strategies by country and segment, assisting in identifying high-value segments and re-engaging potential churners.

## Conclusion

This analysis uses customer segmentation and geographic data visualization to identify key patterns in customer behavior. By leveraging metrics such as recency, frequency, and monetary value:

- **High-value segments** like Loyal Customers can be retained and rewarded.
- **Potential Churners** can be re-engaged with targeted campaigns.
- **Geographic trends** provide insights into how engagement levels differ by country, assisting in region-specific strategy planning.
