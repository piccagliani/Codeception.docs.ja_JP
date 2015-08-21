# Webサービスをテストする

CodeceptionはWebサイトのテストと同じ方法で、Webサービスをテストすることができます。Webサービスを手動でテストすることはとても大変なので、テストを自動化することはとても良いアイディアです。CodeceptionにはSOAPとRESTに対応したモジュールが標準で備えられています。この章ではそれらのモジュールについて説明します。

新しくテストスイートを作成するところからはじめましょう。これは`bootstrap`コマンドでは提供されていません。テストスイートの名前は**api**とし、`ApiTester`クラスを使いましょう。

```bash
$ php codecept.phar generate:suite api
```

ここにAPIのテストを記述していきます。

## REST

REST方式のWebサービスは、HTTPの標準的なメソッドである`GET`、`POST`、`PUT`、`DELETE`を介してアクセスされます。これにより、Webサービスからエンティティを受け取り、操作することができます。WebサービスへのアクセスにはHTTPクライアントが必要であるため、`PhpBrowser`やいずれかのフレームワーク用モジュールのセットアップを行う必要があります。Webサーバーを無視し、Webサービスを内部的にテストするために、たとえば、Symfony2で実装されたアプリケーションであれば、`Symfony2`モジュールを使用します。

`api.suite.yml`にモジュールの設定を行います。

``` yaml
class_name: ApiTester
modules:
    enabled:
		- REST:
			url: http://serviceapp/api/v1/
			depends: PhpBrowser
```

この設定に従ってRESTモジュールは`PhpBrowser`に接続するでしょう。Webサービスによっては、XMLまたはJSONレスポンスを扱うことができます。Codeceptionはどちらの形式もうまく扱いますが、もしいずれかが必要でない場合、明示的にモジュールがJSONやXMLを利用するよう指定することができます。

``` yaml
class_name: ApiTester
modules:
    enabled:
		- REST:
			url: http://serviceapp/api/v1/
			depends: PhpBrowser
			part: Json
```

APIテストは機能テストとして、そしてSymfony2、Laravel4、Laravel5、Zend、または他のフレームワークモジュールを使って実行することができます。そのためには設定ファイルを少し更新する必要があります：

``` yaml
class_name: ApiTester
modules:
    enabled:
		- REST:
			url: /api/v1/
			depends: Laravel5
```

新しいテストスーとを設定できたら、最初のサンプルテストを作りましょう：

```bash
$ php codecept.phar generate:cept api CreateUser
```

これを`CreateUserCept.php`と呼ぶこととします。REST APIを介したユーザーの作成をテストするために使用します。

`CreateUserCept.php`

```php
<?php
$I = new ApiTester($scenario);
$I->wantTo('create a user via API');
$I->amHttpAuthenticated('service_user', '123456');
$I->haveHttpHeader('Content-Type', 'application/x-www-form-urlencoded');
$I->sendPOST('/users', ['name' => 'davert', 'email' => 'davert@codeception.com']);
$I->seeResponseCodeIs(200);
$I->seeResponseIsJson();
$I->seeResponseContains('{"result":"ok"}');
?>
```

### JSONレスポンスのテスト

最後の行ではレスポンスに与えられた文字列が含まれることを確認しています。しかしながら、内容の形式によっては同じデータでも異なる結果を受け取ることができるので、この方法に頼るべきではありません。私たちに実際に必要なことは、レスポンスが解析できることを確認することであり、それには期待する何らかの値が含まれています。JSONの場合には`seeResponseContainsJson`メソッドを使うことができます。

``` php
<?php
// matches {"result":"ok"}'
$I->seeResponseContainsJson(['result' => 'ok']);
// it can match tree-like structures as well
$I->seeResponseContainsJson([
	'user' => [
			'name' => 'davert',
			'email' => 'davert@codeception.com',
			'status' => 'inactive'
	]
]);
?>
```

