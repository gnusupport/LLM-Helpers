#!/usr/bin/bash -x

# Copyright (C) 2025-01-22 by Jean M. Louis, https://gnu.support

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# go to safe directory to avoid https://github.com/ggml-org/llama.cpp/issues/11198

mkdir -p /tmp/safe/llm
cd /tmp/safe/llm

# BASE_DIR="/home/data1/protected/Programming/LLM"
# BASE_DIR="/home/data1/protected/Programming/LLM"
BASE_DIR="/mnt/data/LLM"

# Declare the models with dynamically constructed paths
declare -A MODELS=(
    ["$BASE_DIR/AllenAI/quantized/OLMo-2-1124-7B-Instruct-Q3_K_M.gguf"]=999
    ["$BASE_DIR/AllenAI/quantized/olmo-2-1124-7B-instruct-Q2_K.gguf"]=999
    ["$BASE_DIR/AllenAI/quantized/olmo-2-1124-7B-instruct-Q3_K_S.gguf"]=999
    ["$BASE_DIR/DeepSeek/quantized/DeepSeek-R1-Distill-Qwen-1.5B-Q5_K_M.gguf"]=999
    ["$BASE_DIR/Dolphin/quantized/Dolphin3.0-Qwen2.5-1.5B-Q5_K_M.gguf"]=999
    ["$BASE_DIR/Dolphin/quantized/Dolphin3.0-Qwen2.5-3B-Q5_K_M.gguf"]=999
    ["$BASE_DIR/EuroLLM/quantized/EuroLLM-1.7B-Instruct-Q4_K_M.gguf"]=999
    ["$BASE_DIR/EuroLLM/quantized/EuroLLM-9B-Instruct-Q5_K_M.gguf"]=999
    ["$BASE_DIR/IBM/quantized/granite-3.1-2b-instruct-Q4_K_M.gguf"]=999
    ["$BASE_DIR/IBM/quantized/granite-3.1-8b-instruct-Q6_K.gguf"]=999
    ["$BASE_DIR/IBM/quantized/granite-3.1-8b-instruct.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-32B-Instruct-abliterated-v2-Q4_K_M.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-32B-Instruct-abliterated-v2-Q4_K_M.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-32B-Instruct-Q5_K.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-32B-Instruct-Q4_K_M.gguf"]=999
    ["$BASE_DIR/open-thoughts/quantized/OpenThinker-32B-Q4_K_M.gguf"]=999
    ["$BASE_DIR/Microsoft/quantized/Phi-3.5-mini-instruct-Q3_K_M.gguf"]=999
    ["$BASE_DIR/Microsoft/quantized/Phi-3.5-mini-instruct-Q3_K_S.gguf"]=999
    ["$BASE_DIR/Microsoft/quantized/Phi-3.5-mini-instruct-Q6_K.gguf"]=999
    ["$BASE_DIR/Microsoft/quantized/Phi-3.5-mini-instruct-Q8_0.gguf"]=999
    ["$BASE_DIR/Microsoft/quantized/phi-4-unsloth-Q5_K_M.gguf"]=999
    ["$BASE_DIR/Microsoft/quantized/phi-4-Q6_K.gguf"]=999
    ["$BASE_DIR/Microsoft/quantized/phi-4-abliterated.Q5_K_M.gguf"]=999
    ["$BASE_DIR/qihoo360/quantized/TinyR1-32B-Preview-Q5_K_M.gguf"]=999
    ["$BASE_DIR/qihoo360/quantized/TinyR1-32B-Preview-Q4_K_M.gguf"]=999
    ["$BASE_DIR/Mistral/quantized/Ministral-3b-instruct-Q4_K_M.gguf"]=999
    ["$BASE_DIR/Mistral/quantized/Mistral-7B-v0.3-Q4_K_M.gguf"]=999
    ["$BASE_DIR/Mistral/quantized/Mistral-Small-24B-Instruct-2501.gguf-9B-Instruct-Q6_K.gguf"]=999
    ["$BASE_DIR/QwQ-LCoT-3B-Instruct.Q4_K_M.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/DeepSeek-R1-Distill-Qwen-7B-Q3_K_M.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/DeepSeek-R1-Distill-Qwen-7B-Q3_K_S.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-1.5B-Instruct.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-14B-Instruct-Q6_K.gguf"]=999
    ["$BASE_DIR/Qwen/quantized/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf"]=999
    ["$BASE_DIR/SmolLM/quantized/SmolLM-1.7B-Instruct-Q5_K_M.gguf"]=999
    ["$BASE_DIR/allenai/quantized/OLMo-2-1124-13B-Instruct-Q6_K.gguf"]=999
    ["$BASE_DIR/deepseek-ai/quantized/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"]=999
    ["$BASE_DIR/deepseek-ai/quantized/DeepSeek-R1-Distill-Qwen-32B-Q6_K.gguf"]=50
    ["$BASE_DIR/fluently-lm/quantized/FluentlyLM-Prinum.Q4_K_S.gguf"]=999
)

