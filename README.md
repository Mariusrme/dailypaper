# DailyPaper

A new wallpaper every day. Same for everyone. Minimal, textured gradients with the date. Zero CPU. Zero cost.

## Preview

![preview](output/wallpaper.png)

## What it does

Every day at midnight UTC, a GitHub Action generates a new wallpaper — gradient with grain texture, the month, the day, and a short phrase. Everyone who installs DailyPaper gets the same wallpaper at the same time.

## Install (macOS)

Open Terminal, paste this, done:

```bash
curl -sL https://raw.githubusercontent.com/Mariusrme/dailypaper/main/install.sh | bash
```

That's it. Your wallpaper updates automatically every morning and at every login.

## How it works

1. A GitHub Action runs daily and generates a wallpaper image
2. The image is committed to this repo (`output/wallpaper.png`)
3. Your Mac fetches it every morning at 6 AM and at login via `launchd`
4. The wallpaper is set natively via `osascript` — your menu bar matches, zero background process

## Uninstall

```bash
bash ~/.dailypaper/uninstall.sh
```

## Stack

- Python + Pillow for generation
- GitHub Actions for daily automation
- `launchd` for macOS scheduling
- Montserrat Arabic (Black) for typography

## License

MIT
