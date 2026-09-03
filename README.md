Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

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