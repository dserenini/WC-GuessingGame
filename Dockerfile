# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: Build Flutter Web
# ─────────────────────────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependency manifests first (layer caching)
COPY pubspec.yaml pubspec.lock ./

# Fetch dependencies
RUN flutter pub get

# Copy the rest of the project
COPY . .

# Ingest Supabase Env Vars safely during build
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

# Build Web Minified
RUN flutter build web --release \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: Serve with Nginx
# ─────────────────────────────────────────────────────────────────────────────
FROM nginx:alpine

# Copy compiled flutter web output to Nginx serving directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Replace default nginx config with SPA routing logic
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
