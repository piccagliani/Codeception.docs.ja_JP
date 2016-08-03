# モジュールとヘルパー

Codeceptionは、記述するすべてのテストスイートに対して快適なテスト環境を作成するために、モジュールを使用します。

テスターオブジェクトによって行われるすべてのアクションとアサーションはモジュールに定義されています。独自のアクションやアサーションをカスタムモジュールに記述することによって、あなた専用のアクションとアサーションを備えたテストスイートに拡張することができます。

次のテストを見てみましょう：

```php
<?php
$I = new FunctionalTester($scenario);
$I->amOnPage('/');
$I->see('Hello');
$I->seeInDatabase('users', array('id' => 1));
$I->seeFileFound('running.lock');

```

このコードの実行には異なるエンティティが使用されます：PhpBrowserモジュールによってウェブページが読み込まれ、データベースのアサーションにはDbモジュールを使用し、そしてFilesystemモジュールによってファイルの状態がチェックされます。

モジュールはスイート設定によりアクタークラスに取り付けられます。
例えば、次の`tests/functional.suite.yml`を見てください：

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - PhpBrowser:
            url: http://localhost
        - Db:
            dsn: "mysql:host=localhost;dbname=testdb"
        - Filesystem
```
FunctionalTesterクラスはモジュールに定義されているメソッドを持っています。しかしメソッドは実際にクラスの中に含まれてるわけではなく、むしろプロキシのように動作しています。FunctionalTesterクラスはどのモジュールがそのアクションを実行するのかを知っており、そしてパラメータを渡すのです。使用しているIDEにFunctionalTesterの持っているすべてのメソッドを認識させるためには、`codecept build`コマンドを使ってください。このコマンドは有効化されているモジュールからメソッドのシグネチャを生成し、アクターにインクルードされるトレイトに保存します。この例では、`tests/support/_generated/FunctionalTesterActions.php`ファイルが生成されるでしょう。
Codeceptionはデフォルトで、スイート設定が変更されるたびに自動的にトレイトを再ビルドします。

## 標準モジュール

Codeceptionには異なる目的や環境に対するテストを実行するのに役立つ、バンドルされたモジュールが多くあります。モジュールのアイディアは、開発者やQAエンジニアが車輪の再発明にではなくテストに集中できるよう、一般的なアクションを共通化することです。個々のモジュールはテストの一部分しか提供しませんが、複数のモジュールを組み合わせることでアプリケーションをすべてのレベルでテストするための強力な仕組みを手に入れることができます。

受け入れテスト向けの`WebDriver`モジュール、ポピュラーなPHPフレームワーク用のモジュール、ブラウザーの実行をエミュレートする`PHPBrowser`モジュール、APIをテストするための`REST`モジュール、など、さらに多くのモジュールがあります。モジュールはCodeceptionの最も価値のあるものであると考えられます。モジュールは、最高のテスト体験を提供するため、そしてあらゆるニーズに柔軟に応えるため、継続的に改善されています。

### モジュールのコンフリクト

モジュールは互いにコンフリクトする可能性があります。モジュールが`Codeception\Lib\Interfaces\ConflictsWithModule`を実装している場合、他モジュールとで使用されるコンフリクトのルールが宣言されます。たとえば、WebDriverモジュールは`Codeception\Lib\Interfaces\Web`インターフェースを実装しているすべてのモジュールとコンフリクトします。

```php
public function _conflicts()
{
    return 'Codeception\Lib\Interfaces\Web';
}
```

この仕組みによって、同一のコンフリクトするインタフェースを共有する2つのモジュールを使用した場合には、例外が発生します。

混乱を避けるために、**Framework、PhpBrowser、そしてWebDriverモジュール** を一緒に使用することはできません。たとえば、`amOnPage`メソッドはそれらすべてのモジュールに存在し、実際にどのモジュールのものが実行されるのかわからなくなります。受け入れテストを行うのであれば、WebDriverとPHPBrowserの両方ではなく、どちらかをセットアップしてください。機能テストを行う場合は、フレームワークモジュールのうち、どれか一つを有効にしてください。

コンフリクトするモジュールに依存するモジュールを使用した場合は、設定で依存するモジュールを指定してください。`WebDriver`モジュールを、`PhpBrowser`を通してサーバーとやり取りをする`REST`モジュールと共に使用したい場合があります。そのような場合、設定は次のようになります：

```yaml
modules:
    enabled:
        - WebDriver:
            browser: firefox
            url: http://localhost
        - REST:
            url: http://localhost/api/v1
            depends: PhpBrowser

