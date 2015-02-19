# 単体テスト

Codeceptionはテストの実行環境としてPHPUnitを使用しています。したがって、PHPUnitのどのテストでもCodeceptionのテストスイートに追加出来ますし、実行出来ます。
今までにPHPUnitテストを書いていたならば、これまで書いてきたようにするだけです。
Codeceptionは簡単な共通処理に対して、すばらしいヘルパー機能を追加しています。

単体テストの基礎はここでは割愛する代わりに、単体テストにCodeceptionが追加する特徴の基礎知識をお伝えしましょう。

__もう一度言います: テストを実行するためにPHPUnitをインストールする必要はありません。Codeceptionも実行出来ます__

## テストを作成する

Codeceptionは簡単にテストを作成する、すばらしいジェネレーターを持っています。
`\PHPUnit_Framework_TestCase`クラスを継承している従来のPHPUnitテストを生成するところから始める事が出来ます。
以下のようなコマンドで生成されます。

```bash
$ php codecept.phar generate:phpunit unit Example
```

Codeceptionは一般的な単体テストのアドオンを備えています、それでは試してみましょう。
Codeceptionの単体テストを作成するには別のコマンドが必要です。

```bash
$ php codecept.phar generate:test unit Example
```

どちらのテストも`tests/unit`ディレクトリに新しく`ExampleTest`ファイルを作成します。

`generate:test`によって作成されたテストは、このようになります。

```php
<?php
use Codeception\Util\Stub;

class ExampleTest extends \Codeception\TestCase\Test
{
   /**
    * @var UnitTester
    */
    protected $tester;

    // 各テスト前に実行される
    protected function _before()
    {
    }

    // 各テスト後に実行される
    protected function _after()
    {
    }
}
?>
```

このクラスは、はじめから`_before`と`_after`のメソッドが定義されています。それらは各テスト前にテスト用のオブジェクトを作成し、終了後に削除するのに使用出来ます。

ご覧の通り、PHPUnitとは違い、`setUp`と`tearDown`メソッドがエイリアス: `_before`, `_after`されています。

実際には`setUp`と`tearDown`メソッドは、親クラスの`\Codeception\TestCase\Test`クラスに実装されており、さらにユニットテストの一部として実行できるように、Ceptファイルからすべてのすてきなアクションを持ったUnitTesterクラスがセットアップされています。受け入れテストや機能テストのように、`unit.suite.yml`の設定ファイルの中で`UnitTester`クラスが使う適切なモジュールを選べます。


```yaml
# Codeception Test Suite Configuration

# suite for unit (internal) tests.
class_name: UnitTester
modules:
    enabled: [UnitHelper, Asserts]
```

### 従来の単体テスト

Codeceptionの単体テストは、PHPUnitで書かれているのと全く同じように書かれています。：

```php
<?php
class UserTest extends \Codeception\TestCase\Test
{
    public function testValidation()
    {
        $user = User::create();

        $user->username = null;
        $this->assertFalse($user->validate(['username']));

        $user->username = 'toolooooongnaaaaaaameeee';
        $this->assertFalse($user->validate(['username']));

        $user->username = 'davert';
        $this->assertTrue($user->validate(['username']));           
    }
}
?>
```

### BDD Spec テスト

テストを書くときは、アプリケーションにおける一定の変化のためにテストを準備する必要があります。テストは読みやすく維持されやすくするべきです。あなたのアプリケーションの使用が変わったら、同じようにテストもアップデートされるべきです。ドキュメントのテストににおいてチーム内部で話し合いが持たれなかったのならば、新しい機能の導入によってテストが影響を受けるということを理解していくのに壁があるでしょう。

なぜなら、アプリケーションを単体テストで網羅するだけでなく、テスト自体を説明的に保っておくことはとても重要な事だからです。私たちは、シナリオ駆動の受け入れテストと機能テストでこれを実践しています。そして、単体テストや結合テストにおいても同様にこれを実践するべきです。

