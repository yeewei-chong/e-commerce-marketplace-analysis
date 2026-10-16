-- USING olist_order_items_dataset.csv, olist_orders_dataset.csv, olist_sellers_dataset.csv, and olist_geolocation_dataset.csv

WITH seller_data_join AS (
    SELECT DISTINCT
        seller_data.seller_id AS seller_id,
        geo_data.geolocation_lat AS seller_lat,
        geo_data.geolocation_lng AS seller_lon,
        seller_data.seller_city AS seller_city,
        seller_data.seller_state AS seller_state,
        SUM(item_data.price) AS monthly_revenue,
        DATE_TRUNC('MONTH', order_data.order_purchase_timestamp) AS yearmonth
    FROM 'data/olist_order_items_dataset.csv' AS item_data
    INNER JOIN 'data/olist_orders_dataset.csv' AS order_data ON item_data.order_id = order_data.order_id
    INNER JOIN 'data/olist_sellers_dataset.csv' AS seller_data ON item_data.seller_id = seller_data.seller_id
    INNER JOIN 'data/olist_geolocation_dataset.csv' AS geo_data on seller_data.seller_zip_code_prefix = geo_data.geolocation_zip_code_prefix
    WHERE order_purchase_timestamp >= '2016-10-01 00:00:00' AND order_purchase_timestamp < '2018-10-01 00:00:00'
    GROUP BY 
        seller_data.seller_id,
        geo_data.geolocation_lat, 
        geo_data.geolocation_lng, 
        seller_data.seller_city, 
        seller_data.seller_state,
        seller_data.seller_zip_code_prefix,
        yearmonth
), seller_aggregate AS (
    SELECT 
        seller_id,
        AVG(seller_lat) AS seller_lat,
        AVG(seller_lon) AS seller_lon,
        seller_city,
        seller_state,
        ROUND(SUM(monthly_revenue), 2) AS total_revenue,
        COALESCE(STDDEV(monthly_revenue) / AVG(monthly_revenue), -1) AS coef_variation
    FROM seller_data_join
    GROUP BY
        seller_id,
        seller_city,
        seller_state
    ORDER BY total_revenue DESC
), cumulative_percentage AS (
    SELECT
        seller_id,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) / SUM(total_revenue) OVER () AS cum_percent
    FROM seller_aggregate
)
INSERT INTO marketplace.sellers
SELECT
    seller_aggregate.*,
    CASE 
        WHEN cumulative_percentage.cum_percent < 0.8 THEN 'A'
        WHEN cumulative_percentage.cum_percent < 0.95 THEN 'B'
        ELSE 'C'
    END AS abc_seg,
    CASE 
        WHEN seller_aggregate.coef_variation < 0 THEN 'insufficient_data'
        WHEN seller_aggregate.coef_variation < 0.5 THEN 'X'
        WHEN seller_aggregate.coef_variation < 1 THEN 'Y'
        ELSE 'Z'
    END AS xyz_seg
FROM seller_aggregate
LEFT JOIN cumulative_percentage ON seller_aggregate.seller_id = cumulative_percentage.seller_id 
ORDER BY total_revenue DESC;
