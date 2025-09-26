#!/bin/bash
# TODO: (20250207 - Shirley) The API version `v2` needs to be obtained from the API instead of hardcoding; or the version API does not need the `v2` prefix
LOG_FILE="${LOG_FILE}"
SLACK_BOT_URL="${SLACK_BOT_URL}"
TARGET_BRANCH="${TARGET_BRANCH}"
SERVER_NAME="${SERVER_NAME}"
APP_PATH="${APP_PATH}"
WEB_URL="${WEB_URL}"
BASE_REPO_URL="${BASE_REPO_URL}"
PORT="${PORT}" 

REPO_URL="$BASE_REPO_URL/tree/$TARGET_BRANCH"

IS_SUCCESS=false
IS_NOTIFICATION_NEEDED=false

# Info: (20241016 - Shirley) Get the script start time in the format HH:MM:SS MONTH/DAY/YEAR
TIME_START=$(date +%H:%M:%S\ %m/%d/%Y)
SECONDS_START=$(date +%s)

# Info: (20241016 - Shirley) Function to send Slack messages
send_slack_message() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" "$SLACK_BOT_URL"
}

# Info: (20241016 - Shirley) Install jq to parse package.json
if ! command -v jq &> /dev/null; then
    apt-get update && apt-get install -y jq
fi

# Info: (20241016 - Shirley) Ensure the log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Info: (20241016 - Shirley) If the log file does not exist, create it
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "$(date): Log file created" >> "$LOG_FILE"
fi

# Info: (20241016 - Shirley) Log the start of the script execution
echo "$(date): Starting update check" >> "$LOG_FILE"

# Info: (20241016 - Shirley) Enter the app directory
cd "$APP_PATH" || { echo "Cannot enter application directory: $APP_PATH" >> "$LOG_FILE"; exit 1; }

# Info: (20250207 - Shirley) Confirm the current directory is a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "$(date): Error - Current directory is not a git repository" >> "$LOG_FILE"
    exit 1
fi

# Info: (20250207 - Shirley) Switch branch
if ! git checkout "$TARGET_BRANCH"; then
    echo "$(date): Error - Cannot switch to branch $TARGET_BRANCH" >> "$LOG_FILE"
    exit 1
fi

# Info: (20241016 - Shirley) Fetch remote updates
if ! git fetch origin 2>>"$LOG_FILE"; then
    echo "Cannot fetch remote updates, please check network connection or repository permissions" >> "$LOG_FILE"
    exit 1
fi

LOCAL_LAST_COMMIT=$(git rev-parse HEAD)
REMOTE_LAST_COMMIT=$(git rev-parse origin/"$TARGET_BRANCH")

LAST_COMMIT_URL="$BASE_REPO_URL/commit/$REMOTE_LAST_COMMIT"

LOCAL_VERSION=$(jq -r .version package.json)
REMOTE_VERSION=$(git show origin/"$TARGET_BRANCH":package.json | jq -r .version)

echo "$(date) TIME_START (UTC): $TIME_START" >> "$LOG_FILE"
echo "$(date) LOCAL_LAST_COMMIT: $LOCAL_LAST_COMMIT" >> "$LOG_FILE"
echo "$(date) REMOTE_LAST_COMMIT: $REMOTE_LAST_COMMIT" >> "$LOG_FILE"
echo "$(date) LOCAL_VERSION: $LOCAL_VERSION" >> "$LOG_FILE"
echo "$(date) REMOTE_VERSION: $REMOTE_VERSION" >> "$LOG_FILE"
echo "$(date): Target branch: $TARGET_BRANCH" >> "$LOG_FILE"

