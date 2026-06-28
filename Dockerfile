FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV ISO_PATH="/iso/Win11_Pro.iso"

# Faster / more stable mirrors for Codespaces Asia region
RUN sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' \
    -e 's|http://security.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' \
    /etc/apt/sources.list || true

RUN apt-get update -o Acquire::Retries=5 && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    ovmf \
    swtpm \
    novnc \
    websockify \
    wget \
    curl \
    net-tools \
    unzip \
    python3 \
    ca-certificates \
    xz-utils \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data /iso /novnc /tpm

# noVNC files
RUN wget -q https://github.com/novnc/noVNC/archive/refs/heads/master.zip -O /tmp/novnc.zip && \
    unzip -q /tmp/novnc.zip -d /tmp && \
    mv /tmp/noVNC-master/* /novnc/ && \
    rm -rf /tmp/novnc.zip /tmp/noVNC-master

RUN cat > /start.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="${ISO_PATH:-/iso/Win11_Pro.iso}"
DISK_PATH="/data/win11-pro.qcow2"
TPM_STATE_DIR="/tpm"

MEMORY="${MEMORY:-14G}"
SMP_CORES="${CPU_CORES:-4}"

OVMF_CODE_FILE=""
OVMF_VARS_TEMPLATE=""

echo "== Detecting KVM =="
if [ -e /dev/kvm ]; then
  echo "KVM available"
  KVM_ARG="-enable-kvm"
  MACHINE_ARG="-machine q35,accel=kvm:tcg"
  CPU_ARG="-cpu host,hv_relaxed=on,hv_vapic=on,hv_time=on,hv_spinlocks=0x1fff"
else
  echo "KVM not available, using TCG fallback"
  KVM_ARG=""
  MACHINE_ARG="-machine q35,accel=tcg"
  CPU_ARG="-cpu qemu64"
fi

echo "== Locating OVMF files =="
for f in \
  /usr/share/OVMF/OVMF_CODE_4M.secboot.fd \
  /usr/share/OVMF/OVMF_CODE.secboot.fd \
  /usr/share/OVMF/OVMF_CODE_4M.fd \
  /usr/share/OVMF/OVMF_CODE.fd
do
  if [ -f "$f" ]; then
    OVMF_CODE_FILE="$f"
    break
  fi
done

for f in \
  /usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/OVMF/OVMF_VARS.fd
do
  if [ -f "$f" ]; then
    OVMF_VARS_TEMPLATE="$f"
    break
  fi
done

if [ -z "$OVMF_CODE_FILE" ] || [ -z "$OVMF_VARS_TEMPLATE" ]; then
  echo "OVMF files not found"
  exit 1
fi

if [ ! -f "$ISO_PATH" ]; then
  echo "Windows 11 ISO not found at: $ISO_PATH"
  echo "Put your official Windows 11 Pro ISO there and name it Win11_Pro.iso"
  exit 1
fi

echo "== Creating virtual disk if missing =="
if [ ! -f "$DISK_PATH" ]; then
  qemu-img create -f qcow2 "$DISK_PATH" 150G
fi

echo "== Preparing UEFI vars =="
if [ ! -f /data/OVMF_VARS.fd ]; then
  cp "$OVMF_VARS_TEMPLATE" /data/OVMF_VARS.fd
fi

echo "== Starting TPM emulator =="
mkdir -p "$TPM_STATE_DIR"
swtpm socket \
  --tpm2 \
  --tpmstate dir="$TPM_STATE_DIR" \
  --ctrl type=unixio,path="$TPM_STATE_DIR/swtpm-sock" \
  --daemon

echo "== Starting QEMU =="
qemu-system-x86_64 \
  $KVM_ARG \
  $MACHINE_ARG \
  $CPU_ARG \
  -m "$MEMORY" \
  -smp "$SMP_CORES",sockets=1,cores="$SMP_CORES",threads=1 \
  -rtc base=utc,clock=host \
  -device qemu-xhci \
  -device usb-tablet \
  -vga std \
  -boot order=d,menu=on \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE_FILE" \
  -drive if=pflash,format=raw,file=/data/OVMF_VARS.fd \
  -chardev socket,id=chrtpm,path="$TPM_STATE_DIR/swtpm-sock" \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0 \
  -drive file="$DISK_PATH",format=qcow2,if=ide \
  -cdrom "$ISO_PATH" \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  -device e1000,netdev=net0 \
  -display vnc=:0 \
  -serial mon:stdio \
  -name "Windows11_Pro_VM" &

echo "== Starting noVNC =="
sleep 5
websockify --web /novnc 6080 localhost:5900 &

echo "===================================================="
echo "noVNC: http://localhost:6080"
echo "RDP:   localhost:3389"
echo "RAM:   14G default"
echo "CPU:   4 cores default"
echo "===================================================="

tail -f /dev/null
EOF

RUN chmod +x /start.sh

VOLUME ["/data", "/iso"]
EXPOSE 6080 3389
CMD ["/start.sh"]