```

この設定によりウェブサイトをブラウザーで動作している最中にサーバー上のAPIに対してGET/POSTリクエストを送信できるようになります。

ただ単にコンフリクトするモジュールの一部のパーツのみロードたいという場合は、次の章を参照してください。

### モジュールパーツ

*パーツ* セクションを持つモジュールは、部分的にロードすることができます。この方法により`$I`オブジェクトはモジュールの特定のパーツに含まれるアクションのみを持つようになります。部分的にロードされたモジュールは、モジュール同士のコンフリクトを回避する目的でも使用することができます。

例えば、Laravel5モジュールにはデータベース関連のアクションが含まれるORMパーツがあります。PhpBrowserをテスト用に、Laravel + ORMをデータベースへの接続およびデータチェック用に、有効化することができます。

```yaml
modules:
    enabled:
        - PhpBrowser:
            url: http://localhost
        - Laravel5:
            part: ORM            
```

同名のアクションはロードされないため、モジュールのコンフリクトは発生しません。

同じように、RESTモジュールには`Xml`と`Json`のパーツがあります。もし、レスポンス形式がJSONのみであるRESTサービスをテストする場合、JSONパーツのみを有効とすることができます：

```yaml
class_name: ApiTester
modules:
    enabled:
        - REST:
            url: http://serviceapp/api/v1/
            depends: PhpBrowser
            part: Json    
```

## ヘルパー

Codeceptionはメインリポジトリからのみのモジュールに制限されているわけではありません。間違いなく、あなたのプロジェクトは独自のアクションをテストスイートに追加する必要があるでしょう。`bootstrap`コマンドを実行することにより、Codeceptionは新規作成される３つのテストスイートそれぞれにダミーモジュールを生成します。これらのカスタムモジュールは'ヘルパー'と呼ばれ、`tests/_support`ディレクトリ内に置かれます。



```php
<?php
namespace Helper;
// here you can define custom functions for FunctionalTester

class Functional extends \Codeception\Module
{
}

```
アクションに関して言えば、すべてが非常にシンプルです。あなたが定義するすべてのアクションはpublicなfunctionです。何かしらのpublicメソッドを書き、`build`コマンドを実行すれば、FunctionalTesterクラスに新しい関数が追加されたことを確認できます。


<div class="alert alert-info">
publicメソッドが`_`から始まる場合は隠しメソッドとして扱われ、アクタークラスには追加されません。
</div>

アサーションは少し注意が必要です。まず始めに、すべてのアサートアクションの接頭語を`see`もしくは`dontSee`とすることを推奨します。

たとえばこのようになります：

```php
<?php
$I->seePageReloaded();
$I->seeClassIsLoaded($classname);
$I->dontSeeUserExist($user);

```
これをテストで使用します：

```php
<?php
$I->seePageReloaded();
$I->seeClassIsLoaded('FunctionalTester');
$I->dontSeeUserExist($user);

```

モジュール内のassertXXXメソッドを使ってアサーションを定義することができます。

```php
<?php

function seeClassExist($class)
{
    $this->assertTrue(class_exists($class));
}

```

ヘルパー内でこれらのアサーションを使うことができます：

```php
<?php

function seeCanCheckEverything($thing)
{
    $this->assertTrue(isset($thing), "this thing is set");
    $this->assertFalse(empty($any), "this thing is not empty");
    $this->assertNotNull($thing, "this thing is not null");
    $this->assertContains("world", $thing, "this thing contains 'world'");
    $this->assertNotContains("bye", $thing, "this thing doesn`t contain 'bye'");
    $this->assertEquals("hello world", $thing, "this thing is 'Hello world'!");
    // ...
}

```

### 他モジュールへのアクセス

他のモジュールから内部データや関数にアクセスすることも可能です。たとえば、あなたのモジュールはレスポンス内容やモジュールの内部アクションにアクセスする必要がある場合があります。

モジュールは`getModule`メソッドを通じて相互にやり取りすることができます。このメソッドは必要なモジュールがロードされていない場合、例外を投げることを覚えておいてください。

データベースに再接続するモジュールを書いていると想定してみましょう。そのモジュールはDbモジュールのコネクションハンドラーを使用するとします。

```php
<?php

function reconnectToDatabase() {
    $dbh = $this->getModule('Db')->dbh;
    $dbh->close();
    $dbh->open();
}

```

`getModule`関数を使うと、リクエストしたモジュール内のすべてのpublicメソッドやプロパティにアクセスできます。`dbh`プロパティは他のモジュールで利用できるよう、publicとして定義されています。

また、モジュールにはヘルパーメソッドでの使用のために用意されているメソッドも含まれています。これらのメソッドは`_`から始まり、アクタークラス内では使用することができないため、モジュールおよび拡張機能からのみアクセスすることができます。

モジュールの内部構造を使用した独自のアクションを記述する際にそれらのメソッドを使ってください。

```php
<?php
function seeNumResults($num)
{
    // retrieving webdriver session
    /**@var $table \Facebook\WebDriver\WebDriverElement */
    $elements = $this->getModule('WebDriver')->_findElements('#result');
    $this->assertNotEmpty($elements);
    $table = reset($elements);
    $this->assertEquals('table', $table->getTagName());
    $results = $table->findElements('tr');
    // asserting that table contains exactly $num rows
    $this->assertEquals($num, count($results));
}

