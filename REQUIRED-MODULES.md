# 使用者自行提供的系统模块

公开仓库及 Release 不附带 Sony 系统模块。将兼容模块放入 `runtime/user/sys_modules/`。启动器会按本机验证版本的 SHA-256 校验。

| 文件 | 本机验证 SHA-256 |
|---|---|
| `libSceNgs2.sprx` | `fbe55d7da893743a6267798acff1a2093ab7ac5f1606b48f8f3d3c5a8d7e74f6` |
| `libSceAvPlayer.sprx` | `3f1a2dbe47bb0d8d731fb670babcd9e72d4b55acf99e190e845093eb63dfbe7f` |
| `libSceAudiodec.sprx` | `bc2806808a735dc18e71226a07374496914a2ee6c19e1a27c17cd17be345b2c7` |
| `libSceAudiodecCpu.sprx` | `ad89da76518bc80073e996aad4c50acd1266dffcbe7adc8a7365e66e0324a612` |
| `libSceAudiodecCpuHevag.sprx` | `4328be624627ee0e9d41d0b5727950a1118714be34dda659996ebc3e69d4a92b` |
| `libSceAudiodecCpuM4aac.sprx` | `72fa07d041df1ee6d58f193b37bda217af9c576f8e789a2e1c2a8334d3aa7448` |
| `libSceFont.sprx` | `2e57d191aa3a26aa6682cb8181c29adf3952b6f16ff2ca60124e4a890a49ca9d` |
| `libSceFontFt.sprx` | `ad78707187be911df1559f4799fef2af3d6c4d098dd95b33d3e22854cca15e2b` |
| `libSceRtc.sprx` | `b05340263cb01606c0bea76b2d1be53739a6dfca75fb51ba228d146450cb3e60` |

缺少模块或文件版本不一致时，启动器会说明具体文件；这不代表游戏资源损坏。不要提交模块、游戏文件或密钥到本仓库。
