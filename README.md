## このプロジェクトについて

ECサイトの運営を想定し、「どの顧客が優良顧客か」「月ごとの売上はどう推移しているか」を
分析するためのデータ基盤です。生の注文・顧客データをBigQuery上でdbtを使って整形し、
マーケティング施策や経営判断に使える分析用テーブルを作成しています。

## ダッシュボード

Looker Studioで作成した分析ダッシュボードはこちら：https://datastudio.google.com/reporting/cd3cf289-f570-47a6-97bd-ea6f24c04a14

### 想定する利用シーン
- リピート顧客への優先的な施策（クーポン配布やメルマガ）のターゲット抽出
- 月次の売上・購入者数の推移をモニタリングし、異常な変動に早く気づく

## データフロー
生データ（BigQuery: raw_customers, raw_orders）
↓ ソース定義（source）
ステージング層（stg_customers, stg_orders）
↓ 整形・カラム名の統一
マート層（dim_customers, fct_orders_incremental）
↓ ビジネスロジックの付与
分析用テーブル（customer_segments, monthly_sales_summary）


## モデル一覧

| モデル名 | 層 | 説明 |
|---|---|---|
| stg_customers | staging | 生の顧客データを整形 |
| stg_orders | staging | 生の注文データを整形、金額をドル換算 |
| dim_customers | marts | 顧客ごとの注文回数・累計購入額を集計 |
| fct_orders_incremental | marts | 注文データのファクトテーブル |
| customer_segments | marts | 顧客をLTVでVIP/優良顧客/新規・一般/未購入に分類 |
| monthly_sales_summary | marts | 月次の注文件数・購入者数・売上・客単価を集計 |

## 補足：このテーブルの作り方について

`fct_orders_incremental.sql` は、本来「差分更新」という方式で作る想定です。
注文データは日々増えていくものなので、毎回すべてのデータを計算し直すのではなく、
「前回より後に増えた分だけ」を追加していく方が、処理時間やコストを節約できるためです。

ただし、今回使っているBigQueryは無料の検証環境（サンドボックス）のため、
差分更新に必要な処理（MERGE文）が制限されており、そのままでは動きません。
そのため、今回はいったん「毎回すべてのデータを作り直す」方式（table）で
動かしています。

差分更新のためのコード自体はファイルの中に残してあるので、
課金が有効な本番相当の環境では、設定を1行変更するだけで
差分更新に切り替えられるように作ってあります。

## データ品質の担保（検証）

構築したデータやモデルの信頼性を保つため、以下の仕組みで品質を担保しています。

### 1. dbtテストによる自動チェック（`schema.yml`）
システム的なエラーやデータの破損を防ぐため、主要なモデルに対して `dbt test` を実行し、以下の項目を自動で検証しています。
- **一意性（unique）**: 顧客IDや月ごとのキーに重複がないか
- **非NULL（not_null）**: 必須カラムに空欄（NULL）が混ざっていないか
- **許容値の制限（accepted_values）**: 顧客セグメント等の分類に想定外の文字列が入っていないか

### 2. BigQueryでの手動検証
dbtのテストではカバーしきれない、集計ロジックの妥当性を以下のSQLで個別に検証しています。

**① 月の重複チェック**
`monthly_sales_summary`の`sales_month`が2行以上に分裂していないかを確認（`group by`の設計ミスによる二重集計を検出するため）。

```sql
SELECT
    sales_month,
    COUNT(*) AS row_count
FROM
    my-dbt-sandbox-507210.dbt_ayumi.monthly_sales_summary
GROUP BY sales_month
HAVING COUNT(*) > 1;
```

**② セグメント分類の妥当性チェック**
`customer_segments`をセグメントごとにグループ化し、LTV（累計購入額）・注文回数の最小値と最大値を確認。VIPセグメントの中に、閾値（$1,000）未満の顧客が混ざっていないか等を検証。

```sql
SELECT
    customer_segment,
    COUNT(customer_id) AS user_count,
    MIN(lifetime_value) AS min_ltv,
    MAX(lifetime_value) AS max_ltv,
    MIN(number_of_orders) AS min_orders,
    MAX(number_of_orders) AS max_orders
FROM
    my-dbt-sandbox-507210.dbt_ayumi.customer_segments
GROUP BY customer_segment
ORDER BY min_ltv DESC;
```

**③ 客単価の計算整合性チェック**
`monthly_sales_summary`に保存されている`avg_order_value_dollars`と、`total_sales_dollars ÷ order_count`で自分で計算した値を突き合わせ、差が0.01ドル以上ある行（計算ロジックのズレ）がないかを確認。

```sql
WITH checked_data AS (
    SELECT
        sales_month,
        total_sales_dollars,
        order_count,
        avg_order_value_dollars,
        SAFE_DIVIDE(total_sales_dollars, order_count) AS calculated_avg
    FROM
        my-dbt-sandbox-507210.dbt_ayumi.monthly_sales_summary
)
SELECT *
FROM checked_data
WHERE ABS(COALESCE(avg_order_value_dollars, 0) - COALESCE(calculated_avg, 0)) > 0.01;
```

①〜③いずれも、問題となる行が0件であることを確認済み。

### 3. ビジネスロジックの整合性チェック
AIやコードが生成したロジックが意図通りに機能しているか、以下の観点でセルフチェックを行っています。
- **セグメント条件の妥当性**: VIP（LTV 1000ドル以上）や未購入（注文数0回）などのランク分けが、意図した基準通りに正しく分類されているかの確認
- **ダッシュボード表示値の裏取り**: Looker Studioに表示している主要な指標（累計売上・総注文数・延べ購入者数・顧客セグメント比率）を、BigQuery上でSQLを直接実行して集計し、表示値と一致することを確認

## 使用技術

- dbt Core  1.12.3
- BigQuery（無料サンドボックス）
- Looker Studio
- Git / GitHub