# カスタマイズ

この章では、どのようにしてファイル構造やテスト実行ルーチンをカスタマイズできるのか、説明します。

## 複数アプリケーションのための1つのランナー

プロジェクトが複数のアプリケーション（frontend, admin, api）で構成されていたり、バンドルとともにSymfony2を使っている場合、すべてのアプリケーション（バンドル）に対するすべてのテストを1ランナーで実行することに興味があるのではないでしょうか。
ここではプロジェクト全体をカバーする1つのレポートを取得してみます。

`codeception.yml`ファイルをプロジェクトのルートフォルダーに配置して、インクルードしたい他の`codeception.yml`へのパスを指定します。

``` yaml
include:
  - frontend
  - admin
  - api/rest
paths:
  log: log
settings:
  colors: false
```

レポートやログの出力先となる`log`ディレクトリーへのパスも指定してください。

### 名前空間

アクタークラスとヘルパークラスの名前空間が衝突するのを避けるため、それらは名前空間に属すべきです。
名前空間を持つテストスイートを作成するためには、ブートストラップコマンドに`--namespace`オプションを付与します。

``` bash
$ php codecept.phar bootstrap --namespace frontend
```

これにより、`namespace: frontend`パラメーターを持つ`codeception.yml`ファイルとともに、新しいプロジェクトが作成されます。
ヘルパークラスの名前空間は`frontend\Codeception\Module`に、アクタークラスの名前空間は`frontend`になります。
こうして、新しく作成されたテストは次のようになります。

```php
<?php use frontend\AcceptanceTester;
$I = new AcceptanceTester($scenario);
//...
?>
```

それぞれのアプリケーション（バンドル）が自身の名前空間と異なるヘルパーやアクタークラスを持つようになって、すべてのテストを1ランナーで実行できるようになります。先ほど作成したメタ設定を使って、通常どおりCodeceptionを実行します。

```bash
$ php codecept.phar run
```

これにより、3つのすべてのアプリケーションのテストスイートが起動し、すべてのテストレポートがマージされます。これはつまり、継続的インテグレーションサーバー上でテストを実行し、1つのJUnitとHTML形式のレポートを取得したい場合に大変役に立ちます。コードカバレッジレポートについても同じくマージされます。

もし各アプリケーションが共通のヘルパーを利用している場合、次のセクションに従ってください。

## 拡張機能

Codeceptionはコアな機能を拡張する限定的な機能を持っています。
拡張機能は現在の機能をオーバーライドすることを想定していませんが、もしあなたが経験のある開発者でテストのフローをフックしたい場合にはとても便利です。

デフォルトで、`RunFailed`エクステンションがすでに`codeception.yml`にて有効化されています。
これにより、`-g failed`オプションをつけることで失敗したテストを再実行することができます。

```
php codecept.phar run -g failed
```

Codeceptionには`ext`ディレクトリーに配置された拡張機能が付属しています。たとえば、Monologを使ってテスト実行のログを記録するLogger拡張を有効にすることができます。

```yaml
extensions:
    enabled:
        - Codeception\Extension\RunFailed # default extension
        - Codeception\Extension\Logger # enabled extension
    config:
        Codeception\Extension\Logger:
            max_files: 5 # logger configuration
```

