Fix PKCS11 KEK rewrap when key_wrap_generate_iv is false

Fixed an issue where a TypeError occurred when key_wrap_generate_iv
was set to false during PKCS#11 KEK rewrapping. This change ensures
proper handling of cases where IV generation is disabled.
