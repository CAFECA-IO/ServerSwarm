#!/bin/sh
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]' 
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "GET", "POST"]'

# Info: (20240902 - Jacky) Ensure the environment variable is set
if [ -z "$SWARM_KEY" ]; then
  echo "KEY environment variable is not set."
  exit 1
fi

# Info: (20240902 - Jacky) Create the file in /data/ipfs directory
cat <<EOF > /data/ipfs/swarm.key
/key/swarm/psk/1.0.0/
/base16/
$SWARM_KEY
EOF

echo "swarm.key created successfully at /data/ipfs/swarm.key"

# Info: (20240902 - Jacky) Clean up the bootstrap list
ipfs bootstrap rm --all

# Info: (20240902 - Jacky) Ensure the environment variable is set
if [ -z "$BOOTSTRAP_NODES" ]; then
  echo "BOOTSTRAP_NODES environment variable is not set."
  exit 1
fi

# Info: (20240902 - Jacky) Add the bootstrap nodes
for node in $BOOTSTRAP_NODES; do
  ipfs bootstrap add "$node"
done

echo "All bootstrap nodes added successfully."

ipfs daemon