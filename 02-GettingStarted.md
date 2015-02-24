# はじめに

はじめにCodeceptionの構造を見てみましょう。
あなたはすでに[インストール](http://codeception.com/install) を終え、最初のテストをブートストラップしたと思います。
Codeceptionは単体テスト、機能テスト、受け入れテストの3つを生成しました。これらについては前の章で解説してあります。__/tests__ フォルダ内には、これら3つのテストに対応する名前の設定ファイルとディレクトリが存在します。これらは共通の目的を持つテストのための独立したグループなのです。

## アクター(Actors)

Codeceptionの主な概念の1つは、人間の行動のように動作することです。UnitTesterは関数を実行し、コードのテストを行います。FunctionalTesterは内部の知識を持ち、アプリケーション全体をテストする有能なテスターです。そしてAcceptanceTesterは、私たちが提供するインターフェイスを使ってアプリケーションを操作するユーザです。

これらのアクターはそれぞれ、許可されたアクションを行うPHPのクラスなのです。彼らが異なる能力を持っていることにもうお気づきでしょう。これらのアクターは一定ではなく、あなたの手によって拡張することができます。各アクターはそれぞれのテストに対応しているのです。

アクターのクラスは書かれるのではなく、設定ファイルによって生成されます。あなたが設定を変更すれば、アクタークラスは**自動的にリビルド**されます。

もしアクターのクラスがうまく生成もしくはアップデートされなかった場合、以下のような`build` コマンドによる手動での生成を試みてください。

```bash
$ php codecept.phar build
```

## シナリオのサンプルを書いてみましょう

デフォルトのテストは、まるで語り口のシナリオのようになっています。PHPファイルを有効なシナリオとして機能させるには、その末尾に`Cept`と付けてください。

ではたとえば、`tests/acceptance/SigninCept.php`というファイルを作ってみたとしましょう。
以下のコマンドを実行することでそれができ上がります。

```bash
$ php codecept.phar generate:cept acceptance Signin
```
シナリオはいつも、アクタークラスの初期化とともに開始します。その後、シナリオを書き進めていくには`$I->`と書き込み、自動補完機能で現れたリストの中からふさわしいアクションを選びます。

```php
<?php
$I = new AcceptanceTester($scenario);
?>
```

それではウェブサイトにログインしてみましょう。
ユーザ名とパスワードの入力によって認証を行う"ログインページ"があります。ログイン後はユーザページに飛ばされ、`Hello, %username%`というテキストが表示されます。このシナリオがCodeceptionでどのように記述されるか見てみましょう。

```php
<?php
$I = new AcceptanceTester($scenario);
$I->wantTo('log in as regular user');
$I->amOnPage('/login');
$I->fillField('Username','davert');
$I->fillField('Password','qwerty');
$I->click('Login');
$I->see('Hello, davert');
?>
```

テストを実行する前に、ローカル上のウェブサーバでウェブサイトがしっかりと動いていることを確認してください。`tests/acceptance.suite.yml`ファイルを開き、URLをあなたのウェブアプリケーションのURLに置き換えてください。

``` yaml
config:
    PhpBrowser:
        url: 'http://myappurl.local'
```

URLの設定後、`run` コマンドによってテストを走らせることができます。

``` bash
$ php codecept.phar run
```

このようなアウトプットが表示されるはずです。

``` bash
Acceptance Tests (1) -------------------------------
Trying log in as regular user (SigninCept.php)   Ok
----------------------------------------------------

Functional Tests (0) -------------------------------
----------------------------------------------------

Unit Tests (0) -------------------------------------
----------------------------------------------------

Time: 1 second, Memory: 21.00Mb

OK (1 test, 1 assertions)
```

アウトプットの詳細を確認してみましょう。

```bash
$ php codecept.phar run acceptance --steps
```

実行されたアクションのステップごとのレポートが表示されるはずです。

```bash
Acceptance Tests (1) -------------------------------
Trying to log in as regular user (SigninCept.php)
Scenario:
* I am on page "/login"
* I fill field "Username" "davert"
* I fill field "Password" "qwerty"
* I click "Login"
* I see "Hello, davert"
  OK
----------------------------------------------------  

Time: 0 seconds, Memory: 21.00Mb

OK (1 test, 1 assertions)
```

これは皆さん自身のウェブサイトで再現可能なとてもシンプルなテストでした。ユーザのアクションをエミレートすることで、あなたのウェブサイトをすべて同様にテストすることができるのです。

ぜひトライしてみましょう！


## モジュールとヘルパー

アクタークラスのアクションはモジュールから取得されます。生成されたアクタークラスは多重継承をエミュレートします。モジュールは1つのメソッドで1つのアクションを実行するよう設計されています。[DRY原則](http://ja.wikipedia.org/wiki/Don't_repeat_yourself)によると、あなたが異なるモジュールで同じシナリオコンポーネントを使用する場合は、それらを組み合わせて、カスタムモジュールにそれらを移動させることができます。デフォルトでは、各スイートはアクタークラスを拡張するために使用できるの空のモジュールを持っています。それらは __support__ ディレクトリに保存されています。


## ブートストラップ

各スイートは自分自身のブートストラップファイルを所有しています。それらは各スイートのディレクトリ内部にあり、`_bootstrap.php`という名前で保存されています。これはテストの前に実行されます。他にも、`tests`ディレクトリ内にはグローバルブートストラップファイルがあります。これは追加ファイルをインクルードする際に使用することができます。

## テストフォーマット

Codeceptionは3つのテストフォーマットをサポートしています。先述したシナリオベースのCeptフォーマットだけでなく、[PHPUnit test files for unit testing](http://codeception.com/docs/06-UnitTests) と [class-based Cest](http://codeception.com/docs/07-AdvancedUsage#Cest-Classes) フォーマットに対応しています。これらについては後の章で解説します。どちらの形式のテストスイートでも実行される方法に違いはありません。

## 設定

Codeceptionではグローバルな設定を行う`codeception.yml`と各スイートの設定があります。また、`.dist`形式の設定もサポートしています。もし、あなたのプロジェクトに開発者が複数人いるようでしたら、共有の設定を`codeception.dist.yml`に書き、個人の設定を`codeception.yml`に書きましょう。スイートの設定も同様です。たとえば、`unit.suite.yml`は`unit.suite.dist.yml`と一緒にマージしてください。


## テストの実行

テストは`run`コマンドによって開始されます。

```bash
$ php codecept.phar run
```

最初の引数を使用すれば、1つのスイートからテストを実行することができます。

```bash
$ php codecept.phar run acceptance
```

本当に1つだけのテストを行いたいのなら、2つ目の引数を使用します。スイートのディレクトリから、テストファイルへのローカルパスを指定します。

```bash
$ php codecept.phar run acceptance SigninCept.php
```

または、テストファイルへのフルパスを指定することも可能です。

```bash
$ php codecept.phar run tests/acceptance/SigninCept.php
```
テストクラスから1つのテストを実行することもできます。

```bash
$ php codecept.phar run tests/acceptance/SignInCest.php:anonymousLogin
```

ディレクトリパスを指定することも可能です。

```bash
$ php codecept.phar run tests/acceptance/backend
```

これはバックエンドのディレクトリからすべてのテストを実行します。

同じディレクトリにないテストのグループを実行したい場合は、[groups](http://codeception.com/docs/07-AdvancedUsage#Groups)を編成できます。

### レポート

`--xml`オプションを付与すればJUnit XMLのアウトプットが生成され、`--html`オプションを付与すればHTMLのレポートが生成されます。

```bash
$ php codecept.phar run --steps --xml --html
```

このコマンドはすべてのスイートのすべてのテストをステップごとに表示しながら実行し、HTMLとXMLのレポートを作成します。レポートは`tests/_output/`ディレクトリ内に保存されます。

以下のコマンドを実行することで、使用できるすべてのオプションを確認することができます。

```bash
$ php codecept.phar help run
```
## デバッグ

詳細なアウトプットを受け取るためには、`--debug` オプションを使ったテストを実行します。
`codecept_debug`関数を使えば、テスト内の任意の情報を出力することができます。

### ジェネレータ (Generators)

Codeceptionの役立つコマンドはたくさんあります。

* `generate:cept` *スイート名* *ファイル名* - Ceptシナリオのサンプルを生成します
* `generate:cest` *スイート名* *ファイル名* - Cestテストのサンプルを生成します
* `generate:test` *スイート名* *ファイル名* - Codeceptionに接続されたPHPUnitテストのサンプルを生成します
* `generate:phpunit` *スイート名* *ファイル名* - 標準的なPHPUnitテストを生成します
* `generate:suite` *スイート名* *アクター名* - 与えられたアクタークラスを持つ新しいスイートを生成します
* `generate:scenarios` *スイート名* - テストからシナリオを含んだテキストファイルを生成します


## まとめ
Codeceptionの構造について見てみました。あなたが必要とするほとんどのものはすでに`bootstrap`コマンドによって生成されています。基本的な概念と構成が確認できたら、最初のシナリオを書いてみましょう。
