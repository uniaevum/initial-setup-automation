{ config, pkgs, lib, isLinux, isDarwin, isWSL, ... }:

let
  # Custom PS1: white time, green user, white colon, cyan path (2 levels), white $ and input
  customPS1 = ''
    # Colors
    GREEN="\[\033[0;32m\]"
    CYAN="\[\033[0;36m\]"
    WHITE="\[\033[0;37m\]"
    RESET="\[\033[0m\]"

    # Function to get last 2 directory levels
    short_pwd() {
      local pwd_str="$PWD"
      local home_str="$HOME"

      # Replace home with ~
      if [[ "$pwd_str" == "$home_str" ]]; then
        echo "~"
        return
      elif [[ "$pwd_str" == "$home_str"/* ]]; then
        pwd_str="~''${pwd_str#$home_str}"
      fi

      # Get last 2 components
      local parts=(''${pwd_str//\// })
      local len=''${#parts[@]}

      if [[ $len -le 2 ]]; then
        echo "$pwd_str"
      else
        echo "''${parts[$len-2]}/''${parts[$len-1]}"
      fi
    }

    # Set PS1: white time, green user, white colon, cyan path, white $ and rest
    PS1="''${WHITE}\t ''${GREEN}\u''${WHITE}:''${CYAN}\$(short_pwd)''${WHITE}\$ ''${RESET}"
  '';

  # Common shell aliases
  commonAliases = {
    # Navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";

    # List files (using eza as modern replacement)
    ls = "eza";
    ll = "eza -la --git";
    la = "eza -a";
    l = "eza -F";
    lt = "eza -T";

    # Modern replacements
    cat = "bat --paging=never";
    diff = "delta";

    # Safety
    rm = "rm -i";
    cp = "cp -i";
    mv = "mv -i";

    # Git shortcuts
    g = "git";
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
    gd = "git diff";
    gco = "git checkout";
    gb = "git branch";
    glog = "git log --oneline --graph --decorate";

    # Docker shortcuts
    d = "docker";
    dc = "docker compose";
    dps = "docker ps";
    dpsa = "docker ps -a";

    # Kubernetes shortcuts
    k = "kubectl";
    kgp = "kubectl get pods";
    kgs = "kubectl get services";
    kgd = "kubectl get deployments";

    # Terraform shortcuts
    tf = "terraform";
    tfi = "terraform init";
    tfp = "terraform plan";
    tfa = "terraform apply";

    # Misc
    grep = "grep --color=auto";
    df = "df -h";
    du = "du -h";
    free = if isLinux then "free -h" else "vm_stat";
    cls = "clear";
    reload = "source ~/.bashrc";

    # Home Manager
    hm = "home-manager";
    hms = "home-manager switch";
    hme = "home-manager edit";
  };
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = commonAliases;

    historyControl = [ "ignoredups" "ignorespace" ];
    historyFileSize = 100000;
    historySize = 10000;

    initExtra = ''
      ${customPS1}

      # Enable bash completion
      if [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
      fi

      # mise: use shims instead of activate for faster shell startup
      export PATH="$HOME/.local/share/mise/shims:$PATH"

      # kubectl completion
      if command -v kubectl &> /dev/null; then
        source <(kubectl completion bash)
        complete -o default -F __start_kubectl k
      fi

      # helm completion
      if command -v helm &> /dev/null; then
        source <(helm completion bash)
      fi

      # terraform completion
      if command -v terraform &> /dev/null; then
        complete -C terraform terraform
        complete -C terraform tf
      fi

      # Docker completion
      if command -v docker &> /dev/null; then
        if [ -f /usr/share/bash-completion/completions/docker ]; then
          source /usr/share/bash-completion/completions/docker
        fi
      fi
    '';

    bashrcExtra = ''
      # Additional bashrc customizations can go here

      # Disable Ctrl+S freezing terminal
      stty -ixon 2>/dev/null

      # Better history search with arrow keys
      bind '"\e[A": history-search-backward' 2>/dev/null
      bind '"\e[B": history-search-forward' 2>/dev/null
    '';
  };

  # Also configure zsh as an alternative
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = commonAliases;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    initContent = ''
      # Custom prompt for zsh: white time, green user, white colon, cyan path (2 levels), white $ and input
      setopt PROMPT_SUBST

      # Function to get last 2 directory levels
      short_pwd() {
        local pwd_str="$PWD"
        local home_str="$HOME"

        # Replace home with ~
        if [[ "$pwd_str" == "$home_str" ]]; then
          echo "~"
          return
        elif [[ "$pwd_str" == "$home_str"/* ]]; then
          pwd_str="~''${pwd_str#$home_str}"
        fi

        # Get last 2 components
        local parts=(''${(s:/:)pwd_str})
        local len=''${#parts[@]}

        if [[ $len -le 2 ]]; then
          echo "$pwd_str"
        else
          echo "''${parts[$len-1]}/''${parts[$len]}"
        fi
      }

      # white time, green user, white colon, cyan path, white $ and rest
      PROMPT='%F{white}%T %F{green}%n%F{white}:%F{cyan}$(short_pwd)%F{white}$ %f'

      # mise: use shims instead of activate for faster shell startup
      export PATH="$HOME/.local/share/mise/shims:$PATH"

      # kubectl completion
      if command -v kubectl &> /dev/null; then
        source <(kubectl completion zsh)
      fi

      # helm completion
      if command -v helm &> /dev/null; then
        source <(helm completion zsh)
      fi
    '';
  };

  # Starship prompt (optional modern alternative)
  programs.starship = {
    enable = false; # Set to true to use starship instead of custom PS1
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      directory = {
        truncation_length = 5;
        truncate_to_repo = true;
      };
      git_branch = {
        symbol = " ";
      };
      docker_context = {
        symbol = " ";
      };
      kubernetes = {
        disabled = false;
        symbol = "☸ ";
      };
    };
  };

  # direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # fzf for fuzzy finding
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };
}
