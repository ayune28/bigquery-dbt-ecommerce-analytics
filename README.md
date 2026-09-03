
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