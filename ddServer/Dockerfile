FROM node:20-bookworm-slim AS builder

# 安装构建依赖，包括 openssl
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY prisma ./prisma
COPY src ./src
COPY scripts ./scripts
# 构建时设置 dummy 变量，以便 prisma generate 通过校验
ENV DATABASE_URL="mysql://dummy:dummy@localhost:3306/dummy"
RUN npm run prisma:generate
RUN npm run build

FROM node:20-bookworm-slim AS runner

# 运行时也需要 openssl
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY prisma ./prisma
COPY scripts ./scripts
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

EXPOSE 3000

CMD ["node", "dist/server.js"]
