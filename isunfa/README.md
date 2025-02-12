Table of Contents

- [如何使用 Server Swarm 的 iSunFA 集群](#如何使用-server-swarm-的-isunfa-集群)
  - [專案介紹](#專案介紹)
    - [container dependency](#container-dependency)
    - [專案資料夾架構](#專案資料夾架構)
  - [系統要求](#系統要求)
    - [硬體要求](#硬體要求)
    - [軟體要求](#軟體要求)
  - [環境建置](#環境建置)
    - [安裝 git](#安裝-git)
    - [安裝 docker](#安裝-docker)
    - [確認 GPU 相關驅動程式是否安裝（可選）](#確認-gpu-相關驅動程式是否安裝可選)
  - [git clone repo](#git-clone-repo)
    - [修改 .env 內容](#修改-env-內容)
  - [設置 domain](#設置-domain)
  - [自動更新 docker container 裡的服務](#自動更新-docker-container-裡的服務)
  - [啟動 docker compose](#啟動-docker-compose)
  - [驗證是否成功啟動](#驗證是否成功啟動)
    - [檢查是否成功使用 GPU （可選）](#檢查是否成功使用-gpu-可選)
  - [其他處理情境](#其他處理情境)
    - [重啟單一容器](#重啟單一容器)
    - [更新單一服務的內容](#更新單一服務的內容)
  - [其他相關指令](#其他相關指令)
- [遷移 iSunFA 服務集群](#遷移-isunfa-服務集群)
  - [遷移應用程式](#遷移應用程式)
  - [遷移資料庫](#遷移資料庫)
    - [備份舊系統資料庫](#備份舊系統資料庫)
    - [將舊資料庫還原到新系統資料庫上](#將舊資料庫還原到新系統資料庫上)
    - [確認是否備份成功](#確認是否備份成功)
  - [遷移媒體文件](#遷移媒體文件)
  - [完成以上遷移後，在新的主機上運行 docker compose 啟動服務](#完成以上遷移後在新的主機上運行-docker-compose-啟動服務)

# 如何使用 Server Swarm 的 iSunFA 集群

## 專案介紹

ServerSwarm 的 iSunFA 是一個旨在透過 Docker Compose 在 Linux 和 macOS 上部署和管理 iSunFA 集群的全面解決方案。
該專案提供了一套完整的服務架構，使得用戶能夠輕鬆地運行、維護和擴展 iSunFA 服務，無論是在開發環境還是生產環境中。透過 ServerSwarm，您可以快速設置必要的服務，確保系統的穩定性和可擴展性，同時簡化了複雜的部署流程。

### container dependency

![image](https://github.com/user-attachments/assets/68dc6e2b-be10-43fe-84c0-934bff524977)

### 專案資料夾架構

```
.
├── .env
├── .env.sample
├── README.md
├── aich
│   ├── .env.aich
│   ├── .env.aich.sample
│   ├── aich-start.sh
│   ├── app
│   └── check-update.sh
├── docker-compose.cpu.yml
├── docker-compose.gpu.yml
├── docker-compose.yml
├── faith
│   ├── .env.faith
│   ├── .env.faith.sample
│   ├── app
│   ├── check-update.sh
│   └── faith-start.sh
├── isunfa
│   ├── .env.isunfa
│   ├── .env.isunfa.sample
│   ├── app
│   ├── check-update.sh
│   ├── isunfa-start.sh
│   └── readme.md
├── nginx
│   ├── .env.nginx
│   ├── .env.nginx.sample
│   ├── nginx.conf
│   └── templates
├── ofelia
│   └── config.ini
├── ollama
│   ├── .env.ollama
│   ├── .env.ollama.sample
│   ├── id_ed25519
│   ├── id_ed25519.pub
│   ├── models
│   └── ollama-start.sh
├── postgres
│   ├── .env.postgres
│   ├── .env.postgres.sample
│   └── data
└── qdrant
    ├── config
    └── qdrant_data
```

## 系統要求

### 硬體要求

1. CPU
   1. 至少 4 核心。
2. 記憶體（RAM）
   1. 最少 32 GB RAM。
3. 儲存
   1. SSD 儲存設備，至少 500 GB 可用空間
4. GPU （可選）
   1. 需配備 NVIDIA GPU，如果沒有的話，則使用 docker-compose.cpu.yml 去運行服務，如果有 GPU 則使用 docker-compose.gpu.yml

### 軟體要求

1. 作業系統
   1. Ubuntu 22.04.4 LTS
2. Docker
   1. Docker version 27.3.1
3. Nividia 驅動程式（可選）
   1. 需配備 NVIDIA GPU，如果沒有硬體資源，則可跳過

## 環境建置

### 安裝 git

確認 git 是否成功安裝

```
git --version

```

如果沒有安裝的話，可以透過以下指令安裝

```
sudo apt update
sudo apt install git

```

### 安裝 docker

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
  sudo apt-get install \\
       ca-certificates \\
       curl \\
       gnupg \\
       lsb-release

  ```

  ```
   sudo mkdir -p /etc/apt/keyrings
     curl -fsSL <https://download.docker.com/linux/ubuntu/gpg> | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  ```

  ```
  echo \\
       "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] <https://download.docker.com/linux/ubuntu> \\
       $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  ```

  ```bash
  sudo apt-get update

  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  ```

- 確認 docker 是否能正常運行
  - `docker run hello-world`

### 確認 GPU 相關驅動程式是否安裝（可選）

- 先確認硬體設備是否有 Nvidia GPU，如果沒有的話，則跳過這一步

```bash
sudo apt-get install -y nvidia-container-toolkit

sudo systemctl restart docker

docker compose down
# 使用 GPU
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
     curl -s -L <https://nvidia.github.io/nvidia-docker/gpgkey> | sudo apt-key add -
     curl -s -L <https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list> | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
     sudo apt-get update
     sudo apt-get install -y nvidia-docker2
     sudo systemctl restart docker

# 查看驅動程式狀態
nvidia-smi

# 下載 cuda 最新版 <https://hub.docker.com/r/nvidia/cuda/tags>
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

### -----應該看到類似以下資訊-----

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

### -----應該看到類似以上資訊-----

# 安裝 nvidia container toolkit repository
curl -fsSL <https://nvidia.github.io/libnvidia-container/gpgkey> | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \\
  && curl -s -L <https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list> | \\
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \\
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# 安裝 nvidia container toolkit
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# 重啟 docker 服務
sudo systemctl restart docker

# 確認 docker 可以識別 nvidia gpu
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu20.04 nvidia-smi

### -----應該看到類似以下資訊-----
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
### -----應該看到類似以上資訊-----

```

## git clone repo

```
git clone <https://github.com/CAFECA-IO/ServerSwarm.git>

git checkout develop

cd isunfa

```

### 修改 .env 內容

- 複製每個 isunfa 相關的 .env sample

```
cp ./.env.sample ./.env
cp ./isunfa/.env.isunfa.sample ./isunfa/.env.isunfa
cp ./faith/.env.faith.sample ./faith/.env.faith
cp ./aich/.env.aich.sample ./aich/.env.aich
cp ./nginx/.env.nginx.sample ./nginx/.env.nginx
cp ./ollama/.env.ollama.sample ./ollama/.env.ollama
cp ./postgres/.env.postgres.sample ./postgres/.env.postgres
```

- `.env` 的階層
  - 在 `./.env` 的設定伺服器群的參數，會影響到其他機器的參數，如果機器資料夾下的 `.env` 有設定同樣的參數名稱的不同值，就會覆蓋掉 `./.env` 的參數
  - 除了個別填寫 .env 欄位之外，以下參數的修改需要特別注意：
- .env.isunfa 特別注意的欄位
  - 其中 `DATABASE_URL` 會用到 `.env.postgres` ，為 `postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${HOST_IP}:${POSTGRES_PORT}/${POSTGRES_DB}`

```
NEXTAUTH_URL = https://<ISUNFA_DOMAIN>
AICH_URI = https://<AICH_DOMAIN>
DATABASE_URL = <DATABASE_URL>
```

- .env.faith 特別注意的欄位

```
NEXT_PUBLIC_AICH_URL=https://<AICH_DOMAIN>

```

- .env.aich 特別注意的欄位

```
OLLAMA_HOST=http://ollama:11434
QDRANT_HOST=http://qdrant:6333

```

- .env.nginx 特別注意的欄位

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

## 設置 domain

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

## 自動更新 docker container 裡的服務

透過 ofelia 在 docker container 裡執行 cron job，依照 GitHub branch 自動更新 docker container 的服務

1. 填寫自動更新腳本的參數
   - 填寫 `isunfa/.env.isunfa`, `faith/.env.faith`, `aich/.env.aich` 用於自動更新 `check-update.sh` 的參數
2. 填寫 config.ini
   - 填寫 `ofelia/config.ini` 用於自動更新的參數

## 啟動 docker compose

```bash
# 使用 GPU
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d

# 使用 CPU
docker compose -f docker-compose.yml -f docker-compose.cpu.yml up -d
```

## 驗證是否成功啟動

- 透過瀏覽器訪問 `<ISUNFA_DOMAIN>`，如果能登入、上傳圖片、建立傳票、產生報表，則服務啟動成功

### 檢查是否成功使用 GPU （可選）

1. 檢查 ollama container 的運行狀態

```bash
# 查看 ollama container 的 log
docker compose logs ollama

# 查看所有 container 的資源使用情況
docker stats
```

2. 監控 GPU 使用狀況

```bash
# 即時監控 GPU 使用情況(每秒更新)
nvidia-smi -l 1
```

當 ollama 正確使用 GPU 時，你應該能看到:

- nvidia-smi 輸出的 Processes 列表中出現 ollama 相關進程
- 在使用 FAITH 機器人對話時，GPU 使用率會有明顯波動
- GPU Memory Usage 會顯示 ollama 佔用的記憶體

如果沒有看到以上現象，可能需要:

1. 重新啟動 docker 服務

```bash
docker compose down
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

2. 確認 nvidia-container-toolkit 安裝正確
3. 檢查 docker-compose.gpu.yml 中的 GPU 相關設定

## 其他處理情境

### 重啟單一容器

在更新 `.env` 之後，需要重啟單一容器，例如更新 isunfa 容器：

```bash
# 使用 GPU
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --no-deps isunfa

# 使用 CPU
docker compose -f docker-compose.yml -f docker-compose.cpu.yml up -d --no-deps isunfa
```

- `-f docker-compose.yml -f docker-compose.gpu.yml`：指定要使用的 Docker Compose 配置檔案。

- `up -d`：在後台啟動或重新啟動服務。

- `--no-deps`：不影響 isunfa 服務的相依服務，只重新啟動 isunfa。

- `isunfa`：指定要重新啟動的服務名稱，依照 docker-compose.yml 裡的 service name 填寫。

### 更新單一服務的內容

在 docker 啟動階段，如果 `app/` 資料夾有東西，則不會重新 clone Github repo，需要手動刪除 `app/` 資料夾之後，重啟 docker compose 才會重新 clone，例如更新 aich 的程式碼：

如果需要切換不同 git branch 測試，在測試完畢後需刪除 `app/` 資料夾，才能讓自動部署成功更新至對應 branch 最新的 git head

```bash
docker compose down
sudo rm -rf aich/app
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

## 其他相關指令

- 查看每個容器使用資源的情況
  - `docker stats`
- 暫停所有在運行的容器之後再徹底刪掉所有容器

  ```bash
  docker stop $(docker ps -q)

  docker rm $(docker ps -a -q)

  ```

- 暫停單一容器

  ```bash
  docker stop <CONTAINER_NAME>
  ```

- 重啟 docker

  ```bash
  # 使用 docker compose 預設的 docker-compose.yml
  docker compose down
  docker compose up -d

  # 使用 docker compose override
  docker compose -f <FIRST_CONFIG_YAML> -f <SECOND_CONFIG_YAML> up -d
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

# 遷移 iSunFA 服務集群

遷移環境需要確保新環境上的服務跟舊環境一樣，需確保程式邏輯跟配置文件一致，在 iSunFA 需要遷移的有

1. 應用程式本身
2. 資料庫
3. 媒體文件

![CleanShot 2024-10-29 at 16 32 52](https://github.com/user-attachments/assets/1f43d6b5-dd01-4ef0-b22b-18d7ebeb698d)

![CleanShot 2024-10-29 at 16 31 50](https://github.com/user-attachments/assets/f80d5b9f-2af4-4b86-b6a6-8d79eafc37d2)

## 遷移應用程式

用 GitHub 備份程式碼，操作如同[如何使用 iSunFA server swarm](#如何使用-isunfa-server-swarm)，然後將光標切到 isunfa swarm 資料夾底下

```bash
cd isunfa
```

## 遷移資料庫

透過 PostgreSQL 官方提供的工具，去備份跟恢復整個資料庫，包含 data, auto increment, schema

### 備份舊系統資料庫

- 在本地終端機執行以下指令去備份舊系統的資料庫

```bash
pg_dump -U <your_username> -h <old_host_ip> -p <old_port> -F c -b -v -f old_db_backup.dump <old_database_name>

```

### 將舊資料庫還原到新系統資料庫上

- 透過 docker 單獨開 postgres container，避免 docker-compose.yml 裡其他 container 去初始化、seed postgres；如果資料庫不是空的，會造成備份失敗

```bash
docker compose up -d postgres # 這邊的 container name 指的是 docker-compose.yml 裡寫好的 service name
```

- 在本地終端機執行以下指令去備份舊系統的資料庫

```bash
pg_restore -U <your_username_in_new_database> -h <new_host_ip> -p <new_port> -d <new_database_name> -v --no-owner old_db_backup.dump

```

- 將資料貼到新系統的過程中如果有出現任何錯誤 log，則暫停 docker container，並且刪除在本地掛載的資料夾，重啟全新的資料庫容器

```bash
docker compose stop postgres # 或者關掉現在目錄底下所有的 container： `docker compose down`
sudo rm -rf ./postgres/data

docker compose up -d postgres
```

### 確認是否備份成功

postgres 的用戶名、密碼、資料庫名稱都在 `.env.postgres` 裡，postgres 的 port 則在 docker-compose.yml 裡，而 postgres host ip 則為運行機器的 ip

- 透過 table plus 連線到新系統資料庫查看是否成功備份資料

```bash
DATABASE_URL = postgresql://<POSTGRES_USER>:<POSTGRES_PASSWORD>@<HOST_IP>:<PORT>/<POSTGRES_DB>
```

- 透過比對舊系統跟新系統的 table schema 跟 table row count 來驗證資料是否成功備份，分別在舊系統跟新系統上執行指令：

```bash
# 用 psql 登入
psql -h <HOST_IP> -U <USER_NAME> -d <DATABASE_NAME>

# 分別登進去兩個資料庫裡之後，輸入以下 sql 進行查詢，再去比對兩者的結果
SELECT
    table_schema,
    table_name,
    COUNT(*) AS row_count
FROM
    information_schema.tables
JOIN
    information_schema.columns USING (table_schema, table_name)
WHERE
    table_type = 'BASE TABLE' AND
    table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY
    table_schema, table_name
ORDER BY
    table_schema, table_name;
```

- 檢查資料庫各個 table 的資料筆數

```bash
SELECT COUNT(*) FROM public.$TABLE;

# 例如檢查 user table 的資料筆數
SELECT COUNT(*) FROM public.user;
```

- 透過模擬重要的用戶操作來檢驗 CRUD 是否跟舊系統運行的結果一樣，例如開啟整個 isunfa service 之後，去操作登入、上傳圖片、建立日記帳、建立傳票、生成並查看報表

## 遷移媒體文件

- 將舊系統上的媒體文件壓縮之後下載到本地，在本地終端機將媒體文件壓縮檔傳輸到要運行新系統的主機上；根據 .env.isunfa 跟 .env.aich 得知有兩個資料夾需要遷移，分別是 `{HOME}/isunfa` 跟 `{HOME}/AICH`
- 將 macOS 上的檔案傳輸到遠端主機上

```bash
rsync -avz --progress /本地/資料夾/路徑 使用者名稱@遠端主機IP:/遠端/目標/路徑

# 例如將壓縮檔傳輸到遠端主機的{HOME}底下
rsync -avz --progress /Users/isunfa/media/isunfa.zip REMOTE_USERNAME@REMOTE_HOST_IP:~

```

- 在 linux 遠端主機上解壓縮

```tsx
unzip file.zip
```

- 比對檔案數量跟檔案大小

```tsx
cd directory_path
find file_or_directory | wc -l
du -sh file_or_directory
```

## 完成以上遷移後，在新的主機上運行 docker compose 啟動服務

```bash
# 使用 GPU
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d

# 使用 CPU
docker compose -f docker-compose.yml -f docker-compose.cpu.yml up -d
```
