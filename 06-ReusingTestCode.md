# テストコードの再利用

Codeceptionはすべてのテストスイートに快適なテスト環境を作成するために、モジュールを用いています。
モジュールは、テストで実行できるアクションとアサーションを選択できるようにしています。

## アクターとは？

クラスのアクターオブジェクトで行われるすべてのアクションとアサーションはモジュールで定義されています。これは一見、Codeceptionがあなたのテストに制限を掛けているように見えますがそうではありません。ヘルパーと呼ばれるカスタムモジュールに自分自身のアクションやアサーションを書き込むことによって、テストスイートを拡張することができるのです。この章で後ほど説明はしますが、まずは次のテストを見て下さい。：

```php
<?php
$I = new AcceptanceTester($scenario);
$I->amOnPage('/');
$I->see('Hello');
$I->seeInDatabase('users', ['id' => 1]);
$I->seeFileFound('running.lock');
?>
```

これは異なるエンティティで動作します。ウェブページはPhpBrowserモジュールをロードすることができ、データベースのアサーションはDbモジュールを使用し、ファイルの状態はFilesystemモジュールで確認することができます。

モジュールはスイート設定によりアクタークラスに取り付けられます。
たとえば、`tests/functional.suite.yml`を見てください。
（訳注：`tests/acceptance.suite.yml`の誤りと思われる）

```yaml
class_name: AcceptanceTester
modules:
    enabled: 
        - PhpBrowser:
            url: http://localhost
        - Db
        - Filesystem
```

FunctionalTesterクラスはモジュールに定義されているメソッドを持っています。では、`tests/_support`ディレクトリに配置されている、`AcceptanceTester`クラスの内部を見てみましょう。
（訳注：冒頭の`FunctionalTesterクラス`は`AcceptanceTesterクラス`の誤りと思われる）

```php
<?php
/**
 * Inherited Methods
 * @method void wantToTest($text)
 * @method void wantTo($text)
 * @method void execute($callable)
 * @method void expectTo($prediction)
 * @method void expect($prediction)
 * @method void amGoingTo($argumentation)
 * @method void am($role)
 * @method void lookForwardTo($achieveValue)
 * @method void comment($description)
 * @method void haveFriend($name, $actorClass = null)
 *
 * @SuppressWarnings(PHPMD)
*/
class AcceptanceTester extends \Codeception\Actor
{
    use _generated\AcceptanceTesterActions;

   /**
    * Define custom actions here
    */

}
?>
```

最も重要な箇所は`_generated\AcceptanceTesterActions`トレイトで、有効化されたモジュールへのプロキシとして機能します。それは、どのモジュールがどのアクションを実行するのか、そしてパラメータとして何を渡すのか、知っています。このトレイトは`codecept build`を実行することによって作成され、モジュールや設定ファイルが変更されるたびに再作成されます。
様々な箇所で利用されるアクションはアクタークラス内に定義することを推奨します。そのようなケースの良い例としては、受入テストや機能テストにて積極的に利用されるであろう、`login`アクションが挙げられます。

``` php
<?php
class AcceptanceTester extends \Codeception\Actor
{
    // この行は絶対に消さないこと！
    use _generated\AcceptanceTesterActions;

    public function login($name, $password)
    {
        $I = $this;
        $I->amOnPage('/login');
        $I->submitForm('#loginForm' [
            'login' => $name, 
            'password' => $password
        ]);
        $I->see($name, '.navbar');
    } 
}
?>
```

これでテストで`login`メソッドを利用することができます：

```php
<?php
$I = new AcceptanceTester($scenario);
$I->login('miles', '123456');
?>
```

