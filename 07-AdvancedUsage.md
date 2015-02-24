# 高度な使用法

この章ではあなたのテストのエクスペリエンスを向上させ、プロジェクトをより良い組織に保つためのいくつかのテクニックとオプションについて取り上げます。

## Cestクラス

もしCept形式に対して、クラスのような構造を持たせたい場合、プレーンなPHPの替わりにCest形式を利用することができます。
Cest形式はとても単純でCept形式のシナリオと完全な互換性があります。これはつまり、テストが非常に長くなり分割したいと感じた場合、簡単にクラスに移動することができることを意味します。

次のコマンドによりCestを作成することができます。

```bash
$ php codecept.phar generate:cest suitename CestName
```

生成されたファイルは次のようになります。

```php
<?php
class BasicCest
{
    public function _before(\AcceptanceTester $I)
    {
    }

    public function _after(\AcceptanceTester $I)
    {
    }

    // tests
    public function tryToTest(\AcceptanceTester $I) 
    {    
    }
}
?>
```

**それぞれのpublicなメソッド（「_」で始まるものを除く）はテストとして実行され**、最初の引数としてアクタークラスを、2つ目の引数して`$scenario`変数を受け取ります。

`_before`と`_after`メソッドはそのクラスのテストに対する共通のセットアップとティアダウンのために使用することができます。このことが、類似の処理をヘルパークラスのみに依存するCept形式と比較して、Cest形式をより柔軟にしています。

ご覧のように、`tryToTest`メソッドにアクターオブジェクトを渡しています。このオブジェクトを使ってこれまでにやってきた方法でシナリオを描くことができます。

```php
<?php
class BasicCest
{
    // test
    public function checkLogin(\AcceptanceTester $I) 
    {
        $I->wantTo('log in to site');
        $I->amOnPage('/');
        $I->click('Login');
        $I->fillField('username', 'john');
        $I->fillField('password', 'coltrane');
        $I->click('Enter');
        $I->see('Hello, John');
        $I->seeInCurrentUrl('/account');
    }
}
?>
```

このように、Cestクラスは`\Codeception\TestCase\Test`や`PHPUnit_Framework_TestCase`といった親クラスを持ちません。意図的にそうしています。これにより、子クラスで使用することができる共通の振る舞いや処理を伴ってクラスを拡張することができます。ただし、それらのメソッドはテストとして実行されないよう`protected`なメソッドとして定義することを忘れないでください。

また、テストが`error`となったり失敗した時に呼ばれる`_failed`メソッドについてもCestクラスに定義することができます。

### Before/Afterアノテーション

`@before`と`@after`アノテーションを使ってテストの実行フローをコントロールすることができます。共通のアクションをprotectedな（テストでない）メソッドに移動し、アノテーションを記述することによってテストの前後でそれらを呼び出すことができます。`@before`や`@after`アノテーションを複数利用することによって、複数のメソッドを呼び出すことが可能です。メソッドは上から下の順で呼び出されます。

```php
<?php
class ModeratorCest {

    protected function login(AcceptanceTester $I)
    {
        $I->amOnPage('/login');
        $I->fillField('Username', 'miles');
        $I->fillField('Password', 'davis');
        $I->click('Login');
    }

    /**
     * @before login
     */
    public function banUser(AcceptanceTester $I)
    {
        $I->amOnPage('/users/charlie-parker');
        $I->see('Ban', '.button');
        $I->click('Ban');
    }
    
    /**
     * @before login
     * @before cleanup
     * @after logout
     * @after close
     */
    public function addUser(AcceptanceTester $I)
    {
        $I->amOnPage('/users/charlie-parker');
        $I->see('Ban', '.button');
        $I->click('Ban');
    }
}
?>
```

`@before`と`@after`アノテーションはインクルードされた関数に対しても使えます。ただし、1つのメソッドに対して同じ種類のアノテーションを複数記述することはできません。1つのメソッドに対して、1つの`@before`と1つの`@after`アノテーションのみですd - one method can have only one `@before` and only one `@after` annotation.

