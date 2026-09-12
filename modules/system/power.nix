# Power profile follows the plug: AC -> remembered-or-performance,
# battery -> remembered-or-balanced.
# power-profiles-daemon never switches on its own, so a udev rule kicks
# this on every AC plug/unplug, and it also runs once at boot.
# Honors the per-source memory written by `power-profiles set`
# (~/.local/state/power-profiles/{ac,battery}).
{ pkgs, ... }:
{
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", RUN+="${pkgs.systemd}/bin/systemctl start --no-block power-profiles-autodetect.service"
  '';

  systemd.services.power-profiles-autodetect = {
    description = "Apply remembered power profile for AC/battery";
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.power-profiles-daemon ];
    script = ''
      set -u
      STATE_DIR=/home/rajan/.local/state/power-profiles

      on_ac=false
      for ps in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
        [ -r "$ps/online" ] && [ "$(cat "$ps/online")" = "1" ] && on_ac=true
      done

      if $on_ac; then key=ac; primary=performance; fallback=balanced; else key=battery; primary=balanced; fallback=power-saver; fi
      [ -r "$STATE_DIR/$key" ] && primary=$(<"$STATE_DIR/$key")

      powerprofilesctl set "$primary" 2>/dev/null \
        || powerprofilesctl set "$fallback" 2>/dev/null \
        || true
    '';
    serviceConfig.Type = "oneshot";
  };
}
