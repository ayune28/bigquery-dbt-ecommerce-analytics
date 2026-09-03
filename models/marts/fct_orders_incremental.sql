{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

select
    order_id,
    customer_id,
    ordered_at,
    order_total_dollars

from {{ ref('stg_orders') }}

{% if is_incremental() %}
  where ordered_at > (select max(ordered_at) from {{ this }})
{% endif %}