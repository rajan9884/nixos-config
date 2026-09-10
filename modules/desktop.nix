# Desktop stack — Pure Wayland Hyprland + portals + greeter + SwayOSD.
{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = false; # Strict pure Wayland (No XWayland / Xorg)
  };

  programs.uwsm.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  # Polkit agent (polkit-gnome)
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Greeter: greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --cmd 'uwsm start hyprland'";
        user = "greeter";
      };
    };
  };

  # SwayOSD needs real backlight/uinput access.
  hardware.uinput.enable = true;
  services.udev.packages = with pkgs; [ swayosd ];

  # Touchpad & input handling
  services.libinput.enable = true;
}
