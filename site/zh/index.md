---
layout: page
navbar: false
footer: false

# site/index.md 的简体中文版。结构与英文版逐段对应：改动英文文案时，
# 请同步这里（反之亦然）。所有组件文案都住在这份 frontmatter 里。
landing:
  # 支持邮箱只写在这一处。它是 keelhaven.app 上的 Cloudflare Email
  # Routing 别名，转发到真实邮箱，可随时改指向而不用动网站。
  contact: support@keelhaven.app
  # 仓库地址，导航图标和页脚的 GitHub 链接都读它。默认主题页面
  # （/zh/privacy、/zh/licenses）经由 config.mts 的 themeConfig.socialLinks
  # 另行携带。
  github: https://github.com/shenxianpeng/keelhaven
  cta: 下载
  # 导航用短标签（FAQ 而非「常见问题」），四项加语言链接才放得进
  # 375px 的手机导航胶囊；页内区块标题和页脚仍用中文全称。
  nav:
    - { text: 功能, anchor: features }
    - { text: 指南, anchor: guide }
    - { text: 价格, anchor: pricing }
    - { text: FAQ, anchor: faq }
  footer:
    tagline: 隐私优先的 Mac 备份。
    versionNote: 公开测试版
    copyright: © shenxianpeng.
    groups:
      - title: 支持
        links:
          - { text: 邮件支持, mailto: true }
          - { text: 常见问题, anchor: faq }
          - { text: 在 X 上关注, href: "https://x.com/xianpengshen" }
      - title: 产品
        links:
          - { text: 功能, anchor: features }
          - { text: 快速上手, anchor: guide }
          - { text: 价格, anchor: pricing }
          - { text: GitHub 源码, github: true }
      - title: 法律
        links:
          - { text: 隐私, link: /zh/privacy }
          - { text: 许可, link: /zh/licenses }
  # 演示动画的界面文案，取自 App 自带的简体中文本地化
  # （Keelhaven/Localizable.xcstrings），保证演示与真实应用一字不差。
  demo:
    ariaLabel: Keelhaven 菜单栏应用执行备份的动画演示：名为「文稿」的计划备份到外置硬盘，运行时只显示一个小小的进度条，然后弹出「备份完成」通知。
    clock: 周一 9:41
    plan1Name: 文稿
    plan1Sched: 每天 9:00
    plan1StatusIdle: 2 小时前完成备份
    plan1StatusDone: 1 秒钟前完成备份
    plan2Name: 照片
    plan2Sched: 每小时
    plan2Status: 26 分钟前完成备份
    backUpNow: 立即备份
    addPlan: 添加备份计划…
    startAtLogin: 开机时自动启动
    quit: 退出 Keelhaven
    notifTitle: 备份完成
    notifBody: 文稿：新增 12 个文件，共 48 MB。
---

<script setup>
import { computed } from 'vue'
import { useData } from 'vitepress'

const { frontmatter } = useData()
const releases = computed(
  () => `${frontmatter.value.landing.github}/releases/latest`
)
</script>

<!-- 下载按钮是活的：/latest.json 解析成功前指向 GitHub Releases 页，
     解析后换成 DMG 直链。 -->

<div class="kh-landing">

<LandingNav />

<section id="top" class="kh-hero">
  <!-- CJK 允许在任意字符间断行，nowrap 保证「Mac 备份」不被拆成「备/份」；
       span 前的普通空格让换行点落在「的」之后。 -->
  <h1 class="kh-hero-title">隐私优先的 <span style="white-space: nowrap">Mac 备份</span></h1>
  <p class="kh-hero-tagline">一个安静的菜单栏应用，备份你最在乎的文件夹——在你的 Mac 上加密，按你的时间表，存进你自己的存储。</p>
  <p class="kh-hero-facts">
    <span>macOS 14+</span>
    <span>免费开源</span>
    <span>无遥测</span>
    <span>开源工具即可恢复</span>
  </p>
  <p class="kh-hero-actions">
    <DownloadButton label="下载 macOS 版" :fallback-href="releases" />
    <a class="kh-btn kh-btn-ghost" href="#guide">阅读指南</a>
    <span class="kh-hero-install">或在终端安装：<code>brew install --cask shenxianpeng/tap/keelhaven</code></span>
  </p>
</section>

<LandingSection id="tour" eyebrow="00 · 看一眼" title="一个菜单栏图标，就是整个应用。">

