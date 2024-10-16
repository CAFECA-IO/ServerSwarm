#!/bin/bash

LOG_FILE="${LOG_FILE}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL}"
TARGET_BRANCH="${TARGET_BRANCH}"
SERVER_NAME="${SERVER_NAME}"
APP_PATH="${APP_PATH}"
WEB_URL="${WEB_URL}"
BASE_REPO_URL="${BASE_REPO_URL}"

REPO_URL="$BASE_REPO_URL/tree/$TARGET_BRANCH"

IS_SUCCESS=false
IS_NOTIFICATION_NEEDED=false

# Info: (20241016 - Shirley) 取得腳本開始執行的時間，格式為 HH:MM:SS MONTH/DAY/YEAR
TIME_START=$(date +%H:%M:%S\ %m/%d/%Y)
SECONDS_START=$(date +%s)

# Info: (20241016 - Shirley) 新增發送 Slack 訊息的函數
send_slack_message() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" "$SLACK_WEBHOOK_URL"
}

# Info: (20241016 - Shirley) 安裝 jq ，用來解析 package.json
if ! command -v jq &> /dev/null; then
    apt-get update && apt-get install -y jq
fi

# Info: (20241016 - Shirley) 確保日誌目錄存在
mkdir -p $(dirname "$LOG_FILE")

# Info: (20241016 - Shirley) 如果日誌文件不存在，則創建它
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "$(date): 日誌文件已創建" >> "$LOG_FILE"
fi

# Info: (20241016 - Shirley) 記錄腳本開始執行的時間
echo "$(date): 開始檢查更新" >> $LOG_FILE

# Info: (20241016 - Shirley) 進入 app 目錄
cd $APP_PATH

# Info: (20241016 - Shirley) 獲取遠端更新
if ! git fetch origin; then
    echo "無法獲取遠端更新，請檢查網絡連接或倉庫權限"
    exit 1
fi

LOCAL_LAST_COMMIT=$(git rev-parse HEAD)
REMOTE_LAST_COMMIT=$(git rev-parse origin/$TARGET_BRANCH)

LAST_COMMIT_URL="$BASE_REPO_URL/commit/$REMOTE_LAST_COMMIT"

LOCAL_VERSION=$(jq -r .version package.json)
REMOTE_VERSION=$(git show origin/$TARGET_BRANCH:package.json | jq -r .version)

echo "$(date) TIME_START (UTC): $TIME_START" >> $LOG_FILE
echo "$(date) LOCAL_LAST_COMMIT: $LOCAL_LAST_COMMIT" >> $LOG_FILE
echo "$(date) REMOTE_LAST_COMMIT: $REMOTE_LAST_COMMIT" >> $LOG_FILE
echo "$(date) LOCAL_VERSION: $LOCAL_VERSION" >> $LOG_FILE
echo "$(date) REMOTE_VERSION: $REMOTE_VERSION" >> $LOG_FILE
echo "$(date): 目標分支: $TARGET_BRANCH" >> $LOG_FILE

if [ "$LOCAL_LAST_COMMIT" != "$REMOTE_LAST_COMMIT" ]; then
    echo "$(date): 發現更新，開始拉取新代碼" >> $LOG_FILE
    LOADING_MESSAGE="🔄 \`$SERVER_NAME\` is in the process of building\nVersion: $REMOTE_VERSION\nBranch: $TARGET_BRANCH\nDetails: <$WEB_URL|web>｜<$REPO_URL|repo>｜<$LAST_COMMIT_URL|commit>"
    send_slack_message "$LOADING_MESSAGE"

    if git pull origin $TARGET_BRANCH && npm install && npm run build && pm2 restart $SERVER_NAME; then
        echo "$(date): 更新完成" >> $LOG_FILE
        IS_SUCCESS=true
        IS_NOTIFICATION_NEEDED=true
    else
        echo "$(date): 更新失敗" >> $LOG_FILE
        IS_SUCCESS=false
        IS_NOTIFICATION_NEEDED=true
    fi
else
    echo "$(date): 沒有發現更新" >> $LOG_FILE
    IS_SUCCESS=true
    IS_NOTIFICATION_NEEDED=false
fi

# Info: (20241016 - Shirley) 取得腳本結束執行的時間
TIME_END=$(date +%H:%M:%S\ %m/%d/%Y)
SECONDS_END=$(date +%s)

# Info: (20241016 - Shirley) 計算執行時間（秒）
DURATION=$((SECONDS_END - SECONDS_START))
# Info: (20241016 - Shirley) 將秒數轉換為小時:分鐘:秒格式
DURATION_FORMATTED=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

echo "$(date) TIME_END (UTC): $TIME_END" >> $LOG_FILE
echo "$(date) 總執行時間: $DURATION_FORMATTED" >> $LOG_FILE

if [ "$IS_SUCCESS" = true ] && [ "$IS_NOTIFICATION_NEEDED" = true ]; then
    SUCCESS_MESSAGE="✅ \`$SERVER_NAME\` update successful!\nVersion: $REMOTE_VERSION\nBranch: $TARGET_BRANCH\nDuration: $DURATION_FORMATTED\nDetails: <$WEB_URL|web>｜<$REPO_URL|repo>｜<$LAST_COMMIT_URL|commit>"
    send_slack_message "$SUCCESS_MESSAGE"
else 
    if [ "$IS_SUCCESS" = false ] && [ "$IS_NOTIFICATION_NEEDED" = true ]; then
        FAILED_MESSAGE="❌ \`$SERVER_NAME\` failed to build!\nVersion: $REMOTE_VERSION\nBranch: $TARGET_BRANCH\nDuration: $DURATION_FORMATTED\nDetails: <$WEB_URL|web>｜<$REPO_URL|repo>｜<$LAST_COMMIT_URL|commit>"
        send_slack_message "$FAILED_MESSAGE"
    fi
fi

echo "$(date): 檢查更新結束" >> $LOG_FILE
echo "----------------------------" >> $LOG_FILE