for model_path in "${!MODELS[@]}"; do
    # Check if the file does not exist
    if [[ ! -f "$model_path" ]]; then
        # Unset the key if the file does not exist
        unset MODELS["$model_path"]
    fi
done

LLAMA_SERVER="/usr/local/bin/llama-server"
LOG="$HOME/tmp/llm.log"

HOST=$(/home/data1/protected/bin/rcd/rcd-get-ethernet-interface.sh)

# Get the list of full model paths
model_paths=("${!MODELS[@]}")

# Check if a model name is provided as a command-line argument
if [ -n "$1" ]; then
    selected_model="$1"
    # Verify if the provided model exists in the MODELS array
    MODEL_FOUND=false
    for model_path in "${!MODELS[@]}"; do
        if [[ "$(basename "$model_path")" == "$selected_model" ]]; then
            MODEL_FOUND=true
            break
        fi
    done
    if [ "$MODEL_FOUND" = false ]; then
        echo "Error: Model '$selected_model' not found in the list."
        exit 1
    fi
else
    # Use dmenu to select a model (display only the basename of the file)
    selected_model=$(basename -a "${!MODELS[@]}" | dmenu -fn "DejaVu:pixelsize=24" -l 10 -i -b -p "Select a model:" -nf blue -nb cyan)
fi

# Check if a model was selected
if [ -z "$selected_model" ]; then
    echo "No model selected. Exiting."
    exit 1
fi

# Find the full path of the selected model
MODEL=""
for model_path in "${!MODELS[@]}"; do
    if [[ "$(basename "$model_path")" == "$selected_model" ]]; then
        MODEL="$model_path"
        break
    fi
done

# Check if the model was found
if [ -z "$MODEL" ]; then
    echo "Selected model not found in the list. Exiting."
    exit 1
fi

# Get the NGL value for the selected model
NGL=${MODELS[$MODEL]}

# Kill any running instance of llama-server
pkill llama-server

# Start the new instance of llama-server
MESSAGE="Starting Large Language Model: $(basename "$MODEL")"
espeak "$MESSAGE" &
notify-send "LLM Model" "$MESSAGE" &
echo "Selected Model: $MODEL"
echo "NGL: $NGL"
EMBEDDING_MODEL=/mnt/data/LLM/nomic-ai/quantized/nomic-embed-text-v1.5-Q8_0.gguf
$LLAMA_SERVER -ngl "$NGL" -v --log-timestamps --host "$HOST" -m "$MODEL" > "$LOG" 2>&1 &
$LLAMA_SERVER -ngl "$NGL" -v -c 8192 -ub 8192 --embedding --log-timestamps --host "$HOST" --port 9999 -m "$EMBEDDING_MODEL" > "$LOG" 2>&1 &
pgrep -a llama-server
sleep 3
firefox "http://$HOST:8080"
