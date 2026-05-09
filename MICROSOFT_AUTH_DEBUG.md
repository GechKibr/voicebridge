# Microsoft Authentication - Debugging Guide

## Issue: Infinite Loading After Email/Password Entry

### Problem Summary
User enters Microsoft credentials → infinite loading spinner → no error message

### Root Causes Fixed ✅

1. **No HTTP timeout** - Backend requests could hang indefinitely
   - Fixed: Added 30-second timeout to all auth requests
   
2. **Poor error messages** - Errors weren't being reported clearly
   - Fixed: Better exception handling with specific messages

3. **Android Manifest redirect URI mismatch**
   - Fixed: Now uses `${appAuthRedirectScheme}` placeholder from build config

---

## Testing Steps

### Step 1: Verify Backend is Accessible
Your backend is configured at: **https://cmfs.onrender.com**

Test the Microsoft auth endpoint:
```bash
curl -X POST https://cmfs.onrender.com/api/auth/microsoft/mobile/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"access_token": "test_token"}'
```

**Expected responses:**
- `200 OK` with `{"access": "...", "refresh": "..."}` = User exists, proceed to dashboard
- `202` or `404` with registration fields = New user, show registration form
- Timeout or connection refused = **Backend not responding** ❌

### Step 2: Check Current Configuration

Your `.env` file has:
```
BACKEND_URL=https://cmfs.onrender.com
MICROSOFT_CLIENT_ID=717df1e7-c444-4623-99e6-7dcebc53d49b
MICROSOFT_REDIRECT_URI=msauth://com.example.voicebrige/97o5GjGRMursH0mpMaTa279I3ug%3D
```

Verify these match your Azure AD registration:
- App ID: Should match `MICROSOFT_CLIENT_ID`
- Redirect URI: Should match `MICROSOFT_REDIRECT_URI` (note the URL encoding `%3D`)

### Step 3: Test with Real Microsoft Credentials

1. Open the app and tap **"Sign in with Microsoft"**
2. Enter your Microsoft account email/password
3. **If infinite loading:**
   - Wait ~35 seconds - timeout error should appear
   - Note the exact error message
   - Share with backend team

### Step 4: Check Android Manifest & Build Config

**These have been fixed, verify they're correct:**

[android/app/build.gradle.kts](android/app/build.gradle.kts#L25-L36):
```kotlin
manifestPlaceholders["appAuthRedirectScheme"] = "msauth"
```

[android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L40-L54):
```xml
<data
    android:scheme="${appAuthRedirectScheme}"
    android:host="com.example.voicebrige"
    android:path="/97o5GjGRMursH0mpMaTa279I3ug=" />
```

---

## Possible Error Messages & Solutions

### "Backend timeout: Microsoft authentication backend request timed out after 30 seconds"
**Cause:** Backend at https://cmfs.onrender.com is not responding  
**Solution:**
1. Check if Render.com service is up
2. Verify backend is running: `curl https://cmfs.onrender.com/api/`
3. Check for 502/503 errors (service down)

### "Microsoft backend error: Network failure"
**Cause:** Network connectivity issue or SSL certificate problem  
**Solution:**
1. Check device internet connection
2. Try on WiFi vs mobile data
3. Check if backend uses valid HTTPS certificate

### "Manifest merger failed : Attribute data@scheme requires placeholder"
**Cause:** AndroidManifest.xml placeholder not being resolved  
**Solution:**
1. Rebuild: `flutter clean && flutter pub get`
2. Run: `flutter run`

### App shows registration form instead of dashboard (after Microsoft auth succeeds)
**Cause:** User doesn't exist in backend database  
**Solution:**
- Complete the registration form
- Backend will create account and log you in

---

## Backend Endpoint Expected Behavior

### POST /api/auth/microsoft/mobile/

**Request:**
```json
{
  "access_token": "<microsoft_graph_access_token>"
}
```

**Response if user exists (200):**
```json
{
  "access": "jwt_access_token",
  "refresh": "jwt_refresh_token",
  "user": {
    "id": 123,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

**Response if user needs registration (202/404/409):**
```json
{
  "is_new": true,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe"
}
```

---

## Manual Testing with Flutter DevTools

1. Start your app in debug mode
2. Run: `flutter pub global activate devtools && devtools`
3. In Flutter DevTools, open the **Logging** tab
4. Tap "Sign in with Microsoft" on your app
5. Watch the logs for detailed error information
6. Look for lines containing "Microsoft" or "auth"

---

## For Backend Team

If the issue persists after timeouts, provide:
1. Backend logs from timestamp when you attempted login
2. Confirm `/api/auth/microsoft/mobile/` endpoint exists and is NOT in maintenance mode
3. Check if endpoint requires additional headers or authentication
4. Verify Microsoft Graph API is accessible from backend
5. Confirm response format matches expected schema

---

## Rebuild After Changes

```bash
cd c:\Users\admin\Documents\flutter-project\voicebrige

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run with debug info
flutter run --verbose
```

## Quick Troubleshooting Summary

| Symptom | Likely Cause | Action |
|---------|--------------|--------|
| Infinite loading | Backend timeout | Wait for error or check backend status |
| After 30s: "timeout" error | Backend unreachable | Check https://cmfs.onrender.com status |
| After 30s: "network" error | Network/SSL issue | Check internet, try WiFi |
| Registration form appears | Normal - user is new | Complete registration |
| Authentication cancelled popup | User clicked cancel | Try again |
| No loading spinner shown | UI not updating | Rebuild with `flutter clean` |
