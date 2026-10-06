{ config, pkgs, ... }:

{
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    imports =
        [ # Include the results of the hardware scan.
        ./hardware-configuration.nix
            <nixos-hardware/microsoft/surface/common>
            <home-manager/nixos>
        ];

    # ======= SURFACE-ONLY START =======
    # ======= SURFACE-ONLY START =======
    # ======= SURFACE-ONLY START =======

    boot.kernelParams = [ "reboot=efi" ];
    environment.etc."libinput/local-overrides.quirks".text = ''
        [Microsoft Surface Laptop Studio Touchpad]
        MatchVendor=0x045E
            MatchProduct=0x09AF
            MatchUdevType=touchpad
            AttrPressureRange=25:10
            AttrPalmPressureThreshold=500
            '';

    # Kernel linux-surface
    hardware.microsoft-surface.kernelVersion = "longterm";

    # --- NVIDIA RTX A2000 (Ampere) with PRIME offload ---

    # Propietary Driver for X/Wayland
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
        enable = true;
        enable32Bit = true;  
    };

    hardware.nvidia = {
        modesetting.enable = true;

        powerManagement.enable = true;
        powerManagement.finegrained = true;

        open = false; 
        nvidiaSettings = true;

        prime = {
            offload = {
                enable = true;
                enableOffloadCmd = true; 
            };
            intelBusId  = "PCI:0:2:0";
            nvidiaBusId = "PCI:243:0:0";
        };
    };

    # Stage-Mode workaround so the touchpad works
    services.udev.extraRules = ''
        ACTION!="remove", KERNEL=="event[0-9]*", ATTRS{name}=="Microsoft Surface POS Tablet Mode Switch", ENV{LIBINPUT_IGNORE_DEVICE}="1"
        '';

    # Power-Management weird fix, how is this related?
    services.colord.enable = true;
    
    # ======= SURFACE-ONLY END =======
    # ======= SURFACE-ONLY END =======
    # ======= SURFACE-ONLY END =======

    # Bootloader.
    boot.loader.systemd-boot = {
        enable = true;
        configurationLimit = 3;
    };
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "nixos"; 
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Enable networking
    networking.networkmanager.enable = true;

    time.timeZone = "America/Mexico_City";

    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
        LC_ADDRESS = "es_MX.UTF-8";
        LC_IDENTIFICATION = "es_MX.UTF-8";
        LC_MEASUREMENT = "es_MX.UTF-8";
        LC_MONETARY = "es_MX.UTF-8";
        LC_NAME = "es_MX.UTF-8";
        LC_NUMERIC = "es_MX.UTF-8";
        LC_PAPER = "es_MX.UTF-8";
        LC_TELEPHONE = "es_MX.UTF-8";
        LC_TIME = "es_MX.UTF-8";
    };

    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    services.xserver.xkb = {
        layout = "latam";
        variant = "";
    };

    console.keyMap = "la-latin1";

    services.printing.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
    };

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # ======= ENVIRONMENT START =======
    # ======= ENVIRONMENT START =======
    # ======= ENVIRONMENT START =======

    environment.systemPackages = with pkgs; [
            neovim  
            git 
            gcc
            nodejs
            yarn
            clang-tools
            clamtk
    ];

    # ======= ENVIRONMENT END =======
    # ======= ENVIRONMENT END =======
    # ======= ENVIRONMENT END =======

    # ======= ZRAM START =======
    # ======= ZRAM START =======
    # ======= ZRAM START =======

    zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
    };

    # ======= ZRAM END =======
    # ======= ZRAM END =======
    # ======= ZRAM END =======

    # ======= VIRTUALISATION START =======
    # ======= VIRTUALISATION START =======
    # ======= VIRTUALISATION START =======

    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    # ======= VIRTUALISATION END =======
    # ======= VIRTUALISATION END =======
    # ======= VIRTUALISATION END =======


    # ======= FONTS START =======
    # ======= FONTS START =======
    # ======= FONTS START =======

    fonts.packages = with pkgs; [
        cozette
    ];

    # ======= FONTS END =======
    # ======= FONTS END =======
    # ======= FONTS END =======


    # ======= HOME-MANAGER START =======
    # ======= HOME-MANAGER START =======
    # ======= HOME-MANAGER START =======

    users.users."gonto" = {
        isNormalUser = true;
        description = "gonto";
        extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" ];
    };

    programs.zsh.enable = true;
    users.users.gonto.shell = pkgs.zsh;

    programs.firefox.enable = true;
    nixpkgs.config.allowUnfree = true;
    home-manager.useGlobalPkgs = true;

    home-manager.users.gonto = { pkgs, ... }: {
        home.stateVersion = "26.05";

        home.packages = with pkgs ; [
                alacritty
                tree-sitter
                xclip
                oneko
                discord
                gh
                vinegar
        ];

        # === alacritty ===
        programs.alacritty = {
            enable = true;
            settings = {
                font = {
                    normal.family = "Cozette";
                    size = 15;
                };
                window.opacity = 1.0; 
                colors = {
                    draw_bold_text_with_bright_colors = true;
                    primary = {
                        background = "#080808";
                        foreground = "#bdbdbd";
                    };
                    cursor = {
                        cursor = "#8e8e8e";
                        text = "#080808";
                    };
                    selection = {
                        text = "#080808";
                        background = "#b2ceee";
                    };
                    normal = {
                        black   = "#323437";
                        red     = "#ff5d5d";
                        green   = "#8cc85f";
                        yellow  = "#e3c78a";
                        blue    = "#80a0ff";
                        magenta = "#cf87e8"; 
                        cyan    = "#79dac8";
                        white   = "#c6c6c6";
                    };
                    bright = {
                        black   = "#949494";
                        red     = "#74b2ff";
                        green   = "#36c682";
                        yellow  = "#c6c684";
                        blue    = "#74b2ff";
                        magenta = "#ae81ff"; 
                        cyan    = "#85dc85";
                        white   = "#e4e4e4";
                    };
                };
            };
        };

        # === zsh + oh-my-zsh ===
        programs.zsh = {
            enable = true;
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;

            oh-my-zsh = {
                enable = true;
                theme = "strug";
                plugins = [ "git" "docker" ];
            };

            sessionVariables = {
                EDITOR = "nvim";
                SUDO_EDITOR = "nvim";
            };

            shellAliases = {
                editconf = "sudoedit /etc/nixos/configuration.nix";
                rebuild = "sudo nixos-rebuild switch";
                rmoldgen = "sudo nix-collect-garbage -d";
            };
        };
    };

    # ======= HOME-MANAGER END =======
    # ======= HOME-MANAGER END =======
    # ======= HOME-MANAGER END =======
    

    # ======= NIX-LD START =======
    # ======= NIX-LD START =======
    # ======= NIX-LD START =======

    programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
            stdenv.cc.cc.lib
                zlib
                openssl
                curl
                glib
                nss
                nspr
                libgcc
        ];
    };

    # ======= NIX-LD END =======
    # ======= NIX-LD END =======
    # ======= NIX-LD END =======

    services.clamav = {
        updater.enable = true;
        daemon.enable = true;
        daemon.settings.ExcludePath = [
            "^/proc"
                "^/sys"
                "^/dev"
                "^/run"
                "^/nix/store"   # already hash-verified, huge, and read-only
        ];
        scanner = {
            enable = true;
            interval = "Sun *-*-* 03:00:00";  # weekly, Sunday at 3 AM
                scanDirectories = [ "/" ];
        };
    };

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };
    
    # List services that you want to enable:
    
    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;
    
    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;
    
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "26.05"; # Did you read the comment?

}
