{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    # Global git configuration (new unified settings format)
    settings = {
      # User info - customize these or set via environment variables
      user = {
        name = lib.mkDefault "Your Name";
        email = lib.mkDefault "your.email@example.com";
      };

      # Core settings
      core = {
        editor = "vim";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
        # pager is set automatically by programs.delta
      };

      # Init settings
      init = {
        defaultBranch = "main";
      };

      # Pull settings
      pull = {
        rebase = true;
      };

      # Push settings
      push = {
        default = "current";
        autoSetupRemote = true;
      };

      # Merge settings
      merge = {
        conflictstyle = "diff3";
        tool = "vimdiff";
      };

      # Diff settings
      diff = {
        colorMoved = "default";
      };

      # Rebase settings
      rebase = {
        autoStash = true;
        autoSquash = true;
      };

      # Credential helper
      credential = {
        helper = "cache --timeout=3600";
      };

      # Color settings
      color = {
        ui = true;
        branch = {
          current = "yellow reverse";
          local = "yellow";
          remote = "green";
        };
        diff = {
          meta = "yellow bold";
          frag = "magenta bold";
          old = "red bold";
          new = "green bold";
        };
        status = {
          added = "green";
          changed = "yellow";
          untracked = "red";
        };
      };

      # URL rewrites
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };

      # Fetch settings
      fetch = {
        prune = true;
        pruneTags = true;
      };

      # Branch settings
      branch = {
        sort = "-committerdate";
      };

      # Tag settings
      tag = {
        sort = "-version:refname";
      };

      # Git aliases
      alias = {
        # Status shortcuts
        st = "status";
        s = "status -s";

        # Commit shortcuts
        ci = "commit";
        cm = "commit -m";
        ca = "commit --amend";
        can = "commit --amend --no-edit";

        # Branch shortcuts
        br = "branch";
        co = "checkout";
        cob = "checkout -b";
        sw = "switch";
        swc = "switch -c";

        # Diff shortcuts
        df = "diff";
        dfs = "diff --staged";
        dfc = "diff --cached";

        # Log shortcuts
        lg = "log --oneline --graph --decorate";
        lga = "log --oneline --graph --decorate --all";
        ll = "log --pretty=format:'%C(yellow)%h%Creset %C(green)%ad%Creset | %s%C(red)%d%Creset %C(blue)[%an]%Creset' --date=short";

        # Reset shortcuts
        unstage = "reset HEAD --";
        undo = "reset --soft HEAD~1";
        discard = "checkout --";

        # Stash shortcuts
        sl = "stash list";
        sp = "stash pop";
        ss = "stash save";

        # Remote shortcuts
        f = "fetch";
        fa = "fetch --all";
        pl = "pull";
        ps = "push";
        psf = "push --force-with-lease";

        # Utility
        aliases = "config --get-regexp alias";
        branches = "branch -a";
        tags = "tag -l";
        remotes = "remote -v";
        contributors = "shortlog -sn";
        last = "log -1 HEAD --stat";
        whoami = "config user.email";

        # Interactive rebase
        ri = "rebase -i";
        rc = "rebase --continue";
        ra = "rebase --abort";

        # Cherry-pick
        cp = "cherry-pick";
        cpc = "cherry-pick --continue";
        cpa = "cherry-pick --abort";

        # Clean up
        cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d";
      };
    };

    # Global gitignore
    ignores = [
      # OS files
      ".DS_Store"
      "Thumbs.db"
      "Desktop.ini"

      # Editor files
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      ".idea/"
      "*.sublime-workspace"

      # Environment files
      ".env"
      ".env.local"
      ".env.*.local"

      # Build outputs
      "node_modules/"
      "__pycache__/"
      "*.pyc"
      ".pytest_cache/"
      "target/"
      "dist/"
      "build/"

      # Logs
      "*.log"
      "npm-debug.log*"
      "yarn-debug.log*"

      # Nix
      "result"
      "result-*"

      # Direnv
      ".direnv/"

      # mise
      ".mise.local.toml"
    ];

    # Large File Storage
    lfs = {
      enable = true;
    };
  };

  # Delta for better diffs (separate program)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "Dracula";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        pc = "pr create";
        pl = "pr list";
        is = "issue status";
        il = "issue list";
        ic = "issue create";
      };
    };
  };
}