この場合において、単体テスト内部の仕様を書いている[Specify](https://github.com/Codeception/Specify) (pharパッケージしている)というスタンドアロンのプロジェクトを用意しています。

```php
<?php
class UserTest extends \Codeception\TestCase\Test
{
    use \Codeception\Specify;

    public function testValidation()
    {
        $user = User::create();

        $this->specify("username is required", function() {
            $user->username = null;
            $this->assertFalse($user->validate(['username']));
        });

        $this->specify("username is too long", function() {
            $user->username = 'toolooooongnaaaaaaameeee';
            $this->assertFalse($user->validate(['username']));
        });

        $this->specify("username is ok", function() {
            $user->username = 'davert';
            $this->assertTrue($user->validate(['username']));           
        });     
    }
}
?>        
```

`specify`のコードブロックを使用する事で、テストを細かい単位で説明することが出来ます。このことはチームの全員にとってテストがとても見やすく、理解しやすい状態にしてくれます。

`specify`ブロックの内部にあるコードは独立しています。上記の例だと、`$this->user`（他のどんなオブジェクトやプロパティでも）への変更は他のコードブロックに反映されないでしょう。

あなたはBDD-styleのアサーションをするために、[Codeception\Verify](https://github.com/Codeception/Verify)も追加するかもしれません。もし、あなたが`assert`の呼び出しの中で、引数のどちらが期待している値で、どちらが実際の値なのかをよく混同してしまうなら、この小さなライブラリはとてもすばらしく可読性に長けたアサーションを追加します。

```php
<?php
verify($user->getName())->equals('john');
?>
```

## モジュールを使う

シナリオ駆動の機能テストや受け入れテストの中で、あなたはActorクラスのメソッドにアクセスできました。もし結合テストを書く場合は、データベースをテストする`Db`モジュールが役に立つかもしれません。

```yaml
# Codeception Test Suite Configuration

# suite for unit (internal) tests.
class_name: UnitTester
modules:
    enabled: [Db, UnitHelper]
```

UnitTesterのメソッドにアクセスする事で、テストの中で`UnitTester`のプロパティを使用出来ます。

### データベーステスト

それでは、どのようにデータベースのテストが出来るのか、見て行きましょう：

```php
<?php
function testSavingUser()
{
    $user = new User();
    $user->setName('Miles');
    $user->setSurname('Davis');
    $user->save();
    $this->assertEquals('Miles Davis', $user->getFullName());
    $this->tester->seeInDatabase('users', array('name' => 'Miles', 'surname' => 'Davis'));
}
?>
```

受け入れテストや機能テストのように、データベースはテストが終了するごとに、掃除して構築されるでしょう。
それが必要のない振る舞いであれば、現在のスイートの`Db`モジュールの設定を変更してください。

### モジュールにアクセスする

Codeceptionはこのスイートにおいて、すべてのモジュールに定義されたプロパティとメソッドにアクセスする事を許可しています。このときはUnitTesterクラスを使うときとは違い、直接モジュールを使用する事で、モジュールのすべてのパブリックなプロパティへのアクセスを得られます。

例えば、もし`Symfony2`を使うなら、このようにSymfonyのコンテナにアクセスします：

```php
<?php
/**
 * @var Symfony\Component\DependencyInjection\Container
 */
$container = $this->getModule('Symfony2')->container;
?>
```

すべてのパブリックな変数は、そのモジュールに対応するリファレンスにリストされています。

### Cest

`PHPUnit_Framework_TestCase`を継承したテストケースの代わりに、Codeception仕様のCest形式を使用できるでしょう。他のどのクラスも継承する必要はありません。このクラスのすべてのパブリックなメソッドがテストです。

上記の例をシナリオ駆動の形式でこのように書きなおすことができます：

```php
<?php
class UserCest
{
    public function validateUser(UnitTester $t)
    {
        $user = $t->createUser();
        $user->username = null;
        $t->assertFalse($user->validate(['username']); 

        $user->username = 'toolooooongnaaaaaaameeee';
        $t->assertFalse($user->validate(['username']));

        $user->username = 'davert';
        $t->assertTrue($user->validate(['username']));

        $t->seeInDatabase('users', ['name' => 'Miles', 'surname' => 'Davis']);
    }
}
?>
```

`$t`変数でアクセスしているであろう、UnitTesterクラスのいつものアサーションを追加する`Asserts`モジュールを単体テストのために追加するかもしれません。

```yaml
# Codeception Test Suite Configuration

# suite for unit (internal) tests.
class_name: UnitTester
modules:
    enabled: [Asserts, Db, UnitHelper]
```

[Cest形式について もっと知る](http://codeception.com/docs/07-AdvancedUsage#Cest-Classes).

### スタブ

Codeceptionは、スタブを簡単に作成するPHPUnitモックフレームワークの小さいラッパーを提供しています。`\Codeception\Util\Stub`を追加して、ダミーオブジェクトの作成を始めてください。

この例では、コンストラクタを呼び出さずにオブジェクトを初期化し、`getName`メソッドが*john*という値を返すように置き換えています。

```php
<?php
$user = Stub::make('User', ['getName' => 'john']);
$name = $user->getName(); // 'john'
?>
```

スタブはPHPUnitのモックフレームワークから生成されます。[Mockery](https://github.com/padraic/mockery)（[Mockery module](https://github.com/Codeception/MockeryModule)とセット）、[AspectMock](https://github.com/Codeception/AspectMock)、など他のものを代わりに使用することも出来ます。

スタブのユーティリティクラスの全リファレンスは[ここ](/docs/reference/Stub)を見てください。

## 結論

テストスイートの中で、PHPUnitのテストはfirst-class citizensです。単体テストを書いて実行したいときはいつでも、PHPUnitをインストールする必要はなく、それを実行するのにCodeceptionを使用する必要もありません。幾分のすばらしい特徴は、Codeceptionモジュールを統合する事で共通の単体テストを追加できることです。単体テストや結合テストのほとんどにおいて、PHPUnitのテストだけで十分です。PHPUnitのテストは速く、維持しやすいからです。