-- USING olist_orders_dataset.csv, customers_dataset.csv, olist_order_reviews_dataset.csv, and olist_geolocation_dataset.csv

WITH order_data_join AS (
    SELECT DISTINCT
        order_data.order_id AS order_id,
        customer_data.customer_unique_id AS customer_id,
        geo_data.geolocation_lat AS customer_lat,
        geo_data.geolocation_lng AS customer_lon,
        customer_data.customer_city AS customer_city,
        customer_data.customer_state AS customer_state,
        order_data.order_purchase_timestamp AS purchase_timestamp,
        item_data.shipping_limit_date AS shipment_deadline,
        order_data.order_delivered_carrier_date AS shipment_timestamp,
        order_data.order_estimated_delivery_date AS est_delivery_timestamp,
        order_data.order_delivered_customer_date AS delivery_timestamp,
        review_data.review_score AS rating

    FROM 'data/olist_order_items_dataset.csv' AS item_data
    INNER JOIN 'data/olist_orders_dataset.csv' AS order_data ON item_data.order_id = order_data.order_id
    INNER JOIN 'data/olist_customers_dataset.csv' AS customer_data ON order_data.customer_id = customer_data.customer_id
    INNER JOIN 'data/olist_order_reviews_dataset.csv' AS review_data ON order_data.order_id = review_data.order_id
    INNER JOIN 'data/olist_geolocation_dataset.csv' AS geo_data ON customer_data.customer_zip_code_prefix = geo_data.geolocation_zip_code_prefix
    WHERE order_data.order_purchase_timestamp >= '2016-10-01 00:00:00' AND order_data.order_purchase_timestamp < '2018-10-01 00:00:00'
)
INSERT INTO marketplace.orders
SELECT DISTINCT
    order_id,
    customer_id,
    ROUND(AVG(customer_lat), 6),
    ROUND(AVG(customer_lon), 6),
    customer_city,
    customer_state,
    purchase_timestamp,
    MAX(shipment_deadline) AS shipment_deadline,
    shipment_timestamp,
    shipment_timestamp > MAX(shipment_deadline) AS is_shipment_late,
    est_delivery_timestamp,
    delivery_timestamp,
    delivery_timestamp > est_delivery_timestamp AS is_delivery_late,
    MIN(rating) AS rating
FROM order_data_join
GROUP BY 
    order_id,
    customer_id,
    customer_city,
    customer_state,
    purchase_timestamp,
    shipment_timestamp,
    est_delivery_timestamp,
    delivery_timestamp;