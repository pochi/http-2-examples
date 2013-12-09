# Http::2::Examples

The aim of this library is to understand difference between HTTP and HTTP2.
I'll write examples as possible about below themes.

* 3 way handshake
* flow controll
* window scaling
* slow start

## Installation

You needs 'tcpdump' at first.

Add this line to your application's Gemfile:

    gem 'http-2-examples'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install http-2-examples

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## About HTTP2.0

### Buffer

Stringクラスを継承したクラス。

* initialize

データが必ずbinaryに変更する

* read

破壊的メソッド。
なくなるまで順番に取り出していくのかな。

* getbyte(== readbyte)

一文字取得してコードポイントを返す（UTF-8やらSJISそれぞれのコードポイント）

* read_uint32

ネットワークごしに送るデータを作成する。
Rubyでは"N"を利用してunpackするとネットワークバイトオーダーなものが作成される。

http://e-words.jp/w/E3838DE38383E38388E383AFE383BCE382AFE38390E382A4E38388E382AAE383BCE38380E383BC.html


### Stream

HTTP2.0では一つのTCP接続で並列したデータ転送を行うことがえきる。
これはtransitionやflow-control,error managementなどのHTTP2.0で定められた仕様に従う。
Streamクラスではそれらを内包しあなたは下のダイアグラムで必要なイベントを受付け、必要な処理を行う。

FlowBufferとEmitterはここで利用されている。


```
  #                         +--------+
  #                    PP   |        |   PP
  #                ,--------|  idle  |--------.
  #               /         |        |         \
  #              v          +--------+          v
  #       +----------+          |           +----------+
  #       |          |          | H         |          |
  #   ,---|:reserved |          |           |:reserved |---.
  #   |   | (local)  |          v           | (remote) |   |
  #   |   +----------+      +--------+      +----------+   |
  #   |      | :active      |        |      :active |      |
  #   |      |      ,-------|:active |-------.      |      |
  #   |      | H   /   ES   |        |   ES   \   H |      |
  #   |      v    v         +--------+         v    v      |
  #   |   +-----------+          |          +-_---------+  |
  #   |   |:half_close|          |          |:half_close|  |
  #   |   |  (remote) |          |          |  (local)  |  |
  #   |   +-----------+          |          +-----------+  |
  #   |        |                 v                |        |
  #   |        |    ES/R    +--------+    ES/R    |        |
  #   |        `----------->|        |<-----------'        |
  #   | R                   | :close |                   R |
  #   `-------------------->|        |<--------------------'
  #                         +--------+
```

* initialize

これ直接よびだしちゃいかん。クライアント側で新しい接続作りたいときはConnection#new_streamを利用する。
同様にConnectionは新しいstreamオブジェクトを発火してそのときにフレームを受け取ることになりますよと。

windowキーでサイズを変更できるリスナーを追加。
状態は初期状態なのでidleとする。

* receive(frame)

まずはtransition(flame,false)を呼んで状態の移行を行う。
第二引数にあるfalseはFrameを送る側が受信側かという判断をおこなう


* transition(frame, sending)

かなりコード量が長い。上記の図にもある状態管理を全部こいつが受け持つようだ。
@stateによって処理を変更する。（初期は:idle）

:idle時のソースコメントは以下のように記載されている。

```
全ては"idle"状態から始まります。この状態ではまだどのフレームもやり取りされていません。

* HEADERSフレームによってstreamはopenに変更されます。そのときにStreamの一意なIDはSection5.1.1によって決められます
* PUSH_PROMISEを送ったフレームは後に利用するStreamをチェックします。Streamの状態はその時点で"reserved(local)"に移行します
* PUSH_PROMISEを受け取ったFrameはリモートの接続と関連づけされます。その状態は"reserved(remote)"となります。
```

どうもheaderフレームがきたときはopenかcloseのどっちかになるっぽいぞと。
そもそもフレームの種類は:idle, :push_promise, :headers, :rst_streamがある。

次に@stateが:reserved_localの場合。
:reserved_local時のソースコメントは以下のように記載されている。

```
reserved_localの状態はこちらからPUSH_PROMISEフレームを送ったときの状態です。
PUSH_PROMISEはリモート先で初期化されたopen状態のStreamと関連づけされます。(Section 8.2を参照)
* エンドポイントはHEADERSフレームを送信できます。これはopenのものを"half closed(remote)"に変更するためです。
* どちらのエンドポイントも"closed"状態にするためにRST_STREAMフレームを送信することができます。これもStreamの予約を解放するためです。
エンドポイントはこの状態のときにそれ以外のFrameを送ってはいけません。
それ以外のFrameを送ると(Section 5.4.1)プロトコルエラーとして扱われるようになります。
```

[TODO] エンドポイントが接続OKの旨を返すときはどうするのか？


次に@stateが:reserved_remoteの場合。

```
Streamは"reserved(remote)"になるときはリモート先の接続が予約状態になっているときです。

