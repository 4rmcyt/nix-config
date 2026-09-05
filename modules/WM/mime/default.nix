{pkgs, ...}: {
  home.packages = with pkgs; [
    file-roller
    imv
    zathura
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "nemo.desktop";

      "text/plain" = "dev.zed.Zed.desktop";
      "text/x-script" = "dev.zed.Zed.desktop";
      "text/x-shellscript" = "dev.zed.Zed.desktop";
      "application/x-shellscript" = "dev.zed.Zed.desktop";
      "text/x-python" = "dev.zed.Zed.desktop";
      "text/x-csrc" = "dev.zed.Zed.desktop";
      "text/x-chdr" = "dev.zed.Zed.desktop";
      "text/x-c++src" = "dev.zed.Zed.desktop";
      "text/x-c++hdr" = "dev.zed.Zed.desktop";
      "text/x-rust" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";
      "application/json" = "dev.zed.Zed.desktop";
      "application/xml" = "dev.zed.Zed.desktop";
      "application/x-yaml" = "dev.zed.Zed.desktop";
      "text/x-yaml" = "dev.zed.Zed.desktop";
      "text/yaml" = "dev.zed.Zed.desktop";
      "text/toml" = "dev.zed.Zed.desktop";
      "text/x-toml" = "dev.zed.Zed.desktop";

      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "x-scheme-handler/ftp" = "firefox.desktop";

      "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "application/epub+zip" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "application/x-fictionbook" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "application/x-mobipocket-ebook" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "application/oxps" = "org.pwmt.zathura-pdf-mupdf.desktop";
      "image/vnd.djvu" = "org.pwmt.zathura-djvu.desktop";
      "image/vnd.djvu+multipage" = "org.pwmt.zathura-djvu.desktop";
      "application/postscript" = "org.pwmt.zathura-ps.desktop";
      "application/eps" = "org.pwmt.zathura-ps.desktop";
      "application/x-eps" = "org.pwmt.zathura-ps.desktop";

      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/jpg" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/avif" = "imv.desktop";
      "image/heif" = "imv.desktop";
      "image/jxl" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "image/x-bmp" = "imv.desktop";
      "image/qoi" = "imv.desktop";

      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/3gpp" = "mpv.desktop";

      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/x-vorbis+ogg" = "mpv.desktop";
      "audio/opus" = "mpv.desktop";
      "audio/aac" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/x-m4a" = "mpv.desktop";

      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-bzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-bzip-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-xz-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-zstd-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/x-rar-compressed" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";
      "application/zstd" = "org.gnome.FileRoller.desktop";
      "application/x-lzma" = "org.gnome.FileRoller.desktop";
      "application/x-lz4" = "org.gnome.FileRoller.desktop";
      "application/x-lzip" = "org.gnome.FileRoller.desktop";
      "application/x-rpm" = "org.gnome.FileRoller.desktop";
      "application/x-deb" = "org.gnome.FileRoller.desktop";
      "application/vnd.debian.binary-package" = "org.gnome.FileRoller.desktop";
      "application/x-java-archive" = "org.gnome.FileRoller.desktop";
      "application/vnd.android.package-archive" = "org.gnome.FileRoller.desktop";
    };
  };
}
