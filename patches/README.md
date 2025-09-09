# memo

## patch

リポジトリのルートで以下コマンドを実行

```sh
git apply enable-debugpy.patch
```

## install debugpy
debugpyをインストールする。

```
dnf -y install python3.9-pip
python3.9 -m pip install debugpy
```

## 


``````
python3.9 -m pip install -r requirements.txt
python3.9 -m pip install -r test-requirements.txt
```

ソースの取得方法

rpm

```
mkdir /tmp/src
cd /tmp/src
dnf download --source python3-barbican
rpm -ivh openstack-barbican-20.0.0-1.el9s.src.rpm
ls ~/rpmbuild/SOURCES/barbican-20.0.0.tar.gz
```

opendev

```
# OpenDev の公式 git
git clone https://opendev.org/openstack/barbican.git
cd barbican
git checkout 20.0.0
```
