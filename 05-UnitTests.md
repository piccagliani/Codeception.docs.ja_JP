# 単体テスト

Codeceptionはテストの実行環境としてPHPUnitを使用しています。したがって、PHPUnitのどのテストでもCodeceptionのテストスイートに追加できますし、実行できます。
いままでにPHPUnitテストを書いていたならば、これまで書いてきたようにするだけです。
Codeceptionは簡単な共通処理に対して、すばらしいヘルパー機能を追加しています。

単体テストの基礎はここでは割愛する代わりに、単体テストにCodeceptionが追加する特徴の基礎知識をお伝えしましょう。

__もう一度言います: テストを実行するためにPHPUnitをインストールする必要はありません。Codeceptionも実行できます。__

## テストを作成する

Codeceptionは簡単にテストを作成する、すばらしいジェネレーターを持っています。
`\PHPUnit_Framework_TestCase`クラスを継承している従来のPHPUnitテストを生成するところから始める事ができます。
以下のようなコマンドで生成されます。

```bash
$ php codecept.phar generate:phpunit unit Example
```

Codeceptionは一般的な単体テストのアドオンを備えています、それでは試してみましょう。
Codeceptionの単体テストを作成するには別のコマンドが必要です。

```bash
$ php codecept.phar generate:test unit Example
```

どちらのテストも`tests/unit`ディレクトリーに新しく`ExampleTest`ファイルを作成します。

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

このクラスは、はじめから`_before`と`_after`のメソッドが定義されています。それらは各テスト前にテスト用のオブジェクトを作成し、終了後に削除するのに使用できます。

ご覧の通り、PHPUnitとは違い、`setUp`と`tearDown`メソッドがエイリアス: `_before`, `_after`されています。

実際には`setUp`と`tearDown`メソッドは、親クラスの`\Codeception\TestCase\Test`クラスに実装されており、さらに単体テストの一部として実行できるように、Ceptファイルからすべてのすてきなアクションを持ったUnitTesterクラスがセットアップされています。受け入れテストや機能テストのように、`unit.suite.yml`の設定ファイルの中で`UnitTester`クラスが使う適切なモジュールを選べます。


```yaml
# Codeception Test Suite Configuration

# suite for unit (internal) tests.
class_name: UnitTester
modules:
    enabled:
        - Asserts
        - \Helper\Unit
```

### 従来の単体テスト

Codeceptionの単体テストは、PHPUnitで書かれているのとまったく同じように書かれています。：

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

### BDD Specテスト

テストを書くときは、アプリケーションにおける一定の変化のためにテストを準備する必要があります。テストは読みやすく維持されやすくするべきです。あなたのアプリケーションの仕様が変わったら、同じようにテストもアップデートされるべきです。ドキュメントのテストにおいてチーム内部で話し合いが持たれなかったのならば、新しい機能の導入によってテストが影響を受けるということを理解していくのに壁があるでしょう。

そのため、アプリケーションを単体テストで網羅するだけでなく、テスト自体を説明的に保っておくことはとても重要な事です。私たちは、シナリオ駆動の受け入れテストと機能テストでこれを実践しています。そして、単体テストや結合テストにおいても同様にこれを実践するべきです。

