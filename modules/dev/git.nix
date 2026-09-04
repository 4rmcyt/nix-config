{osConfig, ...}: {
  programs.git = {
    enable = true;
    settings = {
      commit.gpgsign = true;
      gpg.program = "gpg";
      user = {
        email = osConfig.my.defaults.email;
        name = osConfig.my.defaults.gitUsername;
        signingkey = osConfig.my.defaults.gitSigningKey;
      };
    };
  };
}
