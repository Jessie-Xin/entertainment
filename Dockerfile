# 使用最新 Alpine 3.20 + Node 20 LTS
FROM node:22.14.0-alpine3.20 AS base

FROM base AS builder

# 显式指定所有版本
ARG PNPM_VERSION=9.13.0

RUN apk update && apk add --no-cache \
    python3 \
    make \
    g++ \
    libc6-compat \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/cache/apk/*

RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate

# 更新 cross-spawn 到安全版本
RUN npm install -g npm@10.9.0 && \
    # Remove old version
    npm uninstall -g cross-spawn && \
    npm cache clean --force && \
    # Find and remove any remaining old versions
    find /usr/local/lib/node_modules -name "cross-spawn" -type d -exec rm -rf {} + && \
    # Install new version
    npm install -g cross-spawn@7.0.5 --force && \
    # Configure npm
    npm config set save-exact=true && \
    npm config set legacy-peer-deps=true

RUN npm install -g node-gyp@10.1.0 sharp

WORKDIR /app

COPY pnpm-lock.yaml ./
# RUN --mount=type=secret,id=npmrc \
#     cp /run/secrets/npmrc ~/.npmrc
RUN pnpm fetch
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm install --offline --force && pnpm build

FROM base AS runner

RUN apk add --no-cache curl \
    # 确保 c-ares 库是最新的安全版本
    && apk upgrade --no-cache c-ares

# 更新 cross-spawn 到安全版本
RUN npm install -g npm@10.9.0 && \
    # Remove old version
    npm uninstall -g cross-spawn && \
    npm cache clean --force && \
    # Find and remove any remaining old versions
    find /usr/local/lib/node_modules -name "cross-spawn" -type d -exec rm -rf {} + && \
    # Install new version
    npm install -g cross-spawn@7.0.5 --force && \
    # Configure npm
    npm config set save-exact=true && \
    npm config set legacy-peer-deps=true

ARG RUNTIME_ENV
ENV RUNTIME_ENV=$RUNTIME_ENV
ENV NODE_ENV=production

RUN addgroup --system --gid 10001 nodejs && \
    adduser --system --uid 10001 nextjs

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 TZ=Asia/Macau
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /app

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /usr/local/lib/node_modules/sharp ./node_modules/sharp
COPY --from=builder --chown=nextjs:nodejs /usr/local/lib/node_modules/cross-spawn ./node_modules/cross-spawn


USER nextjs

ENV NEXT_SHARP_PATH=/app/node_modules/sharp
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
EXPOSE 3000

CMD ["node", "server.js"]