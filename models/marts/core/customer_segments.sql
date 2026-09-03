-- models/marts/core/customer_segments.sql
-- 顧客をLTV（生涯価値）で分類し、リピート施策のターゲティングに使うモデル

with customers as (

    select * from {{ ref('dim_customers') }}

),

final as (

    select
        customer_id,
        customer_name,
        number_of_orders,
        lifetime_value,

        case
            when lifetime_value >= 300 then 'VIP'
            when lifetime_value >= 100 then '優良顧客'
            when number_of_orders = 0 then '未購入'
            else '新規・一般'
        end as customer_segment

    from customers

)

select * from final