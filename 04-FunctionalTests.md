# 機能テスト

いま、私達はいくつかの受け入れテストを書いてきましたが、機能テストもほぼ同様に書けます。1つの大きな違いがあるだけです：機能テストは実行するのにWebサーバーを必要としないことです。

簡単に言えば、`$_REQUEST`や`$_GET`、`$_POST`の変数をセットし、テストからアプリケーションを実行します。このことは機能テストがより速く動作し、失敗時に詳細なスタックトレースを提供するので価値のあることでしょう。

Codeceptionは機能テストをサポートしている異なるフレームワークと接続できます:Symfony2, Laravel4, Yii2, Zend Frameworkなどです。あなたはお望みのモジュールをfunctionalスイートの設定において使用できるようにするだけです。

これらのフレームワークモジュールは同じインターフェイスを持っているので、フレームワークにテストが縛られることはありません。以下は機能テストのサンプルです。

```php
<?php
$I = new FunctionalTester($scenario);
$I->amOnPage('/');
$I->click('Login');
$I->fillField('Username', 'Miles');
$I->fillField('Password', 'Davis');
$I->click('Enter');
$I->see('Hello, Miles', 'h1');
// $I->seeEmailIsSent() - Symfony2特有のメソッドです
?>
```

ご覧の通り、機能テストと受け入れテストで同じテストを使うことができます。

## 落とし穴

通常、受け入れテストは機能テストよりも相当な時間がかかります。しかし機能テストは1つの環境でCodeceptionとアプリケーションを実行するため、より不安定になります。もしあなたのアプリケーションが単一プロセスで長時間動作するような設計になっていない場合、たとえば`exit`やグローバル変数を使っている場合、機能テストはあなたの役に立たないかもしれません。

#### ヘッダー、クッキー、セッション

機能テストの一般的な問題の1つに、`headers`, `sessions`, `cookies`を扱うPHPメソッドの使い方があります。
ご存知のように、`header`メソッドは同じヘッダーを2回以上実行するとエラーを発生させます。機能テストにおいてはアプリケーションを何回も実行するため、テスト結果にくだらないエラーがたくさん含まれてしまうでしょう。

#### 共有メモリ

従来の方法とは違い、機能テストではリクエストの処理が終わった後にPHPアプリケーションを停止しません。
1つのメモリコンテナですべてのリクエストが実行されるので、リクエストが分離されることはありません。
したがって、**もしあなたが、失敗するはずないと思っているテストがなぜか失敗するときは、単一のテストで実行してみてください。**
これはテストの実行中にそれぞれが分離されているかをチェックします。すべてのテストがメモリを共有して実行されていると容易に環境を壊してしまうからです。
メモリをきれいに保ち、メモリリークを避け、globalやstaticな変数をきれいにしてください。

## フレームワークモジュールを使う

機能テストスイートは`tests/functional`ディレクトリーにあります。
はじめに、スイートの設定ファイル：`tests/functional.suite.yml`にフレームワークモジュールを1つ含める必要があります。下記に最もポピュラーなPHPフレームワークで機能テストをセットアップする簡単な手順を提供しています。

### Symfony2

Symfony2で動作させるために、バンドルをインストールする必要も設定を変更することもありません。
テストスイートに`Symfony2`モジュールを追加する必要があるだけです。もしDoctrine2も使用するのであれば、忘れずに追加してください。
Doctrine2モジュールをSymfonyのDIコンテナから`doctrine`サービスを使って接続するときは、Doctrine2の依存関係としてSymfony2モジュールを指定してください。

`functional.suite.yml`の例

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - Symfony2
        - Doctrine2:
            depends: Symfony2 # connect to Symfony
        - \Helper\Functional
```

デフォルトでは、このモジュールは`app`ディレクトリーのApp Kernelを検索するでしょう。

モジュールは追加の情報とアサーションを提供するためにSymfony Profilerを使用します。

[詳しくはリファレンス全文を見てください。](http://codeception.com/docs/modules/Symfony2)

### Laravel

[Laravel4](http://codeception.com/docs/modules/Laravel4)および[Laravel5](http://codeception.com/docs/modules/Laravel5)モジュールは設定も必要なく、簡単にセットアップできます。

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - Laravel5
        - \Helper\Functional
```


### Yii2

