<div align="center">
  <img src="assets/images/muzumi.jpg" alt="Kikoenai" width="120" height="120">

  # Kikoenai

  **专为同人音声爱好者打造的专属播放器，让您随时随地沉浸在喜爱作品的世界里。**

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS-lightgrey)](https://github.com/Meteor-Sage/Kikoeru-Flutter)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

---

## 📸 应用概览 (Screenshots)

<div align="center">
  <img src="assets/images/app_show.png" width="900" alt="UI展示">
</div>

---

## ✨ 为何选择 Kikoenai？

Kikoenai 旨在为您提供一个纯粹、沉浸且无缝的同人音声收听体验。

#### 无缝收听体验
- **从上次停下的地方继续**：无论是播放列表、音量，还是精确到秒的进度，Kikoenai 都会为您记下，下次打开即可无缝继续。
- **您的专属收听足迹**：自动记录您的收听历史，轻松回顾您钟爱的作品和章节。

#### 轻松发现与管理您的“宝藏”
- **多维度探索作品**：通过分类、标签、声优等多种方式快速找到您感兴趣的作品。
- **优雅的作品展示**：在精美的界面中查看作品封面、详情和文件列表，一切井然有序。

#### 打造您的专属空间
- **随心切换主题**：内置浅色与深色模式，在不同环境下都能享受最舒适的视觉体验。
- **离线畅听，尽在掌握**：高效的缓存机制，让您在没有网络时也能畅听已下载的作品，同时提供便捷的缓存管理功能。
- **本地音视频播放**： 扫描用户选中的文件路径，提供本地的音视频播放
---
#### 🕊 鸽子清单
| 模块分类     | 功能名称         | 详细需求 / 开发内容                                                      | 状态     |
| -------- | ------------ |------------------------------------------------------------------| ------ |
| 💎 发现与推荐 | 个性化推荐        | **数据收集**：上报用户数据，让Kikoeru个性化推荐正常运行                                | 📅 待排期 |
| ☁️ 数据与服务 | 在线标记         | **状态管理**：想看 / 在看 / 看过 / 搁置 / 抛弃   **评分系统**：1–10 分评分机制 ,播放列表添加    | 📅 待排期 |
| 📦 内容管理  | 作品下载         | **下载引擎**：多任务并发、断点续传、后台保活                                         | 📅 待排期 |
| 📦 内容管理  | GofileUrl 导入 | **链接解析**：支持 GofileUrl 导入 **任务处理**：元数据抓取、导入队列管理**异常处理**：失效链接、权限校验 | 📅 待排期 |
| 🎬 核心播放  | 视频播放器        | 支持本地和在线播放                                                        | 📅 待排期 |
| 🎬 核心播放  | 播放模式         | **模式逻辑**：列表循环 / 单曲循环 / 随机 / 顺序                                   | 📅 待排期 |

## 🚀 下载与安装

即将发布，敬请期待！我们正在努力打包各平台的发行版本。

---

<details>
### 🚀 本地运行 (Getting Started)

1.  **克隆仓库 (Clone the repo)**
    ```sh
    git clone https://github.com/your-username/Kikoenai.git
    ```
2.  **安装依赖 (Install dependencies)**
    ```sh
    flutter pub get
    ```
3.  **运行代码生成器 (Run code generator)**
    ```sh
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
4.  **运行应用 (Run the app)**
    ```sh
    flutter run
    ```

</details>

---
