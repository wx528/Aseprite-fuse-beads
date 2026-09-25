# Aseprite 拼豆图纸导出插件

把 Aseprite 里打开的像素画导出为拼豆（fuse beads）图纸 PNG：每颗豆子标注 MARD/漫漫色号，底部附用量统计。

![示例](fixtures/gradient_pattern.png)

## 功能

- 当前帧合并图层导出，1 像素 = 1 颗豆
- 自动匹配 MARD 小豆 221 实色色号（A–H + M 系列，RGB 取自官方色卡），颜色距离用 CIEDE2000
- 方豆（默认）/ 圆豆两种样式，圆豆可调直径
- 网格线 + 每 N 格深色加粗分格线（默认 5，可调，0 关闭）
- 底部用量统计：按色号排序，每列 5 个，色块 + 色号 + 颗数
- 透明像素自动留空
- 单边超过 128 像素时弹出卡死风险警告

## 安装

把 `fuse-beads-export.lua` 和整个 `src/` 目录复制到 Aseprite 脚本目录（Aseprite 里 文件 > 脚本 > 打开脚本文件夹），然后 文件 > 脚本 > 重新扫描脚本文件夹。

## 使用

1. 在 Aseprite 里打开像素画（建议先缩放到拼豆尺寸，如 64×64，精灵 > 精灵大小）
2. 文件 > 脚本 > fuse-beads-export
3. 对话框选项：
   - 输出文件：默认 `原名_pattern.png`
   - 色板：MARD/漫漫
   - 豆子形状：方形（默认）/ 圆形
   - 格子大小：默认 32px
   - 豆子直径：圆豆占格子百分比，默认 90%
   - 分格线间隔：默认 5 格
   - 包含用量统计：默认开
4. 点击导出

## 色板数据

`src/palette_mard.lua` 每行一个色号：`{ code = "A1", name = "A1", rgb = { r = R, g = G, b = B } }`，可直接编辑增删。注意：色值取自官方色卡照片，与实物可能有轻微色差。

## 开发

测试：`powershell -ExecutionPolicy Bypass -File run-tests.ps1`（无头调用 Aseprite 运行全部断言）。
