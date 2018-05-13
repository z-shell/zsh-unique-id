# zsh-unique-id

This plugin will provide **unique** number that will identify Zshell session.
Besides unique number, also a unique codename will be provided. Exported parameters
`$ZUID_ID` and `$ZUID_CODENAME` hold those values. The numeric identification will
be a progressing number starting from `1`.

An example use case is to hold logs in files `.../mylog-${ZUID_CODENAME}.log`, so
that two different Zshells will not write to the same file.

Default codenames are:

 - echelon (for `ZUID_ID` == `1`)
 - quantum (for `ZUID_ID` == `2`)
 - ion (etc.)
 - proxima
 - polaris
 - solar
 - momentum
 - hyper
 - gloom
 - velocity
 - future
 - enigma
 - andromeda
 - saturn
 - jupiter
 - aslan
 - commodore
 - falcon
 - persepolis
 - dharma
 - samsara
 - prodigy
 - ethereal
 - epiphany
 - aurora
 - oblivion

Zstyle configuration allows to customize the codenames:

```zsh
zstyle :plugin:zuid codenames paper metal wood plastic # first 4 shells will have those codenames
```

# Installation

**The plugin is "standalone"**, which means that only sourcing it is needed (without
using a plugin manager). So to install, unpack `zsh-unique-id` somewhere and add:

```zsh
source {where-zsh-unique-id-is}/zsh-unique-id.plugin.zsh
```

to `zshrc`.

Sourcing is recommended, because it can be done early, at top of zshrc, without a
plugin manager – to acquire the unique identification as early as possible.

## [Zplugin](https://github.com/zdharma/zplugin)

Add `zplugin load zdharma/zsh-unique-id` to your `.zshrc` file. Zplugin will clone the plugin
 the next time you start zsh. To update issue `zplugin update zdharma/zsh-unique-id`.

## Antigen

Add `antigen bundle zdharma/zsh-unique-id` to your `.zshrc` file. Antigen will handle
cloning the plugin for you automatically the next time you start zsh.

## Oh-My-Zsh

1. `cd ~/.oh-my-zsh/custom/plugins`
2. `git clone git@github.com:zdharma/zsh-unique-id.git`
3. Add `zsh-unique-id` to your plugin list

## Zgen

Add `zgen load zdharma/zsh-unique-id` to your .zshrc file in the same place you're doing
your other `zgen load` calls in.
