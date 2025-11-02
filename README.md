# mediscan_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Java (JDK) requirement for Android builds

This project has been updated to target Java 21 (latest LTS) for Android builds.

- Gradle wrapper: 8.12
- Android Gradle Plugin (AGP): 8.9.1

Make sure you install JDK 21 and point your environment to it before building the Android app. On Windows (PowerShell) you can set it for the current session:

```powershell
$env:JAVA_HOME = 'C:\\Program Files\\Java\\jdk-21'
# Optionally set Gradle to use a specific JDK installation in android/gradle.properties:
# org.gradle.java.home=C:\\Program Files\\Java\\jdk-21
```

After installing and configuring the JDK, restart your IDE/terminal and run a Gradle build (or `flutter build apk`) to verify everything works.