### Dependsアノテーション

`@depends`アノテーションを使って現在のテストが事前にどのテストにパスしているべきか、指定することができます。もし事前のテストが失敗したら、対象のテストはスキップされます。
依存しているテストのメソッド名をアノテーションに記述してください。

```php
<?php
class ModeratorCest {

    public function login(AcceptanceTester $I)
    {
        // logs moderator in
    }

    /**
     * @depends login
     */
    public function banUser(AcceptanceTester $I)
    {
        // bans user
    }
}
?>
```

ヒント：`@depends`アノテーションは`@before`アノテーションと組み合わせることができます。

## インタラクティブ・コンソール

インタラクティブ・コンソールはCodeceptionのコマンドをテストで実行する前に試すために追加されました。

![コンソール](http://img267.imageshack.us/img267/204/003nk.png)

次のコマンドでコンソールを起動することができます。

``` bash
$ php codecept.phar console suitename
```

これで、アクタークラスに対応したすべてのコマンドを実行することができ、結果をすぐに確認できます。特に、`WebDriver`モジュールと使用する場合に便利です。Selenuimとブラウザーの起動にはいつも長い時間がかかります。ところが、コンソールを使って別のセレクタ、異なるコマンドを試すことで、実行された際に確実にパスするテストを書くことができます。

特別なヒント：コンソールとSeleniumを使ってあなたがウェブページを上手に操作できるか上司に見せましょう。この手順を自動化し、プロジェクトに受け入れテストを導入することを説得しやすくなるでしょう。

## 異なるフォルダーからテストを実行する

もしCodeceptionを使ったプロジェクトが複数あったとしても、すべてのテストを1つの`codecept.phar`で実行することができます。
異なるディレクトリーのCodeceptionを実行するために、`bootstrap`を除くすべてのコマンドに`-c`オプションが用意されています。

```bash
$ php codecept.phar run -c ~/projects/ecommerce/
$ php codecept.phar run -c ~/projects/drupal/
$ php codecept.phar generate:cept acceptance CreateArticle -c ~/projects/drupal/
```

現在の場所と異なるディレクトリー内にプロジェクトを作成するには、パラメータとしてパスを指定するだけです。

```bash
$ php codecept.phar bootstrap ~/projects/drupal/
```

基本的に`-c`オプションにはパスを指定しますが、使用する設定ファイルを指定することもできます。従って、テストスイートに対して複数の`codeception.yml`を持つことができます。さまざまな環境や設定を指定するためにこのオプションを使用することができます。特定の設定ファイルを使ってテストを実行するためには、`-c`オプションにファイル名を渡してください。

## グループ

テストをグルーピングして実行する方法はいくつかあります。特定のディレクトリを指定して実行することもできます。

```bash
$ php codecept.phar run tests/acceptance/admin
```

また、特定の（もしくは複数の）グループを指定して実行することもできます。

```bash
$ php codecept.phar run -g admin -g editor
```

このケースでは`admin`と`editor`グループに属すすべてのテストが実行されます。グループの概念はPHPUnitから取り入れたもので、従来のPHPUnitと同様の振る舞いをします。Ceptをグループに追加するには、`scenario`変数を使います。

```php
<?php
$scenario->group('admin');
$scenario->group('editor');
// or
$scenario->group(array('admin', 'editor'))
// or
$scenario->groups(array('admin', 'editor'))

$I = new AcceptanceTester($scenario);
$I->wantToTest('admin area');
?>
```

Test形式とCest形式のテストでは、テストをグループに追加するために`@group`アノテーションを使います。

```php
<?php
/**
 * @group admin
 */
public function testAdminUser()
{
    $this->assertEquals('admin', User::find(1)->role);
}
?>
```

Cestクラスでも同じアノテーションを使用できます。

### グループファイル

グループはグローバルまたはテストスイートの設定ファイルで定義できます。
グループに含まれるテストは、配列形式で指定するか、テストの一覧が含まれるファイルパスを指定します。

```yaml
groups:
  # add 2 tests to db group
  db: [tests/unit/PersistTest.php, tests/unit/DataTest.php]

  # add list of tests to slow group
  slow: tests/_data/slow  
```

たとえば、最も遅いテストの一覧ファイルを作成し、それらのグループ内で実行することができます。
グループファイルは各行にテスト名が記述されたプレーンテキストファイルです。

```bash
tests/unit/DbTest.php
tests/unit/UserTest.php:create
tests/unit/UserTest.php:update
```

グループファイルは手動で作成することもできますし、サードパーティ製のアプリケーションによって生成することもできます。
たとえば、XMLレポートから遅いテストを抽出してグループファイルを更新するスクリプトを記述することができるでしょう。

1つの定義で複数のグループファイルをロードするような、パターンについても指定することもできます。

```yaml
groups:
  p*: tests/_data/p*
```

これは、`tests/_data`内の`p*`パターンに一致するすべてのファイルをグループとしてロードします。

## リファクタリング

テストが成長していくにつれ、共通の変数や振る舞いを共有するためのリファクタリングが必要になります。古典的な例は、テストスイートのあらゆる箇所で呼び出される`login`アクションです。これは、1度だけ記述しすべてのテストで使用するようにするのが賢明です。

このようなケースにおいてPHPクラスの中にそれらのメソッドを定義するというのは明白です。

```php
<?php
class TestCommons
{
    public static $username = 'john';
    public static $password = 'coltrane';

    public static function logMeIn($I)
    {
        $I->amOnPage('/login');
        $I->fillField('username', self::$username);
        $I->fillField('password', self::$password);
        $I->click('Enter');
    }
}
?>
```

そして、このファイルを`_bootstrap.php`ファイルから読み込みます。

```php
<?php
// bootstrap
require_once '/path/to/test/commons/TestCommons.php';
?>
```

シナリオの中で使います。

```php
<?php
$I = new AcceptanceTester($scenario);
TestCommons::logMeIn($I);
?>
```

もしアイディアを得られたら、テストコードを構造化するためのいくつかのビルトイン機能について学びましょう。Codeceptionにおける`PageObject`と`StepObject`パターンの実装について学びます。

## ページオブジェクト

[ページオブジェクトパターン](http://code.google.com/p/selenium/wiki/PageObjects)はテスト自動化エンジニアの間では広く使われています。ページオブジェクトパターンでは、ウェブページをクラスとして、ページ上のDOM要素をプロパティとして表現し、いくつかの基本的なインタラクションをメソッドして持ちます。
ページオブジェクトはテストの柔軟なアーキテクチャを作りこむ際にとても重要です。複雑なCSSやXPathロケーターをテストにハードコードするのではなく、ページオブジェクトクラスに移動してください。

Codeceptionは次のコマンドでページオブジェクトクラスを生成することができます。

```bash
$ php codecept.phar generate:pageobject Login
```

これにより、`tests/_pages`内に`LoginPage`クラスが作成されます。基本のページオブジェクトはいくつかのスタブを持った空クラス以上の何ものでもありません。
空クラスであることは、ページオブジェクトがページを表現するUIロケーターとともに準備されることを期待しており、それらのロケーターはページで利用されるでしょう。
ロケーターはpublicでstaticなプロパティとして定義されます。

```php
<?php
class LoginPage
{
    public static $URL = '/login';

    public static $usernameField = '#mainForm #username';
    public static $passwordField = '#mainForm input[name=password]';
    public static $loginButton = '#mainForm input[type=submit]';
}
?>
```

そして、ページオブジェクトはテストの中で次のように使用されます。

```php
<?php
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

しかし、ここでさらに先に進みましょう。ページオブジェクトの概念は、ページのインタラクションを行うメソッドについてもページオブジェクトクラスに含まれるべき、と規定しています。
先ほど作成した`LoginPage`クラスではこれを行うことはできません。なぜなら、このクラスはすべてのテストスイートからアクセス可能なので、どのアクタークラスをインタラクションに使用するのかわからないためです。そのため、別のページオブジェクトを作成する必要があります。この例では、ページオブジェクトを使用するテストスイートを明示します。

```bash
$ php codecept.phar generate:pageobject acceptance UserLogin
```

*先ほど作成したLoginクラスと名前が衝突しないよう、UserLoginクラスとします*

作成された`UserLoginPage`クラスは1つの違いをのぞき、ほぼ先ほどのLoginPageクラスと同じように見えます。今度は渡されたアクタークラスのインスタンスを保持しています。AcceptanceTesterに`AcceptanceTester`プロパティを介してアクセスできます。では、このクラスに`login`メソッドを定義しましょう。

```php
<?php
class UserLoginPage
{
    // include url of current page
    public static $URL = '/login';

    /**
     * @var AcceptanceTester
     */
    protected $AcceptanceTester;

    public function __construct(AcceptanceTester $I)
    {
        $this->AcceptanceTester = $I;
    }

    public static function of(AcceptanceTester $I)
    {
        return new static($I);
    }

    public function login($name, $password)
    {
        $I = $this->AcceptanceTester;

        $I->amOnPage(self::$URL);
        $I->fillField(LoginPage::$usernameField, $name);
        $I->fillField(LoginPage::$passwordField, $password);
        $I->click(LoginPage::$loginButton);

        return $this;
    }    
}
?>
```

そして、これがテストの中でページオブジェクトを使用する方法の例です。

```php
<?php
$I = new AcceptanceTester($scenario);
UserLoginPage::of($I)->login('bill evans', 'debby');
?>
```

おそらく、`UserLoginPage`と`LoginPage`とは同じ役割を担っているようなので、マージすべきかもしれません。しかし、`LoginPage`が機能テストと受け入れテストの両方で使える一方、`UserLoginPage`は`AcceptanceTester`でのみ使うことができます。ですので、グローバルなページオブジェクトを利用するかテストスイート単位のページオブジェクトを使用するかはあなた次第です。もし機能テストと受け入れテストとに多くの共通点がある場合は、グローバルなページオブジェクトにロケーターを格納し、ページオブジェクトの振る舞いの部分については代替としてステップオブジェクトを使ってください。

## ステップオブジェクト

ステップオブジェクトパターンはBDDフレームワークに由来します。ステップオブジェクトは異なるテストで広く使われるであろう共通のアクション群を含みます。
前述の`login`メソッドはそのような共通アクションの良い例です。似たようなアクションであるリソースの作成・更新・削除についてもステップオブジェくトに移動するべきです。ステップオブジェクトを作成し、どのようなものか見てみましょう。

`Member`ステップクラスを作成しましょう。ジェネレーターが含まれるメソッドを聞いてくるので、`login`を追加しましょう。

```bash
$ php codecept.phar generate:stepobject acceptance Member
```

アクション名を入力するよう求められますが、これはオプションです。はじめに「login」を入力し、エンターキーを押します。すべての必要なアクションを指定した後、ステップオブジェクトの作成に進むには空行のままにしておきます。

```bash
$ php codecept.phar generate:stepobject acceptance Member
Add action to StepObject class (ENTER to exit): login
Add action to StepObject class (ENTER to exit):
StepObject was created in <you path>/tests/acceptance/_steps/MemberSteps.php
```

これで次のような`tests/acceptance/_steps/MemberSteps.php`クラスが作成されます。

```php
<?php
namespace AcceptanceTester;

class MemberSteps extends \AcceptanceTester
{
    public function login()
    {
        $I = $this;

    }
}
?>
```

ご覧のようにとてもシンプルなクラスです。`AcceptanceTester`クラスを継承しているので、`AcceptanceTester`のすべてのメソッドとプロパティがこのクラス内で利用可能です。

`login`メソッドは次のように実装できるでしょう。

```php
<?php
namespace AcceptanceTester;

class MemberSteps extends \AcceptanceTester
{
    public function login($name, $password)
    {
        $I = $this;
        $I->amOnPage(\LoginPage::$URL);
        $I->fillField(\LoginPage::$usernameField, $name);
        $I->fillField(\LoginPage::$passwordField, $password);
        $I->click(\LoginPage::$loginButton);
    }
}
?>
```

テストでは`AcceptanceTester`の代わりに`MemberSteps`クラスをインスタンス化することでステップオブジェクトを使用することができます。

```php
<?php
$I = new AcceptanceTester\MemberSteps($scenario);
$I->login('bill evans', 'debby');
?>
```

このように、ステップオブジェクトクラスは従来のページオブジェクトと比較してより単純で可読性に優れています。
ステップオブジェクトの代替として`AcceptanceHelper`クラスを利用することができます。ヘルパーの内部では`$I`オブジェクトそのものにアクセスできないため、ヘルパーは新しいアクションを実装するために使い、ステップオブジェクトは共通のシナリオを統合するために使うのが良いでしょう。

## 環境

別の設定を使ってテストを実行する必要がある場合、別の設定環境を定義することができます。
最も典型的なユースケースとしては、種類の違うブラウザーで受け入れテストを実行する場合や、異なるデータベースエンジンを利用してテストを実行する場合です。

ブラウザーのケースについて、環境をどう使うか、実際にやってみましょう。

`acceptance.suite.yml`に新しく行を追加する必要があります。

``` yaml
class_name: AcceptanceTester
modules:
    enabled:
        - WebDriver
        - AcceptanceHelper
    config:
        WebDriver:
            url: 'http://127.0.0.1:8000/'
            browser: 'firefox'

env:
    phantom:
         modules:
            config:
                WebDriver:
                    browser: 'phantomjs'

    chrome:
         modules:
            config:
                WebDriver:
                    browser: 'chrome'

    firefox:
        # nothing changed
```

最初はこのような設定の構造は汚く見えるかもしれませんが、これがもっともクリーンな方法です。
基本的に、ルートの`env`配下に異なる環境を定義し、名前を付け（`phantom`とか`chrome`など）、そしてすでに設定されている任意のパラメータを再定義します。

テスト実行する際に、`--env`オプションによって容易にこれらの設定を切り替えることができます。PhantomJSのみのテストを実行するには、次のように`--env phantom`を渡します。

```bash
$ php codecept.phar run acceptance --env phantom
```

3つのブラウザーすべてのテストを実行するには、単にすべての環境を列挙します。

```bash
$ php codecept.phar run acceptance --env phantom --env chrome --env firefox
```

異なるブラウザーごとに3回テストが実行されるでしょう。

環境に応じて、実行されるべきテストを選択することができます。
たとえば、いくつかのテストはFirefoxでのみ実行され、ほかのいくつかはChromeのみで実行されるようにする必要があるかもしれません。

Test形式、Cest形式のテストでは、`@env`アノテーションを使って求められる環境を指定することができます。

```php
<?php
class UserCest
{
    /**
     * This test will be executed only in 'firefox' and 'phantom' environments
     *
     * @env firefox
     * @env phantom
     */
    public function webkitOnlyTest(AcceptanceTester $I)
    {
        // I do something
    }
}
?>
```

Cept形式では`$scenario->env()`を使ってください。

```php
<?php
$scenario->env('firefox');
$scenario->env('phantom');
// or
$scenario->env(array('phantom', 'firefox'));
?>
```

この方法で、どのブラウザーでどのテストを行うか、簡単にコントロールすることができます。


## まとめ

Codeceptionは一見シンプルなフレームワークのように見えますが、強力なテストを、単一のAPIを使って、それらをリファクタリングし、そしてインタラクティブ・コンソールを使ってより速く、構築することができます。CodeceptionのテストはグループやCestクラスを使って容易に整理することができ、ロケーターはページオブジェクトに、そして共通のステップはステップオブジェクトに統合することができます。

おそらく単体のフレームワークとしては機能が多すぎるかもしれません。しかし、それにもかかわらずCodeceptionはKISSの原則に従っています。Codeceptionは簡単に始めることができ、習得が容易で、楽に拡張することができるのです。
