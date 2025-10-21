FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci && npm cache clean --force

COPY . .
COPY .env.production .env

RUN npm run build

FROM ubuntu:22.04 AS production

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates dumb-init && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1001 nodejs && useradd -r -u 1001 -g nodejs nodejs

WORKDIR /app

COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

RUN chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 CMD node -e "require('http').get('http://localhost:3000/api/v1/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

ENTRYPOINT ["dumb-init", "--"]

CMD ["node", "dist/main.js"]
