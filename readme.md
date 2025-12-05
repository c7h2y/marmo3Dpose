# Docker marmo3Dpose 

## 1. 前提

- Ubuntu (shell scriptやwgetが実行可能であれば何でも)
- NVIDIA GPU 搭載マシン
- Docker インストール済み
- NVIDIA Container Toolkit インストール済み（`docker run --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi` などで動作確認）
- install方法: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
- Configuring Dockerまで実行
---

## 2. Docker Build方法
```
#任意の場所で実行；dockermarmoディレクトリとしてクローンされる
git clone git@github.com:c7h2y/marmo3Dpose.git -b docker.v1.0 dockermarmo
cd dockermarmo
```
```
# もしproxyがあれば
export http_proxy=http://proxy.com:port
bash dockerbld_withproxy.sh $http_proxy .
```
```
# なければこのまま 
bash dockerbld.sh .
```
そして、コンテナが自動的に立ち上がるので、
```
bash work/docker_run_test.sh
```
で実行可能かテストする。エラーが出ず、work_dirに推定結果や動画が出力されていれば成功。 \
ここでNvidia系のエラーはcontainer toolkit関係なので１．前提に戻って依存関係を再インストール \
dockerbldシェルスクリプトを利用することでdockermarmoディレクトリに、 \
- viddata, weightディレクトリが作成されその中に動画・ネットワーク重みファイルがダウンロードされる
- viddata, weight, work_dirディレクトリがdockerコンテナ内のvid, weight, work ディレクトリにマウントされる
そのため、動画データの追加や実行スクリプトの変更がコンテナ実行中に変更可能

# 補足
動画ファイルや実行ファイルの変更方法や補足情報を以下に記載します。

## 1. 動画ファイルの変更

このステップでは、「**ホスト側のどのフォルダに動画を置けば、コンテナ内の `/app/marmo3Dpose/vid` から読めるか**」を決めます。

コンテナ側では常に **`/app/marmo3Dpose/vid`** というフォルダを参照します。  
ホスト側のどのフォルダを `/app/marmo3Dpose/vid` に接続するかは、`dockerbld.sh` / `dockerbld_withproxy.sh` の `-v` オプションで決まります。

### デフォルト設定の場合

`dockerbld.sh` / `dockerbld_withproxy.sh` は、どちらも次のようになっています。

```bash
mount=$1(dockerbld.shの場合) or $2(dockerbld_withproxyの場合)
sudo docker run --rm -it --gpus all \
    -v ${mount}/viddata:/app/marmo3Dpose/vid \
    -v ${mount}/weight:/app/marmo3Dpose/weight \
    -v ${mount}/work_dir:/app/marmo3Dpose/work \
    "${IMAGE_NAME}" bash

```
このときの引数がマウントするディレクトリを指します。 \
そして、`-v ホスト側:コンテナ側` という書式なので、
mountで指定されたフォルダをコンテナが参照します。
* `{mount}/viddata`
  → **ホスト側で動画を置くフォルダ**
* `/app/marmo3Dpose/vid`
  → **コンテナ内で動画を読むフォルダ（固定で OK）**

となります。

したがって、自身の動画ディレクトリを参照する必要があるときは、

```text
    -v ${mount}/viddata:/app/marmo3Dpose/vid \
->
    -v ${自身のディレクトリ}:/app/marmo3Dpose/vid \
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

## 2. セッション名を動画に合わせて変更する

dockerbld.shを実行するとコンテナ内で `marmo3Dpose` ディレクトリで立ち上がります。

```bash
pwd
/app/marmo3Dpose
```

そして、このshell scriptを実行するとテストデータで実行できます。
```
bash ./work_dir/docker_run_test.sh
```

そのときにdocker内とホスト側のpcでwork_dirがマウントされているので`./work_dir/docker_run_test.sh` を編集すると、docker内のスクリプトも編集されます。そして、このスクリプトを編集して、**処理したい動画に対応するセッション名**に変更します。

```bash
nano ./work_dir/docker_run_test.sh   # 好きなエディタでOK
```

そのときに、スクリプトの最初に、

```bash
# change if you want to process different session videos
# procFrame=-1 # -1 is indicate to process all frames
procFrame=100
days=('20230226')
hours=('110000')
```

の行があります。これを、**自分の動画の日時に合わせて書き換え**、**処理するフレーム数を書き換えます**。
この行は最終的に、
```bash
## 個体番号を適宜変える
for day in "${days[@]}"; do
    for hour in "${hours[@]}"; do
        echo "${day}_${hour}"
        session="dailylife_cj611_${day}_${hour}"
        # raw_data_dirs に何か別パスを入れたいならここで設定
        # raw_data_dirs+=("$raw_data_dir")
        sessions+=("$session")
    done
done

```
この行によって処理されます。このときに作られた引数がその後の処理に渡されます。 \
このプロジェクトは8方向からのカメラを用いて処理を行うことが前提とされています。

## 3. 実行

セッション名を変更したら、コンテナ内で次を実行します。

```bash
bash ./work/docker_run_test.sh
```

これにより、以下の処理が自動で行われます。

* 2D 推定・トラッキング
* 2D 可視化動画の生成
* 3D 再構成
* 3D 可視化動画の生成
そのため、2D推定だけ行いたい場合は3D部分をコメントアウトしてください。

---

## 4. 出力結果の確認

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
