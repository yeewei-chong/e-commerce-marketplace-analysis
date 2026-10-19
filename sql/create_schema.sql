-- CREATING A STAR SCHEMA
CREATE SCHEMA IF NOT EXISTS marketplace;


-- DIMENSION TABLES
CREATE TABLE IF NOT EXISTS marketplace.sellers (
    seller_id VARCHAR PRIMARY KEY,
    seller_lat DECIMAL(8, 6),
    seller_lon DECIMAL(9, 6),
    seller_city VARCHAR,
    seller_state VARCHAR,
    total_revenue DECIMAL,
    coef_variation FLOAT,
    seller_abc_segment VARCHAR(2),
    seller_xyz_segment VARCHAR
);

CREATE TABLE IF NOT EXISTS marketplace.products (
    product_id VARCHAR PRIMARY KEY,
    category VARCHAR,
    name_len INT,
    description_len INT,
    photo_qty INT,
    total_revenue DECIMAL,
    coef_variation FLOAT,
    product_abc_segment VARCHAR(2),
    product_xyz_segment VARCHAR
);

-- CUSTOMERS' LOCATIONS DEPEND ON PURCHASE DATE, THEREFORE THEY CANNOT FORM A DIMENSION TABLE
CREATE TABLE IF NOT EXISTS marketplace.orders (
    order_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    customer_lat DECIMAL(8, 6),
    customer_lon DECIMAL(9, 6),
    customer_city VARCHAR,
    customer_state VARCHAR,
    purchase_timestamp TIMESTAMP,
    shipment_deadline TIMESTAMP,
    shipment_timestamp TIMESTAMP,
    is_shipment_late BOOLEAN,
    est_delivery_timestamp TIMESTAMP,
    delivery_timestamp TIMESTAMP,
    is_delivery_late BOOLEAN,
    rating INT
);


-- FACT TABLE
CREATE TABLE IF NOT EXISTS marketplace.order_items (
    order_id VARCHAR REFERENCES marketplace.orders(order_id),
    seller_id VARCHAR REFERENCES marketplace.sellers(seller_id),
    product_id VARCHAR REFERENCES marketplace.products(product_id),
    item_number VARCHAR,
    price DECIMAL
);