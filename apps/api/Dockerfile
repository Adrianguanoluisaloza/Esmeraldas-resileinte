# API Esmeraldas Resiliente. Imagen en dos etapas: compila TypeScript y deja solo lo necesario para correr.
FROM node:22-alpine AS compilacion
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine
ENV NODE_ENV=production CARPETA_FOTOS=/datos/fotos
WORKDIR /app
COPY --from=compilacion /app/node_modules ./node_modules
COPY --from=compilacion /app/dist ./dist
COPY package.json ./
RUN mkdir -p /datos/fotos && chown -R node:node /datos
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -qO- http://127.0.0.1:3000/salud || exit 1
CMD ["node", "dist/index.js"]
