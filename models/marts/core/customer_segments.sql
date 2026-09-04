-- models/marts/core/customer_segments.sql
-- 顧客をLTV（累計購入額）で分類し、施策のターゲティングに使うモデル
--
-- 分類基準:
--   VIP     : lifetime_value 300ドル以上
--   優良顧客 : lifetime_value 100ドル以上
--   未購入   : number_of_orders 0回
--   新規・一般: 上記以外

with customers as (

    -- 顧客ごとの注文回数・累計購入額（dim_customersで集計済み）
    select * from {{ ref('dim_customers') }}

),

final as (

    select
        customer_id,
        customer_name,
        number_of_orders,
        lifetime_value,

        -- lifetime_valueを基準に4段階へランク分け
        -- 上から順に判定し、最初に当てはまったものが採用される
        case
            when lifetime_value >= 1000 then 'VIP'
            when lifetime_value >= 400 then '優良顧客'
            when number_of_orders = 0 then '未購入'
            else '新規・一般'
        end as customer_segment

    from customers

)

select * from final