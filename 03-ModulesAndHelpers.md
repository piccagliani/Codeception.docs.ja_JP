# モジュールとヘルパー

Codeceptionはすべてのテストスイートに快適なテスト環境を作成するために、モジュールを用いています。
モジュールは、あなたがテストで実行できるアクションとアサーションを選択することができます。

クラスのテスターオブジェクトで行われるすべてのアクションとアサーションはモジュールで定義されています。
これは一見、Codeceptionがあなたのテストに制限を掛けているように見えますがそうではありません。
カスタムモジュールに自分自身のアクションやアサーションを書き込むことによって、テストスイートを拡張することができるのです。

以下のテストを見てみて下さい。

```php
<?php
$I = new FunctionalTester($scenario);
$I->amOnPage('/');
$I->see('Hello');
$I->seeInDatabase('users', array('id' => 1));
$I->seeFileFound('running.lock');
?>
```

これは異なるエンティティで動作します。ウェブページはPhpBrowserモジュールをロードすることができ、データベースのアサーションはDbモジュールを使用し、ファイルの状態はFilesystemモジュールで確認することができます。

モジュールはスイートの設定でアクタークラスに取り付けられています。例えば`tests/functional.suite.yml`では次のようになっています。

```yaml
class_name: FunctionalTester
modules:
    enabled: [PhpBrowser, Db, Filesystem]
```

FunctionalTesterクラスはモジュールに定義されているメソッドを持っています。しかしメソッドは実際にクラスの中に含まれてるわけではなく、プロキシのように動作しています。Testerクラスはどのモジュールがそのアクションを実行するのか知っており、その中にパラメータを渡すのです。お使いのIDEがFunctionalTesterの持っているすべてのメソッドを見るには`build`コマンドを使います。対応するモジュールからの署名をコピーしてFunctionalTesterクラスの定義を生成します。

## スタンダードモジュール

Codeceptionには異なる目的や環境のためのテストを実行するのに役立つバンドルされたモジュールが多くあります。
多くのモジュールは一定ではありません - より多くのフレームワークやORMがサポートされるように成長していくべきです。
Modulesセクションのメインメニュー下にリストがあるので確認してみてください。

