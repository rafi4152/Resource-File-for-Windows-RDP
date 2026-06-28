Full Step:-

git clone https://github.com/rafi4152/Resource-File-for-Windows-RDP.git
cd Resource-File-for-Windows-RDP


docker build --no-cache -t windows11-pro-vm .


docker run -it --rm \
  --device /dev/kvm \
  -e MEMORY=14G \
  -e CPU_CORES=4 \
  -p 6080:6080 \
  -p 3389:3389 \
  -v windows_data:/data \
  -v windows_iso:/iso \
  windows11-pro-vm




  # 🚀 Windows 11 Pro VM on GitHub Codespaces

Run a Windows 11 Pro virtual machine inside Docker using QEMU + KVM with noVNC and RDP support.

## ✨ Features

- ✅ Windows 11 Pro
- ✅ UEFI (OVMF)
- ✅ TPM 2.0 (swtpm)
- ✅ QEMU + KVM Acceleration
- ✅ noVNC Web Access
- ✅ Microsoft Remote Desktop (RDP)
- ✅ 4 CPU Cores (Default)
- ✅ 14 GB RAM (Default)
- ✅ 150 GB Virtual Disk
- ✅ Persistent Storage
- ✅ Optimized for GitHub Codespaces

---

# Requirements

- GitHub Codespaces
- Docker
- KVM Support (Recommended)
- Official Windows 11 Pro ISO

Rename the ISO to:

```
Win11_Pro.iso
```

Place it inside:

```
/iso
```

---

# Clone Repository

```bash
git clone https://github.com/rafi4152/Resource-File-for-Windows-RDP.git

cd Resource-File-for-Windows-RDP
```

---

# Build Docker Image

```bash
docker build --no-cache -t windows11-pro-vm .
```

---

# Run VM

```bash
docker run -it --rm \
--device /dev/kvm \
-e MEMORY=14G \
-e CPU_CORES=4 \
-p 6080:6080 \
-p 3389:3389 \
-v windows_data:/data \
-v windows_iso:/iso \
windows11-pro-vm
```

If `/dev/kvm` is unavailable, remove:

```text
--device /dev/kvm
```

The VM will still run using software emulation, but performance will be significantly lower.

---

# Access Windows

## noVNC

```
http://localhost:6080
```

or your forwarded Codespaces URL.

---

## Remote Desktop

After Windows installation:

```
Address:
localhost:3389
```

Or use your forwarded GitHub Codespaces RDP port.

---

# Default Configuration

| Component | Value |
|-----------|-------|
| OS | Windows 11 Pro |
| CPU | 4 Cores |
| RAM | 14 GB |
| Disk | 150 GB QCOW2 |
| Firmware | UEFI |
| TPM | TPM 2.0 |
| Display | noVNC |
| Remote | RDP |

---

# Persistent Volumes

Windows Disk

```
/data
```

Windows ISO

```
/iso
```

---

# Port Forwarding

| Port | Service |
|-------|----------|
| 6080 | noVNC |
| 3389 | Remote Desktop |

---

# Performance Tips

- Enable KVM whenever available.
- Allocate 14 GB RAM.
- Use 4 CPU cores.
- Install VirtIO drivers for better storage and network performance.
- Install the latest QEMU Guest Agent after Windows setup.
- Enable Remote Desktop after installation.

---

# Notes

- Windows ISO is **not included**.
- Use your own legally licensed Windows 11 Pro ISO.
- First boot may take several minutes.
- Windows installation is completed through noVNC.
- After installation, use Microsoft Remote Desktop for the best experience.

---

# License

This repository provides Docker and QEMU configuration only.

Windows is the property of Microsoft and is **not distributed** with this repository.
