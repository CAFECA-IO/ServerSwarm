在 linux 主機上透過 docker compose 運行 isunfa 整個服務

- [確保主機有安裝 git, docker](#確保主機有安裝-git-docker)
  - [安裝 git](#安裝-git)
  - [安裝 docker](#安裝-docker)
- [git clone repo](#git-clone-repo)
- [複製每個 isunfa/ 底下的 .env.xxx.sample](#複製每個-isunfa-底下的-envxxxsample)
- [修改 .env 內容](#修改-env-內容)
  - [修改 .env.isunfa](#修改-envisunfa)
  - [修改 .env.faith](#修改-envfaith)
  - [修改 .env.aich](#修改-envaich)
  - [修改 .env.nginx](#修改-envnginx)
- [設置 domain](#設置-domain)
- [啟動 docker compose](#啟動-docker-compose)

# 確保主機有安裝 git, docker

## 安裝 git

```
sudo apt update
sudo apt install git
```

確認 git 是否成功安裝

```
git --version
```

## 安裝 docker

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

  docker --version
  ```

- 確認 docker 是否能正常運行
  - `docker run hello-world`

# git clone repo

```
git clone https://github.com/CAFECA-IO/ServerSwarm.git

git checkout develop
```

# 複製每個 isunfa/ 底下的 .env.xxx.sample

```
cp isunfa/isunfa/.env.isunfa.sample isunfa/isunfa/.env.isunfa
cp isunfa/faith/.env.faith.sample isunfa/faith/.env.faith
cp isunfa/aich/.env.aich.sample isunfa/aich/.env.aich
cp isunfa/nginx/.env.nginx.sample isunfa/nginx/.env.nginx
cp isunfa/ollama/.env.ollama.sample isunfa/ollama/.env.ollama
cp isunfa/postgres/.env.postgres.sample isunfa/postgres/.env.postgres
```

# 修改 .env 內容

除了個別填寫 .env 欄位之外，以下變數的修改需要特別注意

## 修改 .env.isunfa

- 其中 `DATABASE_URL` 會用到 `.env.postgres` ，為 `postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${HOST_IP}:${POSTGRES_PORT}/${POSTGRES_DB}`

```
NEXTAUTH_URL = https://<ISUNFA_DOMAIN>
AICH_URI = https://<AICH_DOMAIN>
DATABASE_URL = <DATABASE_URL>
```

## 修改 .env.faith

```
NEXT_PUBLIC_AICH_URL=https://<AICH_DOMAIN>
```

## 修改 .env.aich

```
OLLAMA_HOST=http://ollama:11434
QDRANT_HOST=http://qdrant:6333
```

## 修改 .env.nginx

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

在其他 DNS 服務中設置域名之後，執行以下步驟

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

# 啟動 docker compose

```
docker compose up -d
```