* HEADERS Frameを受け取ったときは"half closed(local)"に変更されます。
* どちらのエンドポイントも"closed"状態にするためにRST_STREAMフレームを送信することができます。これもStreamの予約を解放するためです。

これ以外のFrameはSection5.4.2のPROTOCOLエラーとして扱われます。エンドポイントはRST_STREAMもしくはPRIOTRITY Frameを送って
接続のキャンセルや再優先度決めを行うことができます。
```

次に@stateが:openの場合。

```
open状態であるときはどのタイプの接続間でどのタイプのフレームも送信することができます。
この状態ではお互いの接続がSection5.2に記載されているフローを経由してやり取りを行います。

* この状態ではEND_STREAMフラグをセットしたFrameを送信することができます。これは一方の接続を"half closed"の状態に変更します。
  送信した側は"half closed(local)"の状態になり、受信した側は"half closed(remote)"になります。
* どちらの接続もRST_STREAMを送信します。これを利用するとただちに状態は"closed"に移行します
```

次に@stateが:half_closed_localの場合。

```
Streamがこの状態のときFrameを送ることはできません。
この状態から"Closed"に状態が移行されるにはEND_STREAMフラグを受け取るか、RST_STREAMを送るかもらうしかありません。
この状態になるとWINDOW_UPDATEやPRIORITY Frameは無視されます。
それらのFrameはEND_STREAMを送ってから短い期間で応答があるものと期待します。
```

次に@stateが:half_closed_remoteの場合。

```
この状態はFrameがもう送られてこないということを意味しています。
この状態になるとflow controlによって管理される義務がなくなります。
もしこのときにFrameを受け取ったとしてもSection5.4.2の通りSTREAM_CLOSEDを返却してSTREAM_ERRORを起こすべきです。
この状態から"Closed"に状態が移行されるにはEND_STREAMフラグを受け取るか、RST_STREAMを送るかもらうしかありません。
```

最後に@stateが:closedの場合。


```
接続先はclosed streamに対してFrameを送るべきではありません。
一度RST_STREAMもしくはEND_STREAMフラグがついたFrameを受け取った後はSTREAM_CLOSEDの状態として
Section5.4.2にあるようSTREAM_CLOSEDの状態として振る舞うべきです。

WINDOW_UPDATEもしくはPRIORITY FrameはEND_STREAMフラグを送信した直後なら受け取ることができます。
接続先はEND_STREAMフラグのFrameを受け取ったらすぐさま同じFrameを返すでしょう。

もしRST_STREAM Frameを送信してこの状態になった場合、RST_STREAMを受け取った接続が既に送信したFrameなどは
虫されます。接続先はRST_STREAM Frameを送った後のFrameは無視すべきです。

接続先がRST_STREAMを送ってからPUSH_PROMISEもしくはCONTINUATION Frameを受け取るかもしれません。
PUSH_STREAMはそのSTREAMを"reserved"に変更します。もし接続先STREAMがみつからなければRST_STREAMを利用して
それらのSTREAMを閉じることができます。
```

* event(newstate)

状態によって必要なアクションを呼び出します。
emit(:active)とかemit(:reserved)とかはConnectionクラスで作ってるみたい。
[#TODO] 後でみる

* complete_transition(frame)

@stateが終了状態のとき(:closing, :half_closing)終了処理(emit(:close),emit(:half_close))を呼ぶ。


* end_stream?(frame)

frameのflagsにend_streamがはいっていれば終了サインとしてtrueを返す

* stream_error(error, msg)

呼ばれたときはklassを作って例外をぽいってなげる。



### FlowBuffer

Streamクラスでincludeされるモジュール。データを送るときにサイズがあぶれないかみてくれるみたい。
MAX_FRAME_SIZEが16383bytesで指定されているのは仕様です。

http://http2.github.io/http2-spec/
(4-1. Data frames)

```
All frames begin with an 8-octet header followed by a payload of between 0 and 16,383 octets.
```

* bufferd_abount

なぞの@send_buffer

* send_data

Bufferは現状のflow control windowをベースにしてデータフレームを分割し送信を行う。
もしwindowが十分に大きければデータはただちに送信されます。そうでなければ、flow control windowが更新されるまで
データはバッファリングされます。
バッファされたデータはFIFO(First In First Out)で送信されます。

ちょっとコードはsend_buffer依存がすごいので後でみる。

send_bufferはStreamクラスで定義されているただの配列。


### Emitter

イベント実装で一回のイベントコールバックをサポートするモジュールだよと。

* add_listener(event, &block) == on

listeners Hashにevent名のsymbolキーとblockを保存

* once(event, &block)

一回だけeventのcallbackを実行する(Hashには保存しない)

* emit(evnet, *args, &block)

eventキーになるblockを実行し戻り値が:deteleなら要素から削除
