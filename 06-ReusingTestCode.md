# テストコードの再利用

Codeceptionはすべてのテストスイートに快適なテスト環境を作成するために、モジュールを用いています。
モジュールは、テストで実行できるアクションとアサーションを選択できるようにしています。

## アクターとは？

クラスのアクターオブジェクトで行われるすべてのアクションとアサーションはモジュールで定義されています。これは一見、Codeceptionがあなたのテストに制限を掛けているように見えますがそうではありません。ヘルパーと呼ばれるカスタムモジュールに自分自身のアクションやアサーションを書き込むことによって、テストスイートを拡張することができるのです。この章で後ほど説明はしますが、まずは次のテストを見てください：

```php
<?php
$I = new AcceptanceTester($scenario);
$I->amOnPage('/');
$I->see('Hello');
$I->seeInDatabase('users', ['id' => 1]);
$I->seeFileFound('running.lock');
```

これは異なるエンティティで動作します。ウェブページはPhpBrowserモジュールをロードすることができ、データベースのアサーションはDbモジュールを使用し、ファイルの状態はFilesystemモジュールで確認することができます。

モジュールはスイート設定によりアクタークラスに取り付けられます。
たとえば、`tests/acceptance.suite.yml`を見てください。

```yaml
class_name: AcceptanceTester
modules:
    enabled:
        - PhpBrowser:
            url: http://localhost
        - Db
        - Filesystem
```

AcceptanceTesterクラスはモジュールに定義されているメソッドを持っています。では、`tests/_support`ディレクトリーに配置されている、`AcceptanceTester`クラスの内部を見てみましょう。

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
```

最も重要な箇所は`_generated\AcceptanceTesterActions`トレイトで、有効化されたモジュールへのプロキシとして機能します。それは、どのモジュールがどのアクションを実行するのか、そしてパラメーターとして何を渡すのか、知っています。このトレイトは`codecept build`を実行することによって作成され、モジュールや設定ファイルが変更されるたびに再作成されます。

### 認証

さまざまな箇所で利用されるアクションはアクタークラス内に定義することを推奨します。そのようなケースの良い例としては、受入テストや機能テストにて積極的に利用されるであろう、`login`アクションが挙げられます。

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
        $I->submitForm('#loginForm', [
            'login' => $name,
            'password' => $password
        ]);
        $I->see($name, '.navbar');
    }
}
```

これでテストで`login`メソッドを利用することができます：

```php
<?php
$I = new AcceptanceTester($scenario);
$I->login('miles', '123456');
```

