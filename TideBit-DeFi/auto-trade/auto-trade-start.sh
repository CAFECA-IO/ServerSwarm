#!/bin/bash

# Info: (20240905 - Jacky) 嘗試克隆 Git 倉庫到 /TideBit-DeFi/app 目錄
# Info: (20240905 - Jacky) Should use v0.8.0 分支
git clone https://github.com/CAFECA-IO/auto-trade.git /auto-trade/app || (cd /auto-trade/app && git pull origin main)
# Info: (20240905 - Jacky) 進入 /TideBit-DeFi/app 目錄並安裝依賴（假設是 Node.js 應用）
cd /auto-trade/app 

# Info: (20240910 - Jacky) 確保存在 dev 分支並檢出
git fetch origin
git checkout feat/extract_api || git checkout -b feat/extract_api origin/feat/extract_api

npm install

# Info: (20240905 - Jacky) Install PM2 globally
npm install --global pm2

# Info: (20240905 - Jacky) 執行構建命令
npm run build

# Info: (20240905 - Jacky) 啟動服務
PORT=${PORT} pm2-runtime start npm --name "auto-trade" -- run start
