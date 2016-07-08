# データを取り扱う

テストはお互いに影響を与えるべきではありません。これは経験上の法則です。テストがデータベースと連携する場合、最終的にデータ不整合につながるおそれのあるデータがテストによって変更されるかもしれません。テストはまた、すでに登録済みのデータを登録したり、削除されたレコードを取得しようとするかもしれません。テストが失敗するのを避けるために、データベースは各テストの前に初期状態になっていることが必要です。Codeceptionにはデータを初期化するための様々なメソッドと方法があります。

この章では、前章のクリーンアップに関する注意を要約するとともに、データストレージバックエンドを選択する方法の最善策について提案します。

データベースをクリーンアップすると決めたならば、クリーンアップ処理は可能な限り早くすべきです。テストは常に速く実行される必要があります。データベースを一から再構築するのは最良の方法とは言えないかもしれませんが、唯一の方法とも言えるかもしれません。いずれにせよ、テストのための特別なデータベースを使用してください。**絶対に開発環境または本番環境のデータベースでテストを実行しないでください！**

## Db

Codeceptionにはデータベースと対話をする際に必要なほとんどのタスクを行ってくれる`Db`モジュールがあります。デフォルトでは、dumpファイルからデータベースを再構築し、各テストの終了後にクリーンアップを試みます。このモジュールはSQL形式のデータベースdumpファイルを使用します。`codeception.yml`内ですでに設定が準備されています。

```yaml
modules:
    config:
        Db:
            dsn: 'PDO DSN HERE'
            user: 'root'
            password:
            dump: tests/_data/your-dump-name.sql
```


