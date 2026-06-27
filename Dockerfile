FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Use a more reliable Ubuntu mirror for Codespaces / Asia regions
RUN sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' \
    -e 's|http://security.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' \
    /etc/apt/sources.list || true

RUN apt-get update -o Acquire::Retries=5 && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    novnc \
    websockify \
    wget \
    curl \
    net-tools \
    unzip \
    python3 \
    ca-certificates \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data /iso /novnc /opt/app

# noVNC
RUN wget -q https://github.com/novnc/noVNC/archive/refs/heads/master.zip -O /tmp/novnc.zip && \
    unzip -q /tmp/novnc.zip -d /tmp && \
    mv /tmp/noVNC-master/* /novnc/ && \
    rm -rf /tmp/novnc.zip /tmp/noVNC-master

ENV ISO_URL="https://archive.org/download/windows-10-lite-edition-19h2-x64/Windows%2010%20Lite%20Edition%2019H2%20x64.iso"

RUN cat > /start.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="/iso/os.iso"
DISK_PATH="/data/disk.qcow2"

echo "== Checking KVM =="
if [ -e /dev/kvm ]; then
  echo "KVM available"
  KVM_ARG="-enable-kvm"
  MACHINE_ARG="-machine q35,accel=kvm:tcg"
  CPU_ARG="-cpu host"
  MEMORY="${MEMORY:-14G}"
  SMP_CORES="${CPU_CORES:-4}"
else
  echo "KVM not available, using TCG fallback"
  KVM_ARG=""
  MACHINE_ARG="-machine q35,accel=tcg"
  CPU_ARG="-cpu qemu64"
  MEMORY="${MEMORY:-2G}"
  SMP_CORES="${CPU_CORES:-1}"
fi

echo "== Download ISO if missing =="
if [ ! -f "$ISO_PATH" ]; then
  echo "Downloading ISO..."
  curl -L --retry 5 --retry-delay 3 -o "$ISO_PATH" "$ISO_URL"
fi

echo "== Create virtual disk if missing =="
if [ ! -f "$DISK_PATH" ]; then
  echo "Creating 100G qcow2 disk..."
  qemu-img create -f qcow2 "$DISK_PATH" 100G
fi

echo "== Start QEMU =="
qemu-system-x86_64 \
  $KVM_ARG \
  $MACHINE_ARG \
  $CPU_ARG \
  -m "$MEMORY" \
  -smp "$SMP_CORES" \
  -vga std \
  -usb -device usb-tablet \
  -boot order=d,menu=on \
  -drive file="$DISK_PATH",format=qcow2,if=ide \
  -cdrom "$ISO_PATH" \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  -device e1000,netdev=net0 \
  -display vnc=:0 \
  -name "Windows10_VM" &

echo "== Start noVNC =="
sleep 5
websockify --web /novnc 6080 localhost:5900 &

echo "===================================================="
echo "VNC:  http://localhost:6080"
echo "RDP:  localhost:3389"
echo "===================================================="

tail -f /dev/null
EOF

RUN chmod +x /start.sh

VOLUME ["/data", "/iso"]
EXPOSE 6080 3389
CMD ["/start.sh"]
