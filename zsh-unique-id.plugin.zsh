# Set up $0 according to the standard:
# http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
local ZERO="$0"

typeset -gx ZUID_LOCKS_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-unique-id"

[[ ! -d "$ZUID_LOCKS_DIR" ]] && command mkdir -p "$ZUID_LOCKS_DIR"

typeset -gi ZUID_ID ZUID_FD
typeset -gx ZUID_CODENAME

#
# Compile myflock
#

# Binary flock command that supports 0 second timeout (zsystem's
# flock in Zsh ver. < 5.3 doesn't) - util-linux/flock stripped
# of some things, compiles hopefully everywhere (tested on OS X,
# Linux, FreeBSD).
if [[ ! -e "${ZERO:h}/myflock/flock" && ! -e "${ZERO:h}/myflock/flock".exe   ]]; then (
        if zmodload zsh/system 2>/dev/null; then
            if zsystem flock -t 1 "${ZERO:h}/myflock/LICENSE"; then
                echo "\033[1;35m""zdharma\033[0m/\033[1;33m""zsh-unique-id\033[0m is building small locking command for you..."
                make -C "${ZERO:h}/myflock"
            fi
        else
            make -C "${ZERO:h}/myflock"
        fi
    )
fi

#
# Load configuration
#

() {
    typeset -gA ZUID_CONFIG

    local use_zsystem_flock
    zstyle -T ":plugin:zuid" use_zsystem_flock && use_zsystem_flock="yes"
    [[ "$use_zsystem_flock" = "yes" ]] && use_zsystem_flock="1" || use_zsystem_flock="0"
    ZUID_CONFIG[use_zsystem_flock]="$use_zsystem_flock"

    local -a codenames
    zstyle -a ":plugin:zuid" codenames codenames || codenames=( atlantis echelon quantum ion proxima polaris solar
                                                                momentum hyper gloom velocity future enigma andromeda
                                                                saturn jupiter aslan commodore falcon persepolis dharma
                                                                samsara prodigy ethereal epiphany aurora oblivion )
    ZUID_CONFIG[codenames]="${(j,:,)codenames}"
}

#
# Test for zsystem's flock
#

if [[ "${ZUID_CONFIG[use_zsystem_flock]}" = "1" ]]; then
    autoload is-at-least
    if ! is-at-least 5.3; then
        # Use, but not for acquire
        ZUID_CONFIG[use_zsystem_flock]="2"
    fi

    if ! zmodload zsh/system 2>/dev/null; then
        echo "Zsh-Uniq-ID plugin: \033[1;31mzsh/system module not found, will use own flock implementation\033[0m"
        echo "Zsh-Uniq-ID plugin: \033[1;31mDisable this warning via: zstyle \":plugin:zuid\" use_zsystem_flock \"0\"\033[0m"
        ZUID_CONFIG[use_zsystem_flock]="0"
    elif ! zsystem supports flock; then
        echo "Zsh-Uniq-ID plugin: \033[1;31mzsh/system module doesn't provide flock, will use own implementation\033[0m"
        echo "Zsh-Uniq-ID plugin: \033[1;31mDisable this warning via: zstyle \":plugin:zuid\" use_zsystem_flock \"0\"\033[0m"
        ZUID_CONFIG[use_zsystem_flock]="0"
    fi
fi

#
# Acquire ID
#

() {
    integer idx try_id res
    local fd lockfile

    # When in Tmux or Screen then consider every subshell
    # session as new (no inheritance). TODO: detect exec zsh
    [[ -n "$TMUX" || -n "$STY" ]] && ZUID_ID=0 && ZUID_FD=0

    # Already assigned ID (inherited)?
    idx=0
    if [[ "$ZUID_FD" = <-> && "$ZUID_FD" != "0" && "$ZUID_ID" = <-> && "$ZUID_ID" != "0" ]]; then
        # Inherited FD and ID, no need to perform work
        if print -u "$ZUID_FD" -n 2>/dev/null; then
            idx=51
        fi
    fi

    # Supported are 50 shells - acquire takes ~200ms max (zsystem's flock)
    for (( ; idx <= 50; idx ++ )); do
        # First (at first loop) try with $ZUID_ID (the case of inherited ID)
        [[ "$idx" = "0" && "$ZUID_ID" = <-> ]] && try_id="$ZUID_ID" || try_id="$idx"
        [[ "$try_id" = "0" ]] && continue

        lockfile="${ZUID_LOCKS_DIR}/zsh-id-${try_id}"
        [[ ! -f "$lockfile" ]] && echo "(created)" >! "$lockfile"

        # Use zsystem only if non-blocking call is available (Zsh >= 5.3)
        # -e: preserve file descriptor on exec
        if [[ "${ZUID_CONFIG[use_zsystem_flock]}" = "1" ]]; then
            zsystem 2>/dev/null flock -t 0 -f ZUID_FD -e "$lockfile"
            res="$?"
        else
            exec {ZUID_FD}>"$lockfile"
            "${ZERO:h}/myflock/flock" -nx "$ZUID_FD"
            res="$?"
        fi

        if [[ "$res" = "101" || "$res" = "1" || "$res" = "2" ]]; then
            [[ "${ZUID_CONFIG[use_zsystem_flock]}" != "1" ]] && exec {ZUID_FD}>&-

            # Is this the special case, i.e. inheritance of ZUID_ID?
            # In this case being unable to lock means: we already have
            # that lock, we're at our ZUID_ID, we should use it
            # (process cannot lock files locked by itself, too)
            if [[ "$idx" = "0" ]]; then
                # Export again just to be sure
                export ZUID_ID
                # We will not be able and want to close FD on zshexit
                export ZUID_FD=0
                break
            fi
        else
            # Successful locking in the special case (try_id = ZUID_ID,
            # i.e. idx == 0) means: we don't want to have that lock because
            # it's not inherited (i.e. not already locked by ourselves)
            if [[ "$idx" = "0" ]]; then
                # Release the out of order lock
                exec {ZUID_FD}>&-
                # We will not be able to quick-close FD on zshexit
                ZUID_FD=0
            else
                ZUID_ID=$try_id
                # ID and FD will be inherited by subshells and exec zsh calls
                export ZUID_ID
                export ZUID_FD
                break
            fi
        fi
    done

    # Output PID to the locked file. The problem is
    # with Zsh 5.3, 5.3.1 - zsystem's obtained file
    # descriptors cannot be written to
    [[ "$ZUID_FD" -ne "0" ]] && { echo "$$" >&${ZUID_FD} } 2>/dev/null

    (( ZUID_ID )) && ZUID_CODENAME="${${(@s,:,)ZUID_CONFIG[codenames]}[$ZUID_ID]}"
}

# Not called ideally at say SIGTERM, but
# at least when "exit" is enterred
function __zuid_zshexit() {
    [[ "$ZUID_FD" != "0" && "$SHLVL" = "1" ]] && { exec {ZUID_FD}>&- ; } 2>/dev/null
}

autoload -Uz add-zsh-hook

add-zsh-hook zshexit __zuid_zshexit
