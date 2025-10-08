
# Barbican リポジトリで特定タグ（22.0.0）をベースにブランチを作成する手順

## 1. fork したリポジトリを clone
```bash
git clone git@github.com:<your-username>/barbican.git
cd barbican

## 2. upstream を登録（公式の opendev/barbican） 

```
git remote add upstream https://opendev.org/openstack/barbican.git
git fetch upstream --tags
```

## 3. 22.0.0 タグから新しいブランチを作成

```
git checkout -b my-feature-branch 20.0.0
```

## 4. GitHub の fork に push

```
git push origin my-feature-branch
```


# 正常動作するソフトウェアバージョン

```
centos-release-openstack-epoxy-1-1.el9.noarch
python3-openstacksdk-4.4.0-1.el9s.noarch
openstack-barbican-common-20.0.0-1.el9s.noarch
python-openstackclient-lang-7.4.0-1.el9s.noarch
python3-openstackclient-7.4.0-1.el9s.noarch
openstack-barbican-api-20.0.0-1.el9s.noarch
openstack-keystone-27.0.0-1.el9s.noarch
```

# barbican rpmインストールでインストールされるファイル

```
# rpm -ql openstack-barbican-api-20.0.0-1.el9s.noarch
/etc/barbican/api_audit_map.conf
/etc/barbican/barbican-api-paste.ini
/etc/barbican/gunicorn-config.py
/etc/barbican/vassals/barbican-api.ini
/usr/bin/barbican-wsgi-api
/usr/lib/systemd/system/openstack-barbican-api.service

```

# rewrap テスト方法

```
make barbican-rewrap
```

barbicanコンテナ内で実施する場合

```
podman exec -it barbican sh
```

事前準備
```
barbican-manage hsm gen_hmac --library-path /usr/lib64/pkcs11/libsofthsm2.so --passphrase ${SOFTHSM_USERPIN} --slot-id $(softhsm2-util --show-slots | grep -m 1 Slot | sed -e "s/^Slot //") --label softhsm_hmac_1
barbican-manage hsm gen_mkek --library-path /usr/lib64/pkcs11/libsofthsm2.so --passphrase ${SOFTHSM_USERPIN} --slot-id $(softhsm2-util --show-slots | grep -m 1 Slot | sed -e "s/^Slot //") --label softhsm_mkek_1
sed 's/softhsm_hmac_0/softhsm_hmac_1/g' /etc/barbican/barbican.conf > /tmp/barbican1.conf
sed 's/softhsm_mkek_0/softhsm_mkek_1/g' /tmp/barbican1.conf > /tmp/barbican2.conf
```

rewrap debug実行
```
export DEBUGPY_ENABLE_CMD=True
barbican-manage --config-file /tmp/barbican2.conf hsm rewrap_pkek
```

