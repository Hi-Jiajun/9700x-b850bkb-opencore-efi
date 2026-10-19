# 9700X / B850BKB / RTX 5060 — OpenCore 1.0.9 EFI 参考

一台 AMD AM5 桌面机跑 **macOS 15.8.1 (24H32)** 的 OpenCore 配置参考。

> 这不是可以直接开机的 EFI。`config.plist` 里的 SMBIOS 四项已换成占位值，
> Apple 自有 kext 与所有第三方二进制都没有随仓库分发。用法见下面「怎么用」。

本快照的 `config.plist` 已用 OpenCore 1.0.9 的 `ocvalidate` 校验：
**No issues found**（脱敏替换四项后同样通过）。

## 实测状态（2026-10-19 20:37）

下面只写本次取证能拿出证据的状态，未验证的项目不列。

| 功能 | 状态 | 证据 |
| --- | --- | --- |
| 显卡 | ✅ 正常 | RTX 5060 8 GB，`Metal 3`，输出 3840×2160@160 Hz |
| 有线网卡 | ✅ 正常 | `en0` UP，RTL8125，`192.168.1.204` |
| Wi-Fi | ⚠️ 驱动在、无线电关 | `AirportMtk 0.1.0`（fw MT7922）加载，`en1` 存在，`Wi-Fi Power: Off` |
| 蓝牙 | ❌ 本次未工作 | `State: Off`、`Address: NULL`；`SimpleMtkBtPatcher` 已加载但未匹配 |
| 音频 | ✅ 多路输出 | 内置扬声器/麦克风、数字输出、HDMI（Mi Monitor）、USB HECATE G2000 |
| USB | ✅ 正常 | 4 个 XHCI 控制器，10 Gb/s 设备可枚举，`UTBMap` 生效 |

取证命令：`system_profiler SPDisplaysDataType/SPAudioDataType/SPAirPortDataType/SPBluetoothDataType`、
`networksetup -getairportpower en1`、`kextstat -l`、`system_profiler SPUSBDataType`。

## 硬件

| 部件 | 型号 |
| --- | --- |
| CPU | AMD Ryzen 7 9700X（8C/16T） |
| 主板 | MAXSUN MS-Terminator B850BKB WIFI（AMI BIOS E2.4D） |
| 显卡 | NVIDIA GeForce RTX 5060（`10DE:2D05`，Blackwell） |
| 内存 | 48 GB |
| 有线网卡 | Realtek RTL8125 2.5GbE（`10EC:8125`） |
| 无线/蓝牙 | MediaTek MT7922（RZ616） |
| 系统盘 | ZHITAI TiPro9000 2TB NVMe |
| 引导 | OpenCore 1.0.9（`REL-109-2026-09-30`），SMBIOS `MacPro7,1` |

## 目录

| 路径 | 内容 |
| --- | --- |
| `EFI/OC/config.plist` | 脱敏后的 OpenCore 配置（可直接对照结构） |
| `EFI/OC/ACPI/*.aml` | 5 张 SSDT（EC、USB、USBX、CPU 拓扑、禁用 GPP7 网口） |
| `EFI/OC/Kexts/MANIFEST.tsv` | kext 版本、bundle id、是否启用、来源 |
| `EFI/OC/Drivers/MANIFEST.tsv` | UEFI 驱动清单与 SHA-256 |
| `docs/VERSIONS.md` | 由私有快照生成的版本矩阵 |
| `docs/HARDWARE.md` | 硬件与三条自研适配线的说明 |
| `docs/BIOS.md` | BIOS 必改项 |
| `docs/SANITIZATION.md` | 哪些字段被脱敏、为什么不能直接开机 |
| `SNAPSHOT.json` | 快照元数据（配置哈希、文件计数） |

## 怎么用

1. 用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 生成自己的 `MacPro7,1` 三项：
   `SystemSerialNumber`、`MLB`、`SystemUUID`；`ROM` 填本机有线网卡的 6 字节 MAC（或随机 6 字节）。
2. 按 `docs/VERSIONS.md` 的「Source / license」列，从各上游下载对应版本的 kext 与驱动。
   注意 `IO80211FamilyLegacy.kext`、`IOSkywalkFamily.kext`、`HfsPlus.efi` 是 Apple 的文件，
   本仓库不提供，需要从自己的 macOS/OpenCore 发行包里取。
3. 把 `EFI/` 放到 ESP 的根目录，先在一支 U 盘上试启动。
4. 改完配置跑 `ocvalidate`（OpenCore 1.0.9），要求 `No issues found`。

`scripts/verify.sh` 会检查占位值是否还在、目录结构是否齐全、是否误放了二进制。

## 这套配置里有什么特别的

- **NVIDIA RTX 5060**：走 [NullMoth](https://github.com/nullmoth) 的 NVMTL/NVK 驱动，
  不是 Apple 官方显卡路径；能力与稳定性以该项目为准。
- **MT7922 WiFi**：`AirportMtk`（基于 AirportItlwm 的 GPLv2 本地构建）+
  `IOSkywalkFamily` + `IO80211FamilyLegacy`。
- **MT7922 蓝牙**：`SimpleMtkBtFw` + `SimpleMtkBtPatcher` + `BlueToolFixup`。
- **USB**：`USBToolBox` + 本机端口映射 `UTBMap.kext`；`UTBDefault.kext` 保留但禁用。
- **音频**：`AppleALC` + NullMoth `NMHDA`（HDMI 音频）；`DeviceProperties` 注入 `layout-id=2`，
  `boot-args` 另带 `alcid=3`。`NMHDALink` / `NMHDAVol` / `NMProbeAudio` 保持禁用。
- **NVRAM**：AM5 平台固件写入脆弱，`Booter/Quirks/DisableVariableWrite` 保持 `true`。

## 已知限制

- 目标系统是 macOS 15.x；macOS 26 起 `AppleHDA` 被移除、SMBIOS 门槛提高，本配置不能直接照搬。
- `boot-args` 是开发态：带 `-v`、`debug=0x100`、`keepsyms=1`、`gfxrst=4` 和一整套 MT7922 调试开关。
- 本次取证时 Wi-Fi 无线电是关闭的；蓝牙控制器没有起来。这两项不要按"已工作"理解。
- 双系统机器改动 ESP 会同时影响 Windows 与 macOS 的引导，操作前先整份备份 ESP。

## 许可

本仓库里的文档、配置与 ACPI 表以 MIT 发布（见 `LICENSE`）。清单里列出的第三方 kext
各自保留原许可证，二进制不在本仓库内。
