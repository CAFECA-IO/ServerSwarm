#!/bin/bash

# (20240822 - Jacky)下載模型的函數
download_model() {
    local model_name=$1
    echo "Downloading model: $model_name"
    ollama pull $model_name
}

# Info: (20240822 - Jacky) 啟動 ollama 的 serve
/bin/ollama serve &

# Info: (20240822 - Jacky) 等待 serve 啟動
sleep 5

IFS=',' read -r -a models <<< "$MODEL_LIST"

# (20240822 - Jacky)遍歷所有環境變數，篩選出以 _MODEL 結尾的變數
for model_name in "${models[@]}"; do
    if [ -n "$model_name" ]; then
        download_model "$model_name"
    fi
done

# Info: (20240822 - Jacky) 保持容器運行，直到手動停止
wait
