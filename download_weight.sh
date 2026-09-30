#!/usr/bin/env bash

set -e

BASE_DIR="${BASE_DIR:-"$HOME/Exp"}"
TRAVEL_ROOT="${BASE_DIR}/OpenUAV"

LLAMA_ROOT="${TRAVEL_ROOT}/Model/LLaMA-UAV"

MODEL_ZOO="${LLAMA_ROOT}/model_zoo"
LAVIS_DIR="${MODEL_ZOO}/LAVIS"
WORK_DIR="${LLAMA_ROOT}/work_dirs"

HF_ENDPOINT="https://hf-mirror.com"
HFD="${HOME}/hfd.sh"

export HF_ENDPOINT


echo "============================================================"
echo " TravelUAV Model Downloader"
echo "============================================================"


# ============================================================
# Prepare directories
# ============================================================

mkdir -p \
    "${MODEL_ZOO}" \
    "${LAVIS_DIR}" \
    "${WORK_DIR}" \
    "${TRAVEL_ROOT}/downloads"


# ============================================================
# 1. Vicuna-7B-v1.5
# ============================================================

echo
echo ">>> [1/6] Vicuna-7B-v1.5"

"${HFD}" \
    lmsys/vicuna-7b-v1.5 \
    --local-dir "${MODEL_ZOO}/vicuna-7b-v1.5" \
    --tool aria2c \
    -x 8 \
    -j 4


# ============================================================
# 2. EVA-ViT-G
#
# Official LLaMA-UAV README points to Google Storage,
# therefore use aria2c directly rather than hfd.
# ============================================================

echo
echo ">>> [2/6] EVA-ViT-G"

aria2c \
    -c \
    -x 8 \
    -s 8 \
    -k 1M \
    -d "${LAVIS_DIR}" \
    -o eva_vit_g.pth \
    "https://storage.googleapis.com/sfr-vision-language-research/LAVIS/models/BLIP2/eva_vit_g.pth"


# ============================================================
# 3. InstructBLIP QFormer Vicuna-7B
# ============================================================

echo
echo ">>> [3/6] QFormer-7B"

aria2c \
    -c \
    -x 8 \
    -s 8 \
    -k 1M \
    -d "${LAVIS_DIR}" \
    -o instruct_blip_vicuna7b_trimmed.pth \
    "https://storage.googleapis.com/sfr-vision-language-research/LAVIS/models/InstructBLIP/instruct_blip_vicuna7b_trimmed.pth"


# ============================================================
# 4. LLaMA-UAV checkpoint
# ============================================================

echo
echo ">>> [4/6] LLaMA-UAV checkpoint"

"${HFD}" \
    wangxiangyu0814/llama-uav-7b \
    --local-dir \
    "${WORK_DIR}/llama-vid-7b-pretrain-224-uav-full-data-lora32" \
    --tool aria2c \
    -x 8 \
    -j 4


# ============================================================
# 5. Trajectory Completion checkpoint
# ============================================================

echo
echo ">>> [5/6] Trajectory Completion Model"

"${HFD}" \
    wangxiangyu0814/traveluav-traj-model \
    --local-dir \
    "${WORK_DIR}/traj_predictor_bs_128_drop_0.1_lr_5e-4" \
    --tool aria2c \
    -x 8 \
    -j 4


# ============================================================
# 6. GroundingDINO
# ============================================================

echo
echo ">>> [6/6] GroundingDINO"

DINO_TMP="${TRAVEL_ROOT}/downloads/GroundingDINO"

"${HFD}" \
    ShilongLiu/GroundingDINO \
    --include "groundingdino_swint_ogc.pth" \
    --local-dir "${DINO_TMP}" \
    --tool aria2c \
    -x 8 \
    -j 2

mkdir -p \
    "${TRAVEL_ROOT}/src/model_wrapper/utils/GroundingDINO"

cp -f \
    "${DINO_TMP}/groundingdino_swint_ogc.pth" \
    "${TRAVEL_ROOT}/src/model_wrapper/utils/GroundingDINO/groundingdino_swint_ogc.pth"


echo
echo "============================================================"
echo " Download completed."
echo "============================================================"