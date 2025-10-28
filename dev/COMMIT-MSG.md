Fix PKCS11 KEK rewrap when key_wrap_generate_iv is false

Fixed an issue where a TypeError occurred when key_wrap_generate_iv
was set to false during PKCS#11 KEK rewrapping. This change ensures
proper handling of cases where IV generation is disabled.


fix/pkcs11: Handle missing IV during KEK rewrap when IV generation is disabled

When the PKCS#11 crypto plugin's configuration option
`key_wrap_generate_iv` is set to `false`, executing the KEK rewrap
command (`barbican-manage hsm rewrap_pkek`) fails with a `TypeError`.

This error occurs because the command logic unconditionally attempts to
base64-decode the `iv` (initialization vector) from the metadata, even
though the IV field is not populated when generation is disabled. This
results in `NoneType` being passed to `base64.b64decode()`.

This fix adds a check to ensure that the `iv` is present in the metadata
before attempting to decode it. This allows mechanisms like
`CKM_AES_KEY_WRAP_PAD` (which do not require an IV) to function correctly
when IV generation is disabled, aligning with the expected behavior of
the `key_wrap_generate_iv = false` setting.
