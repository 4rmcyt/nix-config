{pkgs, ...}: let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "latest";
    platformToolsVersion = "latest";
    buildToolsVersions = ["35.0.0"];
    platformVersions = ["36"];
    includeNDK = false;
    includeEmulator = false;
    extraLicenses = ["android-sdk-license"];
  };
in {
  home.packages = [
    androidComposition.androidsdk
    pkgs.jdk21
  ];

  home.sessionVariables = {
    ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
    JAVA_HOME = "${pkgs.jdk21}";
  };
}