<!-- MenuBarDemo 是弹窗界面的动画复刻，按 SwiftUI 源码绘制而非截图，
     保证展示的和应用实际拥有的一致——包括那个安静的、不报数字的进度条。 -->
<ShotFrame><MenuBarDemo /></ShotFrame>

</LandingSection>

<LandingSection id="features" eyebrow="01 · 功能" title="装完就可以忘掉它">

<div class="kh-feature-grid">
<div class="kh-feature">

### 隐私为本

数据在离开你的 Mac 之前就已加密。密码保存在 macOS 钥匙串中，绝不写入磁盘或日志。

</div>
<div class="kh-feature">

### 不来打扰

住在菜单栏里——没有 Dock 图标，没有窗口要管理。设置一次时间表，然后忘掉它。

</div>
<div class="kh-feature">

### 没有锁定

备份采用标准的开放格式——在任何机器上都能用免费的开源工具恢复，装没装 Keelhaven 都一样。

</div>
<div class="kh-feature">

### 真正的定时

每小时、每天或每周——选好星期和时间，Keelhaven 会让你的备份始终保持最新。

</div>
</div>

</LandingSection>

<LandingSection id="guide" eyebrow="02 · 指南" title="三个决定，然后是安静">

<ol class="kh-steps">
<li>

### 选好文件夹

选出你不能失去的文件夹——文稿、照片、项目。

</li>
<li>

### 选一个属于你的目的地

外置硬盘、NAS，或任何 S3 兼容的存储桶。传输路径上没有 Keelhaven 的服务器。

</li>
<li>

### 定下时间表

每小时、每天或每周。Keelhaven 在后台运行，只在需要你注意时才出声。

</li>
</ol>

<div class="kh-guide-note">

适用于 macOS 14 及以上，Apple 芯片和 Intel 皆可，所需的一切均已内置。偏好终端？下面任一命令安装的都是下载按钮提供的同一个应用：

<div class="kh-install">
  <div class="kh-install-row"><span class="kh-install-label">用 Homebrew</span><code>brew install --cask shenxianpeng/tap/keelhaven</code></div>
  <div class="kh-install-row"><span class="kh-install-label">不用 Homebrew</span><code>curl -fsSL https://keelhaven.app/install.sh | bash</code></div>
</div>

