fix/pkcs11: Handle KEK rewrap failure with SoftHSM2 when key_wrap_generate_iv is false

When the PKCS#11 crypto plugin's configuration option
`key_wrap_generate_iv` is set to `false`, executing the KEK rewrap
command (`barbican-manage hsm rewrap_pkek`) fails with a `TypeError`.

When using SoftHSM2 with PKCS#11 mechanisms such as
`CKM_AES_KEY_WRAP_PAD`, wrapping can be performed without using an
initialization vector (IV).

This fix adds a check to ensure that the `iv` is present in the metadata
before attempting to decode it. This ensures that mechanisms such as
`CKM_AES_KEY_WRAP_PAD`, which do not require an IV, work correctly even
when IV generation is disabled.


