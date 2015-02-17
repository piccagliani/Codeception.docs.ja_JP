# Webサービスをテストする

CodeceptionはWebサイトのテストと同じ方法で、Webサービスをテストすることができます。Webサービスを手動でテストすることはとても大変なので、テストを自動化することはとても良いアイディアです。CodeceptionにはSOAPとRESTに対応したモジュールが標準で備えられています。この章ではそれらのモジュールについて説明します。

新しくテストスイートを作成するところからはじめましょう。これは `bootstrap` コマンドでは提供されていません。テストスイートの名前は **api** とし、`ApiTester` クラスを使いましょう。

```bash
$ php codecept.phar generate:suite api
```

ここにAPIのテストを記述していきます。

## REST

REST方式のWebサービスは、HTTPの標準的なメソッドである `GET`、`POST`、`PUT`、`DELETE` を介してアクセスされます。これにより、Webサービスからエンティティを受け取り、操作することができます。WebサービスへのアクセスにはHTTPクライアントが必要であるため、`PhpBrowser` やいずれかのフレームワーク用モジュールのセットアップを行う必要があります。Webサーバーを無視し、Webサービスを内部的にテストするために、たとえば、Symfony2 で実装されたアプリケーションであれば、`Symfony2` モジュールを使用します。

`api.suite.yml` にモジュールの設定を行います。

``` yaml
class_name: ApiTester
modules:
    enabled: [PhpBrowser, REST, ApiHelper]
    config:
		PhpBrowser:
			url: http://serviceapp/
		REST:
		    url: http://serviceapp/api/v1/
```

RESTモジュールは自動的に `PhpBrowser` に接続します。Symfony2、Laravel4、Zendやそのほかのフレームワークモジュールによって提供する場合においても同様に接続します。設定の編集が完了したら、`build` コマンドを実行するのを忘れないでください。

それでは最初のテストを作成しましょう。

```bash
$ php codecept.phar generate:cept api CreateUser
```

これを `CreateUserCept.php` と呼ぶこととします。Webサービスを介してのユーザーの作成をテストするために使用します。

`CreateUserCept.php`

```php
<?php
$I = new ApiTester($scenario);
$I->wantTo('create a user via API');
$I->amHttpAuthenticated('service_user', '123456');
$I->haveHttpHeader('Content-Type', 'application/x-www-form-urlencoded');
$I->sendPOST('users', ['name' => 'davert', 'email' => 'davert@codeception.com']);
$I->seeResponseCodeIs(200);
$I->seeResponseIsJson();
$I->seeResponseContains('{"result":"ok"}');
?>
```

RESTモジュールはJSON形式をレスポンスするWebサービスを扱えるよう設計されています。たとえば、`seeResponseContainsJson` メソッドは与えられた配列をJSON形式に変換し、それがレスポンスに含まれているかどうかをチェックします。

レスポンスに対して、より複雑な検証を行いたい場合があると思います。そのためには [ヘルパー](http://codeception.com/docs/03-ModulesAndHelpers#Helpers) クラスに独自のメソッドを記述します。最後のJSONレスポンスにアクセスするためには、`REST` モジュールの `response` プロパティーを使用します。次に示す `seeResponseIsHtml` メソッドで説明しましょう。

```php
<?php
class ApiHelper extends \Codeception\Module
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

## SOAP

SOAP方式のWebサービスは通常、より複雑になります。[SOAPサポートを有効にする](http://php.net/manual/ja/soap.installation.php)必要があります。XMLに関する十分な知識も必要とされます。`SOAP` モジュールは、WSDLで表されたWebサービスに接続するために、特別な形式のPOSTリクエストを利用します。Codeceptionは `PhpBrowser`やいずれかのフレームワーク用モジュールを用いてやり取りを行います。もしフレームワーク用モジュールを選択した場合、SOAPモジュールは自動的に基盤となるフレームワークに接続します。これにより、テスト実行の速度を向上させることができ、詳細なスタックトレースを提供できるようになります。

それでは `PhpBrowser` とともに使用する `SOAP` モジュールを設定しましょう。

``` yaml
class_name: ApiTester
modules:
    enabled: [PhpBrowser, SOAP, ApiHelper]
    config:
		PhpBrowser:
			url: http://serviceapp/
		SOAP:
		    endpoint: http://serviceapp/api/v1/
```

SOAPリクエストには認証や支払いのようなアプリケーション固有の情報を含みます。この情報はXMLリクエストの `<soap:Header>` 要素に含まれるSOAPヘッダーによって提供されます。もしこのようなヘッダーを送信したい場合、`haveSoapHeader` メソッドを使用することができます。たとえば次のようになります。

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

リクエストのボディを定義するためには `sendSoapRequest` を使用します。

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

もし長いXMLを記述したくない場合、[XmlBuilder](http://codeception.com/docs/reference/XmlBuilder) クラスの利用を考えてみてください。これはjQueryのようなスタイルで複雑なXMLを構築するのに役に立ちます。
次の例では通常のXMLに替えて、（SoapUtilsファクトリによって作成された）`XmlBuilder` を使用しています。

```php
<?php
use \Codeception\Util\Soap;

$I = new ApiTester($scenario);
$I->wantTo('create user');
$I->haveSoapHeader('Session', array('token' => '123456'));
$I->sendSoapRequest('CreateUser', Soap::request()
	->user->email->val('miles@davis.com'));
$I->seeSoapResponseIncludes(Soap::response()
	->result->val('Ok')
		->user->attr('id', 1)
);
?>
```

`XmlBuilder` を使うか、プレーンなXMLを利用するかは、どちらでも構いません。`XmlBuilder` も同様にXML文字列を返します。

ヘルパークラスの中で`SOAP`モジュールを利用することにより、機能を拡張することができます。`\DOMDocument` としてSOAPレスポンスにアクセスするためには、`SOAP` モジュールの `response` プロパティーを使用します。

```php
<?php
class ApiHelper extends \Codeception\Module {

	public function seeResponseIsValidOnSchema($schema)
	{
		$response = $this->getModule('SOAP')->response;
		$this->assertTrue($response->schemaValidate($schema));
	}
}
?>
```

## Conclusion

Codeceptionは様々なWebサービスをテストするために役立つモジュールを２つ備えています。それらを利用するために 新しく `api` スイートを作成する必要がありました。レスポンスボディだけのテストしかできないわけではないことを覚えておいてください。`Db` モジュールを使用することで、`CreateUser` の呼び出し後にユーザーが作成されているかどうかテストすることができます。ヘルパーメソッドを利用することでRESTやSOAPを使ったテストシナリオを向上することができます。