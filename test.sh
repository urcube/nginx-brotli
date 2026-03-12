#!/bin/bash

IMAGE_NAME="nginx-brotli-test"
CONTAINER_NAME="nginx-brotli-check"

# 1. Cleanup
sudo docker rm -f $CONTAINER_NAME > /dev/null 2>&1

# 2. Build the TESTER stage specifically
sudo docker build -q --target tester -t $IMAGE_NAME .

# 3. Syntax Test
sudo docker run --rm $IMAGE_NAME nginx -t > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Nginx config test failed."
    exit 1
fi

# 4. Header Test
# We no longer need 'apk add curl' here because it's baked into the tester stage
sudo docker run -d --name $CONTAINER_NAME $IMAGE_NAME \
    sh -c "sed -i 's/location \/ {/location \/ { brotli on; brotli_types *;/' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'" > /dev/null

sleep 2

RESPONSE=$(sudo docker exec $CONTAINER_NAME curl -I -H "Accept-Encoding: br" http://localhost 2>/dev/null)

if echo "$RESPONSE" | grep -iq "content-encoding: br"; then
    echo "SUCCESS: Brotli active."
    sudo docker stop $CONTAINER_NAME > /dev/null
    exit 0
else
    echo "FAILURE: Brotli not found."
    sudo docker stop $CONTAINER_NAME > /dev/null
    exit 1
fi