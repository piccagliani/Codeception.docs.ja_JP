# 継続的インテグレーション

テストスイートを準備して実行できるようになると、テストを定期的に実行することに興味を持つでしょう。もし、コード変更のたび、もしくは少なくとも1日1回テストが実行されることを確認できれば、デグレが発生していないと考えて間違いありません。テストを定期的に実行することで、システムを安定させることができます。ところが、開発者は手動ですべてのテストを実行することに対してまったく魅力を感じませんし、テストを実行する前に本番にコードを反映することを忘れるかもしれません・・・。解決策は非常にシンプルで、テスト実行は自動化されるべきなのです。開発者のローカル環境でテストを実行するより、チームでテスト実行用の専用サーバーを用意する方がよいです。そうすれば、全員のテストが実行されることやどのコミットでデグレったのかを確認することができ、テストが通ったものもにをデプロイすることができます。

ここにはたくさんの継続的インテグレーションサーバーが登場します。Codeceptionをそれらとともにセットアップするための基本的なステップをリストアップしてみます。もしお使いのCIが記載されていない場合は、類推することでアイデアを得られるでしょう。また、記載のない他のCIに対する手順を追加することで、このガイドを充実するためのお手伝いをお願いします。

## Jenkins

![Jenkins](http://codeception.com/images/jenkins/Jenk1.png)

[Jenkins](http://jenkins-ci.org/) は業界で最も有名なオープンソースのソリューションです。セットアップが簡単で、さまざまなプラグインを適用することで容易にカスタマイズできます。

![Create new job in Jenkins](http://codeception.com/images/jenkins/Jenk2.png)

### Jenkinsを準備する

次のプラグインをインストールすることをおすすめします:

* **Git Plugin** - Gitリポジトリーからテストをビルドするため
* **Green Balls** - ビルド成功をグリーンで表示するため
* **xUnit Plugin**, **jUnit Plugin** - CodeceptionのXMLレポートを処理して表示するため
* **HTML Publisher Plugin** - CodeceptionのHTMLレポートを処理するため
* **AnsiColor** - 色付きのコンソール出力を表示するため

![Jenkins Plugins](http://codeception.com/images/jenkins/Jenk3.png)

### 基本セットアップ

最初にビルドするプロジェクトを作成する必要があります。好みに応じて、定期的なビルドかGitHubへのプッシュをトリガーとするビルド（GitHubプラグインが必要）をセットアップすることができます。

ビルド手順を定義します。最もシンプルなのは次のようになります：

```
php codecept run
```

![Jenkins Codeception Build Step](http://codeception.com/images/jenkins/Jenk5.png)

これで最初のジョブを開始して実行の進捗を確認できるようになります。もしテストに失敗すると次のようなコンソール出力となります：

![Jenkins Console Output](http://codeception.com/images/jenkins/Jenk6.png)

### XMLレポート

ただし、ビルドに失敗するたびにコンソール出力を調べることはしたくありません。特にJenkinsは内部のビルド結果を収集してWEBインターフェースに表示できます。CodeceptionはJUnitのXML形式で結果をエクスポートすることができます。XMLレポートを生成するためにはCodeceptionの実行コマンドに`--xml`オプションを付与する必要があります。Codeceptionは各ステップのテストステータスや失敗したテストに対するスタックトレースを含んだ`result.xml`を出力するでしょう。

では、XMLを生成するようにビルド手順を更新しましょう：

```
php codecept run --xml
```

そして出力されるXMLを収集するようJenkinsを設定します。これはビルド後の処理の一部として行うことができます。*Publish xUnit test result report* アクションを追加してPHPUnitレポートで使用するように設定しましょう。

![Use PHPUnit xUnit builder for Jenkins](http://codeception.com/images/jenkins/Jenk7.png)

そして、PHPUnit形式のXMLレポートへのパスを指定する必要があります。Codeceptionを標準的にセットアップしている場合、出力されるXMLにマッチするよう`tests/_output/*.xml`をパターンとして指定してください。では、プロジェクトを保存して再ビルドします。

![Jenkins Result Trend](http://codeception.com/images/jenkins/Jenk8.png)

これですべてのビルドの結果を成功および失敗したテストの割合を示すトレンドグラフが表示されます。また、実行されたすべてのテストとその統計が表に記載されているページへと遷移するための **Latest Test Result** リンクが表示されます。


### HTMLレポート

実行されたステップのより詳細を得たい場合は、HTMLレポートを生成し、Jenkinsで表示することができます。

```
php codecept run --html
```

生成されたHTMLファイルを表示するためにはHTML Publisherプラグインが必要です。XMLレポートで行ったのと同じように、ビルド後の処理に追加してください。

![Jenkins Codeception HTML Setup](http://codeception.com/images/jenkins/Jenk9.png)

Jenkinsは`tests/_output/`にある`report.html`を探します。そして、Jenkinsは各ビルドのHTMLレポートを表示するでしょう。

![Jenkins HTML Report](http://codeception.com/images/jenkins/Jenki10.png)
![Jenkins Codeception HTML Results](http://codeception.com/images/jenkins/Jenki11.png)

## TeamCity

![TeamCity](https://codeception.com/images/teamcity.png)

TeamCityはJetBrains社が提供するホスト型のソリューションです。TeamCityはテスト結果の解析に独自のレポーター形式を使用するため、セットアップには少しコツがいります。バージョン5.x以降のPHPUnitはその形式に対応しているため、Codeceptionも同様に対応しています。必要なことはCodeceptionがカスタムレポーターを使用するように設定することです。デフォルトで、代替出力を提供するための`--report`オプションがあります。`codeception.yml`設定でレポータークラスを変更することができます：

```yaml
reporters:
  report: PHPUnit_Util_Log_TeamCity  
```

より良いレポーティングのための代替として、サードパーティの[TeamCity拡張機能](https://github.com/neronmoon/TeamcityCodeception)を利用することができます。

ビルドするプロジェクトを作成したら、Codeceptionのビルド手順を定義します

```
php codecept run --report
```

![build step](https://codeception.com/images/teamcity/build.png)

最初のビルドが実行されれば、TeamCityのインターフェースで詳細なレポートを確認してください：

![report](https://codeception.com/images/teamcity/report.png)

## TravisCI

![Travis CI](https://codeception.com/images/travis.png)

Travis CIはGitHubとの連携に優れた有名なCIサービスです。Codeception自体のテストはTravis CIを使用しています。設定にあたっては何も特別なことはありません。travis設定の一番下に次の行を追加します
：

```yaml
php codecept run
```

より詳細は設定についてはCodeceptionの[`.travis.yml`](https://github.com/Codeception/Codeception/blob/master/.travis.yml)が参考になるでしょう。
TravisはXMLやHTMLレポートを可視化する機能を提供していないため、コンソール出力以外の形式でレポートを確認することはできません。しかしながら、Codeceptionは詳細はエラー出力を伴うイケてるコンソール出力を行います。

## GitLab

[本家執筆中]

## まとめ

開発に継続的インテグレーションシステムを導入することを強くおすすめします。Codeceptionはのインストールは簡単で、あらゆるCIで動作します。しかしながら、それぞれには考慮しなければならない違いがあります。CIシステムが期待する形式での出力を行うために、異なるレポーターを使用することができます。
