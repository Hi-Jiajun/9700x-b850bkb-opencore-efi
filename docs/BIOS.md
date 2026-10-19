# BIOS 设置

这台机器是 Windows + macOS 双系统，改 BIOS 前先确认 Windows 侧能接受同样的设置。

| 项 | 值 | 说明 |
| --- | --- | --- |
| Above 4G Decoding | **On** | 显卡 BAR 需要映射到 4G 以上 |
| Resizable BAR / Re-Size BAR | **On**（建议） | NullMoth 驱动 1.0.5 起即使关闭也会自行放大 BAR；开启更稳 |
| CSM | **Off** | 纯 UEFI |
| Secure Boot | **Off** | OpenCore 与第三方 kext 需要 |
| Fast Boot | **Off** | 便于进启动菜单与排错 |
| XHCI Hand-off | **On**（有则开） | 没有这项就跳过 |
| Serial/Parallel Port | 关（有则关） | 减少无用 ACPI 设备 |

## 注意

- 部分主板要先打开 `Above 4G Decoding` 并关闭 `CSM`，`Resizable BAR` 才会出现。
- 关闭 Secure Boot 后 Windows 侧若启用了 BitLocker，会要求恢复密钥；改 BIOS 前先确认。
- 这份配置的历史排错记录里出现过"开 ReBAR + `DevirtualiseMmio` 导致 MMIO 区被当普通内存"
  的崩溃路径。若首启不稳，可先把 ReBAR 关掉再试；驱动不依赖它。
