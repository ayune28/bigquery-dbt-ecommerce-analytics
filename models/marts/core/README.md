# core marts モデル

このディレクトリには、ECサイトの顧客・注文分析に関連するモデルが格納されています。

## モデル一覧

- `fct_orders_incremental`: 注文の事実データ（1注文＝1行）
- `dim_customers`: 顧客ごとの注文回数・累計購入額をまとめたディメンションテーブル
- `customer_segments`: 顧客をLTV（累計購入額）でVIP／優良顧客／新規・一般／未購入に分類したテーブル
- `monthly_sales_summary`: 月次の注文件数・購入者数・売上・客単価を集計したテーブル

## 使用例

```sql
-- VIP顧客の一覧を抽出する
select
    customer_id,
    customer_name,
    lifetime_value
from customer_segments
where customer_segment = 'VIP'
order by lifetime_value desc
```