# ddServer 开发流程（Prisma + MySQL）

## 1. 环境准备

- Node.js / npm
- MySQL（你当前有两套库：dd-dev、dd-prod）

本项目通过 `.env.<环境>` 切换数据库：

- 本地开发：`.env.development`（默认连接 dd-dev）
- 服务器部署：`.env.production`（默认连接 dd-prod）

## 2. 配置数据库连接

在 `ddServer` 目录创建/修改以下文件（不要提交到 Git）：

### 2.1 本地开发（dd-dev）

创建 `ddServer/.env.development`：

```ini
PORT=3000
OPENAI_API_KEY=
DB_HOST=8.155.29.171
DB_PORT=3306
DB_USER=你的dev账号
DB_PASSWORD=你的dev密码
DB_NAME=dd-dev
```

### 2.2 服务器部署（dd-prod）

创建 `ddServer/.env.production`：

```ini
PORT=3000
OPENAI_API_KEY=
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=你的prod账号
DB_PASSWORD=你的prod密码
DB_NAME=dd-prod
```

说明：

- `DB_HOST=127.0.0.1` 适用于「MySQL 与后端部署在同一台服务器」的场景；如果是云 RDS 或不同机器，改成对应地址。
- Prisma 连接串 `DATABASE_URL` 会在运行时由 `DB_*` 自动拼出来，无需你手动写。

## 3. 验证数据库是否可连接

在 `ddServer` 目录执行：

```bash
npm run db:check:dev
```

如果返回 `ok: true`，说明连通性正常。

## 4. Prisma 工作流（建表/迁移）

### 4.1 生成 Prisma Client

```bash
npm run prisma:generate
```

### 4.2 开发环境建表（首次）

两种方式任选一种：

- 方式 A：直接把 schema 同步到数据库（适合初期快速迭代）

```bash
npm run db:push:dev
```

- 方式 B：使用迁移文件（推荐长期使用）

首次初始化：

```bash
npm run db:migrate:dev -- --name init
```

之后每次你修改 `prisma/schema.prisma`，都执行：

```bash
npm run db:migrate:dev -- --name change_xxx
```

### 4.3 生产环境部署迁移

在服务器上（进入 `ddServer` 目录）执行：

```bash
npm run db:migrate:deploy:prod
```

## 5. 本地开发与启动

```bash
npm install
npm run dev
```

默认监听 `PORT`（默认 3000）。

## 6. 部署（服务器）

推荐用 PM2 做进程守护（保活/重启/开机自启），下面给出从 0 到上线的完整流程。

### 6.1 服务器首次安装（一次性）

1) 安装 Node.js（推荐用 nvm 管理版本）

2) 全局安装 PM2

```bash
npm i -g pm2
```

3) 准备生产环境变量文件

- 在服务器的 `ddServer` 目录创建 `.env.production`（不要提交到 Git）

4) 首次启动并设置开机自启（按提示执行）

```bash
pm2 startup
```

### 6.2 每次发布（dd-prod）

在服务器上进入项目目录执行：

```bash
cd /path/to/ddServer
git pull
npm ci
npm run prisma:generate
npm run db:migrate:deploy:prod
npm run build
pm2 restart ddserver || pm2 start dist/server.js --name ddserver
pm2 save
```

说明：

- `npm ci` 会严格按 lockfile 安装依赖，比 `npm install` 更适合生产环境。
- `db:migrate:deploy:prod` 会把已提交的迁移应用到生产库 dd-prod（不会生成新迁移）。
- 首次启动时没有 `ddserver` 进程，所以用 `restart || start` 兼容首次与后续发布。

### 6.3 常用 PM2 命令

```bash
pm2 ls
pm2 logs ddserver
pm2 restart ddserver
pm2 stop ddserver
pm2 delete ddserver
```

## 7. 发布到生产（结构变更 / 数据变更）

这里的“发布”包含两类事情：

- 结构变更：新增/删除字段、改类型、加索引、加表等（改 schema）
- 数据变更：批量修正某个字段值、补数据、回填字段等（改数据）

### 7.1 结构变更（推荐标准流程）

1) 在本地修改 `prisma/schema.prisma`

2) 在测试库（dd-dev）生成迁移并应用

```bash
npm run db:migrate:dev -- --name change_xxx
```

3) 检查迁移内容

- 查看 `prisma/migrations/**/migration.sql` 是否符合预期
- 用 Navicat 看 dd-dev 表结构是否正确

4) 本地验证接口与类型

```bash
npm run typecheck
npm run lint
```

5) 提交代码（重点：迁移文件也要提交）

- `prisma/schema.prisma`
- `prisma/migrations/**`
- 相关后端代码改动

6) 在服务器发布（dd-prod）

```bash
cd /path/to/ddServer
npm install
npm run prisma:generate
npm run db:migrate:deploy:prod
npm run build
npm start
```

### 7.2 数据变更（推荐放进迁移里一起发布）

如果你需要“修改某个表的一批数据”，建议把 SQL 作为迁移的一部分，跟着代码一起走发布流程，避免手工误操作。

推荐做法：

1) 先生成一个迁移（只生成，不自动执行），用于写数据 SQL

```bash
npm run db:migrate:dev -- --name data_fix_xxx --create-only
```

2) 打开新生成的 `prisma/migrations/**/migration.sql`，在里面追加你的数据修正 SQL（例如 UPDATE/INSERT）

3) 在 dd-dev 应用这条迁移并验证数据

```bash
npm run db:migrate:dev
```

4) 提交迁移文件与代码，然后按 7.1 的第 6 步在服务器执行 `db:migrate:deploy:prod`

说明：

- 迁移里的 SQL 会在生产环境按顺序执行一次，适合“可重复、可审计、可回滚”的发布。
- 涉及大数据量 UPDATE 时，建议分批执行或选择业务低峰期执行。

### 7.3 风险提示（建议遵守）

- 不建议在生产环境直接使用 `db push`，它不产生迁移历史，容易造成环境不一致。
- 删除字段/改类型前，先在代码里完成兼容（比如先双写/回填，再删除旧字段）。
- 生产发布前建议先做数据库备份（至少保证可以回滚数据）。

## 8. 常见问题

### 8.1 Host is not allowed to connect

说明 MySQL 用户未授权来源 IP。需要在 MySQL 中做 `user@host` 授权（建议精确到你的公网 IP）。

### 8.2 本地跑 production 连接失败

`.env.production` 通常配置为 `DB_HOST=127.0.0.1`，只在服务器上有效。本机跑 production 会出现 `ECONNREFUSED` 属于正常现象。
