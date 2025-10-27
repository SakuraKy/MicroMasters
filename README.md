<div align="center">

<img src="MicroMasters/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="200" alt="MicroMasters Icon"/>

# MicroMasters

Lightweight macOS menu bar vocabulary learning application

[English](README.md) | [简体中文](README_zh-CN.md)

</div>

---

## Features

- **Beginner-Friendly**: Designed for easy vocabulary learning. Just start the app and begin learning.
- **Fully Featured**: Supports CSV word deck imports, system notifications, random quizzes, and learning records.
- **Native UI**: Built with AppKit, adopting macOS native design style.
- **Menu Bar Resident**: Lightweight menu bar app, doesn't occupy Dock space.
- **Pronunciation Support**: Integrated system speech engine for word pronunciation.
- **Learning Records**: Automatically track your learning progress and accuracy rate.

## �� Quick Start

### Installation

Download the latest DMG file from the [Releases](https://github.com/SakuraKy/MicroMasters/releases) page and double-click to install.

### macOS Installation Issues

When installing on macOS, you may encounter the error **"MicroMasters.app" is damaged and can't be opened. You should move it to the Trash.** This is generally not actual file corruption. In fact, to completely avoid this issue, we would need to pay Apple $99 per year to generate a trusted certificate. We don't have the ability to pay this amount. If you want to use this software, you may need some additional steps to complete this.

1. Download and drag to Application directory.
2. Open your terminal and run:

```bash
xattr -d com.apple.quarantine /Applications/MicroMasters.app
```

3. Open the application and start using.

### Build from Source

#### Requirements

- macOS 12.0 or higher
- Xcode 14.0 or higher
- Swift 5

#### Build Steps

1. Clone the repository:

```bash
git clone https://github.com/SakuraKy/MicroMasters.git
cd MicroMasters
```

2. Open Xcode project:

```bash
open MicroMasters.xcodeproj
```

3. Select `MicroMasters` scheme and build & run (⌘R)

On first run, it will request notification permissions and copy the default word deck to `~/Library/Application Support/MicroMasters`.

## 📖 Usage

### Menu Bar Features

- **Start!**: Push study notifications according to configured quantity
- **Set Word Count…**: Configure study quantity per session (10-100, step 5)
- **Select Deck**: Switch between different word decks
- **Import Deck…**: Import CSV format word deck (format: term,phonetic,pos,meaning,example)
- **Export Study Records…**: Export study records to CSV format
- **Random Quiz**: Start three-choice quiz without study process
- **Instructions**: View operation tips
- **Quit**: Exit application

### Deck Format

CSV file format (UTF-8 encoding):

```csv
term,phonetic,pos,meaning,example
abandon,/əˈbændən/,v.,放弃；抛弃,They had to abandon the car.
```

### Data Storage

All data is stored in: `~/Library/Application Support/MicroMasters/`

- `ReviewRecord.json` - Study records
- `default_words.csv` - Default word deck
- Other imported deck files

## 🛠️ Development Scripts

The project includes the following utility scripts (located in `Scripts/` directory):

- **build.sh** - Complete build and packaging script, generates DMG file
- **generate_app_icon.sh** - Generate all sizes of app icons from PNG icon
- **rebuild.sh** - Quickly clean and rebuild application

Usage:

```bash
cd Scripts
./build.sh     # Build complete Release version and package DMG
./rebuild.sh   # Quickly rebuild Debug version
```

## 💻 Tech Stack

- **Language**: Swift 5
- **Framework**: AppKit (Native macOS)
- **Minimum System**: macOS 12.0+
- **UI Design**: Native system components (NSAlert, NSWindow, NSMenu)
- **Data Persistence**: JSON local storage
- **Icons**: SF Symbols + Custom Assets

## 📄 License

This project is open source under the MIT License. See LICENSE file for details.

---

<div align="center">

**MicroMasters** - Lightweight vocabulary learning assistant, making word memorization easier ✨

</div>
