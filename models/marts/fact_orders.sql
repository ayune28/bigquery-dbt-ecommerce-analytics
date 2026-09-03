-- models/marts/core/fact_orders.sql
-- 注文ファクトテーブル（アイテムデータなし版）

with orders as (
    select * from {{ ref('stg_orders') }}
),

final as (
    select
        order_id,
        customer_id,
        ordered_at,
        store_id,
        subtotal_dollars,
        tax_paid_dollars,
        order_total_dollars
    from orders
)

select * from final