-- models/marts/core/monthly_sales_summary.sql
-- 月次の売上サマリー（経営ダッシュボード用）

with orders as (

    select * from {{ ref('fct_orders_incremental') }}

),

final as (

    select
        date_trunc(date(ordered_at), month) as sales_month,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as customer_count,
        sum(order_total_dollars) as total_sales_dollars,
        round(avg(order_total_dollars), 2) as avg_order_value_dollars

    from orders
    group by sales_month
    order by sales_month

)

select * from final