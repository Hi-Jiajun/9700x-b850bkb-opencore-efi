# 脱敏说明

公开仓库由私有仓库的脚本生成，不是手工维护的第二份真值。

## 被替换的字段

只改 `PlatformInfo → Generic` 里的四项：

| 字段 | 公开值 |
| --- | --- |
| `SystemSerialNumber` | `XXXXXXXXXXXX` |
| `MLB` | `XXXXXXXXXXXXXXXXX` |
| `SystemUUID` | `00000000-0000-0000-0000-000000000000` |
| `ROM` | 6 字节全零 |

其余结构（ACPI 引用、Kernel/Add、Booter/Quirks、NVRAM、UEFI 驱动顺序）保持原样。

## 为什么不能直接开机

- 占位序列号不是合法 SMBIOS，App Store / iMessage 一类服务不会工作，部分 kext 也可能拒绝加载。
- `EFI/OC/Kexts` 与 `EFI/OC/Drivers` 里只有 `MANIFEST.tsv`，没有二进制。
- 这台机器的 ACPI 与 USB 映射是按 `B850BKB` 这一块板子做的，换板子需要重新生成 SSDT 与 `UTBMap`。

## 生成自己的四项

```text
GenSMBIOS → 机型 MacPro7,1 → 得到 Serial / Board Serial (MLB) / SmUUID
ROM = 有线网卡的 6 字节 MAC，或随机 6 字节
```

填回 `PlatformInfo → Generic` 后跑 `ocvalidate`，通过再上机。

## 生成方式

私有仓库里执行 `scripts/publish-public.sh`：复制 `config.plist` 与 `ACPI/*.aml`、
生成三份 `MANIFEST.tsv` 与 `docs/VERSIONS.md`、套用本文档模板，
最后扫描输出树确认没有真实标识残留。
