# MusicFree 网易云音乐插件（增强版）+ Cookie 修复版 APK

> **作者：qingniaoheyu**
> 本仓库是对 [maotoumao/MusicFree](https://github.com/maotoumao/MusicFree) 的**社区 fork 增强**，
> 提供：① 功能增强的网易云音乐插件 ② 修复了 Cookie 覆盖缺陷的 MusicFree APK。

---

## ⚠️ 重要声明（请先读）

### 关于上游

本仓库**不是** MusicFree 官方仓库，与原作者 [@maotoumao](https://github.com/maotoumao) **无关**。

- 原项目：[https://github.com/maotoumao/MusicFree](https://github.com/maotoumao/MusicFree)
- 原项目协议：**AGPL-3.0**
- 本仓库的 APK 是在上游 `v0.6.2`（commit `d118b18`）源码基础上打了补丁后重新编译的
- 本仓库的插件是在社区网易云插件基础上重构增强的

**本仓库遵循 AGPL-3.0 协议**，所有修改均开源。如果你是原作者并希望移除本仓库相关内容，请提 issue，我会配合处理。

### 关于版权

- 本插件**只做接口搬运**，不提供、不破解任何付费/会员内容
- 无法播放的会员歌曲会尝试用 **B 站公开视频的音频流**作为备选音源
- **不绕过任何付费墙**，不破解 DRM，不提供无损下载
- 音乐版权归各唱片公司及平台所有，请支持正版
- 本项目仅供**个人学习研究**使用，请勿用于商业用途

### 关于安全

- APK 使用 **Android Debug 证书**签名（因为不持有官方私钥）
- **无法覆盖安装官方版**，需要先卸载官方版（会丢失本地数据，请先备份）
- 所有代码开源可审计，构建方式见 [构建说明](#构建说明)

---

## 一、这个仓库解决什么问题

### 问题 1：MusicFree 手机端插件填的 Cookie 会被覆盖

**这是上游的已知缺陷**，官方 issue：

- [#670 插件设置的 Cookie 头在手机端会被 RN 原生 Cookie 存储覆盖](https://github.com/maotoumao/MusicFree/issues/670)
- [#655 Cookie is not working](https://github.com/maotoumao/MusicFree/issues/655)

**根因**（源码 `src/core/pluginManager/plugin.ts`）：

```js
const deprecatedCookieManager = {
    get: notImplementedFunction,      // 空实现
    set: notImplementedFunction,      // 空实现
    flush: notImplementedFunction,    // 空实现
};

const packages = {
    // ...
    "@react-native-cookies/cookies": deprecatedCookieManager,  // ← 插件拿到的是空壳
};
```

插件**无法操作原生 Cookie 存储**。而 React Native 网络层的行为是：

> 原生 Cookie 存储**非空时**，会用存储里的 Cookie **覆盖**插件显式设置的 `Cookie` 请求头。

于是出现经典的「首次可用、之后失效」：

| 步骤 | 现象 |
|---|---|
| ① 清除应用数据后首次请求 | 存储为空 → 插件 Cookie 透传成功 → **账号正确** ✅ |
| ② 服务端返回 `Set-Cookie` | RN 自动存入原生存储 |
| ③ 之后所有请求 | 存储非空 → 插件 Cookie 被覆盖 → 变成设备匿名会话 → **账号错乱** ❌ |
| ④ 重启 App | 存储仍在 → 一直错 |
| ⑤ 再次清除数据 | 回到 ①，又能用一次 |

**本仓库的修复**（见 `patch/musicfree-cookiefix.patch`）：

```js
// 1. 暴露真实可用的 Cookie 管理器
import CookieManager from "@react-native-cookies/cookies";
const realCookieManager = CookieManager ?? deprecatedCookieManager;

// 2. 给插件专用的 axios 实例挂请求拦截器，每次请求前清空原生存储
function createPluginAxios() {
    const instance = axios.create({ timeout: 2000 });
    instance.interceptors.request.use(async (config) => {
        try { await realCookieManager.clearAll(); } catch (e) {}
        return config;
    });
    return instance;
}
packages.axios = createPluginAxios();
```

> 用独立 axios 实例是为了不影响宿主自身会话。

**验证结果**：

```
JS bundle 内关键符号：
✅ createPluginAxios      (offset 717902)
✅ clearAll               (offset 1109857)
✅ @react-native-cookies/cookies (offset 922503)

dex 内原生模块：
✅ classes.dex  含 CookieManagerPackage
✅ classes2.dex 含 CookieManagerPackage
```

### 问题 2：每日推荐和手机 App 对不上

网易云有**两套每日推荐接口**，返回的是完全不同的列表：

| 接口 | 内容 | 特征 |
|---|---|---|
| `/api/discovery/recommend/songs`（v1） | ❌ 旧接口 | 另一套推荐集合，与 App 重合度 **0** |
| `/api/v3/discovery/recommend/songs`（v3） | ✅ **手机 App 同款** | 带 `recommendReasons`（「超80%人播放」等） |

**实测对比**（同账号、同一时刻）：

| v1（32 首） | v3（33 首） |
|---|---|
| Hits 2000' | smezir_2 |
| insomnia | 神魂颠倒 |
| Why Why Why | 【Free】以和为贵 |

**重合度：0 首。**

本插件**优先使用 v3 接口**，返回的列表与手机 App 完全一致。

### 问题 3：VIP 歌回退慢导致连续跳歌

非会员账号（`vipType=0`）拿不到 `fee=1`（VIP）歌曲的网易云音源，只能走 B 站回退。
原来 B 站回退要串行发 4 个请求（搜索 → view → playurl → 探活），耗时 3～6 秒。

而 MusicFree 播放器 500ms 拿不到音源就会 `handlePlayFail()` → `skipToNext()`，
于是一路跳歌，**表现为「只能切回播放过的歌」**。

**本插件的优化**：

| 优化点 | 之前 | 现在 |
|---|---|---|
| 探活方式 | 串行 | **并行** `Promise.all` |
| `playurl` 超时 | 12 秒 | 6 秒 |
| 探活超时 | 6 秒 | **2 秒** |
| VIP 歌网易云降级 | 试 4 个档位（全空，白等 800ms） | **只试 1 次**，迅速转 B 站 |

**实测效果**：

| 歌曲 | 类型 | 音源 | 耗时 |
|---|---|---|---|
| 神魂颠倒 | VIP | B 站音频 ✅ | 925ms |
| 凄美地 | VIP | B 站音频 ✅ | 709ms |
| Life Goes On | VIP | B 站音频 ✅ | 714ms |
| smezir_2 | 免费 | 网易云 ✅ | 62ms |

---

## 二、安装

### 步骤 1：安装修复版 APK

从 [release](./release) 目录下载，按机型选择：

| 文件 | 适用机型 | 大小 |
|---|---|---|
| `MusicFree-0.6.2-CookieFix-arm64-v8a.apk` | **绝大多数现代安卓手机**（2017 年后） | 17.3 MB |
| `MusicFree-0.6.2-CookieFix-armeabi-v7a.apk` | 老旧 32 位机型 | 16.1 MB |
| `MusicFree-0.6.2-CookieFix-universal.apk` | 不确定架构时用（全包含） | 28.1 MB |

> ⚠️ 签名用的是 Debug 证书，**与官方版签名不同**。如果已装官方版，需要先卸载。
> 卸载前请用官方版的「备份」功能导出数据，装好后再恢复。

### 步骤 2：安装插件

1. 下载 [plugin/musicfree-netease-plugin.js](./plugin/musicfree-netease-plugin.js)
2. 传到手机
3. MusicFree → 插件管理 → **从本地安装** → 选择该 js 文件

### 步骤 3：填 Cookie（可选，但想看私人推荐必须填）

先获取 Cookie：

1. **电脑浏览器**打开 `https://music.163.com` 并登录
2. F12 → **Network** → 刷新页面 → 点任意请求
3. **Headers** → **Request Headers** → 找到 `Cookie:` 那一行
4. 右键 → **Copy value**
5. 发到手机上

然后：MusicFree → 插件管理 → 本插件 → **用户变量** → 「网易云 Cookie」→ 粘贴

**只粘 `MUSIC_U` 和 `__csrf` 两项就够了**：

```
MUSIC_U=xxxxx; __csrf=yyyyy
```

> ⚠️ 不要用某些浏览器的「导出全部 Cookie」功能，它会把 `.163.com` 和
> `music.163.com` 两个域混在一起，可能拿到另一个账号的凭证。
> 用 Network 面板复制实际发送的 Cookie 最可靠。

### 步骤 4：改一个关键设置

**设置 → 基本设置 → 「点击专辑内单曲时」→ 选「播放专辑」**

如果不改，点歌只会播这一首，下一首会回到它自己（因为播放队列里只有一首）。

---

## 三、功能说明

### 3.1 私人每日推荐

填了 Cookie 后，每日推荐就是你账号的**真实个性化推荐**，与手机 App 完全一致（用 v3 接口）。

打开方式：**榜单 → 每日推荐**

标题会显示你的昵称：

```
每日推荐 · 2026-11-11（你的昵称）
共 33 首 · 来自你的网易云账号「你的昵称」· 每日更新
```

**如果不填 Cookie**：每日推荐退化为公共推荐，不是你的口味。

**原理**：插件的 `requestDailySongs()` 优先请求明文 v3 接口：

```js
const result = await plainApiGet("/api/v3/discovery/recommend/songs");
const songs = (result && result.data && result.data.dailySongs) || [];
```

完整回退顺序：`明文 v3` → `明文 v1` → `eapi v3`。

### 3.2 一键导入歌单

插件提供**四种导入方式**：

| 方式 | 操作 | 结果 |
|---|---|---|
| **① 全部歌单合并导入** | 导入 → 歌单 → 输入 `all` | 把账号下**所有歌单的歌合并去重**成一个列表 |
| **② 歌单广场逐个导入** | 歌单广场 → 「我的歌单」标签 → 点歌单 → 顶部 📁 图标 | 保留歌单结构，逐个导入 |
| **③ 按歌单名/ID 导入** | 导入 → 歌单 → 输入歌单名或 ID | 导入指定歌单 |
| **④ 按链接导入** | 导入 → 歌单 → 粘链接 | 导入任意公开歌单 |

#### 实测数据

**全部导入（`all`）**：
```
合并导入 1296 首，耗时 12979ms
重复：无 ✅（按歌曲 ID 自动去重）
```

**「我的歌单」标签**：
```
歌单数以账号为准，实测 32 个
1. 我喜欢的音乐 · 57 首 · id=331947302
2. 断桥记 · 0 首 · id=17403698118
3. 颠 · 6 首 · id=13945650875
...
```

**支持的输入格式**（全部实测通过）：

| 输入 | 结果 |
|---|---|
| `https://music.163.com/#/playlist?id=331947302` | ✅ 57 首 |
| `331947302` | ✅ 57 首 |
| `颠`（歌单名） | ✅ 6 首 |
| `all` | ✅ 1296 首（全部合并） |

**容错**：自动清理零宽空格、BOM、全角字符、换行、前后空格。
歌单名输错时会给出候选：

```
没有完全同名的歌单。你是不是要找：
英雄联盟背景音乐全集=84487769、英雄联盟超神BGM第二期=108919834
（直接填对应的数字 ID 即可）
```

#### 查看全部歌单和 ID

**导入 → 单曲 → 输入 `mylist`**

会列出所有歌单和对应 ID，方便复制。

#### 为什么不能做到「完全不弹窗」

MusicFree 的插件协议是：`importMusicSheet()` **返回歌曲数组**，然后由**宿主 UI** 弹出
「找到 N 首 → 确定 → 选加到哪个歌单」。插件无法跳过宿主确认流程。

所以完整的「一键」体验需要走**歌单广场 → 📁 图标**那条路，只需点两下。

### 3.3 Cookie 不被覆盖

配合本仓库的修复版 APK，Cookie 不会再被 RN 原生存储覆盖。

**自检方法**：打开插件说明（`?`），应该看到：

```
## ✅ 已登录：你的昵称

| 账号 ID | 263273754 |
| MUSIC_U | 长度 834，`00BDC3E2...3D773B0B` |
```

如果显示「已填写 Cookie，但读不到账号」，说明：
- 用的是官方原版 APK（Cookie 会被覆盖），或
- Cookie 已过期 / 粘错了

### 3.4 其他功能

- 搜索：单曲 / 专辑 / 歌手 / 歌单
- 播放：128 / 192 / 320 / 无损（按账号权限降级）
- 歌单广场：分类标签、精选歌单
- 排行榜：官方榜 / 更多榜单
- 专辑详情、歌手作品（单曲 / 专辑）
- 歌词（含翻译）、歌曲评论
- 导入单曲（粘贴链接或 ID）

---

## 四、用户变量说明

| 变量 | 默认 | 说明 |
|---|---|---|
| **网易云 Cookie** | 空 | 填了才有私人推荐和「我的歌单」 |
| **B 站音源回退** | `1` | `1`=网易云拿不到音源时去 B 站找同名音频；`0`=关闭 |
| **改用 mp4 容器** | `0` | `0`=优先纯音频 dash（推荐）；`1`=用 mp4（含视频轨，某些播放器会卡） |

---

## 五、常见问题

### Q：为什么每日推荐和 App 不一样？

A：确认三件事：
1. 装的是**本仓库的插件**（版本号在 `?` 里能看到）
2. 用的是本仓库的**修复版 APK**（否则 Cookie 会被覆盖）
3. Cookie 是**同一个账号**的

### Q：点击下一首回到原曲？

A：改设置：**设置 → 基本设置 → 点击专辑内单曲时 → 播放专辑**

### Q：VIP 歌能播吗？

A：非会员账号的 VIP 歌，网易云拿不到音源，插件会自动去 B 站找同名音频。
匹配算法：标题相似度（硬门槛）+ 作者名匹配 + 时长接近度 + 播放量，排除伴奏/翻唱/教程。

如果 B 站也找不到，会跳过这首。

### Q：为什么 APK 装不上？

A：签名不同。先卸载官方版：
- 卸载前用官方版「备份」导出数据
- 装好修复版后恢复备份

### Q：会不会封号？

A：插件用的是网易云**公开 Web 接口**，与在浏览器里用网易云没有本质区别。
但请**不要高频刷接口**，合理使用。

---

## 六、构建说明

### 方式 A：用 GitHub Actions 构建（推荐）

1. Fork [maotoumao/MusicFree](https://github.com/maotoumao/MusicFree)
2. 应用补丁：

```bash
git apply patch/musicfree-cookiefix.patch
```

3. 把 `patch/build-patched-apk.yml` 放到 `.github/workflows/`
4. Actions 页面手动触发 `Build Patched APK`
5. 构建完在 Artifacts 下载

> 上游自带的 `build-beta.yml` 有 `if: github.actor == 'maotoumao'` 限制，
> fork 后无法手动触发，所以必须用新的 workflow。

### 方式 B：本地构建

**环境要求**：
- JDK 17
- Android SDK：`platform-35`、`build-tools-35.0.0`、`ndk 26.1.10909125`
- Node.js 20

**步骤**：

```bash
# 1. 克隆上游
git clone https://github.com/maotoumao/MusicFree.git
cd MusicFree
git checkout d118b18

# 2. 应用补丁
git apply /path/to/musicfree-cookiefix.patch

# 3. 装依赖
npm ci

# 4. 构建（只编 arm64 省时间）
cd android
./gradlew assembleRelease -PreactNativeArchitectures=arm64-v8a
```

**产物**：`android/app/build/outputs/apk/release/`

**国内网络注意**：`android/build.gradle` 和 `android/settings.gradle` 里已配置
阿里云、华为云镜像，避免连接 Google Maven 超时。

---

## 七、补丁内容

`patch/musicfree-cookiefix.patch` 改动 5 个文件：

| 文件 | 改动 |
|---|---|
| `src/core/pluginManager/plugin.ts` | **核心修复**：真实 CookieManager + axios 拦截器 |
| `package.json` | 新增 `@react-native-cookies/cookies@^6.2.1` 依赖 |
| `android/app/build.gradle` | release 签名兜底（无 keystore 时用 debug 签名） |
| `android/settings.gradle` | 国内镜像仓库 |
| `android/build.gradle` | 国内镜像仓库 |

---

## 八、已知限制

1. **每次请求前清空原生 Cookie** 有轻微性能开销（一次原生调用），实测可忽略
2. **同 App 内多插件**：清空是全局的，若其他插件依赖服务端持久 Cookie，也会受影响
3. **VIP 歌仍需要 B 站匹配**，匹配不到就跳过
4. **上游若更新版本**，补丁可能需重新适配（改动集中在 `plugin.ts` 顶部 60 行内）
5. **APK 用 Debug 签名**，无法覆盖安装官方版

---

## 九、致谢

- [maotoumao/MusicFree](https://github.com/maotoumao/MusicFree) —— 优秀的开源音乐播放器框架
- [NeteaseCloudMusicApi](https://github.com/Binaryify/NeteaseCloudMusicApi) —— 网易云接口实现参考
- 所有提交 issue 帮助定位问题的社区用户

---

## 十、协议

[AGPL-3.0](./LICENSE) —— 与上游保持一致。

本仓库的所有修改同样以 AGPL-3.0 开源。使用、修改、分发请遵守该协议。

---

**如果这个项目帮到了你，欢迎 Star ⭐**
