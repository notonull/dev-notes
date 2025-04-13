---
title: git config | includeIf |目录未能识别指定配置文件,实现不同目录下不同的git config 配置策略
copyright: CC-BY-4.0
tags:
  - git
createTime: 2025/04/13 01:33:05
permalink: /blog/32c35pxt/
---

## 1.问题描述

### 1.1.问题背景

多个仓库，多账号同时开发时如果仓库配置未指定user、email 会因为优先级从而提交时邮箱不正确的问题，使用 `includeIf` 语法配置，匹配目录使用指定git配置文件从而解决多账号问题

### 1.2.影响范围

git全局配置文件中配置`includeIf`匹配指定目录指向单独的配置文件未能生效

### 1.3.问题用例

#### 1.3.1.git全局配置文件 `~/.gitconfig`

```bash
[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true
	
[user]
    name = xxx
    email = xxx@qq.com
	
[http]
    postBuffer = 524288000
    lowSpeedLimit = 0
    lowSpeedTime = 999999

[credential "https://gitee.com"]
    provider = generic

# 生效代码	
#[includeIf "gitdir/i:C:/Users/xxx/WorkSpace/SourceCode/github-private/"]
#   path = C:/Users/xxx/WorkSpace/SourceCode/git-config/.gitconfig-github


# 问题代码
[includeIf "gitdir/i:C:/Users/xxx/WorkSpace/SourceCode/[github]xxx.xxx.xxx@qq.com/"]
	path = C:/Users/xxx/WorkSpace/SourceCode/git-config/.gitconfig-github


```

#### 1.3.2.配置用例 `~/git-config/.gitconfig-github`

```bash
[user]
  name = xxx
  email = xxx.xxx.xxx@qq.com
```

## 2.参考资料

### 2.1.Git官方文档

[Git - git-config Documentation](https://git-scm.com/docs/git-config/zh_HANS-CN)

## 3.场景还原

### 3.1.切换项目目录

```cmd
cd C:/Users/xxx/WorkSpace/SourceCode/[github]xxx.xxx.xxx@qq.com/某项目目录
```

### 3.2.git查看项目配置

```cmd
git config --list --show-origin
```

```cmd
## 期望输出
file:C:/Users/xxx/.gitconfig  includeif.gitdir/i:C:/Users/xxx/WorkSpace/SourceCode/[github]xxx.xxx.xxx@qq.com/.path=C:/Users/xxx/WorkSpace/SourceCode/git-config/.gitconfig-github user.email=xxx.xxx.xxx@qq.com
file:C:/Users/xxx/.gitconfig  includeif.gitdir/i:C:/Users/xxx/WorkSpace/SourceCode/[github]xxx.xxx.xxx@qq.com/.path=C:/Users/xxx/WorkSpace/SourceCode/git-config/.gitconfig-github user.name=xxx

## 实际输出
file:C:/Users/xxx/.gitconfig  includeif.gitdir/i:C:/Users/xxx/WorkSpace/SourceCode/[github]xxx.xxx.xxx@qq.com/.path=C:/Users/xxx/WorkSpace/SourceCode/git-config/.gitconfig-github
file:C:/Users/xxx/.gitconfig  includeif.gitdir/i:C:/Users/xxx/WorkSpace/SourceCode/[github]xxx.xxx.xxx@qq.com/.path=C:/Users/xxx/WorkSpace/SourceCode/git-config/.gitconfig-github
```

### 3.3.git查看配置邮箱

```cmd
git config --get user.email
```

```cmd
## 期望输出
xxx.xxx.xxx@qq.com

## 实际输出
xxx@qq.com
```

## 4.排查过程

#### 4.1.查看官方文档

#### 4.2.尝试各种引入配置方法无果

#### 4.3.缩小变量用简单文件目录命名测试

## 5.问题原因

- 目录名称包含特殊字符 
- git不支持这样的目录命名

## 4.解决过程

### 4.1. 修改`~/.gitconfig`删除特殊字符

删除特殊字符[] ,这里全部删除了，删除[]其实就已经生效了

```bash
[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true
	
[user]
    name = xxx
    email = xxx@qq.com
	
[http]
    postBuffer = 524288000
    lowSpeedLimit = 0
    lowSpeedTime = 999999

[credential "https://gitee.com"]
    provider = generic

[includeIf "gitdir/i:C:/Users/xxx/WorkSpace/SourceCode/github-private/"]
   path = C:/Users/xxx/WorkSpace/SourceCode/git-config/.gitconfig-github

```

## 5.结论

- 虽然git配置语法正确但是依旧会存在无法识别的特殊字符问题
- 目录名称尽量不包含特殊字符，以免git的匹配逻辑不支持
- 实际场景匹配规则参考官方文档

