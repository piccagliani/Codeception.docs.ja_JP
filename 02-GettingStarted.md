# はじめに

はじめにCodeceptionの構造を見てみましょう。
あなたはすでに[インストール](http://codeception.com/install) を終え、最初のテストをブートストラップしたと思います。
Codeceptionは単体テスト、機能テスト、受け入れテストの3つを生成しました。これらについては前の章で解説してあります。__/tests__ フォルダー内には、これら3つのテストに対応する名前の設定ファイルとディレクトリーが存在します。これらは共通の目的を持つテストのための独立したグループなのです。

## アクター

Codeceptionの主な概念の1つは人間の行動のように動作することです。UnitTesterは関数を実行し、コードのテストを行います。FunctionalTesterは内部の知識を持ち、アプリケーション全体をテストする有能なテスターです。そしてAcceptanceTesterは、私たちが提供するインターフェイスを使ってアプリケーションを操作するユーザーです。

アクタークラスは記述するものではなく、スイート設定によってい生成されます。**一般的にアクタークラスの各メソッドはCodeceptionのモジュールから取得されます**。各モジュールは、異なるテストの目的のため事前に定義されたアクションを提供し、テスト環境に合わせて組み合わせることができます。Codeceptionはそのモジュールにより、テストで直面する可能性のある問題の90%を解決しようとしているため、車輪を再発明する必要はありません。私たちは、テストの記述により多くの時間を、それらテストを実行可能とするためのサポートコードの記述にはより少ない時間を費やすことができると考えています。デフォルトではAcceptanceTesterはPhpBrowserモジュールに依存しており、それは`tests/acceptance.suite.yml`ファイルで設定されます:

```yaml
class_name: AcceptanceTester
modules:
    enabled:
        - PhpBrowser:
            url: http://localhost/myapp/
        - \Helper\Acceptance
```

この設定ファイルで、モジュールの有効化/無効化、必要に応じた再設定を行うことができます。
設定ファイルを変更した場合、アクタークラスは自動的に再ビルドされます。もし、アクタークラスが期待通りに作成または更新されない場合、`build`コマンドを使い手動で生成してみてください。

```bash
php codecept build
```

## シナリオのサンプルを書いてみましょう

デフォルトのテストは、まるで語り口のシナリオのようになっています。PHPファイルを有効なシナリオとして機能させるには、その末尾に`Cept`と付けてください。

ではたとえば、`tests/acceptance/SigninCept.php`というファイルを作ってみたとしましょう。
以下のコマンドを実行することでそれができ上がります。

```bash
php codecept generate:cept acceptance Signin
```
シナリオはいつも、アクタークラスの初期化とともに開始します。その後、シナリオを書き進めていくには`$I->`と書き込み、自動補完機能で現れたリストの中からふさわしいアクションを選びます。それではウェブサイトにログインしてみましょう。

```php
<?php
$I = new AcceptanceTester($scenario);
$I->wantTo('login to website');
```

`wantTo`にはシナリオの簡単な説明を記述します。シナリオの内容を記述するために便利な追加のコメント用のメソッドがあります：

```php
<?php
$I = new AcceptanceTester($scenario);
$I->am('user'); // actor's role
$I->wantTo('login to website'); // feature to test
$I->lookForwardTo('access all website features'); // result to achieve
```

このストーリーの背景を説明してから、シナリオを記述してみましょう。

ユーザー名とパスワードとで認証を行う'ログイン'ページがあるとしましょう。そして、マイページへ遷移すると、`Hello, %username%` という文字列が表示されます。このシナリオをCodeceptionでどのように記述するのか見てみましょう。

```php
<?php
$I = new AcceptanceTester($scenario);
$I->am('user');
$I->wantTo('login to website');
$I->lookForwardTo('access all website features');
$I->amOnPage('/login');
$I->fillField('Username','davert');
$I->fillField('Password','qwerty');
$I->click('Login');
$I->see('Hello, davert');
```

おそらく、このシナリオは技術者ではない方々にも読み取ることができるでしょう。括弧や矢印や`$`といった特別な文字を取り除いてみると、単純な英語の文章になります。

```
I am user
I wantTo login to website
I lookForwardTo access all website features
I amOnPage '/login'
I fillField 'Username','davert'
I fillField 'Password','qwerty'
I click 'Login'
I see 'Hello, davert'
```

Codeceptionは次のコマンドを実行することによって、PHPコードから文章形式の表現を生成します：

``` bash
php codecept generate:scenarios
```

生成されたシナリオはテキストファイルとして `_output` ディレクトリー内に保存されます。

テストを実行する前に、ローカル上のウェブサーバーでウェブサイトが動作していることを確認してください。`tests/acceptance.suite.yml`ファイルを開き、URLをあなたのウェブアプリケーションのURLに置き換えてください。

``` yaml
class_name: AcceptanceTester
modules:
    enabled:
        - PhpBrowser:
            url: 'http://myappurl.local'
        - \Helper\Acceptance
```

URLの設定後、`run`コマンドによってテストを走らせることができます。

``` bash
php codecept run
```

このようなアウトプットが表示されるはずです。

``` bash
Acceptance Tests (1) -------------------------------
✔ SigninCept: Login to website
----------------------------------------------------

Time: 1 second, Memory: 21.00Mb

OK (1 test, 1 assertions)
```

アウトプットの詳細を確認してみましょう。

```bash
php codecept run acceptance --steps
```

実行されたアクションのステップごとのレポートが表示されるはずです。

```bash
Acceptance Tests (1) -------------------------------
SigninCept: Login to website
Signature: SigninCept.php
Test: tests/acceptance/SigninCept.php
Scenario --
 I am user
 I look forward to access all website features
 I am on page "/login"
 I fill field "Username" "davert"
 I fill field "Password" "qwerty"
 I click "Login"
 I see "Hello, davert"
 OK
----------------------------------------------------  

Time: 0 seconds, Memory: 21.00Mb

OK (1 test, 1 assertions)
```

このシンプルなテストは完全なウェブサイトの利用シナリオへと拡張することができます。
したがって、ユーザーのアクションをエミュレートすることであたなはどのようなウェブサイトでもテストすることができます。

ぜひトライしてみましょう！

## ブートストラップ

各スイートは自分自身のブートストラップファイルを所有しています。それらは各スイートのディレクトリー内部にあり、`_bootstrap.php`という名前で保存されています。これはテストの前に実行されます。他にも、`tests`ディレクトリー内にはグローバルブートストラップファイルがあります。これは追加ファイルをインクルードする際に使用することができます。

## Cept、Cest、テスト形式

Codeceptionは3つのテスト形式をサポートしています。先述したシナリオベースのCept形式だけでなく、Codeceptionは [単体テスト向けのPHPUnit形式](http://codeception.com/docs/05-UnitTests) およびCest形式についても実行することができます。

Cest形式はシナリオ駆動型テストのアプローチとオブジェクト指向設計を組み合わせています。いくつかのテストシナリオをグループにまとめたい場合、Cest形式を利用することを検討すべきです。下の例では、CRUDのアクションをいくつかのテスト（それぞれがCRUDの各操作に対応）から成る単一のファイルでテストしています:

```php
<?php
class PageCrudCest
{
    function _before(AcceptanceTester $I)
    {
        // will be executed at the beginning of each test
        $I->amOnPage('/');
    }

    function createPage(AcceptanceTester $I)
    {
       // todo: write test
    }

    function viewPage(AcceptanceTester $I)
    {
       // todo: write test
    }

    function updatePage(AcceptanceTester $I)
    {
        // todo: write test
    }

    function deletePage(AcceptanceTester $I)
    {
       // todo: write test
    }
}
```

このようなCest形式のファイルはジェネレーターを実行することにより作成することができます。

```bash
php codecept generate:cest acceptance PageCrud
```

高度な使用法に[Cest形式](http://codeception.com/docs/07-AdvancedUsage#Cest-Classes)の詳細があります。

## BDD

Codeceptionは、CucumberやBehatで使われるものと同様の、Gherkin形式のユーザーストーリーを実行することができます。詳細は[BDDの章](http://codeception.com/docs/07-BDD)を参照してください。

## 設定

Codeceptionではグローバルな設定を行う`codeception.yml`と各スイートの設定があります。また、`.dist`形式の設定もサポートしています。もし、あなたのプロジェクトに開発者が複数人いるようでしたら、共有の設定を`codeception.dist.yml`に書き、個人の設定を`codeception.yml`に書きましょう。スイートの設定も同様です。たとえば、`unit.suite.yml`は`unit.suite.dist.yml`と一緒にマージしてください。


## テストの実行

テストは`run`コマンドによって開始されます。

```bash
php codecept run
```

最初の引数を使用すれば、1つのスイートからテストを実行することができます。

```bash
php codecept run acceptance
```

本当に1つだけのテストを行いたいのなら、2つ目の引数を使用します。スイートのディレクトリーから、テストファイルへのローカルパスを指定します。

```bash
php codecept run acceptance SigninCept.php
```

または、テストファイルへのフルパスを指定することも可能です。

```bash
php codecept run tests/acceptance/SigninCept.php
```
テストクラスから1つのテストを実行することもできます。

```bash
php codecept run tests/acceptance/SignInCest.php:anonymousLogin
```

ディレクトリーパスを指定することも可能です。

```bash
php codecept run tests/acceptance/backend
```

これはバックエンドのディレクトリーからすべてのテストを実行します。

同じディレクトリーにないテストのグループを実行したい場合は、[groups](http://codeception.com/docs/07-AdvancedUsage#Groups)を編成できます。

### レポート

`--xml`オプションを付与すればJUnit XMLのアウトプットが生成され、`--html`オプションを付与すればHTMLのレポートが生成されます。

```bash
php codecept run --steps --xml --html
```

このコマンドはすべてのスイートのすべてのテストをステップごとに表示しながら実行し、HTMLとXMLのレポートを作成します。レポートは`tests/_output/`ディレクトリー内に保存されます。

以下のコマンドを実行することで、使用できるすべてのオプションを確認することができます。

```bash
php codecept help run
```
## デバッグ

詳細なアウトプットを受け取るためには、`--debug`オプションを使ったテストを実行します。
`codecept_debug`関数を使えば、テスト内の任意の情報を出力することができます。

### ジェネレーター

Codeceptionの役立つコマンドはたくさんあります。

* `generate:cept` *スイート名* *ファイル名* - Ceptシナリオのサンプルを生成します
* `generate:cest` *スイート名* *ファイル名* - Cestテストのサンプルを生成します
* `generate:test` *スイート名* *ファイル名* - Codeceptionに接続されたPHPUnitテストのサンプルを生成します
* `generate:phpunit` *スイート名* *ファイル名* - 標準的なPHPUnitテストを生成します
* `generate:feature` *スイート名* *ファイル名* - Gherkin形式のフィーチャ・ファイルを生成します
* `generate:suite` *スイート名* *アクター名* - 与えられたアクタークラスを持つ新しいスイートを生成します
* `generate:scenarios` *スイート名* - テストからシナリオを含んだテキストファイルを生成します
* `generate:helper` *ファイル名* - ヘルパーファイルのサンプルを生成します
* `generate:pageobject` *スイート名* *ファイル名* - ページオブジェクトのサンプルを生成します
* `generate:stepobject` *スイート名* *ファイル名* - ステップオブジェクトのサンプルを生成します
* `generate:environment` *環境* - 環境設定のサンプルを生成します
* `generate:groupobject` *グループ* - グループ拡張のサンプルを生成します


## まとめ
Codeceptionの構造について見てみました。あなたが必要とするほとんどのものはすでに`bootstrap`コマンドによって生成されています。基本的な概念と構成が確認できたら、最初のシナリオを書いてみましょう。
