# Trade X Mobile

The mobile client uses `https://cloudvideo.online` as its default API base URL.
Registration requests are sent to `https://cloudvideo.online/api/v1/...`.

## Run the app

```powershell
flutter run
```

To target a different backend for development or staging, pass a build-time override:

```powershell
flutter run --dart-define=TRADEX_API_BASE_URL=https://api.example.com
```
