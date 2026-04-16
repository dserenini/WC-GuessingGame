# Builder Stage
FROM dart:stable AS build

WORKDIR /app

# Clone Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Install flutter and accept licenses
RUN flutter channel stable && flutter upgrade && flutter doctor -v

# Copy project files
COPY . .

# Fetch dependencies
RUN flutter pub get

# Ingest Supabase Env Vars safely during build
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

# Build Web Minified
RUN flutter build web --release \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Serve Stage
FROM nginx:alpine

# Copy compiled flutter web output to Nginx serving directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Replace default nginx config with SPA routing logic
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
