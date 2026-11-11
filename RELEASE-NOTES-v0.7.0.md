# 插件 v0.7.0 + Cookie 修复版 APK

## 📦 包含内容

| 文件 | 说明 |
|---|---|
| `musicfree-netease-plugin.js` | 网易云插件 **v0.7.0**（作者：qingniaoheyu） |
| `MusicFree-0.6.2-CookieFix-universal.apk` | 修复版 APK（全架构，28.1 MB，不确定机型选这个） |
| `MusicFree-0.6.2-CookieFix-arm64-v8a.apk` | 修复版 APK（现代手机，17.3 MB） |
| `MusicFree-0.6.2-CookieFix-armeabi-v7a.apk` | 修复版 APK（老旧 32 位机型，16.1 MB） |
| `musicfree-cookiefix.patch` | 源码补丁（`git apply` 可用） |

---

## ✨ 核心改进

### 1. Cookie 不再被覆盖（配合修复版 APK）

上游 MusicFree 手机端存在缺陷：插件设置的 `Cookie` 请求头会被 RN 原生 Cookie 存储覆盖，
导致「首次可用、之后账号错乱」。

- 上游 issue：[#670](https://github.com/maotoumao/MusicFree/issues/670) / [#655](https://github.com/maotoumao/MusicFree/issues/655)
- 修复方式：暴露真实的 `@react-native-cookies/cookies` 管理器 + 插件专用 axios 实例在每个请求前 `clearAll()`

**验证**：
```
JS bundle：✅ createPluginAxios / ✅ clearAll / ✅ @react-native-cookies/cookies
dex：    ✅ classes.dex / classes2.dex 含 CookieManagerPackage
签名：    ✅ apksigner verify 通过（Android Debug 证书）
```

### 2. 私人每日推荐（与手机 App 一致）

网易云有**两套每日推荐接口**，返回列表**重合度为 0**：

| 接口 | 内容 |
|---|---|
| `/api/discovery/recommend/songs`（v1） | ❌ 旧接口 |
| `/api/v3/discovery/recommend/songs`（v3） | ✅ **手机 App 同款**（带「超80%人播放」等推荐理由） |

本插件优先用 **v3**，填 Cookie 后返回的就是你账号在 App 里看到的那份。

### 3. 一键导入歌单

| 方式 | 操作 |
|---|---|
| **全部合并导入** | 导入 → 歌单 → 输入 `all`（实测 32 个歌单 → 1296 首，自动去重） |
| **保留结构逐个导入** | 歌单广场 → 「我的歌单」标签 → 点歌单 → 顶部 📁 图标 |
| **按名字/ID 导入** | 导入 → 歌单 → 输入歌单名或 ID |
| **查歌单列表** | 导入 → 单曲 → 输入 `mylist` |

输入容错：自动清理零宽空格、BOM、全角字符、换行、前后空格。

### 4. VIP 歌回退提速（解决「只能切回播放过的歌」）

B 站回退从串行改并行，超时收紧，VIP 歌出源 **3～6 秒 → 0.7～0.9 秒**：

| 歌曲 | 类型 | 音源 | 耗时 |
|---|---|---|---|
| 神魂颠倒 | VIP | B 站音频 | 925ms |
| 凄美地 | VIP | B 站音频 | 709ms |
| smezir_2 | 免费 | 网易云 | 62ms |

匹配度算法完整保留：标题相似度硬门槛 + 作者名 + 时长接近度 + 播放量，排除伴奏/翻唱/教程。

---

## ⚠️ 安装须知

1. **APK 用 Debug 证书签名**，与官方版不同，**需要先卸载官方版**
   - 卸载前用官方版「备份」功能导出数据
   - 装好修复版后恢复备份

2. **改一个关键设置**：设置 → 基本设置 → 「点击专辑内单曲时」→ 选 **「播放专辑」**
   - 不改的话点歌只会播这一首，下一首会回到它自己

3. **Cookie 获取**：电脑浏览器 F12 → Network → 任意请求 → Request Headers → `Cookie:` → Copy value
   - 只用 `MUSIC_U` + `__csrf` 两项即可

---

## 📄 协议与声明

- Fork 自 [maotoumao/MusicFree](https://github.com/maotoumao/MusicFree)，遵循 **AGPL-3.0**
- 只做接口搬运，**不提供任何付费/会员内容破解**，不绕过付费墙
- 仅供个人学习研究，请支持正版音乐

详见仓库 [README](https://github.com/qingniaoheyu/musicfree-netease-plugin-plus) 和 [FORK-NOTICE](https://github.com/qingniaoheyu/musicfree-netease-plugin-plus/blob/main/FORK-NOTICE.md)
