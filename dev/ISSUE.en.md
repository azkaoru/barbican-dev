## Reproduction Environment

We are using the following environment to integrate Barbican's PKCS#11 plugin with SoftHSM2 for HSM operations.

• OS: Rocky Linux 9.6
• OpenStack Barbican: 22.0.0
• OpenStack Keystone: 27.0.0
• SoftHSM2: 2.6.1

## Problem Summary

When using Barbican's PKCS#11 plugin to integrate with SoftHSM2, key generation and storage work normally, but the key rewrap operation fails. Specifically, the following error message is logged.

``` sh
# barbican-manage  hsm rewrap_pkek
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

The configuration file contents are as follows. The notable parameter is key_wrap_generate_iv in the [p11_crypto_plugin] section, which is set to False.

``` sh
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

When key_wrap_generate_iv is set to False and a rewrap operation is performed, the error `TypeError: argument should be a bytes-like object or ASCII string, not 'NoneType'`  occurs.

## Reproduction Steps

New key creation

``` sh
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

Change the labels to new ones.

``` sh
# sed -i 's/softhsm_hmac_old/softhsm_hmac_new/g' /etc/barbican/barbican.conf
# sed -i 's/softhsm_mkek_old/softhsm_mkek_new/g' /etc/barbican/barbican.conf
```

When the key rewrap operation is executed, the following error message is displayed.

``` sh
# barbican-manage  hsm rewrap_pkek
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
