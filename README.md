# emoji-skk-dic.txt: quail-naggy 用絵文字辞書

<!-- Time-stamp: "2020-11-30T17:54:25Z" -->

## これは何？

quail-naggy 用絵文字辞書である。

下記の Google 日本語入力用辞書 emoji.txt v2.2.1 をこのアーカイブ付属の
make_emoji_skk_dic.plで変換したものである。

《日本語で絵文字入力するための IME 追加辞書を公開しました - Qiita》  
https://qiita.com/peaceiris/items/c40ba39679daeb7555c2


## 使い方

まず、quail-naggy をインストールしたディレクトリに、emoji-skk-dic.txt
と emoji-skk-dic.txt.sdb.pag と emoji-skk-dic.txt.sdb.dir をコピーする。

次に quail-naggy の site-init.nginit の最後に次の行を足す(source タグ
はいらない)。

```
add-skk-dic emoji-skk-dic.txt -u
```

あとは、変換するだけ。よみは Google 日本語入力の場合 :よみ という形だっ
たが、: は quail-naggy ではすでに使っているため、替わりに @@yomi とい
う形で入力する。(ちなみに @yomi は部首変換に使う。)

ちなみに、よみを @@ だけで変換すると、絵文字とそれの読みが多く表示され
る。英語ではじまる読みは、全部英語に変わっているが、それらは数が少ないの
で emoji-skk-dic.txt を直接読んで学んで欲しい。


## emoji-skk-dic.txt* の作り方

上記の emoji.txt の v2.2.1 を用意する。quail-naggy のパッケージに入っ
ている make_skk_dic_db.pl を用意する。

```sh
$ perl make_emoji_skk_dic.pl -v 2.2.1 emoji.txt
...
$ perl make_skk_dic_db.pl -u emoji-skk-dic.txt
...
```

v2.2.1 以外のものでうまくいくかはわからない。


## ライセンス

MIT License。LICENSE というファイルを参照のこと。


---
(This file is written in Japanese/UTF8.)
