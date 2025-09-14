## 代码结构

* code 源代码
* docs 构建服务

## 命令

**安装依赖** `pm i`

**启动开发服务** `npm run docs:dev`

**预览开发服务** `npm run docs:preview`

**构建生产** `npm run docs:build`

**更新vuepress主题** `pm run vp-update`

## 发布

1. 删除 `docs` 目录

2. 执行 `npm run docs:build`
3. 添加git `git add docs/`
4. 提交git `git commit`





## 构建发布地址

https://notonull.github.io/logic-hub/