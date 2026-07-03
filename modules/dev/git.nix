_: {
  programs.git = {
    enable = true;
    settings = {
      commit.gpgsign = true;
      gpg.program = "gpg";
      user = {
        email = "redacted@example.com";
        name = "4rmcyt";
        signingkey = "D85B52C9288A138E";
      };
    };
  };
}
