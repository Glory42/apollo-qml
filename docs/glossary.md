# Glossary

Apollo is a personal desktop shell for Hyprland. Its parts are named after the Apollo space programme, which suits the owner more than it explains itself, so this page says what each name means. The code and the other pages use these words and avoid the ones listed after _Avoid_.

## Language

**Piece**:
A self-contained part of Apollo that can be summoned on its own, such as the application launcher or the power menu. Two pieces may look alike and still be separate pieces.
_Avoid_: Module, widget, component

**Rice**:
The owner's customised desktop as a whole, of which Apollo is one part alongside the window manager, terminal and other applications.
_Avoid_: Desktop, setup, dotfiles

**Houston**:
The command the owner uses from outside Apollo to tell a piece what to do, typically from a keybind.
_Avoid_: apollo-ctl, ctl, IPC helper

**Global shortcut**:
A keybind that reaches Apollo straight from Hyprland, without starting Houston. It does the same as a Houston call that takes no arguments.
_Avoid_: Hotkey, keymap

**Switch**:
A setting that is either on or off and can be flipped from a keybind: the night light, silence (notifications stop peeking) and stay awake (the idle steps are held off). Flipping one peeks to say what it changed to.
_Avoid_: Toggle, mode

## Surfaces

**Surface**:
A place on the screen where a piece appears. A surface says where something is shown; a piece says what it is. Only one piece is open at a time across all surfaces; a peek does not count as open.
_Avoid_: Shell, window, panel, popup

**Hull**:
The solid body a surface is made of, and the colour of that body, which is the theme's background colour.
_Avoid_: Pill colour, body

**Orbiter**:
The surface that floats in the middle of the screen, attached to no edge. It has no resting form, and while open it holds the owner's focus. Logbook, Earthrise and Visor each appear in an Orbiter; Logbook's has a hull, while the other two are a carousel floating bare.
_Avoid_: Modal, dialog, popup, card

**Lander**:
The surface that rises from the bottom edge of the screen, shaped like the Capsule mirrored. It has no resting form: it exists only while a piece is shown in it, and while open it holds the owner's focus. Launchpad, Splashdown and Hasselblad's menu each appear in a Lander.
_Avoid_: Drawer, bottom bar, dock

## Pieces

**Launchpad**:
The piece for finding and starting applications.
_Avoid_: App launcher, launcher, runner

**Splashdown**:
The piece offering the ways to end or pause a session: lock, log out, suspend, restart, shut down.
_Avoid_: Power menu, session menu

**Logbook**:
The piece showing the history of what has been copied, for pasting again.
_Avoid_: Clipboard, clipboard history

**Theme**:
A named look for the whole rice: the colours of Apollo and of the other applications on the desktop, together with the wallpapers that belong to it. A wallpaper belongs to a theme only if the theme lists it. Exactly one theme is current at a time.
_Avoid_: Palette, colour scheme, skin

**Main wallpaper**:
The one wallpaper that stands for a theme: it is shown for the theme in Visor and is set when the theme becomes current.
_Avoid_: Default wallpaper, preview, cover

**Carousel**:
A row of slanted picture cards with the current one large in the middle, used to choose one picture-like thing from several.
_Avoid_: Picker, gallery, slider

**Palette**:
The named colours of a theme. A theme differs from another only in its palette and its wallpapers.
_Avoid_: Colours file, tokens

**Template**:
The description of how one application in the rice is coloured from a palette. There is one template per application, shared by every theme.

**Earthrise**:
The piece for choosing a wallpaper from those belonging to the current theme.
_Avoid_: Wallpaper changer, wallpaper picker

**Visor**:
The piece for choosing the current theme.
_Avoid_: Theme changer, theme switcher

**Hasselblad**:
The piece for capturing the screen: it offers a screenshot, a screen recording with a choice of sound, and picking a colour. A plain screenshot never goes through it.
_Avoid_: Capture menu, screenshot tool, recorder

**Airlock**:
The piece that seals the session until the owner authenticates.
_Avoid_: Lock screen, locker

**Idle**:
What Apollo does on its own when the owner has stopped using the machine: turning the screens off, then locking with Airlock, then, if asked to, suspending. It also locks before any suspend. It has no surface of its own.
_Avoid_: Idle daemon, hypridle

**Picker**:
Hasselblad's way of choosing what to capture: the window under the pointer, a dragged region or a whole monitor, over a frozen screen for a screenshot and a live one for a recording.
_Avoid_: Selector, slurp

## The Capsule

**Capsule**:
The piece that hangs from the top edge of the screen and is always present. It is the only piece with a resting form, and it is a companion: it shows things alongside the owner's work without taking focus from it.
_Avoid_: Pill, notch, bar

**Rest**, **Peek**, **Open**:
The three sizes of the Capsule: rest is its idle form (the workspaces, the clock, and the connection and battery icons), a peek is a brief unprompted showing of an event, and open is the full form showing a view.

**Say**:
A peek that Apollo or a script shows to tell the owner what just happened, an icon and a few words that are kept nowhere afterwards. A notification that peeks is not a say.
_Avoid_: Toast, OSD

**View**:
One screen of content shown inside the open Capsule, such as music or the calendar.
_Avoid_: Page, panel, tab

**Dock**:
The row of tabs in the open Capsule used to move between views: quick settings, music, timer, weather, calendar and notifications.

**Detail view**:
A view that is not on the dock and is reached from another view, usually through the arrow on a slider or tile in quick settings: Wi-Fi, Bluetooth, Sound and Display. The connection page is reached in turn from the Wi-Fi view. Each can also be opened directly with Houston.
_Avoid_: Subpage, submenu, settings page
