# Docker で marmo3Dpose を動かす簡単な手順

このリポジトリでは、**`vid` ディレクトリに動画を入れて、`docker_run_test.sh` のセッション名を変更するだけ**で、2D/3D の推定結果と可視化動画を出力できます。

---

## 1. 前提

- NVIDIA GPU 搭載マシン
- Docker インストール済み
- NVIDIA Container Toolkit インストール済み（`docker run --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi` などで動作確認）
- install方法: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
- Configuring Dockerまで実行
---

## 2. 動画ファイルを置く

このステップでは、「**ホスト側のどのフォルダに動画を置けば、コンテナ内の `/app/marmo3Dpose/vid` から読めるか**」を決めます。

コンテナ側では常に **`/app/marmo3Dpose/vid`** というフォルダを参照します。  
ホスト側のどのフォルダを `/app/marmo3Dpose/vid` に接続するかは、`dockerbld.sh` / `dockerbld_withproxy.sh` の `-v` オプションで決まります。

### デフォルト設定の場合

`dockerbld.sh` / `dockerbld_withproxy.sh` は、どちらも次のようになっています。

```bash
# dockerbld.sh / dockerbld_withproxy.sh の一部
docker run --rm -it --gpus all \
    -v /media/user/3a7895b8-6fc9-4b13-b3ed-2045ee637322/marmo3Dpose/viddata:/app/marmo3Dpose/vid \
    -v ./work_dir:/app/marmo3Dpose/work \
    "${IMAGE_NAME}" bash
````

`-v ホスト側:コンテナ側` という書式なので、

* `/media/user/3a7895b8-6fc9-4b13-b3ed-2045ee637322/marmo3Dpose/viddata`
  → **ホスト側で動画を置くフォルダ**
* `/app/marmo3Dpose/vid`
  → **コンテナ内で動画を読むフォルダ（固定で OK）**

となります。

したがって、自身のディレクトリを参照する必要があり、

```text
/media/user/3a7895b8-6fc9-4b13-b3ed-2045ee637322/marmo3Dpose/viddata/
->
${自身のディレクトリ}
```
のように変更してください。
その中に、処理したい動画ファイルを置いてください。 \
例：
```text
/${自身のディレクトリ}
  ├── dailylife_cj611_20230226_110000.23506214
  └── dailylife_cj611_20230226_110000.23506226
   ├── 000000.mp4
   └── ...
```

---

## 3. Docker イメージをビルドしてコンテナに入る

### プロキシ不要な場合

```bash
bash dockerbld.sh
```

### プロキシが必要な場合

```bash
export http_proxy='http://proxy:port'
export https_proxy="$http_proxy"
bash dockerbld_withproxy.sh "$http_proxy"
```

どちらの場合も、ビルド後にコンテナ内のシェルに入ります。

---

## 4. セッション名を動画に合わせて変更する

dockerbld.shを実行するとコンテナ内で `marmo3Dpose` ディレクトリに移動します。

```bash
pwd
/app/marmo3Dpose
```

`docker_run_test.sh` を編集して、**処理したい動画に対応するセッション名**に変更します。

```bash
nano docker_run_test.sh   # 好きなエディタでOK
```

たとえばスクリプト内に

```bash
session="dailylife_20240101_120000"
```

のような行があれば、**自分の動画の日時などに合わせて書き換え**ます。

> ポイント：
>
> * `session` 変数が、`vid` ディレクトリ内の動画ファイル名やフォルダ構成と対応するようにします。
> * 複数セッションを処理したい場合は、同じ形式で行を増やしてください。

---

## 5. テスト実行

セッション名を変更したら、コンテナ内で次を実行します。

```bash
bash docker_run_test.sh
```

これにより、以下の処理が自動で行われます。

* 2D 推定・トラッキング
* 2D 可視化動画の生成
* 3D 再構成
* 3D 可視化動画の生成

---

## 6. 出力結果の確認

コンテナ内では `/app/marmo3Dpose/work` に結果が保存されます。
ホスト側では、`dockerbld.sh` などでマウントしているディレクトリ（例：`./work_dir`）に出力されます。

主な出力例（ホスト側）：

```text
./work_dir/
  ├── 2d_.../          # 2D 推定結果
  ├── 3d_.../          # 3D 推定結果
  └── video/           # 2D/3D 可視化動画
```

---

## まとめ

1. 動画を **`-v ホスト側:/app/marmo3Dpose/vid` の「ホスト側」フォルダ**（例：`./marmo3Dpose/vid`）に入れる
2. `dockerbld.sh`（または `dockerbld_withproxy.sh`）でコンテナを起動
3. `docker_run_test.sh` の **セッション名を自分の動画に合わせて変更**
4. `bash docker_run_test.sh` を実行
5. `work_dir`（などマウント先）に結果が出力される