Beta 版本尚未经过 Apple 公证，因此首次启动需要多确认一步——[下方常见问题](#faq)三步讲清。

</div>

</LandingSection>

<LandingSection id="pricing" eyebrow="03 · 价格" title="免费。这就是全部定价。">

<PricingCard>
<template #price><span class="kh-badge">免费且开源</span></template>
<template #note>Beta 期间免费，1.0 之后依然免费——永远不做订阅制。将来可能推出可选的付费 Pro 版提供进阶便利，但备份和恢复你的数据永远不会被关进付费墙。</template>

- 备份计划和目的地数量不限
- 通用构建——Apple 芯片和 Intel
- 备份引擎内置——无需再装任何东西
- 无账号、无遥测，传输路径上没有我们的服务器

</PricingCard>

</LandingSection>

<LandingSection id="faq" eyebrow="04 · 常见问题" title="直接的回答">

<FaqItem question="macOS 说无法验证 Keelhaven，是出问题了吗？">

没有问题——Beta 版本尚未经过 Apple 公证，任何无法在线验证的应用 macOS 都会弹出这个标准警告。允许一次之后，同一版本不会再问：

- **macOS 15（Sequoia）：** 双击 Keelhaven 一次并关掉警告，然后打开**系统设置 › 隐私与安全性**，滚动到底部，点击**仍要打开**。
- **macOS 14（Sonoma）：** 在「应用程序」中右键点按 Keelhaven，选择**打开**，再点一次**打开**。
- **偏好终端？** `xattr -d com.apple.quarantine /Applications/Keelhaven.app` 直接清除隔离标记，完全跳过对话框。

</FaqItem>
<FaqItem question="它能取代时间机器（Time Machine）吗？">

不能——两个一起用。时间机器擅长用桌上的硬盘把整台 Mac 恢复原样；Keelhaven 负责第二份副本：那些你不能失去的文件夹，加密后放在不在你桌上的某个地方。

</FaqItem>
<FaqItem question="它免费——那靠什么维持？">

靠先在你的 Mac 上赢得一席之地。Keelhaven 的备份引擎是 [restic](https://restic.net)——免费、开源、出色——而 Keelhaven 补上了命令行工具刻意留给你自己处理的一切：真正会按时运行的计划、保存在 macOS 钥匙串且绝不写入磁盘或日志的密码，以及一个在需要你之前保持安静的菜单栏。这一切免费，并且保持免费。如果有足够多的人开始依赖它，可能会推出付费 Pro 版提供进阶便利——比如快照内文件浏览或保留策略——由它供养免费版，而不是削减免费版。

</FaqItem>
<FaqItem question="我会被 Keelhaven 锁定吗？">

不会。每个计划写入的都是普通的 restic 仓库，你可以在任何 Mac 或 Linux 机器上用开源的 restic 命令行列出、校验并恢复你的备份——装没装 Keelhaven 都行。就算 Keelhaven 明天消失，你的备份也不会。

</FaqItem>
<FaqItem question="Keelhaven 开源吗？">

开源。完整源代码以 GPLv3 许可发布在 [GitHub](https://github.com/shenxianpeng/keelhaven)：阅读、审计、自行构建、fork 都可以。内置的 restic 引擎以 BSD 2-Clause 许可开源——两份声明见[许可页](/zh/licenses)。

</FaqItem>
<FaqItem question="别人能读到我的数据吗？">

不能。任何内容在上传之前就已在你的 Mac 上加密，仓库密码只存在你的 macOS 钥匙串里。没有 Keelhaven 服务器、没有账号系统、没有遥测——这个应用没有任何别的地方可以发送任何东西。

</FaqItem>
<FaqItem question="支持哪些备份目的地？">

挂载在 Mac 上的外置或网络硬盘、任何 S3 兼容的存储桶（AWS、Backblaze B2、Wasabi、Cloudflare R2、MinIO），以及通过 SFTP 连接你自己的服务器或 NAS。

</FaqItem>
<FaqItem question="备份会永远增长下去吗？">

目前是的——每次运行新增一个快照，Keelhaven 从不删除快照。快照之间会去重，每次运行只存储自上次以来变化的部分，但目前还没有自动清理。保留策略在路线图上；在它落地之前，仓库就是标准的 restic 仓库，今天就可以在任何机器上用 `restic forget --prune` 配合你选择的策略清理。

</FaqItem>
<FaqItem question="我怎么知道备份真的可用？">

失败或不完整的运行绝不会静默——引擎报出的错误会立刻出现在菜单栏和系统通知里。Keelhaven 还会按计划用 restic 自带的完整性检查校验每个计划的仓库——默认每周一次，可按计划调整——计划行里一条安静的「已验证」记录着上次通过的时间；只有出问题时它才会出声。而时不时恢复一个文件，始终是检验任何备份工具的金标准，我们也不例外。

</FaqItem>
<FaqItem question="我还需要安装别的东西吗？">

不需要。Keelhaven 需要的一切都在应用包里，包括备份引擎——没有单独的安装步骤，不要求 Homebrew，也没有需要你保持更新的东西。

</FaqItem>
<FaqItem question="可以从终端安装吗？">

两种方式，装的都是下载按钮提供的同一个 DMG。用 Homebrew：`brew install --cask shenxianpeng/tap/keelhaven`，之后 `brew upgrade` 会自动跟进新版本。不用 Homebrew：`curl -fsSL https://keelhaven.app/install.sh | bash` 会下载最新版本并拷入「应用程序」；[脚本本身](https://github.com/shenxianpeng/keelhaven/blob/main/site/public/install.sh)是一页简短易读的 shell，想先检查一遍也很方便。

</FaqItem>
<FaqItem question="如果我忘了仓库密码会怎样？">

备份将无法恢复，这是设计使然——仓库端到端加密，没有人握有备用钥匙，我们没有，你的存储服务商也没有。Keelhaven 把密码保存在你的 macOS 钥匙串里，通过 Touch ID 验证后可以随时拷贝出来；同时也请把它存进你的密码管理器。

</FaqItem>
<FaqItem question="为什么不上 Mac App Store？">

App Store 的应用必须运行在沙盒里，而备份引擎需要读取你指定的任意文件夹、建立网络和 SSH 连接。Keelhaven 启用了强化运行时（hardened runtime），只是不通过商店分发——并且在 Beta 期间尚未经过 Apple 公证，所以首次启动需要[多确认一步](#faq)。

</FaqItem>

</LandingSection>

<LandingFooter />

</div>
