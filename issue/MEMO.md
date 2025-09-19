# MKEK とは

Master Key Encryption Key (MKEK) は、Barbican が扱う各テナントやユーザのシークレット（APIキーやパスワードなど）を HSM 内で暗号化する際の ラップキー です。

 MKEK のローテーションとは

    古い MKEK を廃止し、新しい MKEK を生成して既存データをラップし直す（rewrap）ことです。

    このとき Barbican の barbican-manage hsm rewrap を使います。

# 実運用でのユースケース

* 定期的なセキュリティポリシー遵守

金融や公共機関では「暗号鍵は○年以内に更新」という監査要件があります。

このとき年に1回などのサイクルで MKEK をローテーション → rewrap 実行。

* インシデント対応

例: HSM が侵害された疑いがある、PIN が漏洩した可能性がある、旧鍵の強度に懸念が出た。

新しい MKEK を発行し、すべてのシークレットを rewrap することで被害を最小化。

* HSM のライフサイクル管理

古い MKEK が格納されている HSM をリプレースする場合、鍵を移行する前にローテーションを実施。


# 運用方針

我々のプロジェクトの方針は以下である。

メカニズム選定は CKM_AES_KEY_WRAP_KWP を採用

IV が不要でシンプル、RFC 5649 準拠で今後も長く使える。

年に1回（定期）またはインシデント時に MKEK ローテーションを行う

ローテーション時は barbican-manage hsm gen_mkek で新しい MKEK を生成し、
barbican-manage hsm rewrap で既存シークレットを一括更新

効果:

鍵漏洩や暗号強度低下に備え、DB 上のシークレットを安全に守り続けられる

## barbican-manageによるリラップまでの流れ

1. PKCS#11 プラグインの設定

/etc/barbican/barbican.conf にて PKCS#11 プラグインを指定します。

[crypto]
namespace = barbican.crypto.plugin
enabled_crypto_plugins = pkcs11

[crypto_plugin_pkcs11]
library_path = /usr/lib64/pkcs11/libsofthsm2.so
login = 1234               # HSM の PIN
mkek_label = mkek           # Master KEK のラベル
mkek_length = 32            # AES-256 を利用
hmac_label = hmac           # HMAC キーのラベル
slot_id = 0                 # 利用するスロット
mechanism = CKM_AES_KEY_WRAP_KWP

※ mechanism に CKM_AES_KEY_WRAP_KWP を指定することで、IV を不要とするラップ方式を選択できます。


2. HMAC / Master Key Encrypting Key (MKEK) の生成

Barbican が内部で使うラップキーを HSM に作成します。

barbican-manage hsm gen_mkek \
  --library-path /usr/lib64/pkcs11/libsofthsm2.so \
  --slot-id 0 \
  --label mkek \
  --length 32 \
  --mechanism CKM_AES_KEY_WRAP_KWP

    これで HSM 内に Master Key Encryption Key (MKEK) が生成されます。

次に HMAC キーも作ります（データ整合性確認用）:

barbican-manage hsm gen_hmac \
  --library-path /usr/lib64/pkcs11/libsofthsm2.so \
  --slot-id 0 \
  --label hmac \
  --length 32

3. Barbican にキー情報を登録

生成した MKEK と HMAC キーを Barbican に登録して使えるようにします。

barbican-manage hsm create_mkek \
  --label mkek \
  --length 32

barbican-manage hsm create_hmac \
  --label hmac \
  --length 32

これで Barbican が HSM 内の鍵を利用できる状態になります。

4. 既存データのリラップ（rewrap）

古い MKEK / 方式でラップされている鍵を、新しい MKEK または新しいメカニズム（例: CKM_AES_KEY_WRAP_KWP）でラップし直すのが rewrap です。

= ポイント

    AES Key Wrap 系 (CKM_AES_KEY_WRAP, CKM_AES_KEY_WRAP_KWP) は IV 不要
    RFC 3394/5649 準拠で、内部的に定義された初期値を使う。

    barbican-manage hsm rewrap を実行することで、既存シークレットが全て新しい鍵ラップ方式で保護される。

    HSM に複数の MKEK を置いておき、順次 rewrap することでセキュリティローテーションが可能。







