# Troll Engine Burgerballs Mod Fork

Hello guys this is me burgerballs, this here is the fork i use for my fnf mods.
As troll engine is already perfect i kinda only needed to change small tiny things to make it easier for me.

As this is my own personal fork, expect bloat, this is meant to be used by nobody aside from me!

I've modified the `install_haxelibs` files, before building you should check them out.

NOTE: Do not treat this as an official release!!! This version of the engine is unendorsed by the original creators. Despite this, this fork will try to stay as synchronized with the original release as I possibly can until breaking changes arise.

# QNA

Some questions might be asked about this fork in particular. So I might answer them here. 

Q: Why not just use base Troll?

A:

Some features which I wish to be in base Troll simply isn't there because it doesn't fit the needs of the project, this fork specifically fits my own needs for my own projects.

Q: What about your V-Slice mods?

A:

Big ones like song mods are currently being ported to this Troll fork right now, consider all the QOL mods obselete and no longer in active development.

V-Slice is not a reliable modding platform.

Q: Why not use Psych, or other forks like "P-Slice", or NightmareVision?

A: 

Psych is dead, I do not want to use Psych Engine 1.0. "P-Slice" is just Psych with the menus swapped and that means nothing to me. 

I will not use NightmareVision as all of it's code is taken from an older and inferior version of what Troll Engine has. (see: Vs. EXE 2.5 Fork)

NightmareVision only garners popularity because of Hit Single and other popular mods programmed by the engine's "authors" and is completely unremarkable on it's own (like a modern "Forever Engine"). I'm tired of non-programmers recommending it as it's toolset is all but outdated Andromeda Engine code forked over without permission or tangeble credit to an older version of Psych Engine.

# Added features

This fork has some features that are different to the original or are completely new.

## Interpolated Scroll Velocities

![image](https://github.com/user-attachments/assets/ae9a373e-4df3-4000-b72a-975f27c9e983)

https://github.com/user-attachments/assets/e747d50d-54f9-4ce5-a58f-a8bf890a0cd9

Scroll velocities are a big part of Troll Engine, so thats why this modified version adds two extra events for "Interpolated" scroll velocities.

Basically imagine the Scroll Speed Change event in Psych Engine, but for Scroll Velocity instead, with a set duration.

Because of the way that it works, there is an option in the Options Menu, that allows you to change it's smoothness, if it takes a toll on your computer's RAM.

## Themed Options Menu

I've decided to change the appearance of the options menu to make the design more consistant with FNF, instead of the TGT mod specific design the original has.

![image](https://github.com/user-attachments/assets/f0b49edc-c59c-494f-8efb-976d648a7cac)

## V-Slice Character Support

V-Slice's character format is supported.

Along with this are some small optional changes to the Psych Engine character format. Allowing you to use multiple sparrow atlases.

Stages can now also be modified to use V-Slice stage positioning with a small json edit.

# More Atlas Support

Aseprite JSON atlases are supported.

More supported atlas rendering types are as follows:

MultiSparrow (multiple Sparrow atlases on single sprite)

MultiPacker (multiple Packer atlases on single sprite)

MultiAseprite (multiple JSON Packer atlases on single sprite)

# Special Thanks

- [Riconuts](https://github.com/riconuts) - Owner of original engine
- [Nebula the Zorua](https://x.com/Nebula_Zorua) - Co-Owner of original engine
- EliteMasterEric - Code i stole from him and ninjamuffin99 for v-slice bullshit lole!


The following remains unchanged for the purpose of accurate crediting upon the existence of later changes from later versions of Troll Engine.

# Friday Night Funkin': Troll Engine

[Troll Engine](https://github.com/riconuts/troll-engine) is the fork of [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) originally made for the [Tails Gets Trolled mod](https://gamebanana.com/mods/320596).


## Installation:

Must have Haxe 4.3.0 or greater.

The setup files for Troll Engine's specific haxe libraries can be installed with the `install_haxelibs` files located in the `setup` folder.

Refer to [Psych Engine's build instructions](https://github.com/ShadowMario/FNF-PsychEngine/blob/main/BUILDING.md).

## Engine Credits / Special Thanks
- [Nebula the Zorua](https://x.com/Nebula_Zorua) - Most engine stuff
- [crowplexus](https://x.com/crowplexus) - Countdown class and hxdiscord_rpc implementation
- [4mbr0s3_2](https://www.youtube.com/@4mbr0s3-2) - Modifier system inspiration
- [SrtHero278](https://github.com/SrtHero278) - Various NoteField improvements
- [Lat](https://x.com/latzephr) - Week 6 Health Bar and Timer assets
- [moxie-coder](https://github.com/moxie-coder/) - Mac building and workflow help
- [swordcube](https://bsky.app/profile/swordcube.bsky.social) - Pixel notesplashes
- [SRT](https://bsky.app/profile/SrtPro278.bsky.social) - Notefield optimizations
- Gab - We like him
- [AllyTS](https://x.com/NewTioSans) - Made the Mine note texture
- [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) - Dad engine

## Original Funkin' team
- [ninjamuffin99](https://twitter.com/ninja_muffin99) - Programmer
- [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
- [Kawaisprite](https://twitter.com/kawaisprite) - Musician
