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

Dockerはテスト環境を分離する上でとても良く機能します。
この章を記述している時点では、Dockerのようなすばらしいツールはありませんでした。この章では、手動による並列実行の管理方法について説明します。見てわかるように、Dockerが簡単にやってのけるのに対して、この章ではテストを分離するためにとても多くの労力を割いています。現在では、テストの並列実行には<strong>Dockerを使うことをおすすめします</strong>。

## Docker

`docker`もしくは[Docker Toolbox](https://www.docker.com/products/docker-toolbox)がインストール済みであることを確認してください。Dockerに関する経験も同時に必要です。

### CodeceptionのDockerイメージを使用する

DockerHubにあるCodeceptionの公式イメージを実行します：

    docker run codeception/codeception

現在のパスをホストボリュームとしてコンテナにマウントし、プロジェクトからテストを実行します。
コンテナ内のデフォルトの作業ディレクトリは`/project`です。

    docker run -v ${PWD}:/project codeception/codeception run

コンテナ内でアプリケーションとテストを実行できるようにするためには、複数のコンテナを実行し、相互接続できるようにするための[Docker Compose](https://docs.docker.com/compose/)を使う必要があるでしょう。

`docker-compose.yml`に必要となるすべてのサービスを定義します。1コンテナ1サービス、というDockerの哲学に従いましょう。つまり、各プロセスはそれぞれのサービスとして定義されるべきです。これらのサービスにはDockerHubから取得できる公式イメージを使用することができます。コードとテストが含まれるディレクトリは`volume`ディレクティブを使用してマウントしてください。そして、公開するポートは`ports`ディレクティブを使用して明示的に設定してください。

Codeception、ウェブサーバー、データベース、そしてfirefoxと動作するseleniumが一緒に実行されるよう、サンプル設定を用意しました。

```yaml
version: '2'
services:
  codeception:
    image: codeception/codeception
    depends_on:
      - firefox
      - web
    volumes:
      - ./src:/src
      - ./tests:/tests
      - ./codeception.yml:/codeception.yml
  web:
    image: php:7-apache
    depends_on:
      - db
    volumes:
      - .:/var/www/html
  db:
    image: percona:5.6
    ports:
      - '3306'
  firefox:
    image: selenium/standalone-firefox-debug:2.53.0
    ports:
      - '4444'
      - '5900'
```

Codeceptionサービスは`codecept run`コマンドを実行することになりますが、それは他のすべてのサービスが開始された後になります。これは`depends_on`パラメーターを使用して定義されています。

カスタムサービスを追加することは簡単です。たとえば、Redisを使用するためには、次の行を追加すればよいです：

```yaml
  redis:
    image: redis:3
```

デフォルトで、イメージのエントリポイントはcodeceptになっており、単にテストを行う場合は実行用マンドを与えます。

```
docker-compose run --rm codecept help
```

テストスイートを実行

```
docker-compose run --rm codecept run acceptance
```


```
docker-compose run --rm codecept run acceptance LoginCest
```

開発用のbash

```
docker-compose run --rm --entrypoint bash codecept
```

最終的にテストを並列実行するためには、テストをどのように分割するか定義し、`docker-compose`を並列して動作させることが必要です。ここではテストスイートによりテストを分割していますが、異なる分類を使用して分割することができます。下のセクションでは、Roboを使ってどのように並列実行するのか学ぶことができるでしょう。

```
docker-compose --project-name test-web run -d --rm codecept run --html report-web.html web & \
docker-compose --project-name test-unit run -d --rm codecept run --html report-unit.html unit & \
docker-compose --project-name test-functional run -d --rm codecept run --html report-functional.html functional
```

最後に、繰り返しになりますが、Dockerのセットアップは複雑になる可能性があるので、次に進む前にDockerとDocker Composeについてしっかりと理解してください。役立つと思われるいくつかのリンクを挙げます：

* [Acceptance Tests Demo Repository](https://github.com/dmstr/docker-acception)
* [Dockerized Codeception Internal Tests](https://github.com/Codeception/Codeception/blob/master/tests/README.md#dockerized-testing)
* [Phundament App with Codeception](https://gist.github.com/schmunk42/d6893a64963509ff93daea80f722f694)


もし、PHPスクリプトを使用して、並列プロセスによって自動化にテストを分割し、実行したいのであれば、Roboタスクランナーを使用してください。

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

## RoboとRobo-paraceptを準備する

RoboおよびRobo-paraceptをインストールするために、空のフォルダ内で次のコマンドを実行します：
```bash
$ composer require codeception/robo-paracept:dev-master
```

Codeceptionがすでにインストールされている場合は動作しないので、Codeceptionは後からインストールする必要があります。
```bash
$ composer require codeception/codeception
```

### Roboを準備する

プロジェクトのルートで、ベースとなるRoboFileを初期化します。

```bash
$ robo init
```

`RoboFile.php`を開いて編集します。

```php
<?php

class RoboFile extends \Robo\Tasks
{
    // define public methods as commands
}
```

robofileの各publicメソッドはコンソールコマンドとして実行することができます。先ほどの3つのステップのコマンドを定義してautoloadをインクルードしましょう。

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

`robo`を実行すると、それぞれのコマンドが表示されます：

```bash
$ robo
Robo version 0.6.0

Usage:
  command [options] [arguments]

Options:
  -h, --help            Display this help message
  -q, --quiet           Do not output any message
  -V, --version         Display this application version
      --ansi            Force ANSI output
      --no-ansi         Disable ANSI output
  -n, --no-interaction  Do not ask any interactive question
  -v|vv|vvv, --verbose  Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

Available commands:
  help                    Displays help for a command
  list                    Lists commands
 parallel
  parallel:merge-results
  parallel:run
  parallel:split-tests
```

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
        // Slip your tests by files
        $this->taskSplitTestFilesByGroups(5)
            ->projectRoot('.')
            ->testsFrom('tests/acceptance')
            ->groupsTo('tests/_data/paracept_')
            ->run();

        /*
        // Slip your tests by single tests (alternatively)
        $this->taskSplitTestsByGroups(5)
            ->projectRoot('.')
            ->testsFrom('tests/acceptance')
            ->groupsTo('tests/_data/paracept_')
            ->run();
        */
    }
```

グループファイルを準備しましょう。

```bash
$ robo parallel:split-tests

 [Codeception\Task\SplitTestFilesByGroupsTask] Processing 33 files
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_data/paracept_1
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_data/paracept_2
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_data/paracept_3
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_data/paracept_4
 [Codeception\Task\SplitTestFilesByGroupsTask] Writing tests/_data/paracept_5
```

これでグループファイルができました。生成されたグループファイルを読み込むよう、`codeception.yml`を更新してください。今回の場合、*paracept_1*、*paracept_2*、*paracept_3、*paracept_4*、*paracept_5* のグループがあります。

```yaml
groups:
    paracept_*: tests/_data/paracept_*
```

2つ目のグループからテストを実行してみましょう。

```bash
$ codecept run acceptance -g paracept_2
```

#### ステップ2 テストを実行する

Robo has `ParallelExec` task to spawn background processes.

##### コンテナ内で

もし[Docker](#toc1)コンテナを使用している場合、異なるグループのために複数のCodeceptionコンテナを起動することができます：


```php
public function parallelRun()
{
    $parallel = $this->taskParallelExec();
    for ($i = 1; $i <= 5; $i++) {
        $parallel->process(
            $this->taskExec('docker-compose run --rm codecept run')
                ->opt('group', "p$i") // run for groups p*
                ->opt('xml', "tests/_log/result_$i.xml"); // provide xml report
        );
    }
    return $parallel->run();
}
```

##### ローカルで

テストをローカルで実行したい場合はプリインストールされているRoboの`taskCodecept`を使ってCodeceptionコマンドを定義し、`parallelExec`内に配置します。

```php
<?php
public function parallelRun()
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

コンテナを使用しないケースでは、各テストのプロセス毎に異なるウェブサーバーとデータベースを起動することにより、プロセスを分離することができます。

異なるプロセスに対して異なるデータベースを定義することが可能です。これは[環境](http://codeception.com/docs/07-AdvancedUsage#Environments)を使用して行うことができます。`acceptance.suite.yml`に新しい5環境を定義してみましょう：

```yaml
class_name: AcceptanceTester
modules:
    enabled:
        - Db:
            dsn: 'mysql:dbname=testdb;host=127.0.0.1'
            user: 'root'
            dump: 'tests/_data/dump.sql'
            populate: true
            cleanup: true
        - WebDriver:
            url: 'http://localhost/'
env:
    env1:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_1;host=127.0.0.1'
                WebDriver:
                    url: 'http://test1.localhost/'
    env2:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_2;host=127.0.0.1'
                WebDriver:
                    url: 'http://test2.localhost/'
    env3:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_3;host=127.0.0.1'
                WebDriver:
                    url: 'http://test3.localhost/'
    env4:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_4;host=127.0.0.1'
                WebDriver:
                    url: 'http://test4.localhost/'
    env5:
        modules:
            config:
                Db:
                    dsn: 'mysql:dbname=testdb_5;host=127.0.0.1'
                WebDriver:
                    url: 'http://test5.localhost/'
```


----

`parallelRun`が定義されたあとは、次のコマンドで実行することができます：

```bash
$ robo parallel:run
```

#### ステップ3 テスト結果をマージする

`parallelExec`タスクのケースでは、テスト結果を、マージできて継続的インテグレーションに挿入できるJUnit XML形式で保存することをおすすめします。

```php
<?php
    function parallelMergeResults()
    {
        $merge = $this->taskMergeXmlReports();
        for ($i=1; $i<=5; $i++) {
            $merge->from("tests/_output/result_paracept_$i.xml");
        }
        $merge->into("tests/_output/result_paracept.xml")->run();
    }

```
これで次のように実行できます：
```bash
$ robo parallel:merge-results
```
`result_paracept.xml`ファイルが生成されるでしょう。これを処理して分析することができます。

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
