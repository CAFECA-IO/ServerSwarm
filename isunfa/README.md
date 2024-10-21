本文說明如何在 linux 主機上透過 docker compose 運行 isunfa 集群

- [環境建置](#環境建置)
  - [安裝 git](#安裝-git)
  - [安裝 docker](#安裝-docker)
  - [確認 GPU 相關驅動程式是否安裝](#確認-gpu-相關驅動程式是否安裝)
- [git clone repo](#git-clone-repo)
- [複製每個 isunfa/ 底下的 .env.xxx.sample](#複製每個-isunfa-底下的-envxxxsample)
- [修改 .env 內容](#修改-env-內容)
  - [`.env` 的階層](#env-的階層)
  - [.env.isunfa 特別注意的欄位](#envisunfa-特別注意的欄位)
  - [.env.faith 特別注意的欄位](#envfaith-特別注意的欄位)
  - [.env.aich 特別注意的欄位](#envaich-特別注意的欄位)
  - [.env.nginx 特別注意的欄位](#envnginx-特別注意的欄位)
- [設置 domain](#設置-domain)
- [自動更新 docker container 裡的服務](#自動更新-docker-container-裡的服務)
- [啟動 docker compose](#啟動-docker-compose)
  - [其他相關指令](#其他相關指令)

# 環境建置

## 安裝 git

確認 git 是否成功安裝

```
git --version
```

如果沒有安裝的話，可以透過以下指令安裝

```
sudo apt update
sudo apt install git
```

## 安裝 docker

- 確認 docker 是否成功安裝

  ```
  docker --version
  ```

- 查看 Docker 運行狀態跟位置
  - `systemctl status docker`
- 開啟 Docker
  - `sudo systemctl start docker`
- 更新 docker

  - `sudo apt-get update`
  - `sudo apt-get remove docker docker-engine docker.io containerd runc`

  ```
  sudo apt-get install \
       ca-certificates \
       curl \
       gnupg \
       lsb-release
  ```

  ```
   sudo mkdir -p /etc/apt/keyrings
     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  ```

  ```
  echo \
       "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  ```

  ```bash
  sudo apt-get update

  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ```

- 確認 docker 是否能正常運行
  - `docker run hello-world`

## 確認 GPU 相關驅動程式是否安裝

- 先確認是否有 Nvidia GPU，如果沒有的話，就取消 docker-compose.yml 裡 ollama 的 gpu，如果有的話，則需要確認 Linux 主機跟 docker 的相關設置

```bash
sudo apt-get install -y nvidia-container-toolkit

sudo systemctl restart docker

docker compose down
docker compose up -d

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
     curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
     curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
     sudo apt-get update
     sudo apt-get install -y nvidia-docker2
     sudo systemctl restart docker

# 查看驅動程式狀態
nvidia-smi

# 下載 cuda 最新版 https://hub.docker.com/r/nvidia/cuda/tags
docker pull nvidia/cuda:12.6.2-cudnn-devel-ubi9

# 確認 cuda image label (映像檔標籤)
docker run --rm --gpus all nvidia/cuda:12.6.2-cudnn-devel-ubi nvidia-smi

# 檢查內核模組，如果沒有東西，代表驅動程式未載入
lsmod | grep nvidia

# 查詢 GPU 型號
lspci | grep -i nvidia

# 查看 Nvidia 驅動程式檔案路徑
whereis nvidia

# 移除現有的 nvidia 驅動程式
sudo apt-get purge 'nvidia-*'
sudo apt-get autoremove

# 安裝 nvidia 的 PPA 並更新套件列表
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update

# 安裝適合的 GPU 驅動程式版本
sudo ubuntu-drivers autoinstall

# 或者安裝特定版本
sudo apt install nvidia-driver-530

# 安裝好之後重啟系統
sudo reboot

# 查看驅動程式狀態
nvidia-smi

### 應該看到類似以下資訊

Mon Oct 21 16:48:37 2024
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.03 Driver Version: 560.35.03 CUDA Version: 12.6 |
|-----------------------------------------+------------------------+----------------------+
| GPU Name Persistence-M | Bus-Id Disp.A | Volatile Uncorr. ECC |
| Fan Temp Perf Pwr:Usage/Cap | Memory-Usage | GPU-Util Compute M. |
| | | MIG M. |
|=========================================+========================+======================|
| 0 NVIDIA GeForce RTX 4060 Ti Off | 00000000:01:00.0 Off | N/A |
| 0% 34C P8 6W / 165W | 31MiB / 16380MiB | 0% Default |
| | | N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes: |
| GPU GI CI PID Type Process name GPU Memory |
| ID ID Usage |
|=========================================================================================|
| 0 N/A N/A 2284 G /usr/lib/xorg/Xorg 9MiB |
| 0 N/A N/A 3926 G /usr/bin/gnome-shell 3MiB |
+-----------------------------------------------------------------------------------------+

###

# 安裝 nvidia container toolkit repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# 安裝 nvidia container toolkit
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# 重啟 docker 服務
sudo systemctl restart docker

# 確認 docker 可以識別 nvidia gpu
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu20.04 nvidia-smi
###
Mon Oct 21 08:42:36 2024
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.03              Driver Version: 560.35.03      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4060 Ti     Off |   00000000:01:00.0 Off |                  N/A |
|  0%   34C    P8              7W /  165W |      31MiB /  16380MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
+-----------------------------------------------------------------------------------------+
###
```

# git clone repo

```
git clone https://github.com/CAFECA-IO/ServerSwarm.git

git checkout develop
```

# 複製每個 isunfa/ 底下的 .env.xxx.sample

```
cp isunfa/.env.sample isunfa/.env
cp isunfa/isunfa/.env.isunfa.sample isunfa/isunfa/.env.isunfa
cp isunfa/faith/.env.faith.sample isunfa/faith/.env.faith
cp isunfa/aich/.env.aich.sample isunfa/aich/.env.aich
cp isunfa/nginx/.env.nginx.sample isunfa/nginx/.env.nginx
cp isunfa/ollama/.env.ollama.sample isunfa/ollama/.env.ollama
cp isunfa/postgres/.env.postgres.sample isunfa/postgres/.env.postgres
```

# 修改 .env 內容

## `.env` 的階層

- 在 `./.env` 的設定伺服器群的參數，會影響到其他機器的參數，如果機器資料夾下的 `.env` 有設定同樣的參數名稱的不同值，就會覆蓋掉 `./.env` 的參數
- 除了個別填寫 .env 欄位之外，以下參數的修改需要特別注意：

## .env.isunfa 特別注意的欄位

- 其中 `DATABASE_URL` 會用到 `.env.postgres` ，為 `postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${HOST_IP}:${POSTGRES_PORT}/${POSTGRES_DB}`

```
NEXTAUTH_URL = https://<ISUNFA_DOMAIN>
AICH_URI = https://<AICH_DOMAIN>
DATABASE_URL = <DATABASE_URL>
```

## .env.faith 特別注意的欄位

```
NEXT_PUBLIC_AICH_URL=https://<AICH_DOMAIN>
```

## .env.aich 特別注意的欄位

```
OLLAMA_HOST=http://ollama:11434
QDRANT_HOST=http://qdrant:6333
```

## .env.nginx 特別注意的欄位

```
ISUNFA_SERVER_NAME=<ISUNFA_DOMAIN>
AICH_SERVER_NAME=<AICH_DOMAIN>
FAITH_SERVER_NAME=<FAITH_DOMAIN>
```

例如

```
ISUNFA_SERVER_NAME=isunfa.com
AICH_SERVER_NAME=aich.isunfa.com
FAITH_SERVER_NAME=faith.isunfa.com
```

# 設置 domain

如果已經在其他 DNS 服務中設置域名，則可跳過此步驟

1. 使用管理員權限編輯 `/etc/hosts` 文件：

   ```
   sudo nano /etc/hosts
   ```

2. 在文件末尾添加以下行，將 `<HOST_IP>` 替換為您的主機 IP 地址，將 `<ISUNFA_DOMAIN>`、`<AICH_DOMAIN>` 和 `<FAITH_DOMAIN>` 替換為您在 `.env.nginx` 文件中設置的相應域名：

   ```
   <HOST_IP> <ISUNFA_DOMAIN> <AICH_DOMAIN> <FAITH_DOMAIN>
   ```

   例如：

   ```
   192.168.1.100 isunfa.com aich.isunfa.com faith.isunfa.com
   ```

3. 保存文件並退出編輯器。

4. 刷新 DNS 快取

   ```
   sudo systemd-resolve --flush-caches
   ```

   或者重啟網絡服務：

   ```
   sudo systemctl restart systemd-resolved
   ```

5. 驗證 DNS 設置是否生效：

   ```
   ping <ISUNFA_DOMAIN>
   ping <AICH_DOMAIN>
   ping <FAITH_DOMAIN>
   ```

   例如

   ```
    ping isunfa.com
   ```

   如果設置正確，會顯示設置的 IP 地址。

# 自動更新 docker container 裡的服務

透過 ofelia 在 docker container 裡執行 cron job，依照 GitHub branch 自動更新 docker container 的服務

1. 填寫自動更新腳本的參數

   - 填寫 `isunfa/.env.isunfa`, `faith/.env.faith`, `aich/.env.aich` 用於自動更新(check-update.sh)的參數

2. 填寫 config.ini

   - 填寫 `ofelia/config.ini` 用於自動更新的參數

# 啟動 docker compose

```
docker compose up -d
```

## 其他相關指令

- 查看每個容器使用資源的情況
  - `docker stats`
- 暫停所有在運行的容器之後再徹底刪掉所有容器

  ```bash
  docker stop $(docker ps -q)

  docker rm $(docker ps -a -q)
  ```

- 重啟 docker
  ```bash
  docker compose down
  docker compose up -d
  ```
- 查看 docker container name and id
  ```bash
  docker ps
  ```
- 進到 docker container 內部

  ```bash
  # 用 /bin/bash 進入
  docker exec -it <CONTAINER_ID> /bin/bash

  # ofelia 或使用 Alpine 輕量 Linux 的 container 需使用 /bin/sh 進入
  docker exec -it <CONTAINER_ID> /bin/sh

  # 用 docker ps 裡的 container name 進入
  docker exec -it <CONTAINER_NAME> <COMMAND>

  # 用 docker-compose 裡的 container name 進入
  docker-compose exec <CONTAINER_NAME> <COMMAND>

  # 例如 ofelia
  docker-compose exec ofelia sh
  docker exec -it ofelia sh

  # 例如 isunfa
  docker exec -it isunfa-isunfa-1 /bin/bash
  docker-compose exec -it isunfa /bin/bash
  ```
