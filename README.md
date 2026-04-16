# TIC-80

A collection of TIC-80 experiments.

1. [Compiling and Installing TIC-80 Pro](#compiling_and_installing_tic80_pro)
1. [Developing with VS Code](#developing_with_vscode)
    1. [Accessing TIC-80 Files](#accessing_tic80_files)
    1. [The Development Workflow](#the_development_workflow)
1. [Interesting/Useful Tutorials](#interesting_useful_tutorials)

<!-- --------------------------------------------------------------------------- -->


<div id='compiling_and_installing_tic80_pro' />

## Compiling and Installing TIC-80 Pro

We can compile TIC-80 Pro by following the directions given on the [TIC-80 README.md page](https://github.com/nesbox/TIC-80/blob/main/README.md).

For Windows 11, use the [MSYS2/MINGW instructions](https://github.com/nesbox/TIC-80/blob/main/README.md#msys2--mingw).

1. Make sure MSYS2 has the proper prerequisites already installed. Open the MSYS2 terminal and run these two commands:
    ```bash
    pacman -Syu
    pacman -S mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-SDL2 mingw-w64-ucrt-x86_64-freeglut mingw-w64-ucrt-x86_64-ruby
    ```
1. `git` should already be installed, so skip that in those directions and just go straight to:
    ```bash
    winget install Kitware.CMake RubyInstallerTeam.RubyWithDevKit.2.7
    ```
2. Run `ridk install` with options `1,3` to set up MSYS2 and development toolchain
3. Run the following PowerShell command as administrator to add MSYS2's `gcc` at `C:\Ruby27-x64\msys64\mingw64\bin` to the `$PATH`:
    ```bash
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\Ruby27-x64\msys64\mingw64\bin', [EnvironmentVariableTarget]::Machine)
    ```
4. Open a new PowerShell prompt as administrator and run the following commands:
    ```bash
    git clone --recursive https://github.com/nesbox/TIC-80
    cd .\TIC-80\build
    cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_SDLGPU=On -DBUILD_WITH_ALL=On -DBUILD_PRO=On ..
    $numCPUs = [Environment]::ProcessorCount
    mingw32-make "-j$numCPUs"
    ```

If the `mingw32-make` command fails, check to see if it's on a specific language. if so, you can selectively enable/disable the languages TIC-80 supports like this:
```bash
cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_SDLGPU=On -DBUILD_PRO=On -DBUILD_WITH_LUA=On -DBUILD_WITH_MOON=On -DBUILD_WITH_FENNEL=On -DBUILD_WITH_WREN=On -DBUILD_WITH_RUBY=On -DBUILD_WITH_JANET=Off -DBUILD_WITH_JS=On ..
```
Note that we disabled `janet` here with the `-DBUILD_WITH_JANET=Off` flag.

The resulting `tic80.exe` in `TIC-80\build\bin`. Create a shortcut to it wherever you need to.


<!-- --------------------------------------------------------------------------- -->


<div id='developing_with_vscode' />

## Developing with VS Code

Two main videos to refer to for instructions on getting VS Code to access TIC-80 files:

- [How to TIC-80 - A Better Coding Experience](https://www.youtube.com/watch?v=LU0NZ-gvvHQ)
- [Tic 80 Tutorials 2025 - Setting up Tic 80 development environment (VS Code)](https://www.youtube.com/watch?v=x6jAjNzF1Nw)

This latter video says to install these Lua extensions in VS Code:

- [Lua (by sumneko)](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
- [tic80-pro-vscode](https://marketplace.visualstudio.com/items?itemName=justinwash.tic80-pro-vscode)

Then paste in the [TIC-80 api user snippets for Visual Studio Code](https://gist.github.com/Viza74/40a180155049dd26af378f51a92b6033) file for code completion.


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


<div id='accessing_tic80_files' />

#### Accessing TIC-80 Files

Where are the TIC-80 files located once it's up and running? At the TIC-80 command line, run this command to get the storage path and have that folder pop up in explorer:
```bash
>folder
Storage path:
C:\Users\afuller\AppData\Roaming\com.nesbox.tic\TIC-80
```
Open that folder in VS Code.


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


<div id='the_development_workflow' />

#### The Development Workflow

Here are the steps for starting a new project that seem to work so far:
1. Within TIC-80, create a new folder for the project.
    ```bash
    >mkdir test-project
    created [test-project] folder :)
    ```
2. Create a new file to edit
    ```bash
    >cd test-project
    test-project>new lua
    new cart has been created
    test-project>save main.lua
    cart main.lua saved!
    ```
3. This creates a file like this:
    ```lua
    -- title:   game title
    -- author:  game developer, email, etc.
    -- desc:    short description
    -- site:    website link
    -- license: MIT License (change this to your license of choice)
    -- version: 0.1
    -- script:  lua

    t=0
    x=96
    y=24

    function TIC()

        if btn(0) then y=y-1 end
        if btn(1) then y=y+1 end
        if btn(2) then x=x-1 end
        if btn(3) then x=x+1 end

        cls(13)
        spr(1+t%60//30*2,x,y,14,3,0,0,2,2)
        print("Hello World!",84,84)
        t=t+1
    end

    -- <TILES>
    -- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
    -- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
    -- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
    -- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
    -- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
    -- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
    -- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
    -- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
    -- </TILES>

    -- <WAVES>
    -- 000:00000000ffffffff00000000ffffffff
    -- 001:0123456789abcdeffedcba9876543210
    -- 002:0123456789abcdef0123456789abcdef
    -- </WAVES>

    -- <SFX>
    -- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
    -- </SFX>

    -- <TRACKS>
    -- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    -- </TRACKS>

    -- <PALETTE>
    -- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
    -- </PALETTE>
    ```
    This is the actual game code, maps, sprites, sound effects, and music. Don't touch anything below the `-- <TILES>` line including that line.
4. Edit the code as needed.
5. Save the file by pressing `ctrl-R`.

That's it. Make all changes to the `lua` files in VS Code, saving them there as needed. This will autoupdate TIC-80's code editor and allows you to play these files just like a regular cartridge. When we're ready to "compile" the cartridge, save the whole thing as a cartridge file:
```bash
test-project>save test-project
cart test-project.tic saved!
```


<!-- --------------------------------------------------------------------------- -->


<div id='interesting_useful_tutorials' />

## Interesting/Useful Tutorials

[Intro to Game Programming in TIC 80](https://github.com/nesbox/TIC-80/wiki/Intro-to-Game-Programming-in-TIC-80): talks about the basic way to implement code structure.
[btn (TIC-80 API wiki)](https://github.com/nesbox/TIC-80/wiki/btn): code example that shows button presses.