FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build

WORKDIR /workspace/apps/mobile
COPY apps/mobile/ ./
RUN flutter pub get

FROM flutter-build AS flutter-web-build
ARG API_HOST=localhost:9090
RUN flutter build web --release --dart-define=API_HOST=${API_HOST}

FROM nginx:alpine AS flutter-web
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=flutter-web-build /workspace/apps/mobile/build/web/ /usr/share/nginx/html/
EXPOSE 80

FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:stable AS android-flutter-build
WORKDIR /workspace/apps/mobile
COPY apps/mobile/ ./
RUN flutter pub get

FROM android-flutter-build AS android-apk
ARG API_HOST=10.0.2.2:9090
ARG ANDROID_ORG=com.example
RUN flutter create --platforms=android --project-name app_001 --org "${ANDROID_ORG}" --no-pub .
RUN manifest=android/app/src/main/AndroidManifest.xml \
    && if ! grep -q 'android.permission.INTERNET' "$manifest"; then \
      sed -i '/<application/i\    <uses-permission android:name="android.permission.INTERNET" />' "$manifest"; \
    fi \
    && sed -i 's/<application/<application android:usesCleartextTraffic="true"/' "$manifest"
RUN flutter build apk --release --dart-define=API_HOST=${API_HOST}
CMD ["sh", "-c", "mkdir -p /output && cp build/app/outputs/flutter-apk/app-release.apk /output/app-release.apk"]
