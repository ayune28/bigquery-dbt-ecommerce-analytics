-- models/marts/core/monthly_sales_summary.sql
-- 月次の売上サマリー（経営ダッシュボード用）
-- 注文データを月単位に集計し、件数・購入者数・売上・客単価の推移を見えるようにする

with orders as (

    -- 注文の事実データ（1注文＝1行）
    select * from {{ ref('fct_orders_incremental') }}

),

final as (

    select
        -- 注文日時を「月」単位に丸める（例: 3/15も3/27も2024-03-01として扱う）
        date_trunc(date(ordered_at), month) as sales_month,

        count(distinct order_id) as order_count,          -- その月の注文件数
        count(distinct customer_id) as customer_count,     -- その月に購入した人数
        sum(order_total_dollars) as total_sales_dollars,   -- その月の売上合計
        round(avg(order_total_dollars), 2) as avg_order_value_dollars  -- 平均客単価

    from orders
    group by sales_month
    order by sales_month

)

select * from final