if [ "$LOCAL_LAST_COMMIT" != "$REMOTE_LAST_COMMIT" ]; then
    echo "$(date): Update found, pulling new code" >> "$LOG_FILE"
    LOADING_MESSAGE="🔄 \`$SERVER_NAME\` is building\nVersion: $REMOTE_VERSION\nBranch: $TARGET_BRANCH\nDetails: <$WEB_URL|web>｜<$REPO_URL|repo>｜<$LAST_COMMIT_URL|commit>"
    send_slack_message "$LOADING_MESSAGE"

    # Info: (20250210 - Shirley) Calculate build time
    SECONDS_BUILD_START=$(date +%s)

    # Info: (20241021 - Shirley) Handle conflicting branch scenarios
    # git config pull.rebase false

    {
        git pull origin "$TARGET_BRANCH" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo "git pull failed" >> "$LOG_FILE"
            exit 1
        fi

        npm install >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo "npm install failed" >> "$LOG_FILE"
            exit 1
        fi

        npm run build >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo "npm run build failed" >> "$LOG_FILE"
            exit 1
        fi

        pm2 restart "$SERVER_NAME" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo "pm2 restart failed" >> "$LOG_FILE"
            exit 1
        fi
    }

    SECONDS_BUILD_END=$(date +%s)
    DURATION_BUILD=$(( SECONDS_BUILD_END - SECONDS_BUILD_START ))
    DURATION_BUILD_FORMATTED=$(printf '%02d:%02d:%02d' $((DURATION_BUILD/3600)) $((DURATION_BUILD%3600/60)) $((DURATION_BUILD%60)))

    echo "$(date) Build duration: $DURATION_BUILD_FORMATTED" >> "$LOG_FILE"

    # Info: (20250210 - Shirley) Start waiting and confirm if the website update was successful
    SECONDS_WAIT_START=$(date +%s)
    MAX_RETRIES=12         # Maximum number of retries (e.g., retry every 10 seconds, up to 12 times = 120 seconds)
    RETRY_INTERVAL=10      # Interval between retries (seconds)
    CURRENT_RETRY=0

    while [ $CURRENT_RETRY -lt $MAX_RETRIES ]; do
        # Info: (20250210 - Shirley) Get website version number
        API_RESPONSE=$(curl -s "http://localhost:$PORT/api/v2/status_info")
        SITE_VERSION=$(echo "$API_RESPONSE" | jq -r '.powerby' | grep -oP 'iSunFA \K[^ ]+' | sed 's/^v//')
        echo "$(date): Website version number: $SITE_VERSION" >> "$LOG_FILE"

        if [ "$SITE_VERSION" = "$REMOTE_VERSION" ]; then
            echo "Website version matches package.json" >> "$LOG_FILE"
            IS_SUCCESS=true
            break
        else
            echo "Website version does not match package.json, waiting for next check..." >> "$LOG_FILE"
            sleep $RETRY_INTERVAL
            CURRENT_RETRY=$((CURRENT_RETRY + 1))
        fi
    done

    if [ "$IS_SUCCESS" = false ]; then
        echo "Failed to confirm website version number, please refer to the log file for details." >> "$LOG_FILE"
        IS_NOTIFICATION_NEEDED=true
        exit 1
    fi

    SECONDS_WAIT_END=$(date +%s)
    DURATION_WAIT=$(( SECONDS_WAIT_END - SECONDS_WAIT_START ))
    DURATION_WAIT_FORMATTED=$(printf '%02d:%02d:%02d' $((DURATION_WAIT/3600)) $((DURATION_WAIT%3600/60)) $((DURATION_WAIT%60)))

    echo "$(date) Wait duration: $DURATION_WAIT_FORMATTED" >> "$LOG_FILE"

    # Info: (20250210 - Shirley) Total execution time
    DURATION_TOTAL=$(( SECONDS_WAIT_END - SECONDS_BUILD_START ))
    DURATION_TOTAL_FORMATTED=$(printf '%02d:%02d:%02d' $((DURATION_TOTAL/3600)) $((DURATION_TOTAL%3600/60)) $((DURATION_TOTAL%60)))
    echo "$(date) Total execution time: $DURATION_TOTAL_FORMATTED" >> "$LOG_FILE"

    echo "$(date): Update completed" >> "$LOG_FILE"
    IS_NOTIFICATION_NEEDED=true
else
    echo "$(date): No updates found" >> "$LOG_FILE"
    IS_SUCCESS=true
    IS_NOTIFICATION_NEEDED=false
fi

# Info: (20241016 - Shirley) Get the script end time
TIME_END=$(date +%H:%M:%S\ %m/%d/%Y)
SECONDS_END=$(date +%s)

# Info: (20241016 - Shirley) Calculate execution time (seconds)
DURATION=$((SECONDS_END - SECONDS_START))
# Info: (20241016 - Shirley) Convert seconds to HH:MM:SS format
DURATION_FORMATTED=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

echo "$(date) TIME_END (UTC): $TIME_END" >> "$LOG_FILE"
echo "$(date) Total execution time: $DURATION_TOTAL_FORMATTED" >> "$LOG_FILE"
echo "----------------------------" >> "$LOG_FILE"

if [ "$IS_SUCCESS" = true ] && [ "$IS_NOTIFICATION_NEEDED" = true ]; then
    SUCCESS_MESSAGE="✅ \`$SERVER_NAME\` update successful!\nVersion: $REMOTE_VERSION\nBranch: $TARGET_BRANCH\nDuration: $DURATION_TOTAL_FORMATTED (Build: $DURATION_BUILD_FORMATTED + Wait: $DURATION_WAIT_FORMATTED)\nDetails: <$WEB_URL|web>｜<$REPO_URL|repo>｜<$LAST_COMMIT_URL|commit>"
    send_slack_message "$SUCCESS_MESSAGE"
else 
    if [ "$IS_SUCCESS" = false ] && [ "$IS_NOTIFICATION_NEEDED" = true ]; then
        FAILED_MESSAGE="❌ \`$SERVER_NAME\` build failed!\nVersion: $REMOTE_VERSION\nBranch: $TARGET_BRANCH\nDuration: $DURATION_TOTAL_FORMATTED (Build: $DURATION_BUILD_FORMATTED + Wait: $DURATION_WAIT_FORMATTED)\nDetails: <$WEB_URL|web>｜<$REPO_URL|repo>｜<$LAST_COMMIT_URL|commit>"
        send_slack_message "$FAILED_MESSAGE"
    fi
fi