これらのモジュールはすべてドキュメント化されています。詳細なリファレンスは[GitHub](https://github.com/Codeception/Codeception/tree/master/docs/modules)で確認できます。

## ヘルパー

Codeceptionはメインリポジトリからのみのモジュールに制限されているわけではありません。あなたのプロジェクトは独自のアクションをテストスイートに間違いなく追加する必要があるでしょう。`bootstrap`を実行すると、Codeceptionは新しく作られた3つのスイートそれぞれにダミーモジュールを生成します。これらのカスタムモジュールは'ヘルパー'と呼ばれ、`tests/_support`ディレクトリ内に置かれています。

欠けているアクションやアサーションのコマンドをヘルパーに定義することは良いアイディアです。

ノート: ヘルパークラスの名前は"*Helper.php"で終わらなければなりません。

例えば、FunctionalHelperクラスを拡張するとします。これはデフォルトでは、FunctionalTesterクラスと機能テストスイートにリンクされています。

```php
<?php
namespace Codeception\Module;
// here you can define custom functions for FunctionalTester

class FunctionalHelper extends \Codeception\Module
{
}
?>
```
アクションに関して言えば、すべてが非常にシンプルです。あなたが定義するすべてのアクションはpublic functionです。publicメソッドを書き、`build`コマンドを実行すれば、FunctionalTesterクラスに新しい関数が追加されたことを確認できます。

ノート: publicメソッドが`_`から始まる場合は隠され、アクタークラスには追加されません。

アサーションは少し注意が必要です。まず始めに、すべてのアサーションの接頭語が `see` もしくは `dontSee` になっていることを推奨します。

例えばこのようになります。

```php
<?php
$I->seePageReloaded();
$I->seeClassIsLoaded($classname);
$I->dontSeeUserExist($user);
?>
```

これをテストで使用します。

```php
<?php
$I = new FunctionalTester($scenario);
$I->seePageReloaded();
$I->seeClassIsLoaded('FunctionalTester');
$I->dontSeeUserExist($user);
?>
```

モジュール内のassertXXXメソッドを使ってアサーションを定義することができます。すべてのPHPUnitのアサートメソッドがモジュールに含まれているのではありませんが、`PHPUnit_Framework_Assert`クラスにあるPHPUnitの静的メソッドを活用することもできます。

```php
<?php

function seeClassExist($class)
{
    $this->assertTrue(class_exists($class));
    // or
    \PHPUnit_Framework_Assert::assertTrue(class_exists($class));
}
?>
```

ヘルパー内でこれらのアサーションを使うことができます。

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
?>
```

`$this->assert`とタイプすればすべて見ることができます。

### 衝突の解決

もし同じ名前のアクションを含む2つのモジュールがあった場合どうなるでしょう？Codeceptionではモジュールの順序を変更することで
アクションがオーバーライドされます。2つ目のモジュールのアクションがロードされ、1つ目のモジュールのアクションは無視されます。
モジュールの順序はスイートの設定で定義できます。

### モジュールの接続

他のモジュールから内部データや関数にアクセスすることも可能です。例えば、あなたのモジュールはDoctrineからの接続、もしくはSymfonyのためにウェブブラウザが必要になることがあります。

モジュールは`getModule`メソッドを通じて相互に作用できます。このメソッドは必要なモジュールがロードされていない場合、例外を投げることを覚えておいてください。

データベースに再接続するモジュールを書いていると想定してみましょう。Dbモジュールからdbh接続値を使用するようになっています。

```php
<?php

function reconnectToDatabase() {
    $dbh = $this->getModule('Db')->dbh;
    $dbh->close();
    $dbh->open();
}
?>
```

`getModule`関数を使うと、リクエストしたモジュール内のすべてのpublicメソッドやプロパティにアクセスできます。dbhプロパティは他のモジュールで利用できるよう、publicとして定義されています。

これは他のモジュールからアクションのシーケンスを実行する必要がある場合に役立ちます。

例:

```php
<?php
function seeConfigFilesCreated()
{
    $filesystem = $this->getModule('Filesystem');
    $filesystem->seeFileFound('codeception.yml');
    $filesystem->openFile('codeception.yml');
    $filesystem->seeInFile('paths');
}
?>
```

### フック(Hooks)

各モジュールは、実行中のテストからのイベントを処理することができます。モジュールはテスト前に実行させることもできますし、テストが終了してからでも実行できます。これはブートストラップやクリーンアップをする際に役立ちます。また、テストが失敗した時のために特殊な動作を定義することも可能です。これは問題をデバッグする際に便利です。

例えば、PhpBrowserモジュールはテストが失敗した時、`tests/_output`ディレクトリに現在のウェブページを保存します。

すべてのフックは`\Codeception\Module`で定義されており、ここにリストされています。あなたは自由にそれをあなたのモジュールで再定義することができます。

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
    public function _before(\Codeception\TestCase $test) {
    }

    // HOOK: after test
    public function _after(\Codeception\TestCase $test) {
    }

    // HOOK: on fail
    public function _failed(\Codeception\TestCase $test, $fail) {
    }
?>
```

`_`から始まるメソッドはアクタークラスに追加されないことに注意して下さい。
これらはpublicとして定義されますが、内部的な目的でのみ使用されます。

### デバッグ

先述したように、`_failed`フックはテストが失敗した際のデバッグに役立ちます。現在のテストの状態を保存し、それをユーザに見せることができますが、それは`_failed`フックだけではありません。

各モジュールは、デバッグ中に有用的であると思われる内部の値を出力することができます。
例えばPhpBrowserモジュールは、新しいページに移動するたびにレスポンスコードと現在のURLを出力します。
このように、モジュールはブラックボックスではありません。彼らはテスト中に何が起きているのかを見せようとしているのです。あなたがテストをデバッグする際の苦痛を減らしてくれるのです。

追加の情報を表示するには、モジュールの`debug` と `debugSection`メソッドを使用します。
PhpBrowserでどのように動作するか、例を見てみましょう。

```php
<?php
    $this->debugSection('Request', $params));
    $client->request($method, $uri, $params);
    $this->debug('Response Code: ' . $this->client->getStatusCode());
?>
```

PhpBrowserをデバッグモードで実行しているこのテストは、以下のような出力を行います。

```bash
I click "All pages"
* Request (GET) http://localhost/pages {}
* Response code: 200
```

### 設定

モジュールはスイートの設定ファイル、もしくはグローバルな`codeception.yml`で設定することができます。
必須のパラメータはモジュールクラスの`$requiredFields`プロパティで定義する必要があります。Dbモジュールでの例を見てみましょう。

```php
<?php
class Db extends \Codeception\Module {
    protected $requiredFields = array('dsn', 'user', 'password');
?>
```

次回、あなたがこれらの値を設定せずにスイートを開始した場合、例外が投げられます。

オプションのパラメータでは、デフォルト値を設定する必要があります。`$config`プロパティはオプションのパラメータと同様に、それらの値を定義するために使用されます。

WebDriverモジュールでは、Seleniumのデフォルトのサーバーアドレスとポートを使用しています。

```php
<?php
class WebDriver extends \Codeception\Module
{
    protected $requiredFields = array('browser', 'url');
    protected $config = array('host' => '127.0.0.1', 'port' => '4444');
?>
```

ホストとポートのパラメータはスイートの設定で再定義できます。
それらの値は設定ファイルの`modules:config`セクションにあります。

```yaml
modules:
    enabled:
        - WebDriver
        - Db
    config:
        WebDriver:
            url: 'http://mysite.com/'
            browser: 'firefox'
        Db:
            cleanup: false
            repopulate: false
```

オプションと必須のパラメータは`$config`プロパティからアクセスすることができます。その値を取得するには、`$this->config['parameter']`を使ってください。

### ダイナミックな設定(Dynamic Configuration)

もしあなたが実行時にモジュールを再設定したければ、モジュールの`_reconfigure`メソッドを使用してください。
それをヘルパークラスから呼び出し、変更したいすべてのフィールドに渡すことができます。

```php
<?php
$this->getModule('WebDriver')->_reconfigure(array('browser' => 'chrome'));
?>
```

テスト終了後、設定はオリジナルの値に戻されます。

### 追加オプション(Additional options)

各クラスのように、ヘルパーはモジュールから継承することが可能です。

```php
<?php
namespace Codeception\Module;
class MySeleniumHelper extends \Codeception\Module\WebDriver  {
}
?>
```

継承されたヘルパーでは、あなた自身によって実装されているメソッドを書き換えて下さい。
あなたがテストセッションの開始と終了をカスタマイズする際のオプションである`_before` と `_after`フックも置き換えることができます。

親クラスのメソッドが子クラスで使用すべきでない場合、それらを無効にすることができます。Codeceptionにはいくつかのオプションがあります。

```php
<?php
namespace Codeception\Module;
class MySeleniumHelper extends \Codeception\Module\WebDriver
{
    // disable all inherited actions
    public static $includeInheritedActions = false;

    // include only "see" and "click" actions
    public static $onlyActions = array('see','click');

    // exclude "seeElement" action
    public static $excludeActions = array('seeElement');
}
?>
```

`$includeInheritedActions`をfalseに設定することで、親メソッドのエイリアスを作成する機能を追加します。
これはモジュール間の衝突を解決します。`Db`モジュールと、それを継承した私たちの`SecondDbHelper`モジュールを使うとします。
その際、両方のモジュールにある`seeInDatabase`メソッドをどのように使用するのでしょうか？以下を見てみてください。

```php
<?php
namespace Codeception\Module;
class SecondDbHelper extends Db {
    public static $includeInheritedActions = false;

    public function seeInSecondDb($table, $data)
    {
        $this->seeInDatabase($table, $data);
    }
}
?>
```

`$includeInheritedActions`をfalseに設定することで、生成されたアクターに親クラスのメソッドを含まないのです。
ヘルパークラスでは継承したメソッドを、引き続き使用することが可能です。

## 結論

モジュールはCodeceptionの真髄です。これらはアクタークラス（UnitTester、FunctionalTester、AcceptanceTesterなど）への複数の継承をエミュレートするために使用されます。Codeceptionはウェブリクエスト、アクセスデータ、人気PHPライブラリとのインタラクション等をエミュレートするモジュールを提供しています。あなたのアプリケーションは、カスタムされたアクションが必要になるでしょう。これらはヘルパークラスで定義することができます。もしあなたが他の人にも役立ちそうなモジュールを書いたのでしたら、ぜひシェアしてください。Codeceptionリポジトリをフォークし、モジュールを__src/Codeception/Module__ディレクトリ内に設置し、プルリクエストを送信して下さい。
