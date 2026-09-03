-- models/staging/stg_orders.sql
-- 注文データのステージングモデル

select
    id as order_id,
    customer as customer_id,
    ordered_at,
    store_id,
    subtotal / 100.0 as subtotal_dollars,
    tax_paid / 100.0 as tax_paid_dollars,
    order_total / 100.0 as order_total_dollars
from {{ source('jaffle_shop', 'raw_orders') }}