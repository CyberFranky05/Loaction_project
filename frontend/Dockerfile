# Use Node.js official image
FROM node:20-slim AS builder

# Build arguments
ARG PUBLIC_API_URL=http://mrelectron.xyz/api/v1
ARG PUBLIC_KEYCLOAK_URL=http://mrelectron.xyz/auth
ARG PUBLIC_KEYCLOAK_REALM=location-auth-realm
ARG PUBLIC_KEYCLOAK_CLIENT_ID=location-auth-frontend
ARG PUBLIC_SUPABASE_URL=https://mnjazdphxhxgwlmqtgeb.supabase.co
ARG PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1uamF6ZHBoeGh4Z3dsbXF0Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5NjcyNDAsImV4cCI6MjA3NjU0MzI0MH0.dfgqMP2Pz5MiaXrrZqYoKDwQ0Uz2dp8xFPU1ZFkPQAo

# Set as environment variables for the build
ENV PUBLIC_API_URL=$PUBLIC_API_URL
ENV PUBLIC_KEYCLOAK_URL=$PUBLIC_KEYCLOAK_URL
ENV PUBLIC_KEYCLOAK_REALM=$PUBLIC_KEYCLOAK_REALM
ENV PUBLIC_KEYCLOAK_CLIENT_ID=$PUBLIC_KEYCLOAK_CLIENT_ID
ENV PUBLIC_SUPABASE_URL=$PUBLIC_SUPABASE_URL
ENV PUBLIC_SUPABASE_ANON_KEY=$PUBLIC_SUPABASE_ANON_KEY

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install && npm cache clean --force

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:20-slim

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies
RUN npm install --omit=dev && npm cache clean --force

# Copy built application from builder
COPY --from=builder /app/build ./build

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

CMD ["node", "build/index.js"]