レスポンスに対して、より複雑な検証を行いたい場合があると思います。そのためには [ヘルパー](http://codeception.com/docs/03-ModulesAndHelpers#Helpers)クラスに独自のメソッドを記述します。最後のJSONレスポンスにアクセスするためには、`REST`モジュールの`response`プロパティーを使用します。次に示す`seeResponseIsHtml`メソッドで説明しましょう。
（訳注：「ヘルパー」のリンク先は正しくは[こちら](http://codeception.com/docs/06-ReusingTestCode#Modules-and-Helpers)）

```php
<?php
namespace Helper;
class Api extends \Codeception\Module
{
	public function seeResponseIsHtml()
	{
		$response = $this->getModule('REST')->response;
        \PHPUnit_Framework_Assert::assertRegex('~^<!DOCTYPE HTML(.*?)<html>.*?<\/html>~m', $response);
	}
}
?>
```

同じ方法で、リクエストパラメーターや、ヘッダー情報を取得することができます。

### JSON構造の検証

APIのテストにおいて、受け取ったデータの検証だけでなく、レスポンスの構造についても検証することはとても一般的です。レスポンスデータは通常一貫したものとしては認識されず、リクエストのたびに変わりますが、JSON/XMLの構造は同じAPIバージョンであれば同じでなければなりません。レスポンスの構造をチェックするための便利なメソッドをRESTモジュールは持っています。

期待するJSONレスポンスを受け取ったら、その構造を[JSONPath](http://goessner.net/articles/JsonPath/)でチェックすることができます。XPathのように聞こえますが、JSONデータに対して動作するよう設計されています。一方で、JSONをXMLに変換してXPathを使って構造をチェックすることもできます。どちらのアプローチについても正解でかつRESTモジュール内で使用することができます。

```php
<?php
$I = new ApiTester($scenario);
$I->wantTo('validate structure of GitHub api responses');
$I->sendGET('/users');
$I->seeResponseIsJson();
$I->seeResponseJsonMatchesJsonPath('$[0].user.login');
$I->seeResponseJsonMatchesXpath('//user/login');
?>
```

### XMLレスポンスのテスト

REST APIがXML形式で動作する場合についても、似たような方法でデータと構造をテストすることができます。
`seeXmlResponseIncludes`メソッドはレスポンスに部分的なXMLをマッチさせる関数で、`seeXmlResponseMatchesXpath`は構造を検証するためのものです。

```php
<?php
use Codeception\Util\Xml as XmlUtils;

$I = new ApiTester($scenario);
$I->wantTo('validate structure of GitHub api responses');
$I->sendGET('/users.xml');
$I->seeResponseIsXml();
$I->seeXmlResponseMatchesXpath('//user/login');
$I->seeXmlResponseIncludes(XmlUtils::toXml(
		'user' => [
			'name' => 'davert',
			'email' => 'davert@codeception.com',
			'status' => 'inactive'
	]
));
?>
```

XML構造をきれいな方法で構築することのできるXmlUtilsクラスを使っています。`toXml`メソッドは文字列もしくは配列をとり、\DOMDocumentインスタンスを返します。もしXMLに属性が含まれていいる関係によりPHPの配列で表現できない場合は、[XmlBulder](http://codeception.com/docs/reference/XmlBuilder)を使ってXMLを作成することができます。次のセクションでもう少し見てみましょう。

<div class="alert alert-info">
XmlBuilderのインスタンスを作成するためには、`\Codeception\Util\Xml::build()`を使ってください。
</div>

## SOAP

SOAP方式のWebサービスは通常、より複雑になります。[SOAPサポートを有効にする](http://php.net/manual/ja/soap.installation.php)必要があります。XMLに関する十分な知識も必要とされます。`SOAP`モジュールは、WSDLで表されたWebサービスに接続するために、特別な形式のPOSTリクエストを利用します。Codeceptionは`PhpBrowser`やいずれかのフレームワーク用モジュールを用いてやり取りを行います。もしフレームワーク用モジュールを選択した場合、SOAPモジュールは自動的に基盤となるフレームワークに接続します。これにより、テスト実行の速度を向上させることができ、詳細なスタックトレースを提供できるようになります。

それでは`PhpBrowser`とともに使用する`SOAP`モジュールを設定しましょう。

``` yaml
class_name: ApiTester
modules:
    enabled:
		- SOAP:
			depends: PhpBrowser
			endpoint: http://serviceapp/api/v1/
```

SOAPリクエストには認証や支払いのようなアプリケーション固有の情報を含みます。この情報はXMLリクエストの`<soap:Header>`要素に含まれるSOAPヘッダーによって提供されます。もしこのようなヘッダーを送信したい場合、`haveSoapHeader`メソッドを使用することができます。たとえば次のようになります。

```php
<?php
$I->haveSoapHeader('Auth', array('username' => 'Miles', 'password' => '123456'));
?>
```

このコードは次のXMLヘッダーを生成します。


```xml
<soap:Header>
<Auth>
	<username>Miles</username>
	<password>123456</password>
</Auth>
</soap:Header>
```

リクエストのボディーを定義するためには`sendSoapRequest`を使用します。

```php
<?php
$I->sendSoapRequest('CreateUser', '<name>Miles Davis</name><email>miles@davis.com</email>');
?>
```

この呼び出しは次のXMLに変換されます。

```xml
<soap:Body>
<ns:CreateUser>
	<name>Miles Davis</name>
	<email>miles@davis.com</email>
</ns:CreateUser>
</soap:Body>
```

そして、SOAPモジュールで使用できるアサーションの一覧がこちらです。


```php
<?php
$I->seeSoapResponseEquals('<?xml version="1.0"?><error>500</error>');
$I->seeSoapResponseIncludes('<result>1</result>');
$I->seeSoapResponseContainsStructure('<user><name></name><email></email>');
$I->seeSoapResponseContainsXPath('//result/user/name[@id=1]');
?>
```

もし長いXMLを記述したくない場合、[XmlBuilder](http://codeception.com/docs/reference/XmlBuilder)クラスの利用を考えてみてください。これはjQueryのようなスタイルで複雑なXMLを構築するのに役に立ちます。
次の例では通常のXMLに替えて、`XmlBuilder`を使用しています。

```php
<?php
use \Codeception\Util\Xml;

$I = new ApiTester($scenario);
$I->wantTo('create user');
$I->haveSoapHeader('Session', array('token' => '123456'));
$I->sendSoapRequest('CreateUser', Xml::build()
	->user->email->val('miles@davis.com'));
$I->seeSoapResponseIncludes(Xml::build()
	->result->val('Ok')
		->user->attr('id', 1)
);
?>
```

`XmlBuilder`を使うか、プレーンなXMLを利用するかは、どちらでも構いません。`XmlBuilder`も同様にXML文字列を返します。

ヘルパークラスの中で`SOAP`モジュールを利用することにより、機能を拡張することができます。`\DOMDocument`としてSOAPレスポンスにアクセスするためには、`SOAP`モジュールの`response`プロパティーを使用します。

```php
<?php
namespace Helper;
class Api extends \Codeception\Module {

	public function seeResponseIsValidOnSchema($schema)
	{
		$response = $this->getModule('SOAP')->response;
		$this->assertTrue($response->schemaValidate($schema));
	}
}
?>
```

## まとめ

CodeceptionはさまざまなWebサービスをテストするために役立つモジュールを2つ備えています。それらを利用するために 新しく`api`スイートを作成する必要がありました。レスポンスボディーだけのテストしかできないわけではないことを覚えておいてください。`Db`モジュールを使用することで、`CreateUser`の呼び出し後にユーザーが作成されているかどうかテストすることができます。ヘルパーメソッドを利用することでRESTやSOAPを使ったテストシナリオを向上することができます。