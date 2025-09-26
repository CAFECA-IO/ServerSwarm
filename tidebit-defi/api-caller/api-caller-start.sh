#!/bin/sh

# Define the API base URL and health check URL
AUTO_TRADE_URL="http://auto-trade:${AUTO_TRADE_PORT}"
TBD_BACKEND_URL="http://tidebit-defi-backend:${TBD_BACKEND_PORT}"

# Function to check if the base URL is healthy
check_health() {
  echo "Checking if the backend ($TBD_BACKEND_URL) is healthy..."
  until curl -s --fail "$TBD_BACKEND_URL" | grep -q "tbd-backend"; do
    echo "tbd-backend not ready yet. Waiting 10 seconds..."
    sleep 10
  done
  echo "Checking if the auto-trade ($AUTO_TRADE_URL) is healthy..."
  until curl -s --fail "$AUTO_TRADE_URL" | grep -q "Welcome to the auto trade!"; do
    echo "auto-trade not ready yet. Waiting 10 seconds..."
    sleep 10
  done
  echo "auto-trade is up and running."
}

# Function to create a tradebot and get its ID
create_tradebot() {
  
  # Send POST request to create a tradebot
  response=$(curl -s -X POST "$AUTO_TRADE_URL/tradebot")
  
  # Extract tradebot ID from the response using sed
  tradebot_id=$(echo "$response" | sed -n 's/.*Tradebot \([0-9a-fA-F-]\{36\}\) created.*/\1/p')
  
  if [ -z "$tradebot_id" ]; then
    echo "Failed to create tradebot or extract tradebot ID"
    exit 1
  fi

  echo "$tradebot_id"
}

# Function to send a command to the tradebot
send_command_to_tradebot() {
  local tradebot_id="$1"
  local command="$2"

  echo "Sending command '$command' to tradebot $tradebot_id..."
  
  # Send POST request with the command
  response=$(curl -s -X POST "$AUTO_TRADE_URL/tradebot/$tradebot_id" \
       -H "Content-Type: application/json" \
       -d "{\"command\":\"$command\"}")
  
  echo "Response = $response"
}

# Function to create tradebots and send commands immediately
create_and_send_commands() {
  check_health

  # Initialize the created count
  created_count=0

  for i in $(seq 1 50); do
    tradebot_id=$(create_tradebot)
    created_count=$(($created_count + 1))
    echo "Tradebot $tradebot_id created ($created_count/50)"
    # Decide which command to send based on the number of tradebots created
    if [ $created_count -le 45 ]; then
      command="run"
    else
      command="aiTrade"
    fi

    send_command_to_tradebot "$tradebot_id" "$command"
  done
}

# Execute the function
create_and_send_commands
