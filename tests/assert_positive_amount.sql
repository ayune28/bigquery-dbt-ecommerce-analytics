-- tests/assert_positive_amount.sql
-- 注文金額が0未満の異常データがないかチェックするテスト

select
    order_id,
    order_total_dollars
from {{ ref('fact_orders') }}
where order_total_dollars < 0