しかしながら、すべての再利用のためのアクションを一つのアクタークラスに定義することは、[単一責任の原則](http://en.wikipedia.org/wiki/Single_responsibility_principle)の破壊につながる可能性があります。

## ステップオブジェクト

もし、アクタークラスに定義された`login`メソッドがテストの90%で使われているとか、テストのグループのために共通化された処理のようなものを必要とする場合、ステップオブジェクトは素晴らしいものです。たとえば、サイトの管理画面をテストするとしましょう。おそらく、フロントエンドのテスト中に管理画面から同じアクションは必要としないので、それら管理画面特有のものは専用のクラスにまとめてしまいましょう。我々はそのようなクラスをステップオブジェクトと呼んでいます。

コマンドプロンプト上で、テストスイートを指定し、作成したいメソッド名を渡すことで、ジェネレータを使って管理画面用のステップオブジェクトを作成することができます。

```bash
$ php codecept.phar generate:stepobject acceptance Admin
```

アクション名を入力するよう促されますが、これはオプションです。ここでは１つ入力し、エンターキーを押します。すべての必要なアクションを指定し終えたら、何も入力せずに改行することでステップオブジェクトが作成されます。

```bash
$ php codecept.phar generate:stepobject acceptance Admin
Add action to StepObject class (ENTER to exit): loginAsAdmin
Add action to StepObject class (ENTER to exit):
StepObject was created in /tests/acceptance/_support/Step/Acceptance/Admin.php
```

これで次のようなクラスが`/tests/_support/Step/Acceptance/Admin.php`に生成されます：

```php
<?php
namespace Step\Acceptance;

class Admin extends \AcceptanceTester
{
    public function loginAsAdmin()
    {
        $I = $this;
    }
}
?>
```

このように、クラスはとてもシンプルなものです。`AcceptanceTester`クラスを継承しているため、クラス内部ですべての`AcceptanceTester`のメソッドとプロパティを利用することができます。

`loginAsAdmin`メソッドは次のように実装できるでしょう：

```php
<?php
namespace Step\Acceptance;

class Member extends \AcceptanceTester
{
    public function loginAsAdmin()
    {
        $I = $this;
        $I->amOnPage('/admin');
        $I->fillField('username', 'admin');
        $I->fillField('password', '123456');
        $I->click('Login');
    }
}
?>
```

テストでは、`AcceptanceTester`のかわりに`Step\Acceptance\Admin`をインスタンス化うることでステップオブジェクトを使うことができます。

```php
<?php
use Step/Acceptance/Admin as AdminTester;

$I = new AdminTester($scenario);
$I->loginAsAdmin();
?>
```

上と同じように、Cest形式を利用する場合は、DIコンテナによってステップオブジェクトは自動的にインスタンス化されます。

```php
<?php
class UserCest 
{    
    function showUserProfile(\Step\Acceptance\Admin $I)
    {
        $I->loginAsAdmin();
        $I->amOnPage('/admin/profile');
        $I->see('Admin Profile', 'h1');        
    }
}
?>
```

もし複雑なテストシナリオがある場合、1つのテストのなかで複数のステップオブジェクトを使用してかまいません。アクタークラス（この場合はAcceptanceTesterです）にあまりに多くのアクションを追加していると感じたときは、そのうちのいくつかを別々のステップオブジェクトに移動することを考えてみてください。

## ページオブジェクト

受入テストと機能テストにおいて、異なるテストにわたって共通のアクションを再利用可能とするだけではなく、ボタンやリンク、フォームの入力欄についても同じように再利用できるようにする必要があるでしょう。
そのようなケースでは、テスト自動化エンジニアの間では広く使われている[ページオブジェクトパターン](http://code.google.com/p/selenium/wiki/PageObjects)を実装する必要があります。ページオブジェクトパターンでは、ウェブページをクラスとして、ページ上のDOM要素をプロパティとして表現し、いくつかの基本的なインタラクションをメソッドして持ちます。
ページオブジェクトはテストの柔軟なアーキテクチャを作りこむ際にとても重要です。複雑なCSSやXPathロケーターをテストにハードコードするのではなく、ページオブジェクトクラスに移動してください。

Codeception can generate a PageObject class for you with command:
Codeceptionは次のコマンドでページオブジェクトクラスを生成することができます：

```bash
$ php codecept.phar generate:pageobject Login
```

これにより、`tests/_pages`内に`LoginPage`クラスが作成されます。基本のページオブジェクトはいくつかのスタブを持った空クラス以上の何ものでもありません。
空クラスであることは、ページオブジェクトがページを表現するUIロケーターとともに準備されることを期待しており、それらのロケーターは実際のページで利用されるものとなります。
ロケーターはpublicでstaticなプロパティとして定義されます。


```php
<?php
namespace Page;

class Login
{
    public static $URL = '/login';

    public static $usernameField = '#mainForm #username';
    public static $passwordField = '#mainForm input[name=password]';
    public static $loginButton = '#mainForm input[type=submit]';
}
?>
```

そして、ページオブジェクトはテストの中で次のように使用されます：

```php
<?php
use Page\Login as LoginPage;

$I = new AcceptanceTester($scenario);
$I->wantTo('login to site');
$I->amOnPage(LoginPage::$URL);
$I->fillField(LoginPage::$usernameField, 'bill evans');
$I->fillField(LoginPage::$passwordField, 'debby');
$I->click(LoginPage::$loginButton);
$I->see('Welcome, bill');
?>
```
このとおり、あなたはログインページのマークアップを気兼ねなく変更することができ、このページを対象とするすべてのテストに含まれるロケーターはLoginPageクラスのプロパティに従って更新されるでしょう。

しかし、ここでさらに先に進みましょう。ページオブジェクトの概念は、ページのインタラクションを行うメソッドについてもページオブジェクトクラスに含まれるべき、と規定しています。今度は渡されたアクタークラスのインスタンスを保持しています。AcceptanceTesterに`AcceptanceTester`プロパティを介してアクセスできます。では、このクラスに`login`メソッドを定義しましょう。
（訳注：ここの説明、文章がいくつか飛んでしまっているよう？で、下のコードとの文脈が失われています）

```php
<?php
class UserLoginPage
{
    // include url of current page
    public static $URL = '/login';

    /**
     * @var AcceptanceTester
     */
    protected $tester;

    public function __construct(AcceptanceTester $I)
    {
        $this->tester = $I;
    }

    public function login($name, $password)
    {
        $I = $this->tester;

        $I->amOnPage(self::$URL);
        $I->fillField(LoginPage::$usernameField, $name);
        $I->fillField(LoginPage::$passwordField, $password);
        $I->click(LoginPage::$loginButton);

        return $this;
    }    
}
?>
```

そして、これがテストの中でこのページオブジェクトがどのように使われるかの例です。

```php
<?php
$I = new AcceptanceTester($scenario);
$loginPage = new \Page\Login($I);
$loginPage->login('bill evans', 'debby');
$I->amOnPage('/profile');
$I->see('Bill Evans Profile', 'h1');
?>
```

もしシナリオ駆動のテストをCest形式で記述している場合（これは推奨されるアプローチです）は、ページオブジェクトを手動で作成する処理をCodeceptionに任せることができます。テストでどのようなオブジェクトを必要とするか指定すれば、CodeceptionはDIコンテナを使ってそれを作成しようとします。ページオブジェクトの場合、テストメソッドのパラメータとしてクラスを宣言してください：

```php
<?php
class UserCest 
{    
    function showUserProfile(AcceptanceTester $I, \Page\Login $loginPage)
    {
        $loginPage->login('bill evans', 'debby');
        $I->amOnPage('/profile');
        $I->see('Bill Evans Profile', 'h1');        
    }
}
?>
```

DIコンテナは任意の既知のクラスを必要とするどのようなオブジェクトでも作成することができます。たとえば、`Page\Login`は`AcceptanceTester`を必要としたので、`Page\Login`のコンストラクタにそれが注入されましたし、ページオブジェクトは作成されてメソッドの引数に渡されました。Codeceptionがテストのためにどのオブジェクトを作成すればよいか知るために、必要とするオブジェクトの型を明示的に指定してください。依存性の注入については次の章で解説します。

## モジュールとヘルパー

上の例はただアクションを1つのグループにしただけでした。カスタムアクションが必要となったときはどうなるのでしょうか？
そのようなケースでは足りないアクションやアサーションコマンドをカスタムモジュールに定義するのが良いアイディアで、それをヘルパーと呼びます。ヘルパーは`tests/_support/Helper`ディレクトリに見つけることができます。

<div class="alert alert-info">
すでにAcceptanceTesterクラスにカスタムなログインメソッドを作成する方法については学びました。ユーザーが簡単にログインできるように、標準モジュールのアクションを使用してそれをひとまとめにしました。ヘルパーは標準モジュールとは関係のない、**新しいアクション**を作る（もしくは内部的に使用する）ことができます。
</div>


```php
<?php
namespace Helper;
// here you can define custom functions for FunctionalTester

class Functional extends \Codeception\Module
{
}
?>
```

アクションについてもすべてはとてもシンプルです。すべてのアクションはPublicなメソッドとして定義します。任意のpublicメソッドを記述し、`build`コマンドを実行すれば、FunctionalTesterクラスに新しいメソッドが追加されることを確認できるでしょう。

<div class="alert alert-info">
`_`からはじまるpublicメソッドは隠しメソッドとして扱われ、アクタークラスへは追加されません。
</div>

アサーションは少し特殊です。まずはじめに、すべてのアサーションは`see`または`dontSee`を接頭辞とすることを推奨します。

次のようにアサーションをネーミングします：

```php
<?php
$I->seePageReloaded();
$I->seeClassIsLoaded($classname);
$I->dontSeeUserExist($user);
?>
```
そして、テストの中で使います：

```php
<?php
$I->seePageReloaded();
$I->seeClassIsLoaded('FunctionalTester');
$I->dontSeeUserExist($user);
?>
```

モジュール内ではアサーションをassertXXXメソッドを使って定義することができます。モジュールはすべてのPHPUnitのアサーションが読み込んでいませんが、それら全てを活用するために`PHPUnit_Framework_Assert`クラスの静的メソッドを利用できます。

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

ヘルパーないでこれらのアサーションを利用できます：

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

### 衝突の解消

同じ名前のアクションを含むモジュールが2つ存在した場合、何がおきるでしょうか？
Codeceptionはモジュールの順序によってアクションをオーバーライドすることができます。
2つ目のモジュールのアクションは読み込まれ、はじめのものは無視されます。
モジュールの順序はスイート設定により定義されます。

しかしながら、いくつかのモジュールは互いに衝突するかもしれません。最も優先されるモジュールがなんであるか混乱するのをを避けるために、フレームワークモジュール、PhpBrowserモジュール、そしてWebDriverモジュールは一緒に使うことができません。モジュールの`_conflicts`メソッドはどのクラスまたはインタフェースが衝突するか指定するために使われます。Codeceptionはもし条件に一致するモジュールが有効出る場合、例外を投げます。

### モジュールへの接続

他のモジュールの内部データや関数にアクセスすることができます。たとえば、あたなのモジュールは他のモジュールのレスポンスや内部アクションにアクセスする必要がある場合があります。
モジュールは`getModule`メソッドを通して互いにやり取りすることができます。もし必要なモジュールが読み込まれていない場合、例外が投げられることに注意してください。

データベースの再接続を行うモジュールを実装していることを想像してください。それはDbモジュールのdbhコネクションを使って行うことになります。

```php
<?php

function reconnectToDatabase() {
    $dbh = $this->getModule('Db')->dbh;
    $dbh->close();
    $dbh->open();
}
?>
```

`getModule`メソッドを使うことで、要求したモジュールのすべてのpublicなメソッドとプロパティにアクセスできるようになります。このdbhプロパティは他のモジュールから利用できるようpublicとして定義されました。

標準モジュールの機能を拡張したい場合は、そのモジュールに接続してpublicなプロパティとメソッドを使うカスタムアクションやアサーションを作成してください。

```php
<?php
function seeNumResults($num)
{
    // retrieving webdriver session
    /** @var $wd \RemoteWebDriver */
    $wd = $this->getModule('WebDriver')->webDriver;

    // searching for table which contains results
    /**@var $el \WebDriverElement */
    $el = $wd->findElement(WebDriverBy::id('results'));
    // asserting that #results is actually a table
    $this->assertEquals('table', $el->getTagName());
    $results = $el->findElements('tr');

    // asserting that table contains exactly $num rows
    $this->assertEquals($num, count($results));
}
?>
```

<div class="alert alert-info">
この例ではSelenium WebDriverのクライアントである<a href="https://github.com/facebook/php-webdriver">facebook/php-webdriver</a>のAPIを使用しています。
</div>

### フック

各モジュールは実行中のテストで発生するイベントを処理することができます。テストの開始前や終了後にモジュールを実行することができます。これは起動/クリーンアップのアクションのために便利です。
テストが失敗した場合の特別な振る舞いを定義することもできます。これは問題のデバッグに役立つでしょう。
たとえば、PhpBrowserモジュールはテストが失敗した場合に現在のページを`tests/_output`ディレクトリに保存します。

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

`_`ではじまるメソッドはアクタークラスに追加されないことに注意してください。これはpublicとして定義されますが、内部的な目的のために使用するためのものです。

### デバッグ

すでに触れたように、`_failed`フックは失敗したテストをデバッグするのに役に立ちます。現在のテストの状態を保存しユーザーに表示する機会を提供しますが、これに限ったことではありません。

各モジュールはデバッグ中に役立つであろう内部的な値を出力することができます。
たとえば、PhpBrowserモジュールは新しいページに移動するたびにレスポンスコードと現在のURLを出力します。
このように、モジュールはブラックボックスではありません。彼らはテスト中に何が発生したのかあなたに見せようとします。これはテストのデバッグにかかる苦痛を軽減します。

To display additional information, use the `debug` and `debugSection` methods of the module.
追加の情報を表示するためには、モジュールの`debug`と`debugSection`メソッドを使います。
PhpBrowserモジュールでの使用例がこちらです：


```php
<?php
    $this->debugSection('Request', $params);
    $this->client->request($method, $uri, $params);
    $this->debug('Response Code: ' . $this->client->getStatusCode());
?>    
```

このテストをデバッグモードでPhpBrowserモジュールとともに実行すると、次のようなものが表示されるでしょう：

```bash
I click "All pages"
* Request (GET) http://localhost/pages {}
* Response code: 200
```



### 設定

モジュールとヘルパーはスイート設定もしくはグローバルな`codeception.yml`によって設定されます。

必須のパラメータはモジュールクラスの`$requiredFields`プロパティで定義する必要があります。Dbモジュールでの例を見てみましょう。：


```php
<?php
class Db extends \Codeception\Module 
{
    protected $requiredFields = ['dsn', 'user', 'password'];
?>
```

次回、あなたがこれらの値を設定せずにスイートを開始した場合、例外が投げられます。

オプションのパラメータには、デフォルト値を設定する必要があります。`$config`プロパティはオプションのパラメータと同様に、それらの値を定義するために使用されます。WebDriverモジュールでは、Seleniumのデフォルトのサーバーアドレスとポートを使用しています。

```php
<?php
class WebDriver extends \Codeception\Module
{
    protected $requiredFields = ['browser', 'url'];    
    protected $config = ['host' => '127.0.0.1', 'port' => '4444'];
?>    
```

ホストとポートのパラメータはスイートの設定で再定義できます。それらの値は設定ファイルの`modules:config`セクションにあります。

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

オプションと必須のパラメータは`$config`プロパティからアクセスすることができます。その値を取得するには、`$this->config['parameter']`を使ってください。

### 動的設定

もし実行時にモジュールを再設定したければ、モジュールの`_reconfigure`メソッドを使用してください。
それをヘルパークラスから呼び出し、変更したいすべてのフィールドに渡すことができます。

```php
<?php
$this->getModule('WebDriver')->_reconfigure(array('browser' => 'chrome'));
?>
```

テスト終了時に、変更した設定はオリジナルの値に戻されます。

### 追加オプション

標準モジュールの機能を拡張する別の方法は、モジュールを継承してヘルパーを作成することです。

```php
<?php
namespace Helper;

class MyExtendedSelenium extends \Codeception\Module\WebDriver  {
}
?>
```

このヘルパー内で、実装されているメソッドを自身の実装で置き換えます。
テストセッションの開始と終了をカスタマイズする際のオプションである`_before` と `_after`フックも置き換えることができます。

親クラスのメソッドが子クラスで使用すべきでない場合、それらを無効にすることができます。Codeceptionにはいくつかのオプションがあります。

```php
<?php
namespace Helper;

class MyExtendedSelenium extends \Codeception\Module\WebDriver 
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
これはモジュール間の衝突を解決します。`Db`モジュールを、`Db`を継承した`SecondDbHelper`モジュールとして使いたいとします。
その際、両方のモジュールにある`seeInDatabase`メソッドをどのように使用するのでしょうか？以下を見てみてください。

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
?>
```

`$includeInheritedActions`をfalseに設定することで、生成されたアクターに親クラスのメソッドを含まないのです。
ヘルパークラスでは継承したメソッドを、引き続き使用することが可能です。

## まとめ

テストの可読性と再利用性を高める方法はたくさんあります。共通アクションを1つのグループとし、アクタークラスまたはステップオブジェクトに移動します。CSSとXPathロケーターをページオブジェクトに移します。独自のカスタムアクションとアサーションをヘルパーに記述します。シナリオ駆動のテストには、`$I->doSomething`コマンドよりも複雑などんなものも含まれるべきではありません。このアプローチに従うことえテストをきれいに、読みやすく、壊れにくく、そしてメンテナンスしやすく保つことができるでしょう。