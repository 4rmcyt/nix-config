_: {
  programs.gpg = {
    enable = true;
    settings = {
      # Algorithm preferences
      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      s2k-cipher-algo = "AES256";
      s2k-digest-algo = "SHA512";

      # Charset and display
      charset = "utf-8";
      fixed-list-mode = true;
      keyid-format = "long";
      keyserver-options = "no-honor-keyserver-url";
      list-options = "show-uid-validity";
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      with-key-origin = true;
      with-keygrip = true;
      with-subkey-fingerprint = true;

      # Security and verification
      no-symkey-cache = true;
      require-cross-certification = true;
      throw-keyids = true;
      use-agent = true;
    };
  };
}
