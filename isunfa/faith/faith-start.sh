#!/bin/bash

# Info: (20240821 - Jacky) 嘗試克隆 Git 倉庫到 /aich/app 目錄
# 如果目錄已經存在，則會失敗並執行後面的命令
# Info: (20240821 - Jacky) Should use v0.8.0 分支
# git clone https://github.com/CAFECA-IO/AICH.git -b v0.8.0 --single-branch /aich/app || (cd /isunfa/app && git pull origin main)
git clone https://github.com/CAFECA-IO/FAITH.git /faith/app || (cd /faith/app && git pull origin main)
# Info: (20240821 - Jacky) 進入 /isunfa/app 目錄並安裝依賴（假設是 Node.js 應用）
cd /faith/app && npm install

# Info: (20240821 - Jacky) Install PM2 globally
npm install --global pm2

# Info: (20240821 - Jacky) 執行構建命令
npm run build

# Info: (20240821 - Jacky) 啟動服務
PORT=${PORT} pm2-runtime start npm --name "faith" -- run start