```

この例では、モジュールの構築元となるSelenium WebDriverのクライアントである<a href="https://github.com/facebook/php-webdriver">facebook/php-webdriver</a>ライブラリのAPIを使用しています。
Seleniumと直接的に対話するための`Facebook\WebDriver\RemoteWebDriver`インスタンスにアクセスするため、`webDriver`プロパティを利用することもできます。

### モジュールの継承

もしモジュールにアクセスすることで必要な柔軟性を得られない場合は、ヘルパークラスでモジュールを継承することができます：

```php
<?php
namespace Helper;

class MyExtendedSelenium extends \Codeception\Module\WebDriver  {
}

```

このヘルパーでは親クラスのメソッドを独自の実装で置き換えることができます。
テストセッションの開始と終了をカスタマイズする際のオプションである`_before`と`_after`フックについても置き換えることができます。

もし、親クラスのいくつかのメソッドが子クラスで使用されるべきでない場合は無効にすることができます。それにはいくつかの方法があります：

```php
<?php
namespace Helper;

class MyExtendedSelenium extends \Codeception\Module\WebDriver
{
    // disable all inherited actions
    public static $includeInheritedActions = false;

    // include only "see" and "click" actions
    public static $onlyActions = ['see','click'];

    // exclude "seeElement" action
    public static $excludeActions = ['seeElement'];
}

```
`$includeInheritedActions`にfalseを設定することで、親メソッドのエイリアスを作成する機能を追加します。
これはモジュール同士のコンフリクトを解決します。`Db`モジュールを、`Db`を継承した`SecondDbHelper`モジュールとして使いたいとします。その際、両方のモジュールにある`seeInDatabase`メソッドをどのように使用するのでしょうか？以下を見てみてください。

```php
<?php
namespace Helper;

class SecondDb extends \Codeception\Module\Db
{
    public static $includeInheritedActions = false;

    public function seeInSecondDb($table, $data)
    {
        $this->seeInDatabase($table, $data);
    }
}

```

`$includeInheritedActions`をfalseに設定することで、生成されたアクターには親クラスのメソッドを含まなくなりｍす。

### フック

各モジュールは実行中のテストで発生するイベントを処理することができます。テストの開始前や終了後にモジュールを実行することができます。これは起動/クリーンアップ処理のために有用です。テストが失敗した場合の特別な振る舞いを定義することもできます。これは問題のデバッグに役立つでしょう。
たとえば、PhpBrowserモジュールはテストが失敗した場合に現在のページを`tests/_output`ディレクトリーに保存します。

ここに列挙するすべてのフックは`\Codeception\Module`で定義されています。あなたのモジュールの中で自由に再定義してください。

```php
<?php

    // HOOK: used after configuration is loaded
    public function _initialize() {
    }

    // HOOK: on every Actor class initialization
    public function _cleanup() {
    }

    // HOOK: before each suite
    public function _beforeSuite($settings = array()) {
    }

    // HOOK: after suite
    public function _afterSuite() {
    }    

    // HOOK: before each step
    public function _beforeStep(\Codeception\Step $step) {
    }

    // HOOK: after each step
    public function _afterStep(\Codeception\Step $step) {
    }

    // HOOK: before test
    public function _before(\Codeception\TestInterface $test) {
    }

    // HOOK: after test
    public function _after(\Codeception\TestInterface $test) {
    }

    // HOOK: on fail
    public function _failed(\Codeception\TestInterface $test, $fail) {
    }

```

`_`ではじまるメソッドはアクタークラスに追加されないことに注意してください。これはpublicとして定義されますが、内部的な目的のために使用するためのものです。

### デバッグ

すでに触れたように、`_failed`フックは失敗したテストをデバッグするのに役に立ちます。現在のテストの状態を保存しユーザーに表示する機会を提供しますが、これに限ったことではありません。

各モジュールはデバッグ中に役立つであろう内部的な値を出力することができます。
たとえば、PhpBrowserモジュールは新しいページに移動するたびにレスポンスコードと現在のURLを出力します。
このように、モジュールはブラックボックスではありません。彼らはテスト中に何が発生したのかあなたに見せようとします。これはテストのデバッグにかかる苦痛を軽減します。

追加の情報を表示するためには、モジュールの`debug`と`debugSection`メソッドを使います。
PhpBrowserモジュールでの使用例がこちらです：

```php
<?php
    $this->debugSection('Request', $params);
    $this->client->request($method, $uri, $params);
    $this->debug('Response Code: ' . $this->client->getStatusCode());