Yii2のテストは[Basic](https://github.com/yiisoft/yii2-app-basic)と[Advanced](https://github.com/yiisoft/yii2-app-advanced)アプリケーションテンプレートに含まれています。始めるには、Yii2のガイドに従ってください。

### Yii

Yiiフレームワークは、単体では機能テストを動作させる仕組みを持っていません。
なので、CodeceptionがYiiフレームワークの最初で唯一の機能テストです。
Yiiで機能テストを使用するには設定に`Yii1`モジュールを追加してください。

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - Yii1
        - \Helper\Functional
```

先ほど議論した落とし穴を避けるために、CodeceptionはYiiエンジン上に基盤となるフックを提供しています。
それをthe installation steps in module referenceのページに従って設定してください。

### Zend Framework 2

Zend Framework 2の内部で機能テストを実行するには[ZF2](http://codeception.com/docs/modules/ZF2)モジュールを使用してください。

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - ZF2
        - \Helper\Functional
```

### Zend Framework 1.x

Zend FrameworkのためのモジュールはPHPUnitの機能テストに使われるControllerTestCaseクラスに強く影響を受けています。
ブートストラップとクリーンアップに同様のアプローチが使われています。機能テストでZend Frameworkを使用する場合は`ZF1`モジュールを追加してください。

`functional.suite.yml`の例

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - ZF1
        - \Helper\Functional
```

[詳しくはリファレンス全文を見てください。](http://codeception.com/docs/modules/ZF1)

### Phalcon 1.x

`Phalcon1`モジュールは`\Phalcon\Mvc\Application`のインスタンスを返すブートストラップファイルを作成する必要があります。Phalconで機能テストを始めるには、`Phalcon1`モジュールを追加し、このブートストラップファイルにパスを通す必要があります。:

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - Phalcon1:
            bootstrap: 'app/config/bootstrap.php'
        - \Helper\Functional
```

[詳しくはリファレンス全文を見てください。](http://codeception.com/docs/modules/Phalcon1)

## 機能テストを書く

機能テストは`PhpBrowser`モジュールでの[受け入れテスト](http://codeception.com/docs/03-AcceptanceTests)と同じような方法で書かれます。すべてのフレームワークモジュールと`PhpBrowser`モジュールは同じメソッドと同じエンジンを共有しています。

したがって、私たちは`amOnPage`メソッドでウェブページを開くことができます。

```php
<?php
$I = new FunctionalTester;
$I->amOnPage('/login');
?>
```

アプリケーションのページを開くリンクをクリックします。

```php
<?php
$I->click('Logout');
// .nav要素内のリンクをクリックする
$I->click('Logout', '.nav');
// CSSセレクターによるクリック
$I->click('a.logout');
// strict locatorを使用したクリック
$I->click(['class' => 'logout']);
?>
```

フォームの送信も同様です。：

```php
<?php
$I->submitForm('form#login', ['name' => 'john', 'password' => '123456']);
// 代替
$I->fillField('#login input[name=name]', 'john');
$I->fillField('#login input[name=password]', '123456');
$I->click('Submit', '#login');
?>
```

そしてアサーションをします。：

```php
<?php
$I->see('Welcome, john');
$I->see('Logged in successfully', '.notice');
$I->seeCurrentUrlEquals('/profile/john');
?>
```

フレームワークのモジュールはフレームワーク内部にアクセスするメソッドも含んでいます。たとえば、`Laravel4`、`Phalcon1`、そして`Yii2`モジュールはデータベースにレコードが存在するかチェックするためのActiveRecord layerを使用する`seeRecord`メソッドを持っています。
`Laravel4`モジュールはセッションをチェックするメソッドも含んでいます。フォームのバリデーションをテストするときに`seeSessionHasErrors`メソッドは役に立つと分かるでしょう。

使用するモジュールの完全なリファレンスを見てください。モジュールのほとんどのメソッドはすべてに共通で、固有のメソッドは数種類です。

また、フレームワーク内部globalないし、`Helper\Functional`クラスのDIコンテナの内部へもアクセスできます。

```php
<?php
namespace Helper;

class Functional extends \Codeception\Module
{
    function doSomethingWithMyService()
    {
        $service = $this->getModule('Symfony2')->grabServiceFromContainer('myservice');
        $service->doSomething();
    }
}
?>
```

モジュール内部データへフルアクセスするために、使用しているモジュールのすべての*Publicプロパティ*についても確認してください。

## エラーレポート

Codeceptionはデフォルトで`E_ALL & ~E_STRICT & ~E_DEPRECATED`のエラー出力レベルを使用しています。
機能テストの中で、エラーレベルをフレームワークごとの方針に変更したいと思うかもしれません。
エラー出力レベルはスイートの設定ファイルで設定する事ができます：

```yaml
class_name: FunctionalTester
modules:
    enabled:
        - Yii1
        - \Helper\Functional
error_level: "E_ALL & ~E_STRICT & ~E_DEPRECATED"
```

`error_level`は`codeception.yml`ファイルにグローバルに定義することもできます。


## まとめ

パワフルなフレームワークを使用しているならば、機能テストはすばらしいです。機能テストを使用する事で、フレームワークの内部状態にアクセスでき、制御する事ができます。
このことはテストをより短く、より速くしてくれます。フレームワークを使用しない場合ならば、機能テストを書く実用的な理由はないです。
もしここで挙げたものと違うフレームワークを使用しているならば、モジュールを作成して、コミュニティーで共有してください。
