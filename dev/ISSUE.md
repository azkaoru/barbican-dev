
## 再現環境

我々は以下の環境で、BarbicanのPKCS#11プラグインを使用し、SoftHSM2を用いたHSM連携を行っている。

- OS: Rocky Linux 9.6
- OpenStack Barbican: 22.0.0
- OpenStack Keystone: 27.0.0
- SoftHSM2: 2.6.1

## 問題の概要

BarbicanのPKCS#11プラグインを使用した鍵のリラップ（rewrap）処理でTypeErrorが発生する。具体的には、 `barbican-manage hsm rewrap_pkek` で以下のエラーメッセージがログに記録される。

```
# barbican-manage hsm rewrap_pkek
2025-10-24 05:34:31.951 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1483686139: label: token0 sn: 6bd6aa93d86f40fb _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:34:31.951 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1: label:  sn:  _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:34:31.951 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Found token sn: 6bd6aa93d86f40fb in slot 1483686139 _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:552
2025-10-24 05:34:31.952 273 WARNING barbican.plugin.crypto.pkcs11 [-] Ignoring slot_id: 1483686139 from barbican.conf
2025-10-24 05:34:31.962 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Connected to PCKS#11 Token in Slot 1483686139 __init__ /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:506
Retrieving all available projects
Retrieving KEKs for Project 06399ef3-264d-414e-bce2-a4027b129be8
Error occurred! SQLAlchemy automatically rolled-back the transaction
Traceback (most recent call last):
  File "/usr/lib/python3.9/site-packages/barbican/cmd/kek_rewrap.py", line 73, in execute
    self.rewrap_kek(project, kek)
  File "/usr/lib/python3.9/site-packages/barbican/cmd/pkcs11_kek_rewrap.py", line 87, in rewrap_kek
    iv = base64.b64decode(meta_dict['iv'])
  File "/usr/lib64/python3.9/base64.py", line 80, in b64decode
    s = _bytes_from_decode_data(s)
  File "/usr/lib64/python3.9/base64.py", line 45, in _bytes_from_decode_data
    raise TypeError("argument should be a bytes-like object or ASCII "
TypeError: argument should be a bytes-like object or ASCII string, not 'NoneType'
```

設定ファイルの内容は以下の通りである。注目すべきパラメータは `[p11_crypto_plugin]` セクション内の `key_wrap_generate_iv` で、これは `False` に設定されている。

```
# cat /etc/barbican/barbican.conf
[DEFAULT]
host_href =

log_level = DEBUG 
default_log_levels = barbican=DEBUG, sqlalchemy=WARN

[audit_middleware_notifications]
driver = log

[crypto]
enabled_crypto_plugins = p11_crypto
p11_crypto = barbican.plugin.crypto.p11_crypto.P11CryptoPlugin

[database]
connection = postgresql+psycopg2://barbican:barbican@barbican_postgres:5432/barbican

[keystone_authtoken]
auth_url = http://barbican_keystone:5000/v3
www_authenticate_uri = http://barbican_keystone:5000/v3
auth_type = password
project_domain_id = default
user_domain_id = default
project_name = service
username = barbican
password = barbican

[p11_crypto_plugin]
library_path = /usr/lib64/pkcs11/libsofthsm2.so
token_serial_number = 6bd6aa93d86f40fb
login = userpin123
mkek_label = 'softhsm_mkek_new'
mkek_length = 32
hmac_label = 'softhsm_hmac_new'
slot_id = 1483686139
encryption_mechanism = CKM_AES_CBC
hmac_key_type = CKK_GENERIC_SECRET
hmac_keygen_mechanism = CKM_GENERIC_SECRET_KEY_GEN
hmac_mechanism = CKM_SHA256_HMAC
key_wrap_mechanism = CKM_AES_KEY_WRAP_PAD
key_wrap_generate_iv = False
aes_gcm_generate_iv = true

[secretstore]
enabled_secretstore_plugins = store_crypto
```

key_wrap_generate_iv を False で、再ラップ操作を行うと、`TypeError: argument should be a bytes-like object or ASCII string, not 'NoneType'` のエラーが発生する。

問題の箇所は以下であり、meta_dict['iv'] が None となる場合、None が base64.b64decode() に渡されてしまい、TypeErrorが発生している。

https://opendev.org/openstack/barbican/src/commit/25ef5677a674088bfb433ab39df3a75ac7b3cf8f/barbican/cmd/pkcs11_kek_rewrap.py#L87

## 期待される動作

key_wrap_generate_iv が False に設定されている場合でも、鍵のリラップ（rewrap）処理が正常に完了し、TypeErrorが発生しないこと。

SoftHSM2(/usr/lib64/pkcs11/libsofthsm2.so)を利用する場合、初期化ベクトルを設定しなくても鍵のリラップが可能である。そのため、Barbicanは初期化ベクトル生成が無効化されている場合を考慮し、適切に処理を行う必要がある。


## 再現手順

鍵の作成

