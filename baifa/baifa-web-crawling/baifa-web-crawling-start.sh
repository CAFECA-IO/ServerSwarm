#!/bin/bash

# Info: (20240821 - Jacky) 嘗試克隆 Git 倉庫到 /baifa-web-crawling/app 目錄
# 如果目錄已經存在，則會失敗並執行後面的命令
git clone https://github.com/CAFECA-IO/BAIFA-web-crawling.git /baifa-web-crawling/app || (cd /baifa-web-crawling/app && git pull origin main)

# Info: (20240821 - Jacky) 進入 /baifa-web-crawling/app 目錄
cd /baifa-web-crawling/app 

# Info: (20240910 - Jacky) 確保存在 develop 分支並檢出
git fetch origin
git checkout develop || git checkout -b develop origin/develop

npm install
# Info: (20240821 - Jacky) Install PM2 globally
npm install --global pm2

# Info: (20240821 - Jacky) 執行 Prisma 相關命令
npx prisma db push

# Info: (20240821 - Jacky) 執行構建命令
npm run build

# Info: (20240821 - Jacky) 啟動服務
pm2-runtime start npm --name "baifa-web-crawling" -- run start
