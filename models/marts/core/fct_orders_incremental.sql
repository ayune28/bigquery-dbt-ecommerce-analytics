-- models/marts/core/fct_orders_incremental.sql
-- 注文ファクトテーブル（1注文＝1行）
--
-- 本来は「差分更新（incremental）」で設計している。
-- 注文データは日々増えるので、前回より新しいデータだけ追加すれば
-- 処理時間とコストを抑えられるため。
--
-- ただし今のBigQuery環境（無料サンドボックス）は差分更新に必要な
-- 処理（MERGE文）が制限されているため、いったん「table」（毎回全件作り直す）方式。
--差分のみ更新用のコードは残しているので
-- 課金を有効にした環境ではconfigを1行変えるだけで切り替え可能。

{{
    config(
        materialized='table'
    )
}}
-- 本番環境ではこちらに切り替える: materialized='incremental', unique_key='order_id'

select
    order_id,
    customer_id,
    ordered_at,
    order_total_dollars

from {{ ref('stg_orders') }}

{% if is_incremental() %}
  -- 差分更新のときだけ有効。前回より新しい注文だけに絞り込む
  where ordered_at > (select max(ordered_at) from {{ this }})
{% endif %}