# AI_IMAGE

## 🎯 项目定位

这个项目不是单独做一个新的后端，而是把两个现有项目组合成一套对外服务：

- `sub2api`
  - 作为统一后端
  - 负责用户体系、鉴权、额度、计费、充值、模型转发、管理员后台
  - **只给管理员使用后台页面**

- `gpt_image_playground`
  - 作为用户前端
  - 负责图像生成、任务历史、收藏、Agent 工作流等用户交互
  - **普通用户只访问这个前端**

可以把它理解为：

```text
管理员  -> sub2api admin
普通用户 -> gpt_image_playground
                |
                v
             sub2api backend
```

## 🧱 当前架构

开发环境默认会启动 3 个服务：

| 服务 | 地址 | 作用 |
|---|---|---|
| `sub2api backend` | `http://127.0.0.1:8080` | 统一后端 API、鉴权、支付、额度、模型代理 |
| `sub2api frontend` | `http://127.0.0.1:3000` | 管理员后台 |
| `gpt_image_playground` | `http://127.0.0.1:5811` | 用户前端 |

## 👥 使用边界

- 管理员：
  - 登录 `sub2api frontend`
  - 管用户、配渠道、配额度、配支付、看后台数据

- 普通用户：
  - 不进入 `sub2api frontend`
  - 只访问 `gpt_image_playground`
  - 通过 `sub2api` 登录态与后端能力完成图像生成和相关操作

## 🚀 启动

```bash
bash ./start-dev.sh
```

启动后：

- 管理员后台：`http://127.0.0.1:3000`
- 用户前端：`http://127.0.0.1:5811`
- 后端 API：`http://127.0.0.1:8080`

## 🔄 更新上游

```bash
bash ./update-upstreams.sh
```

## 📦 仓库关系

- 根目录仓库：`git@github.com:abigmiu/ai_image_sell.git`
- `sub2api`：`git@github.com:abigmiu/sub2api.git`
- `gpt_image_playground`：`git@github.com:abigmiu/gpt_image_playground.git`
