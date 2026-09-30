#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# TravelUAV NYC dataset + closeloop simulator downloader
# ============================================================

# !!!!! 按你的实际项目根目录修改 !!!!!
TRAVEL_ROOT="$HOME/Exp/OpenUAV"

# 如果你实际项目目录就是 OpenUAV，则改成：
# TRAVEL_ROOT="/root/autodl-tmp/OpenUAV"

DOWNLOAD_ROOT="$HOME/Downloads"

RAW_DL="${DOWNLOAD_ROOT}/TravelUAV_NYC"
ENV_DL="${DOWNLOAD_ROOT}/TravelUAV_env"

TRAIN_ROOT="${TRAVEL_ROOT}/data/train_dataset"
ENV_ROOT="${TRAVEL_ROOT}/envs"

HFD="${HOME}/hfd.sh"

export HF_ENDPOINT="https://hf-mirror.com"


echo "============================================================"
echo "TravelUAV NYC data installer"
echo
echo "TRAVEL_ROOT = ${TRAVEL_ROOT}"
echo "RAW_DL      = ${RAW_DL}"
echo "ENV_DL      = ${ENV_DL}"
echo "============================================================"


# ============================================================
# 0. Dependencies
# ============================================================

echo
echo ">>> [0/6] Installing tools..."

# sudo apt-get update
# sudo apt-get install -y \
#  aria2 \
#    jq \
#    p7zip-full

if [ ! -f "${HFD}" ]; then
    echo "Downloading hfd.sh..."
    wget https://hf-mirror.com/hfd/hfd.sh -O "${HFD}"
    chmod +x "${HFD}"
fi

echo
echo "jq:"
jq --version

echo
echo "7z:"
7z | head -3 || true


# ============================================================
# 1. Prepare directories
# ============================================================

echo
echo ">>> [1/6] Preparing directories..."

mkdir -p \
    "${RAW_DL}" \
    "${ENV_DL}" \
    "${TRAIN_ROOT}" \
    "${ENV_ROOT}"

df -h $HOME


# ============================================================
# 2. Download NYC raw dataset
# ============================================================

echo
echo ">>> [2/6] Downloading NYCEnvironmentMegapa raw dataset..."

"${HFD}" \
    wangxiangyu0814/TravelUAV \
    --dataset \
    --include 'NYCEnvironmentMegapa.*' \
    --local-dir "${RAW_DL}" \
    --tool aria2c \
    -x 8 \
    -j 4


echo
echo "NYC archive files:"
ls -lh "${RAW_DL}"/NYCEnvironmentMegapa.*


# ============================================================
# 3. Download closeloop simulator
# ============================================================

echo
echo ">>> [3/6] Downloading closeloop environments..."

"${HFD}" \
    wangxiangyu0814/TravelUAV_env \
    --dataset \
    --include 'closeloop_envs.*' 'carla_town_envs.*' \
    --local-dir "${ENV_DL}" \
    --tool aria2c \
    -x 8 \
    -j 4


echo
echo "closeloop archive files:"
ls -lh "${ENV_DL}"/closeloop_envs.*


# ============================================================
# 4. Test archives BEFORE extraction
# ============================================================

echo
echo ">>> [4/6] Testing multipart archives..."

echo
echo "Testing NYC dataset archive..."

7z t \
    "${RAW_DL}/NYCEnvironmentMegapa.zip"


echo
echo "Testing closeloop simulator archive..."

7z t \
    "${ENV_DL}/closeloop_envs.zip"


# ============================================================
# 5. Extract
# ============================================================

echo
echo ">>> [5/6] Extracting NYC dataset..."

7z x \
    -y \
    -o"${TRAIN_ROOT}" \
    "${RAW_DL}/NYCEnvironmentMegapa.zip"


echo
echo ">>> Extracting closeloop simulator..."

7z x \
    -y \
    -o"${ENV_ROOT}" \
    "${ENV_DL}/closeloop_envs.zip"


# ============================================================
# 6. Verify
# ============================================================

echo
echo ">>> [6/6] Verifying..."

echo
echo "========== NYC Dataset =========="

if [ -d "${TRAIN_ROOT}/NYCEnvironmentMegapa" ]; then
    echo "[OK] ${TRAIN_ROOT}/NYCEnvironmentMegapa"
else
    echo "[ERROR] NYCEnvironmentMegapa directory not found!"
fi

find \
    "${TRAIN_ROOT}/NYCEnvironmentMegapa" \
    -name mark.json \
    | head -10 || true


echo
echo "========== Simulator =========="

if [ -d "${ENV_ROOT}/closeloop_envs" ]; then
    echo "[OK] ${ENV_ROOT}/closeloop_envs"
else
    echo "[ERROR] closeloop_envs directory not found!"
fi

ls -lh "${ENV_ROOT}/closeloop_envs" | head -30 || true

chmod +x \
    "${ENV_ROOT}/closeloop_envs/"*.sh \
    2>/dev/null || true


echo
echo "========== Important files =========="

ls -lh \
    "${ENV_ROOT}/closeloop_envs/NYCEnvironmentMegapa.sh" \
    2>/dev/null || true

echo
echo "========== Disk usage =========="

du -sh \
    "${TRAIN_ROOT}/NYCEnvironmentMegapa" \
    "${ENV_ROOT}/closeloop_envs" \
    2>/dev/null || true

df -h /root/autodl-tmp


echo
echo "============================================================"
echo "TravelUAV NYC data preparation finished."
echo "============================================================"