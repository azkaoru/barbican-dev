
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
