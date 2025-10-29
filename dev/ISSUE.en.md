# Bug 

KEK rewrap (barbican-manage hsm rewrap_pkek) fails with TypeError when key_wrap_generate_iv=False (PKCS#11)

## **Bug Description**

**Hello Barbican team,**

First of all, thank you for your great work on Barbican.  
This is my first time reporting an issue here, and I hope the following information helps improve the project.

---

### **Summary**
The `barbican-manage hsm rewrap_pkek` command fails with a `TypeError` when the `[p11_crypto_plugin] key_wrap_generate_iv` option is set to `False` in `barbican.conf`.  
This issue prevents successful rewrapping of Project KEKs (PKEKs).

The traceback shows that the IV (initialization vector) is retrieved as `None` from `meta_dict['iv']` and then passed directly to `base64.b64decode()`, which expects a bytes-like object or ASCII string, resulting in the error.

https://opendev.org/openstack/barbican/src/tag/20.0.0/barbican/cmd/pkcs11_kek_rewrap.py#L87

When using SoftHSMv2 with PKCS#11 mechanisms such as CKM_AES_KEY_WRAP_PAD (as configured), wrapping can be performed without using an initialization vector.

Barbican should handle the potential absence of the IV when the `key_wrap_generate_iv` configuration option is disabled.

---

### **Steps to Reproduce**

1. **Environment Setup**  
   Use the PKCS#11 plugin with SoftHSM2, ensuring the following environment is established:
   - OS: Rocky Linux 9.6  
   - OpenStack Barbican: 22.0.0  
   - OpenStack Keystone: 27.0.0  
   - SoftHSM2: 2.6.1  

2. **Configure Barbican**  
   Ensure `key_wrap_generate_iv` is set to `False` in `/etc/barbican/barbican.conf`:

   ```ini
   [p11_crypto_plugin]
   # ... other settings ...
   key_wrap_mechanism = CKM_AES_KEY_WRAP_PAD
   key_wrap_generate_iv = False

   ```

3. **Generate new HMAC and MKEK**

   ```bash
   barbican-manage hsm gen_hmac --library-path /usr/lib64/pkcs11/libsofthsm2.so --passphrase ${SOFTHSM_USERPIN} --slot-id $(softhsm2-util --show-slots | grep -m 1 Slot | sed -e "s/^Slot //") --label softhsm_hmac_new

   barbican-manage hsm gen_mkek --library-path /usr/lib64/pkcs11/libsofthsm2.so --passphrase ${SOFTHSM_USERPIN} --slot-id $(softhsm2-util --show-slots | grep -m 1 Slot | sed -e "s/^Slot //") --label softhsm_mkek_new
   ```

4. **Change the labels to new ones**

   ```bash
   sed -i 's/softhsm_hmac_old/softhsm_hmac_new/g' /etc/barbican/barbican.conf
   sed -i 's/softhsm_mkek_old/softhsm_mkek_new/g' /etc/barbican/barbican.conf
   ```

5. **Execute KEK Rewrap**

   ```bash
   barbican-manage hsm rewrap_pkek
   ```

---

### **Actual Result**
The process fails with the following traceback (excerpt):

```
# barbican-manage hsm rewrap_pkek
2025-10-24 05:34:31.951 273 DEBUG barbican.plugin.crypto.pkcs11 [-] Slot 1483686139: label: token0 sn: 6bd6aa93d86f40fb _get_slot_id /usr/lib/python3.9/site-packages/barbican/plugin/crypto/pkcs11.py:542
...
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

- The error points to line 87 in `barbican/cmd/pkcs11_kek_rewrap.py`:

  ```python
  iv = base64.b64decode(meta_dict['iv'])
  ```

- This occurs because `meta_dict['iv']` is `None` when IV generation is disabled, and this `None` value is passed to `base64.b64decode()`.

---

### **Expected Result**
The KEK rewrap operation should complete successfully without raising a `TypeError`, even when `key_wrap_generate_iv` is set to `False`.  
Barbican should gracefully handle the case where the IV is absent in the metadata when the encryption mechanism (e.g., `CKM_AES_KEY_WRAP_PAD` via SoftHSM2) does not require it or when IV generation is explicitly disabled in the configuration.

---

### **Environment**
- OS: Rocky Linux 9.6  
- OpenStack Barbican: 22.0.0  
- OpenStack Keystone: 27.0.0  
- SoftHSM2: 2.6.1  

---

### **Additional Notes**
- When `key_wrap_generate_iv=True`, the rewrap process succeeds.  
- This may be related to handling of IV values during rewrap operations in the PKCS#11 plugin.  
- The configuration file contents are as follows (notable parameter: `key_wrap_generate_iv=False` in the `[p11_crypto_plugin]` section):

```ini
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

---