しかしながら、すべての再利用のためのアクションを1つのアクタークラスに定義することは、[単一責任の原則](http://en.wikipedia.org/wiki/Single_responsibility_principle)の破壊につながる可能性があります。

### セッションのスナップショット

もしテスト用ユーザーを認証する必要がある場合、それぞれのテストの開始時にログインフォームを入力させることでそれを行うことができます。
これらのステップにかかる時間、特に（それ自体が遅い）Seleniumを使ったテストにおいては、この時間は問題になるかもしれません。

Codeceptionは複数のテスト間でCookieを共有することができるため、一度ログインしたユーザーは他のテストでも認証状態を保つことができます。

さきほどの`login`メソッドを、初回ログイン時のみ一度だけ実行し、その後はクッキーからセッションを復元するように改善してみましょう。

``` php
<?php
    public function login($name, $password)
    {
        $I = $this;
        // if snapshot exists - skipping login
        if ($I->loadSessionSnapshot('login')) {
            return;
        }
        // logging in
        $I->amOnPage('/login');
        $I->submitForm('#loginForm', [
            'login' => $name,
            'password' => $password
        ]);
        $I->see($name, '.navbar');
         // saving snapshot
        $I->saveSessionSnapshot('login');
    }

```
セッションの復元は（`Codeception\Lib\Interfaces\SessionSnapshot`インタフェースを実装している）`WebDriver`と`PhpBrowser`モジュールでのみ動作することに注意してください。

## ステップオブジェクト

もし、アクタークラスに定義された`login`メソッドがテストの90%で使われているとか、テストのグループのために共通化された処理のようなものを必要とする場合、ステップオブジェクトはすばらしいものです。たとえば、サイトの管理画面をテストするとしましょう。おそらく、フロントエンドのテスト中に管理画面から同じアクションは必要としないので、それら管理画面特有のものは専用のクラスにまとめてしまいましょう。われわれはそのようなクラスをステップオブジェクトと呼んでいます。

コマンドプロンプト上で、テストスイートを指定し、作成したいメソッド名を渡すことで、ジェネレーターを使って管理画面用のステップオブジェクトを作成することができます。

```bash
php codecept generate:stepobject acceptance Admin
```

アクション名を入力するよう促されますが、これはオプションです。ここでは1つ入力し、エンターキーを押します。すべての必要なアクションを指定し終えたら、何も入力せずに改行することでステップオブジェクトが作成されます。

```bash
php codecept generate:stepobject acceptance Admin
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
```

テストでは、`AcceptanceTester`のかわりに`Step\Acceptance\Admin`をインスタンス化うることでステップオブジェクトを使うことができます。

```php
<?php
use Step\Acceptance\Admin as AdminTester;

$I = new AdminTester($scenario);
$I->loginAsAdmin();
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
```

もし複雑なテストシナリオがある場合、1つのテストのなかで複数のステップオブジェクトを使用してかまいません。アクタークラス（この場合はAcceptanceTesterです）にあまりに多くのアクションを追加していると感じたときは、そのうちのいくつかを別々のステップオブジェクトに移動することを考えてみてください。

## ページオブジェクト

受入テストと機能テストにおいて、異なるテストにわたって共通のアクションを再利用可能とするだけではなく、ボタンやリンク、フォームの入力欄についても同じように再利用できるようにする必要があるでしょう。
そのようなケースでは、テスト自動化エンジニアの間では広く使われている[ページオブジェクトパターン](http://docs.seleniumhq.org/docs/06_test_design_considerations.jsp#page-object-design-pattern)を実装する必要があります。ページオブジェクトパターンでは、ウェブページをクラスとして、ページ上のDOM要素をプロパティとして表現し、いくつかの基本的なインタラクションをメソッドして持ちます。
ページオブジェクトはテストの柔軟なアーキテクチャを作りこむ際にとても重要です。複雑なCSSやXPathロケーターをテストにハードコードするのではなく、ページオブジェクトクラスに移動してください。

Codeceptionは次のコマンドでページオブジェクトクラスを生成することができます：

```bash
php codecept generate:pageobject Login
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
```
このとおり、あなたはログインページのマークアップを気兼ねなく変更することができ、このページを対象とするすべてのテストに含まれるロケーターはLoginPageクラスのプロパティに従って更新されるでしょう。

しかし、ここでさらに先に進みましょう。ページオブジェクトの概念は、ページのインタラクションを行うメソッドについてもページオブジェクトクラスに含まれるべき、と規定しています。今度は渡されたアクタークラスのインスタンスを保持しています。AcceptanceTesterに`AcceptanceTester`プロパティを介してアクセスできます。では、このクラスに`login`メソッドを定義しましょう。

```php
<?php
namespace Page;

class Login
{
    public static $URL = '/login';

    public static $usernameField = '#mainForm #username';
    public static $passwordField = '#mainForm input[name=password]';
    public static $loginButton = '#mainForm input[type=submit]';

    /**
     * @var AcceptanceTester
     */
    protected $tester;

    public function __construct(\AcceptanceTester $I)
    {
        $this->tester = $I;
    }

    public function login($name, $password)
    {
        $I = $this->tester;

        $I->amOnPage(self::$URL);
        $I->fillField(self::$usernameField, $name);
        $I->fillField(self::$passwordField, $password);
        $I->click(self::$loginButton);

        return $this;
    }    
}
```

そして、これがテストの中でこのページオブジェクトがどのように使われるかの例です。

```php
<?php
use Page\Login as LoginPage;

$I = new AcceptanceTester($scenario);
$loginPage = new LoginPage($I);
$loginPage->login('bill evans', 'debby');
$I->amOnPage('/profile');
$I->see('Bill Evans Profile', 'h1');
```

もしシナリオ駆動のテストをCest形式で記述している場合（これは推奨されるアプローチです）は、ページオブジェクトを手動で作成する処理をCodeceptionに任せることができます。テストでどのようなオブジェクトを必要とするか指定すれば、CodeceptionはDIコンテナを使ってそれを作成しようとします。ページオブジェクトの場合、テストメソッドのパラメーターとしてクラスを宣言してください：

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
```

DIコンテナは任意の既知のクラスを必要とするどのようなオブジェクトでも作成することができます。たとえば、`Page\Login`は`AcceptanceTester`を必要としたので、`Page\Login`のコンストラクタにそれが注入されましたし、ページオブジェクトは作成されてメソッドの引数に渡されました。Codeceptionがテストのためにどのオブジェクトを作成すればよいか知るために、必要とするオブジェクトの型を明示的に指定してください。依存性の注入については次の章で解説します。

## まとめ

テストの可読性と再利用性を高める方法はたくさんあります。共通アクションを1つのグループとし、アクタークラスまたはステップオブジェクトに移動します。CSSとXPathロケーターをページオブジェクトに移します。独自のカスタムアクションとアサーションをヘルパーに記述します。シナリオ駆動のテストには、`$I->doSomething`コマンドよりも複雑などんなものも含まれるべきではありません。このアプローチに従うことえテストをきれいに、読みやすく、壊れにくく、そしてメンテナンスしやすく保つことができるでしょう。
