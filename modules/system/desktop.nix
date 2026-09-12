# Desktop stack — Pure Wayland Hyprland + portals + greeter + SwayOSD.
{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = false; # Strict pure Wayland (No XWayland / Xorg)
  };

  programs.uwsm.enable = true;

  # NOTE: programs.hyprland already adds xdg-desktop-portal-hyprland AND
  # xdg-desktop-portal-gtk to extraPortals. Listing them again here puts the
  # same unit names in twice and breaks the build with:
  #   ln: .../user-units/xdg-desktop-portal-hyprland.service: File exists
  # So only keep the portal *config* (backend order), no extraPortals.
  xdg.portal = {
    enable = true;
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

  # Greeter: greetd with tuigreet.
  # MUST launch the uwsm-managed session entry (hyprland-uwsm.desktop), NOT
  # bare `uwsm start hyprland`: the withUWSM Hyprland wrapper warns and skips
  # UWSM integration otherwise, which breaks every `uwsm-app` autostart
  # (awww-daemon, hypridle, ...) and leaves waybar/rofi unstyled + no wallpaper.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --cmd 'uwsm start hyprland-uwsm.desktop'";
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
