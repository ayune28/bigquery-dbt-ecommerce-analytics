-- models/marts/core/dim_customers.sql
-- 顧客ディメンションテーブル
-- 顧客の基本情報（名前など）に、注文実績（注文回数・累計購入額）を紐付けたマスターテーブル。
-- マーケティング施策のターゲティングや、customer_segmentsのベースとして使用する。

with customers as (

    -- 顧客の基本情報（stg_customersで整形済み）
    select * from {{ ref('stg_customers') }}

),

orders as (

    -- 注文データ（fct_orders_incrementalで整形済み）
    select * from {{ ref('fct_orders_incremental') }}

),

customer_orders as (

    -- 顧客ごとに注文を集計する
    -- number_of_orders：これまでの注文件数
    -- lifetime_value  ：これまでの累計購入額（LTV）
    select
        customer_id,
        count(*) as number_of_orders,
        sum(order_total_dollars) as lifetime_value
    from orders
    group by customer_id

),

final as (

    -- 全顧客（customers）を基準に、注文実績（customer_orders）をする。
    -- LEFT JOINの理由：1回も注文していない顧客も一覧から漏らさないため。
    -- 注文がない顧客はnumber_of_orders・lifetime_valueがNULL→「0」に置き換え
    select
        customers.customer_id,
        customers.customer_name,
        coalesce(customer_orders.number_of_orders, 0) as number_of_orders,
        coalesce(customer_orders.lifetime_value, 0) as lifetime_value
    from customers
    left join customer_orders using (customer_id)

)

select * from final