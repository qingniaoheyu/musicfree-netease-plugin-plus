# 一键推送到 GitHub

本目录已是一个完整的 Git 仓库（18 个文件，5 次提交，约 62 MB），**只差推送到 GitHub**。

---

## 方式一：双击运行（最简单）

1. 双击 `PUSH.bat`
2. 按提示粘贴你的 GitHub Token
3. 等待推送完成，会显示仓库地址

Token 创建地址：https://github.com/settings/tokens/new
- Note：`musicfree-upload`
- Expiration：`7 days`（或更短）
- **Scope：勾选 `repo`**（整个大类，勾了它下面全部自动选中）

---

## 方式二：手动命令行

```bash
cd C:\Users\Administrator\Desktop\musicfree-netease-plugin-plus

# 1. 先在 GitHub 网页上创建空仓库（不要勾选 README / .gitignore / license）
#    https://github.com/new
#    仓库名：musicfree-netease-plugin-plus
#    设为 Public

# 2. 添加远端并推送
git remote add origin https://github.com/qingniaoheyu/musicfree-netease-plugin-plus.git
git push -u origin main
# 会弹窗要求登录，用户名填 GitHub 用户名，密码填 Token（不是账号密码）
```

---

## 方式三：用 GitHub Desktop

1. 打开 GitHub Desktop
2. File → Add local repository → 选本目录
3. Publish repository（取消勾选 Keep this code private）

---

## 推送后建议做的三件事

### 1. 创建 Release（方便别人下载 APK）

```bash
# 用 gh CLI（如果装了）
gh release create v0.7.0 \
  --title "插件 v0.7.0 + Cookie 修复版 APK" \
  --notes-file RELEASE-NOTES-v0.7.0.md \
  release/*.apk plugin/musicfree-netease-plugin.js patch/musicfree-cookiefix.patch
```

或者网页操作：
- 仓库 → Releases → Create a new release
- Tag：`v0.7.0`
- Title：`插件 v0.7.0 + Cookie 修复版 APK`
- Description：把 `RELEASE-NOTES-v0.7.0.md` 内容粘进去
- 上传 `release/` 里的三个 APK + `plugin/musicfree-netease-plugin.js` + `patch/musicfree-cookiefix.patch`

### 2. 填写仓库描述和 topics

**描述**：
```
MusicFree 网易云插件增强版 + 修复 Cookie 被覆盖缺陷的 APK | Fork-enhanced from maotoumao/MusicFree
```

**Topics**：`musicfree` `netease` `netease-cloud-music` `plugin` `android` `cookie-fix` `music-player`

### 3. 加个链接回上游

在仓库 About 里填 Website：`https://github.com/maotoumao/MusicFree`

---

## 仓库内容清单

```
README.md                          主说明
INSTALL-GUIDE.md                   安装 / 排错完整指南
FORK-NOTICE.md                     Fork 声明与 AGPL 合规
CHANGELOG.md                       版本更新日志
RELEASE-NOTES-v0.7.0.md            Release 说明
LICENSE                            AGPL-3.0
.gitignore
.github/workflows/validate-plugin.yml    CI 自动校验
.github/ISSUE_TEMPLATE/            问题反馈表单
plugin/musicfree-netease-plugin.js  插件 v0.7.0（作者 qingniaoheyu）
release/*.apk                      修复版 APK ×3
patch/musicfree-cookiefix.patch    源码补丁
patch/build-patched-apk.yml        Actions 构建配置
```

---

## 验证推送成功

推送后访问 https://github.com/qingniaoheyu/musicfree-netease-plugin-plus 应该看到：

- ✅ 18 个文件
- ✅ README 正常渲染（带 badge 和快速下载表格）
- ✅ Actions 页面自动跑了一次 `Validate Plugin`（应该通过）
- ✅ 提交历史有 5 条

如果 Actions 显示红色，点进去看是哪个检查失败，把日志发我。
