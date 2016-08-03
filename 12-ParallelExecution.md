# 並列実行

テストの実行時間がコーヒーブレイクよりも長くなったとしたら、それはテストの実行速度向上を考える良い機会です。もしすでにテストをSSD上で実行している、またはSeleniumの替わりにPhantomJSの使用を試しているのに、まだ実行速度にイライラしているようでしたら、テストを並列実行してみるのが良いかもしれません。

## どこからはじめよう？

Codeceptionは`run-parallel`のようなコマンドを提供していません。全員にとって満足に動作する共通の解決策はありません。あなたは次の疑問を解決する必要があります。

* どのようにして並列プロセスは実行されるのか？
* どのようにして並列プロセスがお互いに影響を与えないようにするか？
* プロセスごとに異なるデータベースを使用するか？
* プロセスごとに異なるホストを使用するか？
* どのように並列プロセス間でテストを分割すべきか？

並列化を実現するためのアプローチは2つあります。[Docker](http://docker.com)を使って、それぞれのプロセスを独立したコンテナ内で実行するか、それらコンテナを同時に実行するか、することができます。

<div class="alert alert-info">
Dockerは独立したテスト環境のため、本当に良く機能します。
この章を記述している時点では、Dockerのようなすばらしいツールはありませんでした。この章では、手動による並列実行の管理方法について説明します。見てわかるように、Dockerが簡単にやってのけるのに対して、この章ではテストを分離するためにとても多くの労力を割いています。現在では、テストの並列実行には**Dockerを使うことをおすすめします**。
</div>

## Docker

> :construction: このセクションは準備中です（本家が完成したら和訳します）

### Requirements

 - `docker` or [Docker Toolbox](https://www.docker.com/products/docker-toolbox)


### Using Codeception Docker image

Run Docker image

 docker run codeception/codeception    

Running tests from a project, by mounting the current path as a host-volume into the container.
The default working directory in the container is `/project`.

 docker run -v ${PWD}:/project codeception/codeception run

For local testing of the Codeception repository with Docker and `docker-copmose`, please refer to the [testing documentation](../tests/README.md).

## Robo

### なにをすればいい？

並列テスト実行は以下の3ステップから構成されます。

* テストを分割する
* テストを並列に実行する
* テスト結果をマージする

これらのステップの実施にタスクランナーを利用することを提案します。このガイドでは[**Robo**](http://robo.li)というタスクランナーを使用します。これは非常に簡単に利用できるモダンなPHPのタスクランナーです。バックグラウンドおよび並列プロセスの起動に[Symfony Process](http://symfony.com/doc/current/components/process.html)を使っています。ステップ2に必要なのはこれだけです！ではステップ1とステップ2はどうでしょう？私たちはテストをグループに分割するのと、テスト結果をJUnit XMLレポートにマージするためにrobo [tasks](https://github.com/Codeception/robo-paracept)を作成しました。

まとめると、私たちに必要なものは以下となります。

* [Robo](http://robo.li) - タスクランナー
* [robo-paracept](https://github.com/Codeception/robo-paracept) - 並列実行のためのCodeceptionタスク

### Roboを準備する

`Robo`はグローバルインストールすることを推奨します。[Composerを使用してグローバルインストールする](https://getcomposer.org/doc/03-cli.md#global)か、`robo.phar`をダウンロードしてPATHを通すか、どちらでも構いません。

プロジェクトのルートで`robo`を実行します。

```bash
$ robo
  RoboFile.php not found in this dir
  Should I create RoboFile here? (y/n)
```

`RoboFile.php`が作成されることを確認します。

```php
<?php
class RoboFile extends \Robo\Tasks
{
    // define public methods as commands
}
```

Composer経由で`codeception/robo-paracept`をインストールし、RoboFileにインクルードします。

robofileの各publicメソッドはコンソールコマンドとして実行することができます。先ほどの3つのステップのコマンドを定義しましょう。

```php
<?php
require_once 'vendor/autoload.php';

class Robofile extends \Robo\Tasks
{
    use \Codeception\Task\MergeReports;
    use \Codeception\Task\SplitTestsByGroups;

    public function parallelSplitTests()
    {

    }

    public function parallelRun()
    {

    }

    public function parallelMergeResults()
    {

    }
}
```

`robo`を実行すると、それぞれのコマンドが表示されます。

```bash
$ robo
Robo version 0.4.4
---
Available commands:
  help                     Displays help
  list                     Lists commands
parallel
  parallel:merge-results   
  parallel:run             
  parallel:split-tests     
```

### サンプルプロジェクト

とても時間のかかる受け入れテストを5プロセスに分割して実行することを考えてみましょう。それぞれのテストが衝突しないように異なるホストとデータベースを使用すべきです。そのため、先に進む前に5つの異なるホストにApache/Nginxを設定する必要があります（もしくは、単に異なるポートを使用してPHPのビルトインサーバーでアプリケーションを実行します）。ホスト情報に基づいて対応するデータベースを使用するようにしてください。

代替として[Docker](https://www.docker.io/)や[LXC](https://linuxcontainers.org/)を使用して**分離された環境**を準備し、それぞれのテストプロセスをコンテナー上で実行することもできます。新しいコンテナを起動してより多くのプロセスを実行することは、手動で追加のデータベースとホストを作成するよりもはるかに簡単です。これはより安定したテスト環境を作成しているということです（データベース、ファイル、プロセスの衝突はありません）。ただ、新しく仮想マシンを作成する度にコンテナをプロビジョニングする必要があるでしょう。

SSHを使用してリモートホスト上でテストを実行するということも考えられます。`Robo`はSSHコマンドを実行するためのビルトインタスクも備えています。

このサンプルプロジェクトでは、アプリケーションのために5つのデータべースと5つの独立したホストを準備していることを想定しています。

#### ステップ1 テストを分割する

Codeceptionはテストを[グループ](http://codeception.com/docs/07-AdvancedUsage#Groups)に整理することができます。バージョン2.0からはグループの情報をファイルから読み込むことができます。テキストファイルにファイルの一覧を記述すると、動的にグループとして設定されます。サンプルのグループファイルを見てみましょう。

```bash
tests/functional/LoginCept.php
tests/functional/AdminCest.php:createUser
tests/functional/AdminCest.php:deleteUser
```

`\Codeception\Task\SplitTestsByGroups`タスクは交差しない（non-intersecting）グループファイルを生成します。テストはファイル単位、テスト単位のどちらでも分割することができます。

```php
<?php
    function parallelSplitTests()
    {
        $this->taskSplitTestFilesByGroups(5)
            ->projectRoot('.')
            ->testsFrom('tests/functional')
            ->groupsTo('tests/_log/p')
            ->run();

        // alternatively
        $this->taskSplitTestsByGroups(5)
            ->projectRoot('.')
            ->testsFrom('tests/functional')
            ->groupsTo('tests/_log/p')
            ->run();
    }
```

後者の場合、`Codeception\TestLoader`が使用され、テストクラスはメモリ上に読み込まれます。

グループファイルを準備しましょう。

```bash
$ robo parallel:split-tests

 [Codeception\Task\SplitTestFilesByGroupsTask] Processing 33 files
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_log/p1
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_log/p2
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_log/p3
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_log/p4
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_log/p5
```

これでグループファイルができました。生成されたグループファイルを読み込むよう、`codeception.yml`を更新してください。今回の場合、*p1*、*p2*、*p3*、*p4*、*p5* のグループがあります。

```yaml
groups:
    p*: tests/_log/p*
```

2つ目のグループからテストを実行してみましょう。

```bash
$ php codecept run functional -g p2
```

#### ステップ2 テストを実行する

すでに述べたように、Roboにはバックグラウンドプロセスを起動するための`ParallelExec`を備えています。しかし、これが唯一のオプションとは考えないでください。たとえば、SSHを介してリモートでテストを実行することもできますし、GearmanやRabbitMQなどを利用してプロセスを起動することもできます。ただ、この例では5つのバックグラウンドプロセスを利用します。

```php
<?php
    function parallelRun()
    {
        $parallel = $this->taskParallelExec();
        for ($i = 1; $i <= 5; $i++) {            
            $parallel->process(
                $this->taskCodecept() // use built-in Codecept task
                ->suite('acceptance') // run acceptance tests
                ->group("p$i")        // for all p* groups
                ->xml("tests/_log/result_$i.xml") // save XML results
            );
        }
        return $parallel->run();
    }
```

私たちは何か重要なことを見落としています。異なるプロセスに異なるデータベースを定義することを忘れていますね。これは[環境](http://codeception.com/docs/07-AdvancedUsage#Environments)を利用して行うことができます。`acceptance.suite.yml`に新しく5つの環境を定義しましょう。

```yaml
class_name: AcceptanceTester
modules:
    enabled: [WebDriver, Db]
    config:
        Db:
            dsn: 'mysql:dbname=testdb;host=127.0.0.1'
            user: 'root'
            dump: 'tests/_data/dump.sql'
            populate: true
            cleanup: true
        WebDriver:
            url: 'http://localhost/'
env:
    p1:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_1;host=127.0.0.1'
                WebDriver:
                    url: 'http://test1.localhost/'
    p2:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_2;host=127.0.0.1'
                WebDriver:
                    url: 'http://test2.localhost/'
    p3:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_3;host=127.0.0.1'
                WebDriver:
                    url: 'http://test3.localhost/'
    p4:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_4;host=127.0.0.1'
                WebDriver:
                    url: 'http://test4.localhost/'
    p5:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_5;host=127.0.0.1'
                WebDriver:
                    url: 'http://test5.localhost/'
```

そうしたら、対応する環境を利用するように`parallelRun`メソッドを更新してください。

```php
<?php
    function parallelRun()
    {
        $parallel = $this->taskParallelExec();
        for ($i = 1; $i <= 5; $i++) {            
            $parallel->process(
                $this->taskCodecept() // use built-in Codecept task
                ->suite('acceptance') // run acceptance tests
                ->group("p$i")        // for all p* groups
                ->env("p$i")          // in its own environment
                ->xml("tests/_log/result_$i.xml") // save XML results
              );
        }
        return $parallel->run();
    }
```

これで次のようにテストを実行することができます。

```bash
$ robo parallel:run
```

#### ステップ3 テスト結果をマージする

テスト実行中はコンソールに出力される内容を信用すべきではありません。`parallelExec`タスクの場合、いくつかの文字列は失われるでしょう。テスト結果は、マージできて継続的インテグレーションに挿入できるJUnit XML形式で保存することをおすすめします。

```php
<?php
    function parallelMergeResults()
    {
        $merge = $this->taskMergeXmlReports();
        for ($i=1; $i<=5; $i++) {
            $merge->from("/tests/_log/result_$i.xml");
        }
        $merge->into("/tests/_log/result.xml")
            ->run();
    }
```
`result.xml`ファイルが生成されます。これを処理して、分析することができます。

#### すべてを統合する

これまでのステップを統括して1つのコマンドとするために、新しくpublicな`parallelAll`メソッドを定義し、すべてのコマンドを実行するようにします。`parallelRun`の結果を保存して、最終的な終了コードとして使います。

```php
<?php
    function parallelAll()
    {
        $this->parallelSplitTests();
        $result = $this->parallelRun();
        $this->parallelMergeResults();
        return $result;
    }
```

## まとめ

Codeceptionはテストを並列実行するためのツールを提供していません。これは複雑なタスクであり、解決策はプロジェクトに依存しています。私たちはすべての必要なステップを行うために外部ツールとしての[Robo](http://robo.li)タスクランナーを使いました。テストを並列実行するための準備としてCodeceptionの動的グループと環境の仕組みを利用しました。さらに、テストプロセスに応じて動的な設定を行うための拡張機能とグループクラスを作成することができます。
