{
 "name": "Build APK",
 "on": {
  "workflow_dispatch": {}
 },
 "jobs": {
  "build": {
   "runs-on": "ubuntu-latest",
   "steps": [
    {
     "uses": "actions/checkout@v4"
    },
    {
     "uses": "actions/setup-java@v4",
     "with": {
      "distribution": "temurin",
      "java-version": "17"
     }
    },
    {
     "uses": "subosito/flutter-action@v2",
     "with": {
      "channel": "stable"
     }
    },
    {
     "name": "Unpack project",
     "run": "mkdir src && unzip -q project.zip -d src\nD=$(dirname $(find src -name pubspec.yaml | head -1))\necho \"D=$D\" >> $GITHUB_ENV\nflutter create --org com.diecast --project-name diecast_garage --platforms android app\nrm -rf app/lib app/assets app/test\ncp -r $D/lib $D/assets $D/pubspec.yaml app/\ncp $D/keystore/diecast.jks app/android/app/diecast.jks\n[ -f $D/google-services.json ] && cp $D/google-services.json app/android/app/google-services.json || echo no-google-services\n[ -f google-services.json ] && cp google-services.json app/android/app/google-services.json || true\nmkdir -p app/assets/models\ncurl -fL --retry 3 -o app/assets/models/embedder.tflite https://storage.googleapis.com/mediapipe-models/image_embedder/mobilenet_v3_small/float32/latest/mobilenet_v3_small.tflite || { rm -f app/assets/models/embedder.tflite; echo no-ai-model; }"
    },
    {
     "name": "Patch Android",
     "run": "cat > patch.py << 'PYEOF'\nimport re,os,sys\na='app/android/app/'\ndef rw(p,f):\n    s=open(p).read(); s=f(s); open(p,'w').write(s)\nkts=os.path.exists(a+'build.gradle.kts')\ngj=os.path.exists('app/android/app/google-services.json')\nif kts:\n    def app(s):\n        s=s.replace('minSdk = flutter.minSdkVersion','minSdk = 26')\n        s=re.sub(r'compileSdk\\s*=\\s*flutter\\.compileSdkVersion','compileSdk = 36',s)\n        if gj and 'google-services' not in s:\n            s=s.replace('id(\"dev.flutter.flutter-gradle-plugin\")','id(\"dev.flutter.flutter-gradle-plugin\")\\n    id(\"com.google.gms.google-services\")',1)\n        s=s.replace('buildTypes {','signingConfigs {\\n        create(\"release\") {\\n            storeFile = file(\"diecast.jks\")\\n            storePassword = \"diecast123\"\\n            keyAlias = \"diecast\"\\n            keyPassword = \"diecast123\"\\n        }\\n    }\\n    buildTypes {',1)\n        s=s.replace('signingConfigs.getByName(\"debug\")','signingConfigs.getByName(\"release\")')\n        return s\n    rw(a+'build.gradle.kts',app)\n    if gj:\n        def st(s):\n            return s.replace('id(\"org.jetbrains.kotlin.android\")','id(\"com.google.gms.google-services\") version \"4.4.2\" apply false\\n    id(\"org.jetbrains.kotlin.android\")',1)\n        rw('app/android/settings.gradle.kts',st)\nelse:\n    sys.exit('Unsupported Gradle layout: send me the build log')\ndef man(s):\n    perms=['SCHEDULE_EXACT_ALARM','USE_EXACT_ALARM','POST_NOTIFICATIONS','WAKE_LOCK','VIBRATE','USE_FULL_SCREEN_INTENT','RECEIVE_BOOT_COMPLETED','FOREGROUND_SERVICE','FOREGROUND_SERVICE_MEDIA_PLAYBACK','REQUEST_IGNORE_BATTERY_OPTIMIZATIONS','INTERNET']\n    add=''.join('    <uses-permission android:name=\"android.permission.%s\"/>\\n'%p for p in perms)\n    s=s.replace('<application',add+'    <application',1)\n    s=s.replace('<activity','<activity android:showWhenLocked=\"true\" android:turnScreenOn=\"true\"',1)\n    return s\nrw('app/android/app/src/main/AndroidManifest.xml',man)\nprint('patched, google-services:',gj)\nPYEOF\npython3 patch.py\nprintf '\\nkotlin.jvm.target.validation.mode=ignore\\n' >> app/android/gradle.properties\nyes | sdkmanager --licenses > /dev/null || true\nsdkmanager \"platforms;android-36\" \"build-tools;36.0.0\" > /dev/null || true"
    },
    {
     "name": "Extra fixes",
     "run": "cat > app/android/app/proguard-rules.pro << 'EOF'\n-dontwarn com.google.mlkit.vision.text.**\nEOF\ncat > fix.py << 'PYEOF'\np='app/android/app/build.gradle.kts'\ns=open(p).read()\nold='signingConfig = signingConfigs.getByName(\"release\")'\nif old in s:\n    s=s.replace(old, old+'\\n            isMinifyEnabled = false\\n            isShrinkResources = false\\n            proguardFiles(getDefaultProguardFile(\"proguard-android-optimize.txt\"), \"proguard-rules.pro\")',1)\n    open(p,'w').write(s)\n    print('app gradle fixed')\nelse:\n    print('WARNING: release block not found')\np='app/android/build.gradle.kts'\ns=open(p).read()\nsnippet='subprojects {\\n    if (!state.executed) {\\n        afterEvaluate {\\n            try {\\n                extensions.findByName(\"android\")?.withGroovyBuilder { \"compileSdkVersion\"(36) }\\n            } catch (e: Exception) {\\n                println(\"compileSdk skipped for \" + name)\\n            }\\n        }\\n    }\\n}\\n\\n'\nopen(p,'w').write(snippet+s)\nprint('root gradle fixed')\nPYEOF\npython3 fix.py\ncat app/android/build.gradle.kts | head -30\nrm -rf app/android/app/src/main/res/mipmap-anydpi-v26\n[ -d \"$D/icons\" ] && cp -r \"$D/icons/.\" app/android/app/src/main/res/ || echo no-icons\n"
    },
    {
     "name": "Build",
     "run": "cd app\n(flutter pub get && flutter build apk --release --no-shrink) 2>&1 | tee ../build.log\nkeytool -list -v -keystore android/app/diecast.jks -storepass diecast123 | grep SHA1",
     "shell": "bash"
    },
    {
     "name": "Show log summary",
     "if": "always()",
     "shell": "bash",
     "run": "{ echo '## Build log (last 80 lines)'; echo '```'; tail -n 80 build.log 2>/dev/null || echo 'no build.log'; echo '```'; } >> $GITHUB_STEP_SUMMARY"
    },
    {
     "name": "Save full log",
     "if": "always()",
     "uses": "actions/upload-artifact@v4",
     "with": {
      "name": "build-log",
      "path": "build.log",
      "if-no-files-found": "ignore"
     }
    },
    {
     "uses": "actions/upload-artifact@v4",
     "with": {
      "name": "diecast-garage-apk",
      "path": "app/build/app/outputs/flutter-apk/app-release.apk"
     }
    }
   ]
  }
 }
}
