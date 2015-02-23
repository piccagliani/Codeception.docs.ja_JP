# 受け入れテスト

受け入れテストは、技術者ではない人でも実行することが出来ます。技術者ではないテスターやマネージャー、あるいはクライアントでも実行出来ます。
あなたがウェブアプリケーションを開発している場合、（おそらくあなた自身である）テスターは、あなたのサイトが正しく動いているかをチェックするのにウェブブラウザ以外に必要なものはありません。
シナリオでAcceptanceTesterクラスの行動を再現することによって、サイトを変更する毎にそれらを自動的に実行することができます。
AcceptanceTesterの言葉から記録されたかのようCodeceptionは、テストを簡潔に保ってくれます。

CMSやフレームワークをアプリケーションに取り入れていても違いはありません。Java、.NETなど異なるプラットフォームでさえ同じようにテスト出来ます。
どんな時でも、あなたのウェブサイトにテストを加えるということは良い考えだと言えるでしょう。
少なくとも、最後の変更からアプリケーションがしっかりと機能していることに確信が持てるでしょう。

## シナリオサンプル

おそらく、最初に実行したいテストはサインインする機能でしょう。そのようなテストを書くためには、基本的なPHPとHTMLの知識が必要です。

```php
<?php
$I = new AcceptanceTester($scenario);
$I->wantTo('sign in');
$I->amOnPage('/login');
$I->fillField('username', 'davert');
$I->fillField('password', 'qwerty');
$I->click('LOGIN');
$I->see('Welcome, Davert!');
?>
```

このシナリオは、おそらく非技術者の人でも読めます。Codeceptionはシナリオを平易な英語に変換し、'自然言語化'することさえ出来ます:

```bash
I WANT TO SIGN IN
I am on page '/login'
I fill field 'username', 'davert'
I fill field 'password', 'qwerty'
I click 'LOGIN'
I see 'Welcome, Davert!'
```

そのような自然言語への翻訳は、コマンドによって行われます:

``` bash
$ php codecept.phar generate:scenarios
```

作成されたシナリオは __tests/_data__ディレクトリにテキストファイルとして格納されます。

**このシナリオテストはシンプルなPHP BrowserでもSelenium WebDriverを使ったブラウザでも実行することが出来ます。**まずはPHP Browserで受け入れテストを書いて行きましょう。

## PHP Browser