<div class="alert alert-notice">
環境変数もしくはアプリケーション設定ファイルからデータベースの認証情報を設定するためには、[モジュールパラメーター](06-ModulesAndHelpers#Dynamic-Configuration-With-Params)を使用してください。
</div>

テストスイートでこのモジュールを有効化したら、自動的にdumpファイルからデータベースにデータが投入され、各テストの実行時に再構築されます。これらの設定は`populate`と`cleanup`オプションに`false`を設定するなどして変更することができます。

<div class="alert alert-notice">
大きなdumpファイルを使用している場合、データベースをフルにクリーンアップする処理は非常に遅くなります。機能および統合のレベルでより多くのデータテストを行うことをお勧めします。この方法により、ORMを使用してパフォーマンス面でのボーナスを得ることができます。
</div>

受け入れテストでは、テストはWEBサーバーを介してアプリケーションとやり取りをします。これはつまり、テストとアプリケーションは同じデータベースを使用して動作するということです。アプリケーションが使用しているものと同じ認証情報をDbモジュールに設定することで、アサーション（`seeInDatabase`アクションなど）のためにデータベースにアクセスすることができ、また自動クリーンアップを行うことができます。

Dbモジュールはデータベース内のデータを作成し、検証するためのアクションを提供します。

あるテストのために、特別なレコードを作成した場合、`Db`モジュールの[`haveInDatabase`](http://codeception.com/docs/modules/Db#haveInDatabase)を使用することができます。

```php
<?php
$I->haveInDatabase('posts', [
  'title' => 'Top 10 Testing Frameworks',
  'body' => '1. Codeception'
]);
$I->amOnPage('/posts');
$I->see('Top 10 Testing Frameworks');

```

`haveInDatabase`は与えられた値で、データベースに行をインサートします。すべての追加されたレコードはテスト終了時に削除されるでしょう。

作成されたレコードをチェックしたい場合は[`seeInDatabase`](http://codeception.com/docs/modules/Db#haveInDatabase)メソッドを使います：

```php
<?php
$I->amOnPage('/posts/1');
$I->fillField('comment', 'This is nice!');
$I->click('Submit');
$I->seeInDatabase('comments', ['body' => 'This is nice!']);

```

データベーステストに使用できるその他のメソッドについては、[モジュールのリファレンス](http://codeception.com/docs/modules/Db)を参照してください。

似たような振る舞いをする、[MongoDb](http://codeception.com/docs/modules/MongoDb)、 [Redis](http://codeception.com/docs/modules/Redis)、 [Memcache](http://codeception.com/docs/modules/Memcache)向けのモジュールもあります。

### Sequence

データベースのクリーンアップ処理によても長い時間がかかる場合、テスト毎に新しいデータを作成する、という異なる方法を取ることができます。この方法で直面するかもしれない唯一の問題は、データレコードの重複です。[Sequence](http://codeception.com/docs/modules/Sequence)はこれを解決するために作成されました。このモジュールは、テストで作成されるデータに対して一意の接尾辞を生成する`sq()`メソッドを提供します。

## ORMモジュール

おそらく、あなたのアプリケーションはデータベースとの連携にORMを使用していると思います。このようなケースにおいて、Codeceptionでは、データベースに直接アクセスする代わりにORMのメソッドを使用することができます。これにより、テーブルや行ではなく、ドメインのモデルやエンティティを取り扱うことができます。

機能や統合テストでORMを使用することにより、テストのパフォーマンスを向上することもできます。各テストの終了後にデータベースをクリーンアップする代わりに、ORMモジュールはすべてのデータベースアクションをトランザクション内で行い、終了時にロールバックするでしょう。こうすれば、実際のデータはデータベースへの書き込まれません。このクリーンアップの方法はデフォルトで有効化されており、任意のORMモジュールを`cleanup: false`と設定することで無効にできます。

### ActiveRecord

Laravel、YiiそしてPhalconといった有名なフレームワークはデフォルトでActiveRecordを含んでいます。この密結合により、必要なことはフレームワークモジュールを有効にして、データベースアクセス用の設定を使用するだけです。

対応するフレームワークモジュールはORMアクセスのための類似のメソッドを提供します：

* `haveRecord`
* `seeRecord`
* `dontSeeRecord`
* `grabRecord`

これらはモデル名やモデルのフィールド名により、データの作成およびチェックを行うことができます。次はLaravelでの例です：

```php
<?php
// create record and get its id
$id = $I->haveRecord('posts', ['body' => 'My first blogpost', 'user_id' => 1]);
$I->amOnPage('/posts/'.$id);
$I->see('My first blogpost', 'article');
// check record exists
$I->seeRecord('posts', ['id' => $id]);
$I->click('Delete');
// record was deleted
$I->dontSeeRecord('posts', ['id' => $id]);

```

<div class="alert alert-notice">
Laravel5モジュールは、ダミーデータを使用してモデルを生成するためのファクトリを使用する、`haveModel`、`makeModel`メソッドについても提供します。
</div>

機能テストのためだけにORMを使用したい場合は、フレームワークモジュールを`ORM`パーツのみ有効化して使用してください。

```yaml
modules:
    enabled:
        - Laravel5:
            - part: ORM
```

```yaml
modules:
    enabled:
        - Yii2:
            - part: ORM
```

これにより、`$I`オブジェクトにはWEB用のアクションが追加されなくなります。

受け入れテストの内部で、データの取り扱いにORMを使用したい場合、やはりORMパーツのみをインクルードする必要があります。受け入れテストにおいてWEBアプリケーションはWEBサーバー内で動作するため、トランザクションをロールバックすることでデータをクリーンアップすることはできません。そのため、clearnupオプションを無効にし、テスト間のデータべースのクリーンアップには`Db`モジュールを使用します。設定のサンプルです：

```yaml
modules:
    enabled:
        - WebDriver:
            url: http://localhost
            browser: firefox
        - Laravel5:
            cleanup: false
        - Db
```


### DataMapper

Doctrineもまた有名なORMで、DataMapperパターンを実装し、いずれのフレームワークと結びついていない点が他とは異なります。[Doctrine2](http://codeception.com/docs/modules/Doctrine2)モジュールは動作に`EntityManager`を必要とします。これは、（Doctrineを使用するよう設定された）SymfonyやZend Frameworkから得ることができます。

```yaml
modules:
    enabled:
        - Symfony
        - Doctrine2:
            depends: Symfony
```

```yaml
modules:
    enabled:
        - ZF2
        - Doctrine2:
            depends: ZF2
```

Doctrineと共に使用しているフレームワークがない場合、`connection_callback`オプションに`EntityManager`のインスタンスを返す有効なコールバックを設定する必要があります。

Doctrine2はデータの作成とチェックのための次のメソッドも提供します：

* `haveInRepository`
* `grabFromRepository`
* `seeInRepository`
* `dontSeeInRepository`

### DataFactory

テスト用のデータを準備することは非常に創造的であるにもかかわらず、退屈な作業です。もしレコードを作成する場合、モデルのすべてのフィールドを埋める必要があるでしょう。その作業に[Faker](https://github.com/fzaninotto/Faker)を使用することで、より簡単に、そしてモデルに対するデータの生成ルールをより効果的にセットアップできるでしょう。そのようなルールセットは *ファクトリ* と呼ばれ、[DataFactory](http://codeception.com/docs/modules/DataFactory)モジュールによって提供されます。

一度設定すれば簡単にレコードを作成できます：

```php
<?php
// creates a new user
$user_id = $I->have('App\Model\User');
// creates 3 posts
$I->haveMultiple('App\Model\Post', 3);
```

作成されたレコードはテストの終了時に削除されます。DataFactoryはORMとしか動作しませんので、ORMモジュールのいずれかを有効化する必要があります：

```yaml
modules:
    enabled:
        - Yii2:
            configFile: path/to/config.php
        - DataFactory:
            depends: Yii2
```

```yaml
modules:
    enabled:
        - Symfony
        - Doctrine2:
            depends: Symfony
        - DataFactory:
            depends: Doctrine2            
```

DataFactoryは統合/機能/受け入れの各テストにおけるデータ管理に対して、強力なソリューションを提供します。このモジュールをどうのようにセットアップするかについては[リファレンス](http://codeception.com/docs/modules/DataFactory)を読んでください。

## まとめ

Codeceptionはデータを取り扱う際に開発者を見捨てません。データベースへの投入とクリーンアップを行うツールは`Db`モジュールにバンドルされています。ORMを使用している場合は、データ抽象化レイヤーを介してデータベースと動作するために提供されるフレームワークモジュールのいずれかを使用することができ、そして簡単に新しいレコードを作成するためにDataFactoryモジュールを使用することができます。
