# 🚀 Feedzo Admin Deployment Guide (Vercel & Netlify)

Because the **Feedzo Admin Panel** is built with Flutter Web, it compiles into a static website consisting of HTML, CSS, and JavaScript. This makes it incredibly easy to host on static hosting providers like Vercel and Netlify.

This guide covers the two best ways to deploy your app from GitHub:

---

## Method 1: The Easiest Way (Pre-build & Deploy)
If you just want to get your site live quickly without dealing with CI/CD scripts, do this:

### 1. Build the Web App Locally
Open your terminal, navigate to the admin project folder, and run:
```bash
cd feedzo_admin
flutter build web --release
```
*This creates a `build/web` directory containing your compiled website.*

### 2. Push to GitHub
Wait! By default, Flutter ignores the `build/` directory in Git (`.gitignore`).
To deploy the `build/web` folder directly, you must force-add it to GitHub:
```bash
git add -f build/web
git commit -m "chore: add flutter web build for deployment"
git push origin main
```

### 3. Deploy to Vercel or Netlify
**For Vercel:**
1. Go to your [Vercel Dashboard](https://vercel.com/dashboard) and click **Add New > Project**.
2. Import your GitHub repository.
3. Open the **"Build and Output Settings"** accordion.
4. Set the **Output Directory** to `build/web`.
5. Set the **Build Command** to be completely empty (override the default).
6. Click **Deploy**.

**For Netlify:**
1. Go to your [Netlify Dashboard](https://app.netlify.com/) and click **Add new site > Import an existing project**.
2. Connect your GitHub and select the repository.
3. Set the **Publish directory** to `build/web`.
4. Leave the Build Command empty.
5. Click **Deploy Site**.

---

## Method 2: Continuous Deployment (Vercel Build Script)
If you want Vercel to automatically compile your Flutter app every time you push code (without committing the `build` folder), you need a custom build script.

### 1. Create a Vercel Build Script
In your `feedzo_admin` root directory, create a file named `build.sh`:

```bash
#!/bin/bash
# Download and install Flutter SDK
echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Build the app
echo "Building Flutter Web..."
flutter clean
flutter pub get
flutter build web --release
```

### 2. Make the script executable
Run this command in your terminal so Vercel has permission to run it:
```bash
git update-index --chmod=+x build.sh
```

### 3. Push to GitHub
```bash
git add build.sh
git commit -m "feat: add vercel build script"
git push origin main
```

### 4. Configure Vercel
1. Go to Vercel, import your GitHub repo.
2. Under "Build and Output Settings":
   * **Build Command**: `./build.sh`
   * **Output Directory**: `build/web`
3. Click **Deploy**. Vercel will now download Flutter and build your app automatically on every push!

---

## 🛑 Important Fix for Client-Side Routing
Flutter web uses client-side routing. If you refresh a page (like `yoursite.com/orders`), Vercel/Netlify might return a 404 error because the page doesn't physically exist on the server.

### How to fix it:

**If using Vercel:**
Create a file named `vercel.json` in your `feedzo_admin` folder with this content:
```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

**If using Netlify:**
Create a file named `_redirects` inside your `feedzo_admin/web/` folder and add this exact single line:
```
/*    /index.html   200
```
Then run `flutter build web` again and push, or let your CI script build it.

---

## Firebase Whitelist (Crucial)
After your app is live, you **MUST** whitelist your new Vercel/Netlify domain in Firebase, otherwise Google Sign-In and Firestore will block requests!

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Navigate to **Authentication > Settings > Authorized domains**.
3. Click **Add domain** and enter your Vercel or Netlify URL (e.g., `feedzo-admin.vercel.app`).
4. Click Add.
