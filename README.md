**English** | [Русский](README.ru.md)

# QSP game workspace

A folder for writing a text game for [QSP](https://qsp.org). After a one-time setup it holds everything you need:

- **an editor**, a program for writing text: VSCodium, a free version of Visual Studio Code;
- **the QSP extension**, an add-on that teaches the editor the QSP language: it colours the code, marks mistakes and lists your locations;
- **a player**, the program people use to play QSP games;
- **your game**, starting with a small example you can change or delete.

Everything stays inside this folder. You need no administrator rights, and nothing else on your computer changes.

## What you need

- Windows 10 or 11, macOS, or 64-bit Linux on an Intel or AMD processor.
- About 2 GB of free disk space.
- An internet connection during the setup: it downloads about 450 MB.

## Quick start

> Checked on Linux. The Windows and macOS steps are not tested yet on real computers.

1. **Download the archive:** [qsp-game-template.zip](https://github.com/QSPFoundation/qsp-game-template/releases/latest/download/qsp-game-template.zip).
   A ZIP file is an archive: many files packed into one.
   *It worked if* `qsp-game-template.zip` is in your Downloads folder.

2. **Unpack it.** Windows: right-click the file → **Extract All…** → **Extract**. macOS: double-click the file. Linux: right-click the file → **Extract Here**.
   Inside it you get a `qsp-game` folder. Drag it with the mouse to where you keep your documents.
   *It worked if* the `qsp-game` folder holds files such as `install-windows.cmd` and a `game` folder.

3. **Run the setup** for your system:
   - **Windows:** double-click `install-windows.cmd`. If a blue window says “Windows protected your PC”, click **More info** → **Run anyway**.
   - **macOS:** double-click `install-macos.command`. If macOS says it can't open the file, hold **Control**, click the file, choose **Open**, then **Open** again.
   - **Linux:** a terminal is a window where you type commands. Right-click an empty spot in the `qsp-game` folder, choose **Open in Terminal**, type this line and press **Enter**:
     ```
     bash install-linux.sh
     ```
     If there is no **Open in Terminal**, start the **Terminal** program, type `cd` and a space, drag the `qsp-game` folder into the terminal window, press **Enter**, and then type the line above.

   A window with text opens and asks for a language: type `2` for English (or `1` for Russian) and press **Enter**. The setup takes a few minutes.
   *It worked if* a line starting with `Done!` appears. Press **Enter** to finish.

4. **Open your game:** double-click `open-game-windows.cmd` (Windows) or `open-game-macos.command` (macOS). On Linux, type in the terminal:
   ```
   bash open-game-linux.sh
   ```
   *It worked if* the editor opens with the file `main.qsps` on the left and a **QSP LOCATIONS** section below the files: it lists the game's locations.

5. **Play:** press **F5**, or the **▷** button at the top right above an open file. On a laptop you may need to hold the **Fn** key for F5.
   *It worked if* the QSP player opens and shows “You stand in a dark hallway…”. Close the player to go back to writing.

## Writing your game

- Click `main.qsps` on the left to open it. A game is made of **locations**: places or scenes. Each starts with a line `# name` and ends with a line `---`. Lines that start with `!` are notes for you; players don't see them.
- The editor saves your text by itself a second after you stop typing.
- A red wavy line marks a mistake. Point at it with the mouse to read what is wrong.
- You can split the game into several files: right-click the file list → **New File…**, and give the name an ending of `.qsps`. All of them go into the game; it starts at the first location of `main.qsps`.
- Put pictures in `game/images` and sounds in `game/sounds`.
- **Ctrl+K**, then **J**, in an open game file shows a map of which location leads where.
- To get back an earlier version of a file, open **Timeline** at the bottom of the file list and click a moment in time.

## Giving the game to players

Each **F5** builds the file `game/game.qsp`. That is the game itself. Give players `game.qsp` together with the `images` and `sounds` folders, for example packed into one ZIP. They open `game.qsp` in a QSP player from [qsp.org](https://qsp.org).

## Trying the game in qSpider

qSpider is a second player, which shows HTML the way a web browser does. It is also installed. Press **F5** first, then choose the menu **Terminal** → **Run Task…** → **Open in qSpider**. *(Not tested yet.)* In qSpider the names of pictures and sounds must match in capital and small letters: `Image.jpg` and `image.jpg` are different files.

## What is in this folder

| Folder or file | What it is |
|---|---|
| `game` | Your game. This is the folder to copy when you make a backup. |
| `tools` | The editor and the players. You can delete it; the setup puts it back. |
| `setup` | Files the setup needs. Leave them as they are. |
| `install-…`, `open-game-…` | The files you start the setup and the editor with. |

## Updating

Run the setup file again (step 3). It updates the editor, the extension and the players, and keeps your game and your editor settings.

## If something goes wrong

- **The setup stopped with an error.** The message says why. Check the internet connection and run the setup again. Everything it did is written to `tools/setup.log`.
- **F5 says it can't start the player.** Run the setup again: it puts back what is missing.
- **On Linux the player doesn't open.** It needs a desktop with the GTK 3 library, which Ubuntu, Linux Mint and Fedora have.
- **After you moved the folder, the editor looks new** (macOS, some Linux systems). There the editor keeps its settings outside the folder, tied to the folder's place. Your game has not changed.
- **You have an old game file (`.qsp`).** Press **Ctrl+Shift+P**, type `Import QSP Game`, press **Enter** and pick the file: the editor turns it back into text. Games written for QSP 5.7 may need changes for today's players; see [Aleks Versus's notes](https://aleksversus.github.io/howdo_faq/docs/articles/transition_570_590) (in Russian).

## Learning QSP

- [QSP wiki](https://wiki.qsp.org): the full description of the language.
- [“How do I…?” by Aleks Versus](https://aleksversus.github.io/howdo_faq/) (in Russian): answers to common questions, for today's players.
- [QSP forum](https://qsp.org): the authors' community.
- A tip many authors follow: first write the whole story with simple placeholders (“Win the fight”, “Lose the fight”), then the complex code, and only then pictures and music. The game gets finished more often that way.

## License

The files of this workspace are under the [BSD Zero Clause License](LICENSE): you may use them in any way. Your game belongs to you.