```

このテストをデバッグモードでPhpBrowserモジュールとともに実行すると、次のようなものが表示されるでしょう：

```bash
I click "All pages"
* Request (GET) http://localhost/pages {}
* Response code: 200
```


## 設定

モジュールとヘルパーはスイート設定もしくはグローバルな`codeception.yml`によって設定されます。

必須のパラメーターはモジュールクラスの`$requiredFields`プロパティで定義する必要があります。Dbモジュールでの例を見てみましょう：

```php
<?php
class Db extends \Codeception\Module
{
    protected $requiredFields = ['dsn', 'user', 'password'];

```

次回、あなたがこれらの値を設定せずにスイートを開始した場合、例外が投げられます。

オプションのパラメーターには、デフォルト値を設定する必要があります。`$config`プロパティはオプションのパラメーターと同様に、それらの値を定義するために使用されます。WebDriverモジュールでは、Seleniumのデフォルトのサーバーアドレスとポートを使用しています。

```php
<?php
class WebDriver extends \Codeception\Module
{
    protected $requiredFields = ['browser', 'url'];    
    protected $config = ['host' => '127.0.0.1', 'port' => '4444'];

```

ホストとポートのパラメーターはスイートの設定で再定義できます。それらの値は設定ファイルの`modules:config`セクションにあります。

```yaml
modules:
    enabled:
        - WebDriver:
            url: 'http://mysite.com/'
            browser: 'firefox'
        - Db:
            cleanup: false
            repopulate: false
```

オプションと必須のパラメーターは`$config`プロパティからアクセスすることができます。その値を取得するには、`$this->config['parameter']`を使ってください。

### パラメーターを使用した動的設定

モジュールは環境変数により動的に設定することができます。パラメーターストレージはグローバルな`codeception.yml`設定ファイルの`params`セクションに指定してください。パラメーターは環境変数、yamlファイル（Symfony形式）や、.envファイル（Laravel形式）、もしくはiniファイルからロードすることができます。

パラメーターをどのようにロードするかをグローバルな`codeception.yml`設定ファイルの`params`セクションに指定してください。パラメータをロードするソースファイルを複数指定することができます。

環境変数からパラメーターをロードする例：

```yaml
params:
    - env # load params from environment vars
```

yamlファイルをロードする例（Symfony）：

```yaml
params:
    - app/config/parameters.yml
```

動作環境ファイルからパラメーターをロードする例（Laravel）：

```yaml
params:
    - .env
    - .env.testing
```

ロードされたパラメーターは、モジュールの設定値として使うことができます。変数名を`%`プレースホルダーで囲うことで、その値で置換されるでしょう。

クラウドテスティングサービスに対する認証情報を指定したいとします。動作環境から`SAUCE_USER`と`SAUCE_KEY`という変数をロード済みとし、`WebDriver`の設定に実際の値を渡してみましょう：

```yaml
    modules:
       enabled:
          - WebDriver:
             url: http://mysite.com
             host: '%SAUCE_USER%:%SAUCE_KEY%@ondemand.saucelabs.com'
```
パラメーターは`Db`モジュールの認証情報を提供するためにも役に立ちます（Laravelの.envファイルを参考にしています）。

```yaml
module:
    enabled:
        - Db:
            dsn: "mysql:host=%DB_HOST%;dbname=%DB_DATABASE%"
            user: "%DB_USERNAME%"
            password: "DB_PASSWORD"
```

### 実行時設定

もし実行時にモジュールを再設定したければ、モジュールの`_reconfigure`メソッドを使用してください。
それをヘルパークラスから呼び出し、変更したいすべてのフィールドに渡すことができます。

```php
<?php
$this->getModule('WebDriver')->_reconfigure(array('browser' => 'chrome'));

```

テスト終了時に、変更した設定はオリジナルの値に戻されます。

## まとめ

モジュールはCodeceptionの真髄です。これらはアクタークラス（UnitTester、FunctionalTester、AcceptanceTesterなど）への複数の継承をエミュレートするために使用されます。Codeceptionはウェブリクエスト、データアクセス、人気のあるPHPライブラリとのインタラクション等をエミュレートするモジュールを提供しています。もし標準のモジュールでは十分でなくても問題ありません。自由に独自モジュールを記述してください！Codceptionで出来ることの枠を超えるようなものについてはヘルパー（カスタムモジュール）を使用してください。ヘルパーを使えば、オリジナルモジュールの機能を拡張することもできます。
