# 硬件与适配线

## 平台

| 项 | 值 |
| --- | --- |
| CPU | AMD Ryzen 7 9700X，8 核 16 线程，Zen 5 |
| 主板 | MAXSUN MS-Terminator B850BKB WIFI，AM5，AMI BIOS E2.4D |
| 芯片组 | B850 |
| 内存 | 48 GB |
| 显卡 | NVIDIA GeForce RTX 5060，8 GB，`10DE:2D05` |
| 有线网卡 | Realtek RTL8125 2.5GbE，`10EC:8125` |
| 无线网卡 | MediaTek MT7922（RZ616），PCIe |
| 蓝牙 | MT7922 内置 USB 蓝牙 |
| 存储 | ZHITAI TiPro9000 2TB NVMe |
| 固件 | UEFI，Secure Boot 关闭，CSM 关闭 |

## 三条非标准适配线

### 1. NVIDIA RTX 5060

Blackwell 显卡没有 Apple 官方驱动。这套 EFI 依赖 NullMoth 的 NVMTL/NVK 实现，
启动参数里带 `nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth nvfbhidpi`。
它不属于 Apple 支持范围，升级系统或驱动前先确认上游版本兼容性。

### 2. MediaTek MT7922 WiFi

macOS 15 需要 `IOSkywalkFamily` + `IO80211FamilyLegacy` 两个 Apple kext 作为底座，
再由 `AirportMtk`（GPLv2，前端派生自 AirportItlwm，HAL 派生自 OpenBSD `if_mwx`）接管。
这两个 Apple kext 不能随仓库分发，必须从自己的系统里取。

### 3. MT7922 蓝牙

`SimpleMtkBtFw`（GPL-3.0）负责固件装载，`SimpleMtkBtPatcher` 打补丁，
`BlueToolFixup` 让 BlueTool 接受非 Apple 蓝牙控制器。顺序是
`Lilu → SimpleMtkBtFw → SimpleMtkBtPatcher → BlueToolFixup`。

## 通用部分

- `VirtualSMC` + `SMCProcessor`/`SMCSuperIO` 未随仓库分发；本机 EFI 只带 `VirtualSMC` 主 kext。
- `AppleALC` 使用 `alcid=3` 驱动板载 ALC1220。
- NullMoth `NMHDA` 负责 HDMI 音频；`NMHDALink` / `NMHDAVol` / `NMProbeAudio` 为实验件，保持禁用。
- `NVMeFix` 处理 NVMe 电源管理。
- `RestrictEvents` 用于压制无关的 CPU 型号提示。
- `USBToolBox` + `UTBMap` 固化 USB 端口映射，绕开 15 端口上限。

## EFI 之外

Mellanox ConnectX-3 的 `Cx3Mlx4` 驱动装在 `/Library/Extensions`，不在这份 EFI 里；
换机或重装系统后需要单独安装。
