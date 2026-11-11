# Fork 声明 / Fork Notice

## 本仓库是什么

本仓库是 [maotoumao/MusicFree](https://github.com/maotoumao/MusicFree) 的 **社区 fork 增强版**。

| 项目 | 说明 |
|---|---|
| 上游项目 | [maotoumao/MusicFree](https://github.com/maotoumao/MusicFree) |
| 上游作者 | [@maotoumao](https://github.com/maotoumao) |
| 上游协议 | AGPL-3.0 |
| 本仓库作者 | qingniaoheyu |
| 基线版本 | `v0.6.2`（commit `d118b18`） |
| 本仓库协议 | AGPL-3.0（与上游一致） |

## 我改了什么

**只做了一处功能性改动**（`src/core/pluginManager/plugin.ts`）：

让插件能拿到**真实可用的 Cookie 管理器**，并在插件请求前清空 RN 原生 Cookie 存储，
使插件设置的 `Cookie` 请求头能真正透传到服务端。

相关的上游缺陷：

- [issue #670](https://github.com/maotoumao/MusicFree/issues/670) —— 插件设置的 Cookie 头在手机端会被 RN 原生 Cookie 存储覆盖
- [issue #655](https://github.com/maotoumao/MusicFree/issues/655) —— Cookie is not working

**外加两处构建便利性改动**：

1. `android/app/build.gradle` —— release 签名在没有 `keystore.properties` 时回退到 debug 签名
   （否则 fork 后无法构建出可安装的 APK）
2. `android/build.gradle` / `android/settings.gradle` —— 增加阿里云、华为云 Maven 镜像
   （国内直连 Google Maven 会超时）

**没有改动**：UI、播放器、下载器、插件协议、其他任何业务逻辑。全部改动见
[`patch/musicfree-cookiefix.patch`](./patch/musicfree-cookiefix.patch)。

## 本仓库另外提供的东西

**不属于对上游的修改**，是本仓库独立维护的内容：

- `plugin/musicfree-netease-plugin.js` —— 网易云音乐插件（社区插件的增强重构版，非上游代码）
- `release/*.apk` —— 用上游源码 + 补丁编译出的 APK
- `README.md` —— 使用说明

## 与上游的关系

- 本仓库**不代表上游立场**，上游**不为此仓库内容负责**
- 遇到本仓库的问题，请在本仓库提 issue，**不要去上游仓库提**
- 如果你认为本仓库的改动有价值，欢迎向上游提 PR（我这边也乐意配合整理）

## 如果我是原作者，想处理这个仓库？

如果你（@maotoumao）对本仓库有任何异议，比如：

- 不希望 APK 以你的项目名义分发
- 希望移除某些内容
- 希望调整声明措辞

请在本仓库提 issue 或通过 GitHub 联系我，我会**立即配合处理**。

## 版权归属

- MusicFree 软件著作权归 [@maotoumao](https://github.com/maotoumao) 所有
- 本仓库对上游代码的修改部分，同样以 AGPL-3.0 授权
- 网易云音乐相关的接口、内容、商标归网易公司所有，本仓库与之无关
- 所有音乐版权归各唱片公司及平台所有

## 法律与合规

- 本项目**只做接口搬运**，不提供、不破解任何付费/会员内容
- **不绕过付费墙**，不破解 DRM，不提供无损下载
- 仅供**个人学习研究**，请勿用于商业用途
- 请支持正版音乐

## AGPL-3.0 合规说明

AGPL-3.0 要求：**通过网络提供修改后的程序时，必须向用户提供完整源码**。

本仓库的合规做法：

1. 完整源码公开在本仓库（含所有修改）
2. 补丁文件单独提供，便于审计每一处改动
3. APK 由公开源码 + 公开补丁构建，任何人可复现
4. 构建脚本公开（`patch/build-patched-apk.yml`）

任何基于本仓库 APK 的再分发，都必须同样公开源码。
