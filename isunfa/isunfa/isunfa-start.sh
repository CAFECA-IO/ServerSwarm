#!/bin/bash

# Info: (20240821 - Jacky) 嘗試克隆 Git 倉庫到 /isunfa/app 目錄
# 如果目錄已經存在，則會失敗並執行後面的命令
# git clone https://github.com/CAFECA-IO/iSunFA.git -b v0.8.0 --single-branch /isunfa/app || (cd /isunfa/app && git pull origin main)
# git clone https://github.com/CAFECA-IO/iSunFA.git /isunfa/app || (cd /isunfa/app && git pull origin main)
(git clone https://github.com/CAFECA-IO/iSunFA.git /isunfa/app && cd /isunfa/app && git checkout $TARGET_BRANCH) || (cd /isunfa/app && git checkout $TARGET_BRANCH && git pull)

# Info: (20240821 - Jacky) 進入 /isunfa/app 目錄並安裝依賴（假設是 Node.js 應用）
cd /isunfa/app && npm install

# Info: (20240821 - Jacky) Install PM2 globally
npm install --global pm2

# Info: (20240821 - Jacky) 執行 Prisma 相關命令
npx prisma migrate deploy

# Info: (20241011 - Shirley) 使用 prisma db seed 會出現 `Error: Command failed with exit code 1: ts-node -r tsconfig-paths/register --compiler-options {"module":"CommonJS"} prisma/seed.ts` 錯誤
# npx prisma db seed
npx ts-node -r tsconfig-paths/register --compiler-options '{"module":"CommonJS"}' prisma/seed.ts

# Info: (20240821 - Jacky) 執行構建命令
npm run build

# Info: (20240821 - Jacky) 啟動服務
PORT=${PORT} pm2-runtime start npm --name "isunfa" -- run start
