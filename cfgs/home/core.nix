{
  config,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.nvim ];

  # Set default editor.
  home.sessionVariables.EDITOR = "nvim";

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
  ];

  # Allow fonts to be discovered.
  fonts.fontconfig.enable = true;

  programs = {
    # Per-directory automatic environment loading.
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    gpg = {
      enable = true;
      settings.throw-keyids = false;
    };

    git = {
      enable = true;
      signing = {
        format = "openpgp";
        signByDefault = true;
        key = "0xAE53B4C2E58EDD45";
      };
      settings = {
        user.name = "Harry Ying";
        user.email = "lexugeyky@outlook.com";
        # Avoid complaints about impermanence's bind mount.
        credential.helper = "store --file=\"$HOME/.git_creds_dir/.git-credentials\"";
        pull.ff = "only";
      };
    };

    zsh = {
      enable = true;
      initContent = ''
        bindkey "^P" up-line-or-search
        bindkey "^N" down-line-or-search
      '';
      envExtra = "";
      defaultKeymap = "emacs";
      oh-my-zsh = {
        enable = true;
        theme = "agnoster";
        plugins = [ "git" ];
      };
      history.path = "$HOME/.zsh_hist_dir/.zsh_history";
    };
  };

  # GNOME and other Wayland DEs use systemd session variables to launch GUI apps.
  systemd.user.sessionVariables = config.home.sessionVariables;
}