実際に動くブラウザが必要となるまでは、これはもっとも速く受け入れテストを実行する方法です。
リクエストを送り、それからレスポンスを受け取って解析する、というようなブラウザのような動きをするPHP web scraperを使用しています。
Codeceptionは[Guzzle](http://guzzlephp.org)とSymfony BrowserKitをHTMLページを操作するのに使用しています。
HTMLのある要素の実際の可視性や、javascriptの動作をテストできないことに注意してください。
PHP Browserの利点は、PHPとcURLだけでどんな環境でも実行できることです。

一般的なPHP Browserの欠点：

* 有効なURLのリンクとフォームの送信ボタンしかクリックできないこと
* フォームの中にないフィールドには書き込めないこと
* JavaScriptによる動作は機能しないこと：モーダルを表示させたり、datepickersの使用など

テストを書き始める前に、アプリケーションが動作しているホストをローカルコピーしてください。
受け入れテストスイートの設定ファイル (tests/acceptance.suite.yml) に、`url`パラメータを指定する必要があるからです。

``` yaml
class_name: AcceptanceTester
modules:
    enabled:
        - PhpBrowser
        - AcceptanceHelper
        - Db
    config:
        PhpBrowser:
            url: [your site's url]
```

それでは、__tests/acceptance__ディレクトリに'Cept'ファイルを作成してください。ファイル名は __SigninCept.php__とします。
最初の行に以下のように書きます。

```php
<?php
$I = new AcceptanceTester($scenario);
$I->wantTo('sign in with valid account');
?>
```

`wantTo`という部分はシナリオを簡潔に説明しています。
他にもBDDのようなCodeceptionのシナリオを書くための有用なコメント追加メソッドがあります。GherkinでBDDのシナリオを書いたことがある人なら、以下のようにフィーチャーを書くことができます。

```bash
As an Account Holder
I want to withdraw cash from an ATM
So that I can get money when the bank is closed
```

Codeceptionでは以下のように書きます:

```php
<?php
$I = new AcceptanceTester($scenario);
$I->am('Account Holder');
$I->wantTo('withdraw cash from an ATM');
$I->lookForwardTo('get money when the bank is closed');
?>
```

ストーリーの前提を説明した上で、シナリオを書き始めましょう。

この `$I`オブジェクトは、すべての動作を記述するために使われます。`$I`オブジェクトのメソッドは`PhpBrowser`モジュールや`Db`モジュールから取得されています。
簡単にそれを説明します：

```php
<?php
$I->amOnPage('/login');
?>
```

常に`am`は、最初の状態を記述するように想定しています。`amOnPage`メソッドは__/login__ページが最初の状態だと設定しています。

`PhpBrowser`では、リンクのクリックとフォームを埋めることが出来ます。これらは、おそらくもっとも多い動作だと思います。

#### クリック

有効なリンクのクリックをエミュレートします。
"href"属性の値のページが開きます。リンク名やCSSセレクター、XPathでクリックするリンクを指定できます。

```php
<?php
$I->click('Log in');
// CSSセレクターを使用する場合
$I->click('#login a');
// XPathを使用する場合
$I->click('//a[@id=login]');
// 第二引数としてコンテキストを使用する場合
$I->click('Login', '.nav');
?>
```

Codeceptionは、テキストやname属性、CSSセレクタ、XPathのどれかで要素を検索しようとします。
locatorの種類を配列として渡すことで、指定することもできます。我々は **strict locator**呼んでいます。
利用できるstrict locatorの種類は以下です：

* id
* name
* css
* xpath
* link
* class

```php
<?php
// locatorの種類で指定する場合
$I->click(['link' => 'Login']);
$I->click(['class' => 'btn']);
?>
```

リンクをクリックする前に、本当にリンクが存在するかどうかチェックすることもできます。
その場合`seeLink`メソッドを使用します。

```php
<?php
// 実際にリンクが存在するかチェックする
$I->seeLink('Login');
$I->seeLink('Login','/login');
$I->seeLink('#login a','/login');
?>
```


#### フォーム

ウェブサイトのテストにおいてもっとも時間が取られることは、リンクをクリックすることではないです。もし、リンクだけで構成されているサイトならテストを自動化する必要は無いでしょう。
もっとも時間を消費する機能はフォームです。Codeceptionはフォームを処理する方法をいくつか提供します。

それでは、Codeceptionのテストでフォームを送信してみましょう。

```html
<form method="post" action="/update" id="update_form">
     <label for="user_name">Name</label>
     <input type="text" name="user[name]" id="user_name" />
     <label for="user_email">Email</label>
     <input type="text" name="user[email]" id="user_email" />
     <label for="user_gender">Gender</label>
     <select id="user_gender" name="user[gender]">
          <option value="m">Male</option>
          <option value="f">Female</option>
     </select>
     <input type="submit" name="submitButton" value="Update" />
</form>
```

ユーザーからの視点で見ると、このフォームは埋める必要のある複数の項目から構成されており、最後にはUpdateボタンがクリックされます。

```php
<?php
// user_name項目に対応するラベルを使います
$I->fillField('Name', 'Miles');
// inputタグのname属性やid属性を使用しています
$I->fillField('user[email]','miles@davis.com');
$I->selectOption('Gender','Male');
$I->click('Update');
?>
```

それぞれのフィールドをラベルで検索するためには、labelタグに`for`属性を書く必要があります。

開発者から見ると、フォームを送信することは、サーバーに有効なPOSTリクエストを送信しているだけです。
時には、一度にすべての項目に書き込み、'Submit'ボタンをクリックすることなく送信してしまう方が楽です。そのようなシナリオをたった一つのメソッドで書き換えることが出来ます。

```php
<?php
$I->submitForm('#update_form', array('user' => array(
     'name' => 'Miles',
     'email' => 'Davis',
     'gender' => 'm'
)));
?>
```

`submitForm`メソッドはユーザーの行動をエミュレートしてはいませんが、フォームが適切にフォーマットされていない時に、非常に有効です。
例えば、ラベルがついていなかったり、不適切なname属性やid属性がつけられているフォームやjavascriptによって送信されているフォームです。

デフォルトでは、`submitForm`メソッドはボタンの値を送信することはありません。どのボタンのvalueを送信するかは最後の引数に指定出来ますし、あるいは第二引数に含めて指定することも出来ます。

```php
<?php
$I->submitForm('#update_form', array('user' => array(
     'name' => 'Miles',
     'email' => 'Davis',
     'gender' => 'm'
)), 'submitButton');
// これは同じ機能を果たしますが、送信ボタンのvalueは指定する必要があります
$I->submitForm('#update_form', array('user' => array(
     'name' => 'Miles',
     'email' => 'Davis',
     'gender' => 'm',
	 'submitButton' => 'Update'
)));
?>
```

#### Ajaxエミュレーター

ご存知のように、PHP browserではjavascriptは機能しません。
しかし、すべてのajax呼び出しは、適切なリクエストをサーバーに送信することで簡単にエミュレート出来ます。

ajax通信には以下のメソッドが使えることを覚えておいてください。

```php
<?php
$I->sendAjaxGetRequest('/refresh');
$I->sendAjaxPostRequest('/update', array('name' => 'Miles', 'email' => 'Davis'));
?>
```

#### アサーション

PHP browserでは、ページの内容をテスト出来ます。ほとんどの場合は、ページに必要なテキストや要素が存在しているかチェックする必要があるのみでしょう。

そのためにもっとも使い勝手の良いメソッドは`see`です。

```php
<?php
// 'Thank you, Miles'というテキストがページにあることをチェックします
$I->see('Thank you, Miles');
// 'Thank you Miles'の内部をチェックします
// この要素は'notice'というクラス属性を持っています
$I->see('Thank you, Miles', '.notice');
// XPathを使用することもできます
$I->see('Thank you, Miles', "descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' notice ')]");
// このメッセージがページに無いことをチェックしています
$I->dontSee('Form is filled incorrectly');
?>
```

特定の要素がページに存在する（あるいは存在しない）ことをチェック出来ます。

```php
<?php
$I->seeElement('.notice');
$I->dontSeeElement('.error');
?>
```

私達は、他にもチェックを実行するために役立つメソッドを用意しています。それらがすべて`see`というプレフィックスから始まっていることに注目してください。

```php
<?php
$I->seeInCurrentUrl('/user/miles');
$I->seeCheckboxIsChecked('#agree');
$I->seeInField('user[name]', 'Miles');
$I->seeLink('Login');
?>
```

#### 条件付きアサーション

時にはアサーションが失敗したとしても、途中でテストを止めたくないでしょう。時間のかかるテストを行っていて、最後まで実行したいかもしれません。
この場合には、条件付のアサーションを使用することが出来ます。`see`メソッドは`canSee`メソッドに対応しており、`dontSee`メソッドは`cantSee`メソッドに対応しています。

```php
<?php
$I->canSeeInCurrentUrl('/user/miles');
$I->canSeeCheckboxIsChecked('#agree');
$I->cantSeeInField('user[name]', 'Miles');
?>
```

それぞれの失敗したアサーションはテスト結果に示されますが、アサーションが失敗することでテストが止まることは無いでしょう。

#### グラバー

これらのメソッドはテストで使われるデータを取得します。あなたのサイトがすべてのユーザーごとにパスワードを発行指定、そのパスワードでユーザーがサイトにログインできることをチェックしたいという場面を想像してください。

```php
<?php
$I->fillField('email', 'miles@davis.com')
$I->click('Generate Password');
$password = $I->grabTextFrom('#password');
$I->click('Login');
$I->fillField('email', 'miles@davis.com');
$I->fillField('password', $password);
$I->click('Log in!');
?>
```

グラバーは現在のページから一つの値を取得できるメソッドです。

```php
<?php
$token = $I->grabTextFrom('.token');
$password = $I->grabTextFrom("descendant::input/descendant::*[@id = 'password']");
$api_key = $I->grabValueFrom('input[name=api]');
?>
```

#### コメント

長いシナリオ内では、これから実行しようとしている行動とそれによって得られる結果を説明するべきです。
`amGoingTo`, `expect`, `expectTo`というメソッドは、よりわかりやすいテストを作成する助けとなります。

```php
<?php
$I->amGoingTo('submit user form with invalid values');
$I->fillField('user[email]', 'miles');
$I->click('Update');
$I->expect('the form is not submitted');
$I->see('Form is filled incorrectly');
?>
```

#### クッキー、URL、タイトル、その他

クッキーを扱うためのメソッド：

```php
<?php
$I->setCookie('auth', '123345');
$I->grabCookie('auth');
$I->seeCookie('auth');
?>
```
ページのタイトルを扱うためのメソッド:

```php
<?php
$I->seeInTitle('Login');
$I->dontSeeInTitle('Register');
?>
```

URLを扱うためのメソッド:

```php
<?php
$I->seeCurrentUrlEquals('/login');
$I->seeCurrentUrlMatches('~$/users/(\d+)~');
$I->seeInCurrentUrl('user/1');
$user_id = $I->grabFromCurrentUrl('~$/user/(\d+)/~');
?>
```

## Selenium WebDriver

Codeceptionのすばらしい特徴は、ほとんどのシナリオが異なるテスト動作環境に容易に移植できることです。
これまでに書いてきたPhpBrowserテストはSelenium WebDriverを使って、実際のブラウザの中で（あるいはPhantomJSでさえ）実行出来ます。

ただひとつだけ変更しなければならない事は、AcceptanceTesterクラスがPhpBrowserの代わりに**WebDriver**を使用するように設定してビルドし直すことです。

`acceptance.suite.yml`ファイルを変更してください：

```yaml
class_name: AcceptanceTester
modules:
    enabled:
        - WebDriver
        - AcceptanceHelper
    config:
        WebDriver:
            url: 'http://localhost/myapp/'
            browser: firefox
```

Seleniumでテストを実行するために、[Selenium Server](http://seleniumhq.org/download/)をダウンロードして、起動しておく必要があります。（替わりに`ghostdriver`モードで動くヘッドレスブラウザの[PhantomJS](http://phantomjs.org/)を使うことも出来ます。）

Seleniumを使用して受け入れテストを実行するならば、Firefoxから始められます。ブラウザエンジンを使用する事ですべての処理がステップ実行されます。

この場合、`seeElement`メソッドはページにその要素が存在する事だけをチェックするのではなく、実際のユーザーからの可視性もチェックします。

```php
<?php
$I->seeElement('#modal');
?>
```


#### Wait

ウェブアプリケーションをテストしている間に、JavaScriptのeventが起こるまで待機しておく必要があるかもしれません。
複雑なJavaScriptの処理は、その非同期性によってテストが困難になります。テストが先に進んでしまう前に、そのページで起こると予測しているeventを指定できるように、`wait`メソッドが必要なのです。

例：

```php
<?php
$I->waitForElement('#agree_button', 30); // secs
$I->click('#agree_button');
?>
```

この場合には、agree buttonが表示されるまで待機し、表示されたらクリックします。30秒経過しても表示されなかったときは、テストは失敗します。他にも使える`wait`メソッドがあります。

詳細なリファレンスはCodeception's [WebDriver module documentation](http://codeception.com/docs/modules/WebDriver)を参照してください。

### 複数セッションのテスト

Codeceptionは同時に複数のセッションを実行出来ます。サイト上でユーザ同士がリアルタイムにメッセージをやり取りする場合がもっともわかりやすいです。そのためには２つのブラウザウィンドウを同じテスト中に同時に立ち上げる必要があるでしょう。Codeceptionはこのための**Friends**と呼ばれるとってもスマートな方法が用意されています。

```php
<?php
$I = new AcceptanceTester($scenario);
$I->wantTo('try multi session');
$I->amOnPage('/messages');
$nick = $I->haveFriend('nick');
$nick->does(function(AcceptanceTester $I) {
    $I->amOnPage('/messages/new');
    $I->fillField('body', 'Hello all!')
    $I->click('Send');
    $I->see('Hello all!', '.message');
});
$I->wait(3);
$I->see('Hello all!', '.message');
?>
```

この場合には、2つ目のウィンドウでfriendオブジェクトが`does`メソッドを使用していくつかの行動をしました。

### クリーンアップ

テストをしている中で、あなたの行動はサイト上のデータを変えてしまうかもしれません。2度同じデータを生成したり、アップデートしようとしてテストは失敗する事になるでしょう。この問題を避けるために、データベースはそれぞれのテストごとに再構築する必要があります。Codeceptionはそのために`Db`モジュールを提供しています。テストを通過した後にデータベースのdumpをロードします。データベースの再構築を機能させるためには、データベースをdumpしてsqlファイルを作成し、__/tests/_data__ディレクトリに配置してください。Codeceptionのglobalの設定にデータベースへの接続情報とパスをセットしてください。

```yaml
# in codeception.yml:
modules:
    config:
        Db:
            dsn: '[set pdo dsn here]'
            user: '[set user]'
            password: '[set password]'
            dump: tests/_data/dump.sql
```

### デバッグ

Codeceptionモジュールは実行中に価値のある情報を出力できます。実行中の詳細を見るために`--debug`オプションをテスト起動時に付けるだけです。出力をカスタマイズするには`codecept_debug`ファンクションを使います。

```php
<?php
codecept_debug($I->grabTextFrom('#name'));
?>
```


テストの失敗ごとに、最後に表示されていたページのスナップショットを__tests/_log__ディレクトリに保存します。PhpBrowserはHTMLのコードを保存し、WebDriverはページのスクリーンショットを保存します。

## 結論

CodeceptionとPhpBrowserで受け入れテストを書くことは、良いスタートです。フレームワークで作られたサイトと同じように、Joomla, Drupal, WordPressのサイトも簡単にテスト出来ます。受け入れテストを書くことはPHPでのテスターの行動を説明するようなものです。可読性に長け、とても書きやすいです。テストを実行するごとにデータベースの再構築を忘れないように。