この場合において、単体テスト内部の仕様を書いている[Specify](https://github.com/Codeception/Specify)（pharパッケージに含まれている）というスタンドアロンのプロジェクトを用意しています。

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

`specify`のコードブロックを使用する事で、テストを細かい単位で説明することができます。このことはチームの全員にとってテストがとても見やすく、理解しやすい状態にしてくれます。

`specify`ブロックの内部にあるコードは独立しています。上記の例だと、`$this->user`（他のどんなオブジェクトやプロパティでも）への変更は他のコードブロックに反映されないでしょう。

あなたはBDD-styleのアサーションをするために、[Codeception\Verify](https://github.com/Codeception/Verify)も追加するかもしれません。もし、あなたが`assert`の呼び出しの中で、引数のどちらが期待している値で、どちらが実際の値なのかをよく混同してしまうなら、この小さなライブラリーはとてもすばらしく可読性に長けたアサーションを追加します。

```php
<?php
verify($user->getName())->equals('john');
?>
```

## モジュールを使う

シナリオ駆動の機能テストや受け入れテストの中で、あなたはアクタークラスのメソッドにアクセスできました。もし結合テストを書く場合は、データベースをテストする`Db`モジュールが役に立つかもしれません。

```yaml
# Codeception Test Suite Configuration

# suite for unit (internal) tests.
class_name: UnitTester
modules:
    enabled:
        - Asserts
        - Db
        - \Helper\Unit
```

UnitTesterのメソッドにアクセスする事で、テストの中で`UnitTester`のプロパティを使用できます。

### データベースをテストする

それでは、どのようにデータベースのテストができるのか、見て行きましょう：

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

単体テストでデータベース機能を有効にするためには、unit.suite.yml設定ファイルにて有効なモジュール一覧に`Db`モジュールが含まれていることを確認してください。
受け入れテストや機能テストのように、データベースはテストが終了するごとに、クリーンにされて構築されるでしょう。
それが必要のない振る舞いであれば、現在のスイートの`Db`モジュールの設定を変更してください。

### フレームワークとやりとりする

もしプロジェクトがすでにデータベースとのやりとりのためにORMを利用しているのであれば、データベースに直接アクセスすべきではないはずです。
テストの中で直接ORMを使ってみませんか？LaravelのORMであるEloquentを使ってテストを書いてみましょう。そのためにはLaravel5モジュールを設定する必要があります。`amOnPage`や`see`といったWebに対する振る舞いは必要ないため、ORMのみ有効化しましょう：

```yaml
class_name: UnitTester
modules:
    enabled:
        - Asserts
        - Laravel5:
            part: ORM
        - \Helper\Unit
```

機能テストと同じように、Laravel5モジュールをインクルードしました。実際のテストでの使い方を見てみましょう：

```php
<?php
function testUserNameCanBeChanged()
{
    // フレームワークからユーザーを作成、このユーザーはテスト後に削除される
    $id = $this->tester->haveRecord('users', ['name' => 'miles']);
    // モジュールにアクセスする
    $user = User::find($id);
    $user->setName('bill');
    $user->save();
    $this->assertEquals('bill', $user->getName());
    // フレームワークの関数を使ってデータが保存されたことを検証する
    $this->tester->seeRecord('users', ['name' => 'bill']);
    $this->tester->dontSeeRecord('users', ['name' => 'miles']);
}
?>
```

ActiveRecordパターンで実装されたORMを持つすべてのフレームワークにおいて、とても良く似たアプローチをとることができます。
それらはYii2やPhalconで、同じように動作する`haveRecord`、`seeRecord`、`dontSeeRecord`を持っています。機能テスト用のアクションを利用しないよう、`part: ORM`を指定してインクルードしてください。

In case you are using Symfony2 with Doctrine you may not enable Symfony2 itself but use only Doctrine2 only:
DoctrineとともにSymfony2を利用するケースでは、Symfony2そのものは有効とせず、Doctrine2のみを利用するようにしてください。：

```yaml
class_name: UnitTester
modules:
    enabled:
        - Asserts
        - Doctrine2:
            depends: Symfony2
        - \Helper\Unit
```

このようにすることで、Doctrineはデータベースへの接続確立のためにSymfony2を使いながら、Doctrine2モジュールのメソッドを利用することができます。このケースではテストは次のようになります。：

```php
<?php
function testUserNameCanBeChanged()
{
    // フレームワークからユーザーを作成、このユーザーはテスト後に削除される
    $id = $this->tester->haveInRepository('Acme\DemoBundle\Entity\User', ['name' => 'miles']);
    // モジュールにアクセスしてEntity Managerを取得する
    $em = $this->getModule('Doctrine2')->em;
    // 実際のユーザーを取得する
    $user = $em->find('Acme\DemoBundle\Entity\User', $id);
    $user->setName('bill');
    $em->persist($user);
    $em->flush();
    $this->assertEquals('bill', $user->getName());
    // フレームワークの関数を使ってデータが保存されたことを検証する
    $this->tester->seeInRepository('Acme\DemoBundle\Entity\User', ['name' => 'bill']);
    $this->tester->dontSeeInRepository('Acme\DemoBundle\Entity\User', ['name' => 'miles']);
}
?>
```

どちらの例においても、テスト間におけるデータの永続化について心配する必要はありません。
Doctrine2、Laravel4、どちらのモジュールにおいてもテストの終了時に作成されたデータはクリーンアップされます。
これは、トランザクションでテストをラッピングし、その後、それをロールバックすることによって行われます。

### モジュールにアクセスする

Codeceptionはこのスイートにおいて、すべてのモジュールに定義されたプロパティとメソッドにアクセスする事を許可しています。このときはUnitTesterクラスを使うときとは違い、直接モジュールを使用する事で、モジュールのすべてのパブリックなプロパティへのアクセスを得られます。

この話は、先ほどのコードでDoctrine2モジュールからEntity Managerへのアクセスを行ったように、すでに検証しました。

```php
<?php
/** @var Doctrine\ORM\EntityManager */
$em = $this->getModule('Doctrine2')->em;
?>
```

もし`Symfony2`を使うなら、このようにSymfonyのコンテナにアクセスします：

```php
<?php
/** @var Symfony\Component\DependencyInjection\Container */
$container = $this->getModule('Symfony2')->container;
?>
```

有効化されているモジュールのすべてのPublicプロパティについても同じようにアクセスすることができます。アクセス可能なプロパティはモジュールリファレンスに列挙されています。

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
    enabled:
        - Asserts
        - Db
        - \Helper\Unit
```

[Cest形式について もっと知る](http://codeception.com/docs/07-AdvancedUsage#Cest-Classes).

<div class="alert alert-info">
Cest形式は、テストを記述するにはシンプルすぎるように思えるかもしれません。
Cestはアサーション用の関数、モックやスタブを作成する関数、さらにはこれまで見てきた例にあったモジュールにアクセスするための`getModule`でさえも提供しません。
しかしながらCest形式は関心を分離するという点で優れています。テストコードは`UnitTester`オブジェクトによって提供されるサポートコードと干渉しません。単体/結合テストに必要となる、すべての追加アクションは`Helper\Unit`クラスに実装するようにしてください。これは推奨されたアプローチであり、テストをムダなく綺麗な状態に保つことができます。
</div>

### スタブ

Codeceptionは、スタブを簡単に作成するPHPUnitモックフレームワークの小さいラッパーを提供しています。`\Codeception\Util\Stub`を追加して、ダミーオブジェクトの作成を始めてください。

この例では、コンストラクタを呼び出さずにオブジェクトを初期化し、`getName`メソッドが*john*という値を返すように置き換えています。

```php
<?php
$user = Stub::make('User', ['getName' => 'john']);
$name = $user->getName(); // 'john'
?>
```

スタブはPHPUnitのモックフレームワークから生成されます。[Mockery](https://github.com/padraic/mockery)（[Mockery module](https://github.com/Codeception/MockeryModule)とセット）、[AspectMock](https://github.com/Codeception/AspectMock)、など他のものを代わりに使用することもできます。

スタブのユーティリティークラスの全リファレンスは[ここ](/docs/reference/Stub)を見てください。

## まとめ

テストスイートの中で、PHPUnitのテストはfirst-class citizensです。単体テストを書いて実行したいときはいつでも、PHPUnitをインストールする必要はなく、そのままCodeception上で実行することができます。いくつかのすばらしい特徴は、Codeceptionモジュールを統合する事で共通の単体テストを追加できることです。単体テストや結合テストのほとんどにおいて、PHPUnitのテストだけで十分です。PHPUnitのテストは速く、維持しやすいからです。