```
#barbican-manage hsm gen_hmac --library-path /usr/lib64/pkcs11/libsofthsm2.so --passphrase ${SOFTHSM_USERPIN} --slot-id $(softhsm2-util --show-slots | grep -m 1 Slot | sed -e "s/^Slot //") --label softhsm_hmac_new
2025-10-24 05:20:42.056 211 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1483686139: label: token0 sn: 6bd6aa93d86f40fb _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:20:42.056 211 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1: label:  sn:  _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:20:42.056 211 DEBUG barbican.plugin.crypto.pkcs11 [-] Found token sn: 6bd6aa93d86f40fb in slot 1483686139 _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:552
2025-10-24 05:20:42.056 211 WARNING barbican.plugin.crypto.pkcs11 [-] Ignoring slot_id: 1483686139 from barbican.conf
2025-10-24 05:20:42.068 211 DEBUG barbican.plugin.crypto.pkcs11 [-] Connected to PCKS#11 Token in Slot 1483686139 __init__ /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:506
HMAC successfully generated!

# barbican-manage hsm gen_mkek --library-path /usr/lib64/pkcs11/libsofthsm2.so --passphrase ${SOFTHSM_USERPIN} --slot-id $(softhsm2-util --show-slots | grep -m 1 Slot | sed -e "s/^Slot //") --label softhsm_mkek_new
2025-10-24 05:21:00.907 216 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1483686139: label: token0 sn: 6bd6aa93d86f40fb _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:21:00.907 216 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1: label:  sn:  _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:21:00.908 216 DEBUG barbican.plugin.crypto.pkcs11 [-] Found token sn: 6bd6aa93d86f40fb in slot 1483686139 _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:552
2025-10-24 05:21:00.908 216 WARNING barbican.plugin.crypto.pkcs11 [-] Ignoring slot_id: 1483686139 from barbican.conf
2025-10-24 05:21:00.919 216 DEBUG barbican.plugin.crypto.pkcs11 [-] Connected to PCKS#11 Token in Slot 1483686139 __init__ /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:506
MKEK successfully generated!
```

ラベルを新しいものに変更。

```
# sed -i 's/softhsm_hmac_old/softhsm_hmac_new/g' /etc/barbican/barbican.conf 
# sed -i 's/softhsm_mkek_old/softhsm_mkek_new/g' /etc/barbican/barbican.conf
```

設定ファイルの内容は以下の通りである。

```
# cat /etc/barbican/barbican.conf
[DEFAULT]
host_href =

log_level = DEBUG 
default_log_levels = barbican=DEBUG, sqlalchemy=WARN

[audit_middleware_notifications]
driver = log

[crypto]
enabled_crypto_plugins = p11_crypto
p11_crypto = barbican.plugin.crypto.p11_crypto.P11CryptoPlugin

[database]
connection = postgresql+psycopg2://barbican:barbican@barbican_postgres:5432/barbican

[keystone_authtoken]
auth_url = http://barbican_keystone:5000/v3
www_authenticate_uri = http://barbican_keystone:5000/v3
auth_type = password
project_domain_id = default
user_domain_id = default
project_name = service
username = barbican
password = barbican

[p11_crypto_plugin]
library_path = /usr/lib64/pkcs11/libsofthsm2.so
token_serial_number = 6bd6aa93d86f40fb
login = userpin123
mkek_label = 'softhsm_mkek_new'
mkek_length = 32
hmac_label = 'softhsm_hmac_new'
slot_id = 1483686139
encryption_mechanism = CKM_AES_CBC
hmac_key_type = CKK_GENERIC_SECRET
hmac_keygen_mechanism = CKM_GENERIC_SECRET_KEY_GEN
hmac_mechanism = CKM_SHA256_HMAC
key_wrap_mechanism = CKM_AES_KEY_WRAP_PAD
key_wrap_generate_iv = false
aes_gcm_generate_iv = true

[secretstore]
enabled_secretstore_plugins = store_crypto
```

鍵のリラップ（rewrap）操作を実行すると、以下のエラーメッセージが表示される。

```
# barbican-manage hsm rewrap_pkek
2025-10-24 05:34:31.951 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1483686139: label: token0 sn: 6bd6aa93d86f40fb _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:34:31.951 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1: label:  sn:  _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
2025-10-24 05:34:31.951 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Found token sn: 6bd6aa93d86f40fb in slot 1483686139 _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:552
2025-10-24 05:34:31.952 273 WARNING barbican.plugin.crypto.pkcs11 [-] Ignoring slot_id: 1483686139 from barbican.conf
2025-10-24 05:34:31.962 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Connected to PCKS#11 Token in Slot 1483686139 __init__ /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:506
Retrieving all available projects
Retrieving KEKs for Project 06399ef3-264d-414e-bce2-a4027b129be8
Error occurred! SQLAlchemy automatically rolled-back the transaction
Traceback (most recent call last):
  File "/usr/lib/python3.9/site-packages/barbican/cmd/kek_rewrap.py", line 73, in execute
    self.rewrap_kek(project, kek)
  File "/usr/lib/python3.9/site-packages/barbican/cmd/pkcs11_kek_rewrap.py", line 87, in rewrap_kek
    iv = base64.b64decode(meta_dict['iv'])
  File "/usr/lib64/python3.9/base64.py", line 80, in b64decode
    s = _bytes_from_decode_data(s)
  File "/usr/lib64/python3.9/base64.py", line 45, in _bytes_from_decode_data
    raise TypeError("argument should be a bytes-like object or ASCII "
TypeError: argument should be a bytes-like object or ASCII string, not 'NoneType'
```
