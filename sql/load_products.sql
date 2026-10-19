-- USING olist_order_items_dataset.csv, olist_orders_dataset.csv, olist_products_dataset.csv, and product_category_name_translation.csv

WITH product_data_join AS (
    SELECT DISTINCT
        product_data.product_id AS product_id,
        translation.product_category_name_english AS category,
        product_data.product_name_lenght AS name_len,
        product_data.product_description_lenght AS description_len,
        product_data.product_photos_qty AS photo_qty,
        SUM(item_data.price) AS monthly_revenue,
        DATE_TRUNC('MONTH', order_data.order_purchase_timestamp) AS yearmonth
    FROM 'data/olist_order_items_dataset.csv' AS item_data
    INNER JOIN 'data/olist_orders_dataset.csv' AS order_data ON item_data.order_id = order_data.order_id
    INNER JOIN 'data/olist_products_dataset.csv' AS product_data ON item_data.product_id = product_data.product_id
    INNER JOIN 'data/product_category_name_translation.csv' AS translation on translation.product_category_name = product_data.product_category_name
    WHERE order_data.order_purchase_timestamp >= '2016-10-01 00:00:00' AND order_data.order_purchase_timestamp < '2018-10-01 00:00:00'
    GROUP BY 
        product_data.product_id,
        translation.product_category_name_english, 
        product_data.product_name_lenght, 
        product_data.product_description_lenght, 
        product_data.product_photos_qty,
        yearmonth
), product_aggregate AS (
    SELECT 
        product_id,
        category,
        MAX(name_len) AS name_len,
        MAX(description_len) AS desctiption_len,
        MAX(photo_qty) AS photo_qty,
        ROUND(SUM(monthly_revenue), 2) AS total_revenue,
        COALESCE(STDDEV(monthly_revenue) / AVG(monthly_revenue), -1) AS coef_variation
    FROM product_data_join
    GROUP BY
        product_id,
        category
    ORDER BY total_revenue DESC
), cumulative_percentage AS (
    SELECT
        product_id,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) / SUM(total_revenue) OVER () AS cum_percent
    FROM product_aggregate
)
INSERT INTO marketplace.products
SELECT
    product_aggregate.*,
    CASE 
        WHEN cumulative_percentage.cum_percent < 0.8 THEN 'A'
        WHEN cumulative_percentage.cum_percent < 0.95 THEN 'B'
        ELSE 'C'
    END AS abc_seg,
    CASE 
        WHEN product_aggregate.coef_variation < 0 THEN 'insufficient_data'
        WHEN product_aggregate.coef_variation < 0.5 THEN 'X'
        WHEN product_aggregate.coef_variation < 1 THEN 'Y'
        ELSE 'Z'
    END AS xyz_seg
FROM product_aggregate
LEFT JOIN cumulative_percentage ON product_aggregate.product_id = cumulative_percentage.product_id 
ORDER BY total_revenue DESC;