ではいったい拡張機能とは何でしょうか？基本的に、拡張機能は[Symfony Event Dispatcher](http://symfony.com/doc/current/components/event_dispatcher/introduction.html)コンポーネントを基盤とするイベントリスナー以上の何ものでもありません。

これらがイベントとイベントクラスです。テスト実行中に発生する順番で一覧化しています。それぞれのイベントには対応したクラスがあり、特定のオブジェクトを含んでイベントリスナーに渡されます。

### イベント

|    イベント          |     いつ？                              | 何を含む？
|:--------------------:| --------------------------------------- | --------------------------:
| `suite.before`       | Before suite is executed                | [Suite, Settings](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/SuiteEvent.php)
| `test.start`         | Before test is executed                 | [Test](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/TestEvent.php)
| `test.before`        | At the very beginning of test execution | [Codeception Test](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/TestEvent.php)
| `step.before`        | Before step                             | [Step](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/StepEvent.php)
| `step.after`         | After step                              | [Step](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/StepEvent.php)
| `step.fail`          | After failed step                       | [Step](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/StepEvent.php)
| `test.fail`          | After failed test                       | [Test, Fail](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/FailEvent.php)
| `test.error`         | After test ended with error             | [Test, Fail](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/FailEvent.php)
| `test.incomplete`    | After executing incomplete test         | [Test, Fail](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/FailEvent.php)
| `test.skipped`       | After executing skipped test            | [Test, Fail](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/FailEvent.php)
| `test.success`       | After executing successful test         | [Test](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/TestEvent.php)
| `test.after`         | At the end of test execution            | [Codeception Test](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/TestEvent.php)
| `test.end`           | After test execution                    | [Test](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/TestEvent.php)
| `suite.after`        | After suite was executed                | [Suite, Result, Settings](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/SuiteEvent.php)
| `test.fail.print`    | When test fails are printed             | [Test, Fail](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/FailEvent.php)
| `result.print.after` | After result was printed                | [Result, Printer](https://github.com/Codeception/Codeception/blob/master/src/Codeception/Event/PrintResultEvent.php)

`test.start`と`test.before`、 `test.after`と`test.end`とに混乱するかもしれません。Start/endイベントはPHPUnit自身によって発生されますが、before/afterイベントはCodeceptionによって発生されます。ですので、従来の（`PHPUnit_Framework_TestCase`を継承した）PHPUnitのテストではbefore/afterイベントは発生しません。`test.before`イベントでは、`test.start`では不可能な、スキップされたか不完全なテストを追跡することができます。[Codeception internal event listeners](https://github.com/Codeception/Codeception/tree/master/src/Codeception/Subscriber)にてより多くのことを学ぶことができます。

拡張クラスは`Codeception\Platform\Extension`クラスを継承します。

``` php
<?php
class MyCustomExtension extends \Codeception\Platform\Extension
{
    // list events to listen to
    public static $events = array(
        'suite.after' => 'afterSuite',
        'test.before' => 'beforeTest',
        'step.before' => 'beforeStep',
        'test.fail' => 'testFailed',
        'result.print.after' => 'print',
    );

    // methods that handle events

    public function afterSuite(\Codeception\Event\SuiteEvent $e) {}

    public function beforeTest(\Codeception\Event\TestEvent $e) {}

    public function beforeStep(\Codeception\Event\StepEvent $e) {}

    public function testFailed(\Codeception\Event\FailEvent $e) {}

    public function print(\Codeception\Event\PrintResultEvent $e) {}
}
?>
```  

イベントハンドラーメソッドを実行することにより、渡されたオブジェクトを更新してもイベントをリッスンすることができます。
拡張クラスはいくつかの基本的なメソッドを持っています。

* `write` - コンソールに出力する
* `writeln` - 改行コードとおともにコンソールに出力する
* `getModule` - モジュールにアクセスする
* `hasModule` - モジュールが有効かどうか確認する
* `getModuleNames` - すべての有効なモジュール一覧を取得する
* `_reconfigure` - コンストラクターをオーバーライドする替わりに実装する

### 拡張機能の有効化

単純な拡張クラスを実装したら、`tests/_bootstrap.php`ファイルにインクルードするか、
`composer.json`に定義されたComposerのオートローダーでロードするか、もしくは`tests/_support`ディレクトリーにクラスを格納します。

`codeception.yml`で拡張機能を有効にします。

```yaml
extensions:
    enabled: [MyCustomExtension]
```

### 拡張機能の設定

拡張クラスでは`options`プロパティを介して現状渡されたオプションにアクセスすることができます。
また、`\Codeception\Configuration::config()`を利用してグローバル設定にアクセスすることもできます。
もし拡張クラスにカスタムなオプションを持たせたい場合、`codeception.yml`ファイルからそれを渡すことができます。

```yaml
extensions:
    enabled: [MyCustomExtension]
    config:
        MyCustomExtension:
            param: value

```

渡された設定には次のように`config`プロパティを介してアクセスすることができます。`$this->config['param']`

とても基本的な拡張機能である[Notifier](https://github.com/Codeception/Notifier)を確認してください。

## グループオブジェクト

グループオブジェクトは特定のグループに属すテストのイベントをリッスンするための拡張機能です。
テストが次のグループに追加されたとき、

```php
<?php 
$scenario->group('admin');
$I = new AcceptanceTester($scenario);
?>
```

このテストは次のイベントを発生させます。

* `test.before.admin`
* `step.before.admin`
* `step.after.admin`
* `test.success.admin`
* `test.fail.admin`
* `test.after.admin`

グループオブジェクトはこれらのイベントをリッスンするために構築されています。これは、テストに追加の設定が必要になった場合にとても便利です。`admin`グループに属すテストのためにフィクスチャをロードしたいとしましょう。

```php
<?php
namespace Group;

class Admin extends \Codeception\GroupObject
{
    public static $group = 'admin';

    public function _before(\Codeception\Event\TestEvent $e)
    {
        $this->writeln('inserting additional admin users...');

        $db = $this->getModule('Db');
        $db->haveInDatabase('users', array('name' => 'bill', 'role' => 'admin'));
        $db->haveInDatabase('users', array('name' => 'john', 'role' => 'admin'));
        $db->haveInDatabase('users', array('name' => 'mark', 'role' => 'banned'));
    }

    public function _after(\Codeception\Event\TestEvent $e)
    {
        $this->writeln('cleaning up admin users...');
        // ...
    }
}
?>
```

グループクラスは`php codecept.phar generate:group groupname`コマンドによって作成することができます。
グループクラスは`tests/_support/Group`ディレクトリーに格納されます。

拡張クラスと同様、`codeception.yml`にてグループクラスを有効にすることができます。

``` yaml
extensions:
    enabled: [Group\AdminGroup]
```

これでAdminグループクラスは`admin`グループに属すテストのすべてのイベントをリッスンするようになります。

## まとめ

これまでに述べてきた各機能は、いくつかについては高度なPHPの知識を必要とするかもしれませんが、規模の大きいプロジェクトのテストをCodeceptionで自動化する際に、劇的に役立つことがあります。グループや拡張機能やそのほかCodeceptionの強力な機能には「ベストプラクティス」や「ユースケース」は存在しません。これらの拡張機能を使うことで解決できそうな問題に直面した場合、試してみてください。
