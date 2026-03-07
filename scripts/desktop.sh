#!/bin/bash

function install_desktop_packages() {
    goodecho "[+] Installing desktop/VNC packages for remote GUI access"
    install_dependencies "tigervnc-standalone-server tigervnc-tools novnc websockify socat dbus-x11 lxqt-core openbox breeze-icon-theme fonts-powerline terminator"

    # VNC config
    mkdir -p /root/.vnc
    cp /root/config/xstartup.conf /root/.vnc/xstartup
    chmod u+x /root/.vnc/xstartup

    # Install wallpaper (replace /usr/share/rfswift/wallpaper.png with your own)
    mkdir -p /usr/share/rfswift
    cp /root/config/wallpaper.png /usr/share/rfswift/wallpaper.png

    # Configure LXQt: window manager + icon theme
    mkdir -p /root/.config/lxqt
    echo -e "[General]\n__userfile__=true\nwindow_manager=openbox" > /root/.config/lxqt/session.conf
    echo -e "[General]\n__userfile__=true\nicon_theme=breeze" > /root/.config/lxqt/lxqt.conf

    # PCManFM-Qt config:
    #  - QuickExec: launch .desktop files without trust prompt (GVFS metadata doesn't work in containers)
    #  - DesktopShortcuts: empty to hide Computer/Network icons (not relevant in a container)
    #  - Wallpaper: use RF Swift wallpaper
    #  - IconThemeName: breeze for proper folder/file icons
    mkdir -p /root/.config/pcmanfm-qt/lxqt
    cat > /root/.config/pcmanfm-qt/lxqt/settings.conf <<'PCMANEOF'
[Behavior]
QuickExec=true

[System]
IconThemeName=breeze
Terminal=terminator

[Desktop]
DesktopShortcuts=
Wallpaper=/usr/share/rfswift/wallpaper.png
WallpaperMode=stretch
BgColor=#2d2d2d
PCMANEOF

    # Rebuild font cache for Powerline glyphs in VNC terminals
    fc-cache -f

    # Openbox menu: use terminator as the terminal, add useful entries
    mkdir -p /root/.config/openbox
    cat > /root/.config/openbox/menu.xml <<'MENUEOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="RF Swift">
    <item label="Terminal"><action name="Execute"><command>terminator</command></action></item>
    <separator />
    <item label="File Manager"><action name="Execute"><command>pcmanfm-qt</command></action></item>
    <separator />
    <item label="Reconfigure Openbox"><action name="Reconfigure" /></item>
  </menu>
</openbox_menu>
MENUEOF

    # Terminator config: Powerline font + zsh shell
    mkdir -p /root/.config/terminator
    cat > /root/.config/terminator/config <<'TERMEOF'
[global_config]
[keybindings]
[profiles]
  [[default]]
    font = DejaVu Sans Mono 11
    use_system_font = False
    login_shell = True
[layouts]
  [[default]]
    [[[window0]]]
      type = Window
    [[[child1]]]
      type = Terminal
      parent = window0
TERMEOF

    # Trust all desktop shortcut files so they can be launched from the desktop
    if [ -d /root/Desktop ]; then
        chmod +x /root/Desktop/*.desktop 2>/dev/null || true
    fi

    # noVNC customization: auto-redirect root to VNC client with autoconnect
    echo '<html><head><meta http-equiv="refresh" content="0; URL=/vnc.html?resize=remote&path=websockify&autoconnect=true" /></head></html>' > /usr/share/novnc/index.html

    # noVNC title
    sed -i "s#<title>noVNC</title>#<title>RF Swift</title>#" /usr/share/novnc/vnc.html

    # Desktop management scripts and entrypoint are already copied to
    # /usr/sbin/ by the Dockerfile COPY directives; ensure they are executable
    chmod +x /usr/sbin/desktop-start /usr/sbin/desktop-stop /usr/sbin/desktop-restart /usr/sbin/rfswift-entrypoint

    goodecho "[+] Desktop packages installed"
}
