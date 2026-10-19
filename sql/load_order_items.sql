INSERT INTO marketplace.order_items
SELECT DISTINCT
    item_data.order_id,
    item_data.seller_id,
    item_data.product_id,
    order_item_id,
    price
FROM 'data/olist_order_items_dataset.csv' AS item_data
INNER JOIN marketplace.orders AS order_data ON item_data.order_id = order_data.order_id
INNER JOIN marketplace.sellers AS seller_data ON item_data.seller_id = seller_data.seller_id
INNER JOIN marketplace.products AS product_data ON item_data.product_id = product_data.product_id;