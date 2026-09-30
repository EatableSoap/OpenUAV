#!/usr/bin/env bash

set -e

# ============================================================
# TravelUAV environment bootstrap
# Ubuntu 22.04 + CUDA 11.8 + Python 3.10
# ============================================================

BASE_DIR="${BASE_DIR:$HOME/liu021/Exp}"
TRAVEL_ROOT="${BASE_DIR}/OpenUAV"

CONDA_ENV="llamauav"

HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"

HFD="${HOME}/hfd.sh"

echo "============================================================"
echo " TravelUAV Setup"
echo " BASE_DIR    = ${BASE_DIR}"
echo " TRAVEL_ROOT = ${TRAVEL_ROOT}"
echo " CONDA_ENV   = ${CONDA_ENV}"
echo "============================================================"


# ============================================================
# 0. System dependencies
# ============================================================

echo
echo ">>> [0/7] Installing system dependencies..."

apt-get update

apt-get install -y \
    git \
    git-lfs \
    curl \
    wget \
    aria2 \
    build-essential \
    ninja-build \
    cmake \
    pkg-config \
    unzip \
    ffmpeg

git lfs install


# ============================================================
# 1. Clone TravelUAV
# ============================================================

echo
echo ">>> [1/7] Cloning TravelUAV..."

mkdir -p "${BASE_DIR}"

if [ ! -d "${TRAVEL_ROOT}/.git" ]; then
    git clone https://github.com/prince687028/TravelUAV.git \
        "${TRAVEL_ROOT}"
else
    echo "TravelUAV already exists, skip clone."
fi

cd "${TRAVEL_ROOT}"


# ============================================================
# 2. Install hfd
# ============================================================

echo
echo ">>> [2/7] Installing hfd..."

if [ ! -f "${HFD}" ]; then
    wget https://hf-mirror.com/hfd/hfd.sh -O "${HFD}"
    chmod +x "${HFD}"
fi

export HF_ENDPOINT="${HF_ENDPOINT}"

echo "HF_ENDPOINT=${HF_ENDPOINT}"
"${HFD}" --help >/dev/null || true


# ============================================================
# 3. Create conda environment
# ============================================================

echo
echo ">>> [3/7] Creating conda env..."

source "$(conda info --base)/etc/profile.d/conda.sh"

if ! conda env list | awk '{print $1}' | grep -qx "${CONDA_ENV}"; then
    conda create -n "${CONDA_ENV}" python=3.10 -y
fi

conda activate "${CONDA_ENV}"

python -V

python -m pip install --upgrade \
    "pip<25" \
    "setuptools<82.0.0" \
    wheel \
    packaging


# ============================================================
# 4. PyTorch cu118
# ============================================================

echo
echo ">>> [4/7] Installing PyTorch 2.0.1 cu118..."

python -m pip install \
    torch==2.0.1 \
    torchvision==0.15.2 \
    torchaudio==2.0.2 \
    --index-url https://download.pytorch.org/whl/cu118


# ============================================================
# 5. Install LLaMA-UAV
# ============================================================

echo
echo ">>> [5/7] Installing LLaMA-UAV..."

cd "${TRAVEL_ROOT}/Model/LLaMA-UAV"

python -m pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple

python -m pip install ninja


# ============================================================
# 5.1 flash-attn
# ============================================================

echo
echo ">>> Installing flash-attn..."

if command -v nvcc >/dev/null 2>&1; then

    echo "nvcc:"
    nvcc --version

    MAX_JOBS="${MAX_JOBS:-8}" \
    python -m pip install \
        flash-attn==2.5.9.post1 \
        --no-build-isolation

else

    echo "========================================================"
    echo "WARNING: nvcc not found."
    echo "flash-attn cannot be compiled safely."
    echo "Choose an AutoDL CUDA 11.8 development image."
    echo "========================================================"

fi


# ============================================================
# 6. Root TravelUAV requirements
# ============================================================

echo
echo ">>> [6/7] Installing TravelUAV requirements..."

cd "${TRAVEL_ROOT}"

# AirSim needs numpy to exist during setup.
python -m pip install \
    numpy==1.26.3 \
    "setuptools<82.0.0" \
    wheel

# Install AirSim separately without isolated build.
python -m pip install \
    airsim==1.8.1 \
    --no-build-isolation


# requirement.txt contains:
#     airsim==1.8.1
#     flash-attn==2.5.9.post1
#
# Both are handled separately above.
grep -v -E \
    '^(airsim==|flash-attn==)' \
    requirement.txt \
    > /tmp/traveluav_requirements.txt

python -m pip install \
    -r /tmp/traveluav_requirements.txt


# ============================================================
# 6.1 Force known AirSim/msgpack compatible versions
# ============================================================

echo
echo ">>> Fixing AirSim RPC dependencies..."

python -m pip install --force-reinstall --no-cache-dir \
    msgpack==1.1.0

python -m pip install --force-reinstall --no-cache-dir --no-deps \
    msgpack-rpc-python==0.4

python -m pip install --force-reinstall --no-cache-dir \
    tornado==4.5.3


# ============================================================
# 7. Basic verification
# ============================================================

echo
echo ">>> [7/7] Verifying environment..."

python - <<'PY'
import sys
import torch
import msgpack
import airsim
import transformers
import accelerate
import bitsandbytes

print()
print("========== TravelUAV Environment ==========")
print("Python:", sys.version)
print("Torch:", torch.__version__)
print("Torch CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))
    print("Capability:", torch.cuda.get_device_capability(0))

print("Transformers:", transformers.__version__)
print("Accelerate:", accelerate.__version__)
print("msgpack:", msgpack.__version__)
print("msgpack Packer:", hasattr(msgpack, "Packer"))
print("AirSim import: OK")
print("bitsandbytes import: OK")
print("===========================================")
PY

echo
echo "Environment setup finished."