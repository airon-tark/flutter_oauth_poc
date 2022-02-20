# oauth_poc

The flutter oauth proof-of-concept

## How to build

1. Install Flutter (https://docs.flutter.dev/get-started/install)

2. Make sure everything is ok by running `flutter doctor`
You should see something like that 
```          
$ flutter doctor
[✓] Flutter (Channel stable, 2.8.1, on macOS 11.4 20F71 darwin-x64, locale ru-RU)
[✓] Android toolchain - develop for Android devices (Android SDK version 33.0.0-rc1)
[!] Xcode - develop for iOS and macOS (Xcode 12.5.1)
    ! Flutter recommends a minimum Xcode version of 13.0.0.
      Download the latest version or update via the Mac App Store.
[✓] Chrome - develop for the web
[✓] Android Studio (version 4.2)
[✓] VS Code (version 1.50.1)
[✓] Connected device (2 available)
```       
Resolve issues if any. To see maximum details you can run `flutter doctor -v`

3. Clone the repository or download and unpack the archive with source code
``` 
$ git clone git@github.com:airon-tark/oauth_poc.git
$ cd oauth_poc
```    

4. Get the flutter dependencies
``` 
$ flutter pub get  
```     

5. Plug in physical device or run Android emulator or iOS simulator

6. Check if flutter can see the device
``` 
$ flutter devices  

2 connected devices:
sdk gphone x86 arm (mobile) • emulator-5554 • android-x86    • Android 11 (API 30) (emulator)
Chrome (web)                • chrome        • web-javascript • Google Chrome 98.0.4758.102
```        
The first line here is the running Android emulator

7. Run the project from the command line. 
``` 
$ flutter run
Using hardware rendering with device sdk gphone x86 arm. If you notice graphics artifacts, consider enabling software rendering with
"--enable-software-rendering".
Launching lib/main.dart on sdk gphone x86 arm in debug mode...
Running Gradle task 'assembleDebug'...                             35,9s
✓  Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app.apk...              2 821ms
Syncing files to device sdk gphone x86 arm...                      267ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on sdk gphone x86 arm is available at: http://127.0.0.1:63169/Y_mjmoVXty8=/
The Flutter DevTools debugger and profiler on sdk gphone x86 arm is available at: http://127.0.0.1:9100?uri=http://127.0.0.1:63169/Y_mjmoVXty8=/
I/flutter (21411): -->                         build - code - 84358190bf11bd55a416
D/EGL_emulation(21411): eglCreateContext: 0xebf1eaf0: maj 3 min 0 rcv 3
I/flutter (21411): -->                         build - token - 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
```  
There are a few ways of running the project. You can do it either from the command line, or from the Android Studio or XCode by pressing "run" button.
This way is the simplest to make sure the project is runnable for you

These two lines are the logs from the project
``` 
I/flutter (21411): -->                         build - code - 84358190bf11bd55a416
I/flutter (21411): -->                         build - token - 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
```                                                                                                    

You can see we got the `auth code` and then the `token`.

8. To make the build you can run one of these commands

```                 
# make release ios build
$ flutter build ios   

# make release android build in a modern way to upload to the Google Play
$ flutter build appbundle  

# make release android build in an old way if you want to distribute it NOT in Google Play
$ flutter build apk     

# make a debug build to give your teammates to test
$ flutter build apk --debug
```      

PLease note, that to build an iOS you should have XCode tools installed and have a provisioning profile from the Apple developer account.
