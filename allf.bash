__expand_tilde_by_ref () 
{ 
    if [[ ${!1} == \~* ]]; then
        eval $1=$(printf ~%q "${!1#\~}");
    fi
}
__get_cword_at_cursor_by_ref () 
{ 
    local cword words=();
    __reassemble_comp_words_by_ref "$1" words cword;
    local i cur index=$COMP_POINT lead=${COMP_LINE:0:$COMP_POINT};
    if [[ $index -gt 0 && ( -n $lead && -n ${lead//[[:space:]]} ) ]]; then
        cur=$COMP_LINE;
        for ((i = 0; i <= cword; ++i ))
        do
            while [[ ${#cur} -ge ${#words[i]} && "${cur:0:${#words[i]}}" != "${words[i]}" ]]; do
                cur="${cur:1}";
                [[ $index -gt 0 ]] && ((index--));
            done;
            if [[ $i -lt $cword ]]; then
                local old_size=${#cur};
                cur="${cur#"${words[i]}"}";
                local new_size=${#cur};
                (( index -= old_size - new_size ));
            fi;
        done;
        [[ -n $cur && ! -n ${cur//[[:space:]]} ]] && cur=;
        [[ $index -lt 0 ]] && index=0;
    fi;
    local "$2" "$3" "$4" && _upvars -a${#words[@]} $2 "${words[@]}" -v $3 "$cword" -v $4 "${cur:0:$index}"
}
__gnu_tar_parse_help () 
{ 
    local str line arg;
    while IFS= read line; do
        if [[ "$line" =~ ^[[:blank:]]{1,10}(((,[[:blank:]])?(--?([\]\[a-zA-Z0-9?=-]+))(,[[:space:]])?)+).*$ ]]; then
            line=${BASH_REMATCH[1]};
            str="${line//,/ }";
            arg=none;
            if [[ "$line" =~ --[A-Za-z0-9-]+(\[?)= ]]; then
                [[ -n "${BASH_REMATCH[1]}" ]] && arg=opt || arg=req;
            fi;
            __gtar_parse_help_line "$str" "$arg";
        fi;
    done <<< "$(tar --help)";
    long_opts="        $long_arg_none        $long_arg_opt        $long_arg_req";
    short_opts="$short_arg_none$short_arg_opt$short_arg_req"
}
__gtar_complete_lopts () 
{ 
    local rv;
    COMPREPLY=($(compgen -W "$long_opts" -- "$cur"));
    rv=$?;
    [[ $COMPREPLY == *= ]] && compopt -o nospace;
    return $rv
}
__gtar_complete_sopts () 
{ 
    local generated short_mode_opts i c;
    short_mode_opts="ctxurdA";
    generated=${short_opts//[$short_mode_opts]/};
    for ((i=0 ; 1; i++ ))
    do
        c="${allshort_raw_unused:$i:1}";
        [[ -z "$c" ]] && break;
        generated+=" $cur$c";
    done;
    COMPREPLY=($(compgen -W "$generated" -- "$cur"))
}
__gtar_parse_help_line () 
{ 
    local i;
    for i in $1;
    do
        case "$i" in 
            --* | -*)
                __gtar_parse_help_opt "$i" "$2"
            ;;
            *)
                break
            ;;
        esac;
    done
}
__gtar_parse_help_opt () 
{ 
    local opttype arg opt separator optvar;
    opttype=long;
    arg="$2";
    opt="$1";
    separator=" ";
    case "$opt" in 
        --*)

        ;;
        -\?)
            return
        ;;
        -*)
            opttype=short;
            opt=${opt##-};
            separator=
        ;;
        *)
            echo "bash_completion: $FUNCNAME: unknown option $opt" 1>&2;
            return 1
        ;;
    esac;
    opt=${opt//\[*/};
    opt=${opt//=*/=};
    opt=${opt//\"*/};
    opt=${opt//\'*/};
    opt=${opt//\;*/};
    optvar=$opttype'_arg_'$arg;
    eval "$optvar=\"\$$optvar$separator\"\"$opt\""
}
__gtar_parse_warnings () 
{ 
    local line;
    LC_ALL=C tar --warning= 2>&1 | while IFS= read line; do
        if [[ $line =~ ^[[:blank:]]*-[[:blank:]]*[\`\']([a-zA-Z0-9-]+)\'$ ]]; then
            echo "${BASH_REMATCH[1]} no-${BASH_REMATCH[1]}";
        fi;
    done
}
__load_completion () 
{ 
    local -a dirs=(${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion}/completions);
    local OIFS=$IFS IFS=: dir cmd="${1##*/}" compfile;
    [[ -n $cmd ]] || return 1;
    for dir in ${XDG_DATA_DIRS:-/usr/local/share:/usr/share};
    do
        dirs+=($dir/bash-completion/completions);
    done;
    IFS=$OIFS;
    if [[ $BASH_SOURCE == */* ]]; then
        dirs+=("${BASH_SOURCE%/*}/completions");
    else
        dirs+=(./completions);
    fi;
    for dir in "${dirs[@]}";
    do
        [[ -d "$dir" ]] || continue;
        for compfile in "$cmd" "$cmd.bash" "_$cmd";
        do
            compfile="$dir/$compfile";
            [[ -f "$compfile" ]] && . "$compfile" &> /dev/null && return 0;
        done;
    done;
    [[ -n "${_xspecs[$cmd]}" ]] && complete -F _filedir_xspec "$cmd" && return 0;
    return 1
}
__ltrim_colon_completions () 
{ 
    if [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
        local colon_word=${1%"${1##*:}"};
        local i=${#COMPREPLY[*]};
        while [[ $((--i)) -ge 0 ]]; do
            COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"};
        done;
    fi
}
__parse_options () 
{ 
    local option option2 i IFS=' 	
,/|';
    option=;
    local -a array=($1);
    for i in "${array[@]}";
    do
        case "$i" in 
            ---*)
                break
            ;;
            --?*)
                option=$i;
                break
            ;;
            -?*)
                [[ -n $option ]] || option=$i
            ;;
            *)
                break
            ;;
        esac;
    done;
    [[ -n $option ]] || return 0;
    IFS=' 	
';
    if [[ $option =~ (\[((no|dont)-?)\]). ]]; then
        option2=${option/"${BASH_REMATCH[1]}"/};
        option2=${option2%%[<{().[]*};
        printf '%s\n' "${option2/=*/=}";
        option=${option/"${BASH_REMATCH[1]}"/"${BASH_REMATCH[2]}"};
    fi;
    option=${option%%[<{().[]*};
    printf '%s\n' "${option/=*/=}"
}
__reassemble_comp_words_by_ref () 
{ 
    local exclude i j line ref;
    if [[ -n $1 ]]; then
        exclude="${1//[^$COMP_WORDBREAKS]}";
    fi;
    printf -v "$3" %s "$COMP_CWORD";
    if [[ -n $exclude ]]; then
        line=$COMP_LINE;
        for ((i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++))
        do
            while [[ $i -gt 0 && ${COMP_WORDS[$i]} == +([$exclude]) ]]; do
                [[ $line != [[:blank:]]* ]] && (( j >= 2 )) && ((j--));
                ref="$2[$j]";
                printf -v "$ref" %s "${!ref}${COMP_WORDS[i]}";
                [[ $i == $COMP_CWORD ]] && printf -v "$3" %s "$j";
                line=${line#*"${COMP_WORDS[$i]}"};
                [[ $line == [[:blank:]]* ]] && ((j++));
                (( $i < ${#COMP_WORDS[@]} - 1)) && ((i++)) || break 2;
            done;
            ref="$2[$j]";
            printf -v "$ref" %s "${!ref}${COMP_WORDS[i]}";
            line=${line#*"${COMP_WORDS[i]}"};
            [[ $i == $COMP_CWORD ]] && printf -v "$3" %s "$j";
        done;
        [[ $i == $COMP_CWORD ]] && printf -v "$3" %s "$j";
    else
        for i in "${!COMP_WORDS[@]}";
        do
            printf -v "$2[i]" %s "${COMP_WORDS[i]}";
        done;
    fi
}
__tar_adjust_PREV_from_old_option () 
{ 
    if [[ "$old_opt_used" -eq 1 && "$cword" -gt 1 && "$cword" -lt $(( ${#old_opt_parsed[@]} + 2 )) ]]; then
        prev="-${old_opt_parsed[ $cword - 2 ]}";
    fi
}
__tar_cleanup_prev () 
{ 
    if [[ "$prev" =~ ^-[a-zA-Z0-9?]*$ ]]; then
        prev="-$(__tar_last_char "$prev")";
    fi
}
__tar_complete_mode () 
{ 
    local short_modes has_mode rawopt generated allshort_raw_unused allshort_raw filler i;
    short_modes="ctx";
    [[ -z "$basic_tar" ]] && short_modes="ctxurdA";
    rawopt=${cur#-};
    allshort_raw=${short_opts//[- ]/};
    if [[ "$tar_mode" == none ]]; then
        filler=;
        if [[ -z "$cur" && -z "$basic_tar" ]]; then
            filler=-;
        fi;
        generated="";
        for ((i=0 ; 1; i++ ))
        do
            local c="${short_modes:$i:1}";
            [[ -z "$c" ]] && break;
            generated+=" $filler$cur$c";
        done;
        COMPREPLY=($(compgen -W "$generated" ));
        return 0;
    fi;
    if [[ "$old_opt_progress" -eq 0 ]] && __tar_is_argreq "$(__tar_last_char "$cur")"; then
        COMPREPLY=("$cur") && return 0;
    fi;
    allshort_raw_unused=${allshort_raw//[$rawopt]/};
    if [[ "$tar_mode" != none ]]; then
        allshort_raw_unused=${allshort_raw_unused//[$short_modes]};
    fi;
    generated=;
    for ((i=0 ; 1; i++ ))
    do
        local c="${allshort_raw_unused:$i:1}";
        [[ -z "$c" ]] && break;
        generated+=" $cur$c";
    done;
    COMPREPLY=($(compgen -W "$generated"));
    return 0
}
__tar_detect_ext () 
{ 
    local tars='@(@(tar|gem|spkg)?(.@(Z|[bgx]z|bz2|lz?(ma|o)|zst))|t@([abglx]z|b?(z)2|zst))';
    ext="$tars";
    case "$tar_mode_arg" in 
        --*)

        ;;
        ?(-)*[cr]*f)
            ext='@(tar|gem|spkg)';
            case ${words[1]} in 
                *a*)
                    ext="$tars"
                ;;
                *z*)
                    ext='t?(ar.)gz'
                ;;
                *Z*)
                    ext='ta@(r.Z|z)'
                ;;
                *[jy]*)
                    ext='t@(?(ar.)bz?(2)|b2)'
                ;;
                *J*)
                    ext='t?(ar.)xz'
                ;;
            esac
        ;;
        +([^ZzJjy])f)

        ;;
        *[Zz]*f)
            ext='@(@(t?(ar.)|gem.|spkg.)@(gz|Z)|taz)'
        ;;
        *[jy]*f)
            ext='@(@(t?(ar.)|gem.)bz?(2)|spkg|tb2)'
        ;;
        *[J]*f)
            ext='@(@(tar|gem|spkg).@(lzma|xz)|t[lx]z)'
        ;;
    esac
}
__tar_extract_like_mode () 
{ 
    local i;
    for i in x d t delete;
    do
        [[ "$tar_mode" == "$i" ]] && return 0;
    done;
    return 1
}
__tar_file_option () 
{ 
    local ext="$1";
    case "$tar_mode" in 
        c)
            _filedir -d
        ;;
        *)
            _filedir "$ext"
        ;;
    esac
}
__tar_is_argreq () 
{ 
    local opt;
    opt=$1;
    case "$opt" in 
        -[A-Za-z0-9?])
            [[ "$short_arg_req" =~ ${opt##-} ]] && return 0
        ;;
        [A-Za-z0-9?])
            [[ "$short_arg_req" =~ ${opt} ]] && return 0
        ;;
        --*)
            [[ "$long_arg_req" =~ [[:blank:]]$opt=[[:blank:]] ]] && return 0
        ;;
    esac;
    return 1
}
__tar_last_char () 
{ 
    echo "${1: $(( ${#1} - 1))}"
}
__tar_parse_old_opt () 
{ 
    local first_word char;
    [[ "$cword" -eq 1 && -n "$cur" && "${cur:0:1}" != '-' ]] && old_opt_progress=1;
    first_word=${words[1]};
    [[ -n "$first_word" && "${first_word:0:1}" != "-" ]] && old_opt_used=1;
    if [[ $old_opt_used -eq 1 ]]; then
        char=${first_word:0:1};
        while [[ -n "$char" ]]; do
            if __tar_is_argreq "$char"; then
                old_opt_parsed+=("$char");
            fi;
            first_word=${first_word##$char};
            char=${first_word:0:1};
        done;
    fi
}
__tar_posix_prev_handle () 
{ 
    case "$prev" in 
        -f)
            __tar_file_option "$ext";
            return 0
        ;;
        -b)
            return 0
        ;;
    esac;
    return 1
}
__tar_preparse_cmdline () 
{ 
    local first_arg my_args tmparg i modes="ctxurdA";
    shift;
    __tar_parse_old_opt;
    first_arg=1;
    for i in "$@";
    do
        case "$i" in 
            --delete | --test-label)
                tar_mode=${i:2:100};
                tar_mode_arg=$i;
                break
            ;;
            --*)

            ;;
            -*[$modes]*)
                tar_mode=${i//[^$modes]/};
                tar_mode=${tar_mode:0:1};
                tar_mode_arg=$i;
                break
            ;;
            *[$modes]*)
                if [[ $first_arg -eq 1 ]]; then
                    tar_mode=${i//[^$modes]/};
                    tar_mode=${tar_mode:0:1};
                    tar_mode_arg=$i;
                fi
            ;;
        esac;
        first_arg=0;
    done
}
__tar_try_list_archive () 
{ 
    local tarball tarbin untar i;
    __tar_extract_like_mode || return 1;
    set -- "${words[@]}";
    tarbin=$1;
    untar="tf";
    shift;
    for i in "$@";
    do
        if [[ $i == *.$ext ]]; then
            tarball=$i;
            break;
        fi;
    done;
    if [[ -n "$tarball" ]]; then
        local IFS='
';
        COMPREPLY=($(compgen -o filenames -W "$(
            $tarbin $untar "$tarball" 2>/dev/null |
            while read line; do
                printf "%q\n" "$(printf %q"\n" "$line")"
            done
        )" -- "$(printf "%q\n" "$cur")"));
        return 0;
    fi
}
__tar_try_mode () 
{ 
    case "$cur" in 
        --*)
            [[ -n "$basic_tar" ]] && return 0;
            __gtar_complete_lopts;
            return $?
        ;;
        -*)
            [[ -n "$basic_tar" ]] && return 0;
            __tar_complete_mode && return 0
        ;;
        *)
            if [[ "$cword" -eq 1 || "$tar_mode" == none ]]; then
                __tar_complete_mode && return 0;
            fi
        ;;
    esac;
    return 1
}
_alias () 
{ 
    local cur prev words cword;
    _init_completion -n = || return;
    case ${words[@]} in 
        *[^=])
            COMPREPLY=($(compgen -A alias -- "$cur"))
        ;;
        *=)
            COMPREPLY=("$(alias ${cur%=} 2>/dev/null | command sed                 -e 's|^alias '"$cur"'\(.*\)$|\1|')")
        ;;
    esac
}
_allowed_groups () 
{ 
    if _complete_as_root; then
        local IFS='
';
        COMPREPLY=($(compgen -g -- "$1"));
    else
        local IFS='
 ';
        COMPREPLY=($(compgen -W             "$(id -Gn 2>/dev/null || groups 2>/dev/null)" -- "$1"));
    fi
}
_allowed_users () 
{ 
    if _complete_as_root; then
        local IFS='
';
        COMPREPLY=($(compgen -u -- "${1:-$cur}"));
    else
        local IFS='
 ';
        COMPREPLY=($(compgen -W             "$(id -un 2>/dev/null || whoami 2>/dev/null)" -- "${1:-$cur}"));
    fi
}
_asdf () 
{ 
    local cur;
    cur=${COMP_WORDS[COMP_CWORD]};
    local cmd;
    cmd=${COMP_WORDS[1]};
    local prev;
    prev=${COMP_WORDS[COMP_CWORD - 1]};
    local plugins;
    plugins=$(asdf plugin-list 2>/dev/null | tr '\n' ' ');
    COMPREPLY=();
    case "$cmd" in 
        plugin-update)
            COMPREPLY=($(compgen -W "$plugins --all" -- "$cur"))
        ;;
        plugin-remove | current | list | list-all)
            COMPREPLY=($(compgen -W "$plugins" -- "$cur"))
        ;;
        plugin-add)
            local available_plugins;
            available_plugins=$(asdf plugin-list-all 2>/dev/null | awk '{ if ($2 !~ /^\*/) print $1}');
            COMPREPLY=($(compgen -W "$available_plugins" -- "$cur"))
        ;;
        install)
            if [[ "$plugins" == *"$prev"* ]]; then
                local versions;
                versions=$(asdf list-all "$prev" 2>/dev/null);
                COMPREPLY=($(compgen -W "$versions" -- "$cur"));
            else
                COMPREPLY=($(compgen -W "$plugins" -- "$cur"));
            fi
        ;;
        update)
            COMPREPLY=($(compgen -W "--head" -- "$cur"))
        ;;
        uninstall | where | reshim | local | global | shell)
            if [[ "$plugins" == *"$prev"* ]]; then
                local versions;
                versions=$(asdf list "$prev" 2>/dev/null);
                COMPREPLY=($(compgen -W "$versions" -- "$cur"));
            else
                COMPREPLY=($(compgen -W "$plugins" -- "$cur"));
            fi
        ;;
        *)
            local cmds='current global help install list list-all local plugin-add plugin-list plugin-list-all plugin-remove plugin-update reshim shell uninstall update where which ';
            COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
        ;;
    esac;
    return 0
}
_available_interfaces () 
{ 
    local PATH=$PATH:/sbin;
    COMPREPLY=($({
        if [[ ${1:-} == -w ]]; then
            iwconfig
        elif [[ ${1:-} == -a ]]; then
            ifconfig || ip link show up
        else
            ifconfig -a || ip link show
        fi
    } 2>/dev/null | awk         '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { print $2 } else { print $1 } }'));
    COMPREPLY=($(compgen -W '${COMPREPLY[@]/%[[:punct:]]/}' -- "$cur"))
}
_cd () 
{ 
    local cur prev words cword;
    _init_completion || return;
    local IFS='
' i j k;
    compopt -o filenames;
    if [[ -z "${CDPATH:-}" || "$cur" == ?(.)?(.)/* ]]; then
        _filedir -d;
        return;
    fi;
    local -r mark_dirs=$(_rl_enabled mark-directories && echo y);
    local -r mark_symdirs=$(_rl_enabled mark-symlinked-directories && echo y);
    for i in ${CDPATH//:/'
'};
    do
        k="${#COMPREPLY[@]}";
        for j in $(compgen -d -- $i/$cur);
        do
            if [[ ( -n $mark_symdirs && -h $j || -n $mark_dirs && ! -h $j ) && ! -d ${j#$i/} ]]; then
                j+="/";
            fi;
            COMPREPLY[k++]=${j#$i/};
        done;
    done;
    _filedir -d;
    if [[ ${#COMPREPLY[@]} -eq 1 ]]; then
        i=${COMPREPLY[0]};
        if [[ "$i" == "$cur" && $i != "*/" ]]; then
            COMPREPLY[0]="${i}/";
        fi;
    fi;
    return
}
_cd_devices () 
{ 
    COMPREPLY+=($(compgen -f -d -X "!*/?([amrs])cd*" -- "${cur:-/dev/}"))
}
_command () 
{ 
    local offset i;
    offset=1;
    for ((i=1; i <= COMP_CWORD; i++ ))
    do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            offset=$i;
            break;
        fi;
    done;
    _command_offset $offset
}
_command_offset () 
{ 
    local word_offset=$1 i j;
    for ((i=0; i < $word_offset; i++ ))
    do
        for ((j=0; j <= ${#COMP_LINE}; j++ ))
        do
            [[ "$COMP_LINE" == "${COMP_WORDS[i]}"* ]] && break;
            COMP_LINE=${COMP_LINE:1};
            ((COMP_POINT--));
        done;
        COMP_LINE=${COMP_LINE#"${COMP_WORDS[i]}"};
        ((COMP_POINT-=${#COMP_WORDS[i]}));
    done;
    for ((i=0; i <= COMP_CWORD - $word_offset; i++ ))
    do
        COMP_WORDS[i]=${COMP_WORDS[i+$word_offset]};
    done;
    for ((i; i <= COMP_CWORD; i++ ))
    do
        unset 'COMP_WORDS[i]';
    done;
    ((COMP_CWORD -= $word_offset));
    COMPREPLY=();
    local cur;
    _get_comp_words_by_ref cur;
    if [[ $COMP_CWORD -eq 0 ]]; then
        local IFS='
';
        compopt -o filenames;
        COMPREPLY=($(compgen -d -c -- "$cur"));
    else
        local cmd=${COMP_WORDS[0]} compcmd=${COMP_WORDS[0]};
        local cspec=$(complete -p $cmd 2>/dev/null);
        if [[ ! -n $cspec && $cmd == */* ]]; then
            cspec=$(complete -p ${cmd##*/} 2>/dev/null);
            [[ -n $cspec ]] && compcmd=${cmd##*/};
        fi;
        if [[ ! -n $cspec ]]; then
            compcmd=${cmd##*/};
            _completion_loader $compcmd;
            cspec=$(complete -p $compcmd 2>/dev/null);
        fi;
        if [[ -n $cspec ]]; then
            if [[ ${cspec#* -F } != $cspec ]]; then
                local func=${cspec#*-F };
                func=${func%% *};
                if [[ ${#COMP_WORDS[@]} -ge 2 ]]; then
                    $func $cmd "${COMP_WORDS[${#COMP_WORDS[@]}-1]}" "${COMP_WORDS[${#COMP_WORDS[@]}-2]}";
                else
                    $func $cmd "${COMP_WORDS[${#COMP_WORDS[@]}-1]}";
                fi;
                local opt;
                while [[ $cspec == *" -o "* ]]; do
                    cspec=${cspec#*-o };
                    opt=${cspec%% *};
                    compopt -o $opt;
                    cspec=${cspec#$opt};
                done;
            else
                cspec=${cspec#complete};
                cspec=${cspec%%$compcmd};
                COMPREPLY=($(eval compgen "$cspec" -- '$cur'));
            fi;
        else
            if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
                _minimal;
            fi;
        fi;
    fi
}
_complete_as_root () 
{ 
    [[ $EUID -eq 0 || -n ${root_command:-} ]]
}
_completion_loader () 
{ 
    local cmd="${1:-_EmptycmD_}";
    __load_completion "$cmd" && return 124;
    complete -F _minimal -- "$cmd" && return 124
}
_configured_interfaces () 
{ 
    if [[ -f /etc/debian_version ]]; then
        COMPREPLY=($(compgen -W "$(command sed -ne 's|^iface \([^ ]\{1,\}\).*$|\1|p'            /etc/network/interfaces /etc/network/interfaces.d/* 2>/dev/null)"             -- "$cur"));
    else
        if [[ -f /etc/SuSE-release ]]; then
            COMPREPLY=($(compgen -W "$(printf '%s\n'             /etc/sysconfig/network/ifcfg-* |             command sed -ne 's|.*ifcfg-\([^*].*\)$|\1|p')" -- "$cur"));
        else
            if [[ -f /etc/pld-release ]]; then
                COMPREPLY=($(compgen -W "$(command ls -B             /etc/sysconfig/interfaces |             command sed -ne 's|.*ifcfg-\([^*].*\)$|\1|p')" -- "$cur"));
            else
                COMPREPLY=($(compgen -W "$(printf '%s\n'             /etc/sysconfig/network-scripts/ifcfg-* |             command sed -ne 's|.*ifcfg-\([^*].*\)$|\1|p')" -- "$cur"));
            fi;
        fi;
    fi
}
_count_args () 
{ 
    local i cword words;
    __reassemble_comp_words_by_ref "$1" words cword;
    args=1;
    for ((i=1; i < cword; i++ ))
    do
        if [[ ${words[i]} != -* && ${words[i-1]} != $2 || ${words[i]} == $3 ]]; then
            (( args++ ));
        fi;
    done
}
_direnv_hook () 
{ 
    local previous_exit_status=$?;
    trap -- '' SIGINT;
    eval "$("/usr/local/bin/direnv" export bash)";
    trap - SIGINT;
    return $previous_exit_status
}
_dvd_devices () 
{ 
    COMPREPLY+=($(compgen -f -d -X "!*/?(r)dvd*" -- "${cur:-/dev/}"))
}
_expand () 
{ 
    if [[ "$cur" == \~*/* ]]; then
        __expand_tilde_by_ref cur;
    else
        if [[ "$cur" == \~* ]]; then
            _tilde "$cur" || eval COMPREPLY[0]=$(printf ~%q "${COMPREPLY[0]#\~}");
            return ${#COMPREPLY[@]};
        fi;
    fi
}
_filedir () 
{ 
    local IFS='
';
    _tilde "$cur" || return;
    local -a toks;
    local reset;
    if [[ "$1" == -d ]]; then
        reset=$(shopt -po noglob);
        set -o noglob;
        toks=($(compgen -d -- "$cur"));
        IFS=' ';
        $reset;
        IFS='
';
    else
        local quoted;
        _quote_readline_by_ref "$cur" quoted;
        local xspec=${1:+"!*.@($1|${1^^})"} plusdirs=();
        local opts=(-f -X "$xspec");
        [[ -n $xspec ]] && plusdirs=(-o plusdirs);
        [[ -n ${COMP_FILEDIR_FALLBACK-} ]] || opts+=("${plusdirs[@]}");
        reset=$(shopt -po noglob);
        set -o noglob;
        toks+=($(compgen "${opts[@]}" -- $quoted));
        IFS=' ';
        $reset;
        IFS='
';
        [[ -n ${COMP_FILEDIR_FALLBACK:-} && -n "$1" && ${#toks[@]} -lt 1 ]] && { 
            reset=$(shopt -po noglob);
            set -o noglob;
            toks+=($(compgen -f "${plusdirs[@]}" -- $quoted));
            IFS=' ';
            $reset;
            IFS='
'
        };
    fi;
    if [[ ${#toks[@]} -ne 0 ]]; then
        compopt -o filenames 2> /dev/null;
        COMPREPLY+=("${toks[@]}");
    fi
}
_filedir_xspec () 
{ 
    local cur prev words cword;
    _init_completion || return;
    _tilde "$cur" || return;
    local IFS='
' xspec=${_xspecs[${1##*/}]} tmp;
    local -a toks;
    toks=($(
        compgen -d -- "$(quote_readline "$cur")" | {
        while read -r tmp; do
            printf '%s\n' $tmp
        done
        }
        ));
    eval xspec="${xspec}";
    local matchop=!;
    if [[ $xspec == !* ]]; then
        xspec=${xspec#!};
        matchop=@;
    fi;
    xspec="$matchop($xspec|${xspec^^})";
    toks+=($(
        eval compgen -f -X "'!$xspec'" -- "\$(quote_readline "\$cur")" | {
        while read -r tmp; do
            [[ -n $tmp ]] && printf '%s\n' $tmp
        done
        }
        ));
    [[ -n ${COMP_FILEDIR_FALLBACK:-} && ${#toks[@]} -lt 1 ]] && { 
        local reset=$(shopt -po noglob);
        set -o noglob;
        toks+=($(compgen -f -- "$(quote_readline "$cur")"));
        IFS=' ';
        $reset;
        IFS='
'
    };
    if [[ ${#toks[@]} -ne 0 ]]; then
        compopt -o filenames;
        COMPREPLY=("${toks[@]}");
    fi
}
_fstypes () 
{ 
    local fss;
    if [[ -e /proc/filesystems ]]; then
        fss="$(cut -d'	' -f2 /proc/filesystems)
             $(awk '! /\*/ { print $NF }' /etc/filesystems 2>/dev/null)";
    else
        fss="$(awk '/^[ \t]*[^#]/ { print $3 }' /etc/fstab 2>/dev/null)
             $(awk '/^[ \t]*[^#]/ { print $3 }' /etc/mnttab 2>/dev/null)
             $(awk '/^[ \t]*[^#]/ { print $4 }' /etc/vfstab 2>/dev/null)
             $(awk '{ print $1 }' /etc/dfs/fstypes 2>/dev/null)
             $([[ -d /etc/fs ]] && command ls /etc/fs)";
    fi;
    [[ -n $fss ]] && COMPREPLY+=($(compgen -W "$fss" -- "$cur"))
}
_get_comp_words_by_ref () 
{ 
    local exclude flag i OPTIND=1;
    local cur cword words=();
    local upargs=() upvars=() vcur vcword vprev vwords;
    while getopts "c:i:n:p:w:" flag "$@"; do
        case $flag in 
            c)
                vcur=$OPTARG
            ;;
            i)
                vcword=$OPTARG
            ;;
            n)
                exclude=$OPTARG
            ;;
            p)
                vprev=$OPTARG
            ;;
            w)
                vwords=$OPTARG
            ;;
        esac;
    done;
    while [[ $# -ge $OPTIND ]]; do
        case ${!OPTIND} in 
            cur)
                vcur=cur
            ;;
            prev)
                vprev=prev
            ;;
            cword)
                vcword=cword
            ;;
            words)
                vwords=words
            ;;
            *)
                echo "bash_completion: $FUNCNAME: \`${!OPTIND}':" "unknown argument" 1>&2;
                return 1
            ;;
        esac;
        (( OPTIND += 1 ));
    done;
    __get_cword_at_cursor_by_ref "$exclude" words cword cur;
    [[ -n $vcur ]] && { 
        upvars+=("$vcur");
        upargs+=(-v $vcur "$cur")
    };
    [[ -n $vcword ]] && { 
        upvars+=("$vcword");
        upargs+=(-v $vcword "$cword")
    };
    [[ -n $vprev && $cword -ge 1 ]] && { 
        upvars+=("$vprev");
        upargs+=(-v $vprev "${words[cword - 1]}")
    };
    [[ -n $vwords ]] && { 
        upvars+=("$vwords");
        upargs+=(-a${#words[@]} $vwords "${words[@]}")
    };
    (( ${#upvars[@]} )) && local "${upvars[@]}" && _upvars "${upargs[@]}"
}
_get_cword () 
{ 
    local LC_CTYPE=C;
    local cword words;
    __reassemble_comp_words_by_ref "$1" words cword;
    if [[ -n ${2//[^0-9]/} ]]; then
        printf "%s" "${words[cword-$2]}";
    else
        if [[ "${#words[cword]}" -eq 0 || "$COMP_POINT" == "${#COMP_LINE}" ]]; then
            printf "%s" "${words[cword]}";
        else
            local i;
            local cur="$COMP_LINE";
            local index="$COMP_POINT";
            for ((i = 0; i <= cword; ++i ))
            do
                while [[ "${#cur}" -ge ${#words[i]} && "${cur:0:${#words[i]}}" != "${words[i]}" ]]; do
                    cur="${cur:1}";
                    [[ $index -gt 0 ]] && ((index--));
                done;
                if [[ "$i" -lt "$cword" ]]; then
                    local old_size="${#cur}";
                    cur="${cur#${words[i]}}";
                    local new_size="${#cur}";
                    (( index -= old_size - new_size ));
                fi;
            done;
            if [[ "${words[cword]:0:${#cur}}" != "$cur" ]]; then
                printf "%s" "${words[cword]}";
            else
                printf "%s" "${cur:0:$index}";
            fi;
        fi;
    fi
}
_get_first_arg () 
{ 
    local i;
    arg=;
    for ((i=1; i < COMP_CWORD; i++ ))
    do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            arg=${COMP_WORDS[i]};
            break;
        fi;
    done
}
_get_pword () 
{ 
    if [[ $COMP_CWORD -ge 1 ]]; then
        _get_cword "${@:-}" 1;
    fi
}
_gids () 
{ 
    if type getent &> /dev/null; then
        COMPREPLY=($(compgen -W '$(getent group | cut -d: -f3)' -- "$cur"));
    else
        if type perl &> /dev/null; then
            COMPREPLY=($(compgen -W '$(perl -e '"'"'while (($gid) = (getgrent)[2]) { print $gid . "\n" }'"'"')' -- "$cur"));
        else
            COMPREPLY=($(compgen -W '$(cut -d: -f3 /etc/group)' -- "$cur"));
        fi;
    fi
}
_grm () 
{ 
    local i cur prev opts cmds;
    COMPREPLY=();
    cur="${COMP_WORDS[COMP_CWORD]}";
    prev="${COMP_WORDS[COMP_CWORD-1]}";
    cmd="";
    opts="";
    for i in ${COMP_WORDS[@]};
    do
        case "${i}" in 
            grm)
                cmd="grm"
            ;;
            add)
                cmd+="__add"
            ;;
            completions)
                cmd+="__completions"
            ;;
            goto)
                cmd+="__goto"
            ;;
            help)
                cmd+="__help"
            ;;
            list)
                cmd+="__list"
            ;;
            rm)
                cmd+="__rm"
            ;;
            *)

            ;;
        esac;
    done;
    case "${cmd}" in 
        grm)
            opts=" -h -V  --help --version   add list goto rm completions help";
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 1 ]]; then
                COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
                return 0;
            fi;
            case "${prev}" in 
                *)
                    COMPREPLY=()
                ;;
            esac;
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
            return 0
        ;;
        grm__add)
            opts=" -h -V  --help --version  <PATH> ";
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
                return 0;
            fi;
            case "${prev}" in 
                *)
                    COMPREPLY=()
                ;;
            esac;
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
            return 0
        ;;
        grm__completions)
            opts=" -h -V  --help --version  <SHELL> ";
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
                return 0;
            fi;
            case "${prev}" in 
                *)
                    COMPREPLY=()
                ;;
            esac;
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
            return 0
        ;;
        grm__goto)
            opts=" -h -V  --help --version ";
            git_repo_list=$(complete_git_repos);
            if [[ ${cur} == -* ]]; then
                COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
                return 0;
            else
                if [[ ${cur} != -* && ${COMP_CWORD} -eq 2 ]]; then
                    COMPREPLY=($(compgen -W "${git_repo_list}" -- ${cur}));
                    return 0;
                fi;
            fi;
            case "${prev}" in 
                *)
                    COMPREPLY=()
                ;;
            esac;
            return 0
        ;;
        grm__help)
            opts=" -h -V  --help --version  ";
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
                return 0;
            fi;
            case "${prev}" in 
                *)
                    COMPREPLY=()
                ;;
            esac;
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
            return 0
        ;;
        grm__list)
            opts=" -h -V  --help --version  <PATTERN> ";
            if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
                return 0;
            fi;
            case "${prev}" in 
                *)
                    COMPREPLY=()
                ;;
            esac;
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
            return 0
        ;;
        grm__rm)
            opts=" -h -V  --help --version ";
            git_repo_list=$(complete_git_repos);
            if [[ ${cur} == -* ]]; then
                COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
                return 0;
            else
                if [[ ${cur} != -* && ${COMP_CWORD} -eq 2 ]]; then
                    COMPREPLY=($(compgen -W "${git_repo_list}" -- ${cur}));
                    return 0;
                fi;
            fi;
            case "${prev}" in 
                *)
                    COMPREPLY=()
                ;;
            esac;
            return 0
        ;;
    esac
}
_gtar () 
{ 
    local long_opts short_opts long_arg_none long_arg_opt long_arg_req short_arg_none short_arg_opt short_arg_req tar_mode tar_mode_arg old_opt_progress=0 old_opt_used=0 old_opt_parsed=();
    local tar_mode=none;
    local tar_mode_arg=;
    if [[ "$_TAR_OPT_DEBUG" == 1 ]]; then
        set -x;
        PS4="\$BASH_SOURCE:\$LINENO: ";
    fi;
    local cur prev words cword split;
    _init_completion -s || return;
    __gnu_tar_parse_help;
    __tar_preparse_cmdline "${words[@]}";
    local ext tar untar;
    __tar_detect_ext;
    while true; do
        __tar_adjust_PREV_from_old_option;
        __tar_posix_prev_handle && break;
        __tar_cleanup_prev;
        case $prev in 
            --directory | -!(-*)C)
                _filedir -d;
                break
            ;;
            --atime-preserve)
                COMPREPLY=($(compgen -W 'replace system' -- "$cur"));
                break
            ;;
            --group)
                COMPREPLY=($(compgen -g -- "$cur"));
                break
            ;;
            --owner)
                COMPREPLY=($(compgen -u -- "$cur"));
                break
            ;;
            --info-script | --new-volume-script | --rmt-command | --rsh-command | --use-compress-program | -!(-*)[FI])
                compopt -o filenames;
                COMPREPLY=($(compgen -c -- "$cur"));
                break
            ;;
            --volno-file | --add-file | --files-from | --exclude-from | --index-file | --listed-incremental | -!(-*)[TXg])
                _filedir;
                break
            ;;
            --format | -!(-*)H)
                COMPREPLY=($(compgen -W 'gnu oldgnu pax posix ustar v7'                     -- "$cur"));
                break
            ;;
            --quoting-style)
                COMPREPLY=($(compgen -W 'literal shell shell-always c c-maybe
                    escape locale clocale' -- "$cur"));
                break
            ;;
            --totals)
                COMPREPLY=($(compgen -W 'SIGHUP SIGQUIT SIGINT SIGUSR1 SIGUSR2'                     -- "$cur"));
                break
            ;;
            --warning)
                COMPREPLY=($(compgen -W "$(__gtar_parse_warnings)" -- "$cur"));
                break
            ;;
            --file | -!(-*)f)
                __tar_file_option "$ext";
                break
            ;;
            --*)
                [[ " $long_arg_req " =~ \ $prev=\  ]] && break;
                [[ " $long_arg_opt " =~ \ $prev\  ]] && break;
                $split && break
            ;;
            -!(-*)[a-zA-Z0-9?])
                [[ "$short_arg_req" =~ ${prev##-} ]] && break
            ;;
        esac;
        case "$cur" in 
            -[a-zA-Z0-9]=*)
                break
            ;;
        esac;
        __tar_try_mode && break;
        case "$cur" in 
            --*)
                __gtar_complete_lopts;
                break
            ;;
            -*)
                __gtar_complete_sopts;
                break
            ;;
        esac;
        [[ "$cword" -eq 1 ]] && break;
        __tar_try_list_archive && break;
        if [[ $tar_mode != none ]]; then
            _filedir;
        fi;
        break;
    done;
    if [[ "$_TAR_OPT_DEBUG" == 1 ]]; then
        set +x;
        unset PS4;
    fi
}
_have () 
{ 
    PATH=$PATH:/usr/sbin:/sbin:/usr/local/sbin type $1 &> /dev/null
}
_hwloc_annotate () 
{ 
    local OPTIONS=(--ci --ri --cu --cd -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    fi;
    _filedir xml
}
_hwloc_bind () 
{ 
    local OPTIONS=(--cpubind --membind --mempolicy --logical -l --physical -p --single --strict --get -e --get-last-cpu-location --nodeset --pid --tid --taskset --restrict --disallowed --whole-system --hbm --no-hbm --no-smt --no-smt=N -f --force -q --quiet -v --verbose --version -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        case "$prev" in 
            --mempolicy)
                COMPREPLY=(`compgen -W "default firsttouch bind interleave nexttouch" -- "$cur"`)
            ;;
            --pid)
                COMPREPLY=("<pid>" "")
            ;;
            --tid)
                COMPREPLY=("<tid>" "")
            ;;
            --restrict)
                COMPREPLY=("<bitmask>" "")
            ;;
        esac;
    fi
}
_hwloc_calc () 
{ 
    local TYPES=("Machine" "Misc" "Group" "NUMANode" "MemCache" "Package" "Die" "L1" "L2" "L3" "L4" "L5" "L1i" "L2i" "L3i" "Core" "Bridge" "PCIDev" "OSDev" "PU");
    local OPTIONS=(-N --number-of -I --intersect -H --hierarchical --largest -l --logical -p --physical --li --logical-input --lo --logical-output --pi --physical-input --po --physical-output -n --nodeset --ni --nodeset-input --no --nodeset-output --sep --taskset --single --restrict --disallowed --whole-system --input -i --input-format --if --no-smt --no-smt=N -q --quiet -v --verbose --version -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        case "$prev" in 
            -N | --number-of | -I | --intersect)
                COMPREPLY=(`compgen -W "${TYPES[*]}" -- "$cur"`)
            ;;
            -H | --hierarchical)
                COMPREPLY=("<type1>.<type2>..." "")
            ;;
            --sep)
                COMPREPLY=("<separator>" "")
            ;;
            -i | --input)
                _filedir xml
            ;;
            --if | --input-format)
                COMPREPLY=(`compgen -W "${INPUT_FORMAT[*]}" -- "$cur"`)
            ;;
            --restrict)
                COMPREPLY=("<bitmask>" "")
            ;;
        esac;
    fi
}
_hwloc_compress_dir () 
{ 
    local OPTIONS=(-R --reverse -v --verbose -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    fi;
    _filedir -d
}
_hwloc_diff () 
{ 
    local OPTIONS=(--refname --version -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        case "$prev" in 
            --refname)
                COMPREPLY=("<reference topology identifier>" "")
            ;;
        esac;
    fi;
    _filedir xml
}
_hwloc_distrib () 
{ 
    local TYPES=("Machine" "Misc" "Group" "NUMANode" "MemCache" "Package" "Die" "L1" "L2" "L3" "L4" "L5" "L1i" "L2i" "L3i" "Core" "Bridge" "PCIDev" "OSDev" "PU");
    local OPTIONS=(--ignore --from --to --at --reverse --restrict --disallowed --whole-system --input -i --input-format --if --single --taskset -v --verbose --version -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        case "$prev" in 
            --ignore | --from | --to | --at)
                COMPREPLY=(`compgen -W "${TYPES[*]}" -- "$cur"`)
            ;;
            -i | --input)
                _filedir xml
            ;;
            --if | --input-format)
                COMPREPLY=(`compgen -W "${INPUT_FORMAT[*]}" -- "$cur"`)
            ;;
            --restrict)
                COMPREPLY=("<bitmask>" "")
            ;;
        esac;
    fi
}
_hwloc_gather_cpuid () 
{ 
    local OPTIONS=(-c -s --silent -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        case "$prev" in 
            -c)
                COMPREPLY=("<index of cpu to operate on>" "")
            ;;
        esac;
    fi
}
_hwloc_gather_topology () 
{ 
    local OPTIONS=(--io --dmi --no-cpuid --keep -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    fi
}
_hwloc_info () 
{ 
    local TYPES=("Machine" "Misc" "Group" "NUMANode" "MemCache" "Package" "Die" "L1" "L2" "L3" "L4" "L5" "L1i" "L2i" "L3i" "Core" "Bridge" "PCIDev" "OSDev" "PU");
    local FILTERKINDS=("none" "all" "structure" "important");
    local OPTIONS=(--objects --topology --support -v --verbose -s --silent --ancestors --ancestor --children --descendants -n --restrict --filter --no-icaches --no-io --no-bridges --whole-io --input -i --input-format --if --thissystem --pid --disallowed --whole-system -l --logical -p --physical --version -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        if [[ $COMP_CWORD -ge 3 && "${COMP_WORDS[COMP_CWORD-2]}" == "--filter" && "$cur" == ":" ]]; then
            COMPREPLY=(`compgen -W "${FILTERKINDS[*]}"`);
        else
            if [[ $COMP_CWORD -ge 4 && "${COMP_WORDS[COMP_CWORD-3]}" == "--filter" && "$prev" == ":" ]]; then
                COMPREPLY=(`compgen -W "${FILTERKINDS[*]}" -- "$cur"`);
            else
                case "$prev" in 
                    --restrict)
                        COMPREPLY=(`compgen -W "binding <cpuset>" -- "$cur"`)
                    ;;
                    -i | --input)
                        _filedir xml
                    ;;
                    --if | --input-format)
                        COMPREPLY=(`compgen -W "${INPUT_FORMAT[*]}" -- "$cur"`)
                    ;;
                    --pid)
                        COMPREPLY=("<pid>" "")
                    ;;
                    --filter)
                        COMPREPLY=(`compgen -W "${TYPES[*]/%/:} cache: icache: io:" -- "$cur"`) && compopt -o nospace
                    ;;
                    --ancestor | --descendants)
                        COMPREPLY=(`compgen -W "${TYPES[*]}" -- "$cur"`)
                    ;;
                esac;
            fi;
        fi;
    fi
}
_hwloc_patch () 
{ 
    local OPTIONS=(--R --reverse --version -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    fi;
    _filedir xml
}
_hwloc_ps () 
{ 
    local OPTIONS=(-a --pid --name -l --logical -p --physical -c --cpuset -t --threads -e --get-last-cpu-location --pid-cmd --uid --disallowed --whole-system --json-server --json-port -v --verbose -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        case "$prev" in 
            --name)
                COMPREPLY=("<task name>" "")
            ;;
            --uid)
                COMPREPLY=("<uid>" "all" "")
            ;;
            --pid)
                COMPREPLY=("<pid>" "")
            ;;
            --pid-cmd)
                _filedir
            ;;
            --json-port)
                COMPREPLY=("<port>" "")
            ;;
        esac;
    fi
}
_included_ssh_config_files () 
{ 
    [[ $# -lt 1 ]] && echo "bash_completion: $FUNCNAME: missing mandatory argument CONFIG" 1>&2;
    local configfile i f;
    configfile=$1;
    local included=($(command sed -ne 's/^[[:blank:]]*[Ii][Nn][Cc][Ll][Uu][Dd][Ee][[:blank:]]\{1,\}\([^#%]*\)\(#.*\)\{0,1\}$/\1/p' "${configfile}"));
    for i in "${included[@]}";
    do
        if ! [[ "$i" =~ ^\~.*|^\/.* ]]; then
            if [[ "$configfile" =~ ^\/etc\/ssh.* ]]; then
                i="/etc/ssh/$i";
            else
                i="$HOME/.ssh/$i";
            fi;
        fi;
        __expand_tilde_by_ref i;
        for f in ${i};
        do
            if [ -r $f ]; then
                config+=("$f");
                _included_ssh_config_files $f;
            fi;
        done;
    done
}
_init_completion () 
{ 
    local exclude="" flag outx errx inx OPTIND=1;
    while getopts "n:e:o:i:s" flag "$@"; do
        case $flag in 
            n)
                exclude+=$OPTARG
            ;;
            e)
                errx=$OPTARG
            ;;
            o)
                outx=$OPTARG
            ;;
            i)
                inx=$OPTARG
            ;;
            s)
                split=false;
                exclude+==
            ;;
        esac;
    done;
    COMPREPLY=();
    local redir="@(?([0-9])<|?([0-9&])>?(>)|>&)";
    _get_comp_words_by_ref -n "$exclude<>&" cur prev words cword;
    _variables && return 1;
    if [[ $cur == $redir* || $prev == $redir ]]; then
        local xspec;
        case $cur in 
            2'>'*)
                xspec=$errx
            ;;
            *'>'*)
                xspec=$outx
            ;;
            *'<'*)
                xspec=$inx
            ;;
            *)
                case $prev in 
                    2'>'*)
                        xspec=$errx
                    ;;
                    *'>'*)
                        xspec=$outx
                    ;;
                    *'<'*)
                        xspec=$inx
                    ;;
                esac
            ;;
        esac;
        cur="${cur##$redir}";
        _filedir $xspec;
        return 1;
    fi;
    local i skip;
    for ((i=1; i < ${#words[@]}; 1))
    do
        if [[ ${words[i]} == $redir* ]]; then
            [[ ${words[i]} == $redir ]] && skip=2 || skip=1;
            words=("${words[@]:0:i}" "${words[@]:i+skip}");
            [[ $i -le $cword ]] && (( cword -= skip ));
        else
            (( i++ ));
        fi;
    done;
    [[ $cword -le 0 ]] && return 1;
    prev=${words[cword-1]};
    [[ -n ${split-} ]] && _split_longopt && split=true;
    return 0
}
_installed_modules () 
{ 
    COMPREPLY=($(compgen -W "$(PATH="$PATH:/sbin" lsmod |         awk '{if (NR != 1) print $1}')" -- "$1"))
}
_ip_addresses () 
{ 
    local n;
    case $1 in 
        -a)
            n='6\?'
        ;;
        -6)
            n='6'
        ;;
    esac;
    local PATH=$PATH:/sbin;
    local addrs=$({ LC_ALL=C ifconfig -a || ip addr show; } 2>/dev/null |
        command sed -e 's/[[:space:]]addr:/ /' -ne             "s|.*inet${n}[[:space:]]\{1,\}\([^[:space:]/]*\).*|\1|p");
    COMPREPLY+=($(compgen -W "$addrs" -- "$cur"))
}
_kernel_versions () 
{ 
    COMPREPLY=($(compgen -W '$(command ls /lib/modules)' -- "$cur"))
}
_known_hosts () 
{ 
    local cur prev words cword;
    _init_completion -n : || return;
    local options;
    [[ "$1" == -a || "$2" == -a ]] && options=-a;
    [[ "$1" == -c || "$2" == -c ]] && options+=" -c";
    _known_hosts_real $options -- "$cur"
}
_known_hosts_real () 
{ 
    local configfile flag prefix OIFS=$IFS;
    local cur user suffix aliases i host ipv4 ipv6;
    local -a kh tmpkh khd config;
    local OPTIND=1;
    while getopts "ac46F:p:" flag "$@"; do
        case $flag in 
            a)
                aliases='yes'
            ;;
            c)
                suffix=':'
            ;;
            F)
                configfile=$OPTARG
            ;;
            p)
                prefix=$OPTARG
            ;;
            4)
                ipv4=1
            ;;
            6)
                ipv6=1
            ;;
        esac;
    done;
    [[ $# -lt $OPTIND ]] && echo "bash_completion: $FUNCNAME: missing mandatory argument CWORD" 1>&2;
    cur=${!OPTIND};
    (( OPTIND += 1 ));
    [[ $# -ge $OPTIND ]] && echo "bash_completion: $FUNCNAME($*): unprocessed arguments:" $(while [[ $# -ge $OPTIND ]]; do printf '%s\n' ${!OPTIND}; shift; done) 1>&2;
    [[ $cur == *@* ]] && user=${cur%@*}@ && cur=${cur#*@};
    kh=();
    if [[ -n $configfile ]]; then
        [[ -r $configfile ]] && config+=("$configfile");
    else
        for i in /etc/ssh/ssh_config ~/.ssh/config ~/.ssh2/config;
        do
            [[ -r $i ]] && config+=("$i");
        done;
    fi;
    for i in "${config[@]}";
    do
        _included_ssh_config_files "$i";
    done;
    if [[ ${#config[@]} -gt 0 ]]; then
        local IFS='
' j;
        tmpkh=($(awk 'sub("^[ \t]*([Gg][Ll][Oo][Bb][Aa][Ll]|[Uu][Ss][Ee][Rr])[Kk][Nn][Oo][Ww][Nn][Hh][Oo][Ss][Tt][Ss][Ff][Ii][Ll][Ee][ \t]+", "") { print $0 }' "${config[@]}" | sort -u));
        IFS=$OIFS;
        for i in "${tmpkh[@]}";
        do
            while [[ $i =~ ^([^\"]*)\"([^\"]*)\"(.*)$ ]]; do
                i=${BASH_REMATCH[1]}${BASH_REMATCH[3]};
                j=${BASH_REMATCH[2]};
                __expand_tilde_by_ref j;
                [[ -r $j ]] && kh+=("$j");
            done;
            for j in $i;
            do
                __expand_tilde_by_ref j;
                [[ -r $j ]] && kh+=("$j");
            done;
        done;
    fi;
    if [[ -z $configfile ]]; then
        for i in /etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts2 /etc/known_hosts /etc/known_hosts2 ~/.ssh/known_hosts ~/.ssh/known_hosts2;
        do
            [[ -r $i ]] && kh+=("$i");
        done;
        for i in /etc/ssh2/knownhosts ~/.ssh2/hostkeys;
        do
            [[ -d $i ]] && khd+=("$i"/*pub);
        done;
    fi;
    if [[ ${#kh[@]} -gt 0 || ${#khd[@]} -gt 0 ]]; then
        if [[ ${#kh[@]} -gt 0 ]]; then
            for i in "${kh[@]}";
            do
                while read -ra tmpkh; do
                    set -- "${tmpkh[@]}";
                    [[ $1 == [\|\#]* ]] && continue;
                    [[ $1 == @* ]] && shift;
                    local IFS=,;
                    for host in $1;
                    do
                        [[ $host == *[*?]* ]] && continue;
                        host="${host#[}";
                        host="${host%]?(:+([0-9]))}";
                        COMPREPLY+=($host);
                    done;
                    IFS=$OIFS;
                done < "$i";
            done;
            COMPREPLY=($(compgen -W '${COMPREPLY[@]}' -- "$cur"));
        fi;
        if [[ ${#khd[@]} -gt 0 ]]; then
            for i in "${khd[@]}";
            do
                if [[ "$i" == *key_22_$cur*.pub && -r "$i" ]]; then
                    host=${i/#*key_22_/};
                    host=${host/%.pub/};
                    COMPREPLY+=($host);
                fi;
            done;
        fi;
        for ((i=0; i < ${#COMPREPLY[@]}; i++ ))
        do
            COMPREPLY[i]=$prefix$user${COMPREPLY[i]}$suffix;
        done;
    fi;
    if [[ ${#config[@]} -gt 0 && -n "$aliases" ]]; then
        local hosts=$(command sed -ne 's/^[[:blank:]]*[Hh][Oo][Ss][Tt][[:blank:]]\{1,\}\([^#*?%]*\)\(#.*\)\{0,1\}$/\1/p' "${config[@]}");
        COMPREPLY+=($(compgen -P "$prefix$user"             -S "$suffix" -W "$hosts" -- "$cur"));
    fi;
    if [[ -n ${COMP_KNOWN_HOSTS_WITH_AVAHI:-} ]] && type avahi-browse &> /dev/null; then
        COMPREPLY+=($(compgen -P "$prefix$user" -S "$suffix" -W             "$(avahi-browse -cpr _workstation._tcp 2>/dev/null |                awk -F';' '/^=/ { print $7 }' | sort -u)" -- "$cur"));
    fi;
    COMPREPLY+=($(compgen -W         "$(ruptime 2>/dev/null | awk '!/^ruptime:/ { print $1 }')"         -- "$cur"));
    if [[ -n ${COMP_KNOWN_HOSTS_WITH_HOSTFILE-1} ]]; then
        COMPREPLY+=($(compgen -A hostname -P "$prefix$user" -S "$suffix" -- "$cur"));
    fi;
    if [[ -n $ipv4 ]]; then
        COMPREPLY=("${COMPREPLY[@]/*:*$suffix/}");
    fi;
    if [[ -n $ipv6 ]]; then
        COMPREPLY=("${COMPREPLY[@]/+([0-9]).+([0-9]).+([0-9]).+([0-9])$suffix/}");
    fi;
    if [[ -n $ipv4 || -n $ipv6 ]]; then
        for i in "${!COMPREPLY[@]}";
        do
            [[ -n ${COMPREPLY[i]} ]] || unset -v COMPREPLY[i];
        done;
    fi;
    __ltrim_colon_completions "$prefix$user$cur"
}
_longopt () 
{ 
    local cur prev words cword split;
    _init_completion -s || return;
    case "${prev,,}" in 
        --help | --usage | --version)
            return
        ;;
        --!(no-*)dir*)
            _filedir -d;
            return
        ;;
        --!(no-*)@(file|path)*)
            _filedir;
            return
        ;;
        --+([-a-z0-9_]))
            local argtype=$(LC_ALL=C $1 --help 2>&1 | command sed -ne                 "s|.*$prev\[\{0,1\}=[<[]\{0,1\}\([-A-Za-z0-9_]\{1,\}\).*|\1|p");
            case ${argtype,,} in 
                *dir*)
                    _filedir -d;
                    return
                ;;
                *file* | *path*)
                    _filedir;
                    return
                ;;
            esac
        ;;
    esac;
    $split && return;
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$(LC_ALL=C $1 --help 2>&1 |             while read -r line; do                 [[ $line =~ --[-A-Za-z0-9]+=? ]] &&                     printf '%s\n' ${BASH_REMATCH[0]}
            done)" -- "$cur"));
        [[ $COMPREPLY == *= ]] && compopt -o nospace;
    else
        if [[ "$1" == *@(rmdir|chroot) ]]; then
            _filedir -d;
        else
            [[ "$1" == *mkdir ]] && compopt -o nospace;
            _filedir;
        fi;
    fi
}
_lstopo () 
{ 
    local INPUT_FORMAT=(xml synthetic fsroot cpuid);
    local OUTPUT_FORMAT=(console ascii fig pdf ps png svg xml synthetic);
    local TYPES=("Machine" "Misc" "Group" "NUMANode" "MemCache" "Package" "Die" "L1" "L2" "L3" "L4" "L5" "L1i" "L2i" "L3i" "Core" "Bridge" "PCIDev" "OSDev" "PU");
    local FILTERKINDS=("none" "all" "structure" "important");
    local OPTIONS=(-l --logical -p --physical --output-format --of -f --force --only -v --verbose -s --silent --distances -c --cpuset -C --cpuset-only --taskset --filter --ignore --no-caches --no-useless-caches --no-icaches --merge --no-collapse --factorize --factorize= --no-factorize --no-factorize= --restrict --restrict-flags --no-io --no-bridges --whole-io --input -i --input-format --if --no-smt --thissystem --pid --disallowed --whole-system --allow --children-order --fontsize --gridsize --linespacing --horiz --horiz= --vert --vert= --rect --rect= --text --text= --no-text --no-text= --index --index= --no-index --no-index= --attrs --attrs= --no-attrs --no-attrs= --no-legend --append-legend --binding-color --disallowed-color --top-color --export-xml-flags --export-synthetic-flags --ps --top --version -h --help);
    local cur=${COMP_WORDS[COMP_CWORD]};
    local prev=${COMP_WORDS[COMP_CWORD-1]};
    if [[ $COMP_CWORD == 1 || $cur == -* ]]; then
        COMPREPLY=(`compgen -W "${OPTIONS[*]}" -- "$cur"`);
    else
        if [[ $COMP_CWORD -ge 3 && "${COMP_WORDS[COMP_CWORD-2]}" == "--filter" && "$cur" == ":" ]]; then
            COMPREPLY=(`compgen -W "${FILTERKINDS[*]}"`);
        else
            if [[ $COMP_CWORD -ge 4 && "${COMP_WORDS[COMP_CWORD-3]}" == "--filter" && "$prev" == ":" ]]; then
                COMPREPLY=(`compgen -W "${FILTERKINDS[*]}" -- "$cur"`);
            else
                if [[ "$cur" == "=" && " --horiz --vert --rect --text --no-text --index --no-index --attrs --no-attrs --no-factorize " =~ " $prev " ]]; then
                    COMPREPLY=(`compgen -W "${TYPES[*]}"`);
                else
                    if [[ $COMP_CWORD -ge 3 && "$prev" == "=" && " --horiz --vert --rect --text --no-text --index --no-index --attrs --no-attrs --no-factorize --factorize " =~ " ${COMP_WORDS[COMP_CWORD-2]} " ]]; then
                        COMPREPLY=(`compgen -W "${TYPES[*]}" -- "$cur"`);
                    else
                        if [[ "$cur" == "=" && "--factorize" = "$prev" ]]; then
                            COMPREPLY=(`compgen -W "${TYPES[*]}"` "<N>" "<N,F,L>");
                        else
                            case "$prev" in 
                                --of | --output-format)
                                    COMPREPLY=(`compgen -W "${OUTPUT_FORMAT[*]}" -- "$cur"`)
                                ;;
                                --only | --ignore)
                                    COMPREPLY=(`compgen -W "${TYPES[*]}" -- "$cur"`)
                                ;;
                                --filter)
                                    COMPREPLY=(`compgen -W "${TYPES[*]/%/:} cache: icache: io:" -- "$cur"`) && compopt -o nospace
                                ;;
                                --restrict)
                                    COMPREPLY=(`compgen -W "binding <cpuset>" -- "$cur"`)
                                ;;
                                -i | --input)
                                    _filedir xml
                                ;;
                                --if | --input-format)
                                    COMPREPLY=(`compgen -W "${INPUT_FORMAT[*]}" -- "$cur"`)
                                ;;
                                --pid)
                                    COMPREPLY=("<pid>" "")
                                ;;
                                --allow)
                                    COMPREPLY=(`compgen -W "all local <mask> nodeset=<mask>" -- "$cur"`)
                                ;;
                                --restrict-flags | --export-xml-flags | --export-synthetic-flags | --fontsize | --gridsize | --linespacing)
                                    COMPREPLY=("<integer>" "")
                                ;;
                                --append-legend)
                                    COMPREPLY=("<line of text>" "")
                                ;;
                                --binding-color | --disallowed-color)
                                    COMPREPLY=(`compgen -W "none" -- "$cur"`)
                                ;;
                                --top-color)
                                    COMPREPLY=(`compgen -W "none <#xxyyzz>" -- "$cur"`)
                                ;;
                                --children-order)
                                    COMPREPLY=(`compgen -W "plain memoryabove" -- "$cur"`)
                                ;;
                            esac;
                        fi;
                    fi;
                fi;
            fi;
        fi;
    fi
}
_mac_addresses () 
{ 
    local re='\([A-Fa-f0-9]\{2\}:\)\{5\}[A-Fa-f0-9]\{2\}';
    local PATH="$PATH:/sbin:/usr/sbin";
    COMPREPLY+=($(        { LC_ALL=C ifconfig -a || ip link show; } 2>/dev/null | command sed -ne         "s/.*[[:space:]]HWaddr[[:space:]]\{1,\}\($re\)[[:space:]].*/\1/p" -ne         "s/.*[[:space:]]HWaddr[[:space:]]\{1,\}\($re\)[[:space:]]*$/\1/p" -ne         "s|.*[[:space:]]\(link/\)\{0,1\}ether[[:space:]]\{1,\}\($re\)[[:space:]].*|\2|p" -ne         "s|.*[[:space:]]\(link/\)\{0,1\}ether[[:space:]]\{1,\}\($re\)[[:space:]]*$|\2|p"
        ));
    COMPREPLY+=($({ arp -an || ip neigh show; } 2>/dev/null | command sed -ne         "s/.*[[:space:]]\($re\)[[:space:]].*/\1/p" -ne         "s/.*[[:space:]]\($re\)[[:space:]]*$/\1/p"));
    COMPREPLY+=($(command sed -ne         "s/^[[:space:]]*\($re\)[[:space:]].*/\1/p" /etc/ethers 2>/dev/null));
    COMPREPLY=($(compgen -W '${COMPREPLY[@]}' -- "$cur"));
    __ltrim_colon_completions "$cur"
}
_megacmd () 
{ 
    local cur opts;
    COMPREPLY=();
    cur="${COMP_WORDS[COMP_CWORD]}";
    if [[ ${cur} == '=' ]]; then
        cur="";
    fi;
    COMP_WORDS[0]="${COMP_WORDS[0]/mega-/}";
    linetoexec="";
    lasta="";
    for a in "${COMP_WORDS[@]}";
    do
        if [[ $a =~ ^.*([ \\]).*$ ]] && [[ $a != "\""* ]] && [[ $a != "'"* ]]; then
            lastcharina="${a: -1}";
            linetoexec=$linetoexec" '"$(echo $a | sed 's#\([^\\]\)\\$#\1\\ #g' | sed "s#\\\\\([ \<\>\|\`;\"\!]\)#\1#g")"'";
        else
            if [[ ${a} == '=' ]] || [[ ${lasta} == '=' ]] || [[ ${a} == ':' ]] || [[ ${lasta} == ':' ]]; then
                linetoexec=$linetoexec$a;
            else
                linetoexec=$linetoexec" "$a;
                if [[ $a == "\""* ]] && [[ $a != *"\"" ]]; then
                    linetoexec=$linetoexec"\"";
                fi;
                if [[ $a == "'"* ]] && [[ $a != *"'" ]]; then
                    linetoexec=$linetoexec"'";
                fi;
            fi;
        fi;
        lasta=$a;
    done;
    if [[ "$linetoexec" == *" " ]]; then
        linetoexec="$linetoexec\"\"";
    fi;
    COMPREPLY="";
    opts="$(mega-exec completion ${linetoexec/#mega-/} 2>/dev/null)";
    if [ $? -ne 0 ]; then
        COMPREPLY="";
        return $?;
    fi;
    opts=$(echo "${opts/\`/\\\`}");
    opts=$(echo "${opts/\|/\\\|}");
    declare -a "aOPTS=(${opts})" || declare -a 'aOPTS=(${opts})';
    for a in `seq 0 $(( ${#aOPTS[@]} -1 ))`;
    do
        if [[ $lasta != "\""* ]] && [[ $lasta != "'"* ]]; then
            COMPREPLY[$a]=$( echo ${aOPTS[$a]} | sed "s#\([ \!;\|\`\(\)\<\>\"\'\\]\)#\\\\\1#g");
        else
            COMPREPLY[$a]="${aOPTS[$a]}";
        fi;
    done;
    for i in "${COMPREPLY[@]}";
    do
        if [[ ${i} == --*= ]] || [[ ${i} == */ ]]; then
            hash compopt 2> /dev/null > /dev/null && compopt -o nospace;
        fi;
    done;
    if [[ $opts == "MEGACMD_USE_LOCAL_COMPLETION" ]]; then
        COMPREPLY=();
    fi;
    if [[ $opts == "" ]]; then
        COMPREPLY="";
        compopt -o nospace;
    fi;
    return 0
}
_minimal () 
{ 
    local cur prev words cword split;
    _init_completion -s || return;
    $split && return;
    _filedir
}
_modules () 
{ 
    local modpath;
    modpath=/lib/modules/$1;
    COMPREPLY=($(compgen -W "$(command ls -RL $modpath 2>/dev/null |         command sed -ne 's/^\(.*\)\.k\{0,1\}o\(\.[gx]z\)\{0,1\}$/\1/p')" -- "$cur"))
}
_ncpus () 
{ 
    local var=NPROCESSORS_ONLN;
    [[ $OSTYPE == *linux* ]] && var=_$var;
    local n=$(getconf $var 2>/dev/null);
    printf %s ${n:-1}
}
_parse_help () 
{ 
    eval local cmd=$(quote "$1");
    local line;
    { 
        case $cmd in 
            -)
                cat
            ;;
            *)
                LC_ALL=C "$(dequote "$cmd")" ${2:---help} 2>&1
            ;;
        esac
    } | while read -r line; do
        [[ $line == *([[:blank:]])-* ]] || continue;
        while [[ $line =~ ((^|[^-])-[A-Za-z0-9?][[:space:]]+)\[?[A-Z0-9]+([,_-]+[A-Z0-9]+)?(\.\.+)?\]? ]]; do
            line=${line/"${BASH_REMATCH[0]}"/"${BASH_REMATCH[1]}"};
        done;
        __parse_options "${line// or /, }";
    done
}
_parse_usage () 
{ 
    eval local cmd=$(quote "$1");
    local line match option i char;
    { 
        case $cmd in 
            -)
                cat
            ;;
            *)
                LC_ALL=C "$(dequote "$cmd")" ${2:---usage} 2>&1
            ;;
        esac
    } | while read -r line; do
        while [[ $line =~ \[[[:space:]]*(-[^]]+)[[:space:]]*\] ]]; do
            match=${BASH_REMATCH[0]};
            option=${BASH_REMATCH[1]};
            case $option in 
                -?(\[)+([a-zA-Z0-9?]))
                    for ((i=1; i < ${#option}; i++ ))
                    do
                        char=${option:i:1};
                        [[ $char != '[' ]] && printf '%s\n' -$char;
                    done
                ;;
                *)
                    __parse_options "$option"
                ;;
            esac;
            line=${line#*"$match"};
        done;
    done
}
_pci_ids () 
{ 
    COMPREPLY+=($(compgen -W         "$(PATH="$PATH:/sbin" lspci -n | awk '{print $3}')" -- "$cur"))
}
_pgids () 
{ 
    COMPREPLY=($(compgen -W '$(command ps axo pgid=)' -- "$cur"))
}
_pids () 
{ 
    COMPREPLY=($(compgen -W '$(command ps axo pid=)' -- "$cur"))
}
_pnames () 
{ 
    local -a procs;
    if [[ "$1" == -s ]]; then
        procs=($(command ps axo comm | command sed -e 1d));
    else
        local line i=-1 OIFS=$IFS;
        IFS='
';
        local -a psout=($(command ps axo command=));
        IFS=$OIFS;
        for line in "${psout[@]}";
        do
            if [[ $i -eq -1 ]]; then
                if [[ $line =~ ^(.*[[:space:]])COMMAND([[:space:]]|$) ]]; then
                    i=${#BASH_REMATCH[1]};
                else
                    break;
                fi;
            else
                line=${line:$i};
                line=${line%% *};
                procs+=($line);
            fi;
        done;
        if [[ $i -eq -1 ]]; then
            for line in "${psout[@]}";
            do
                if [[ $line =~ ^[[(](.+)[])]$ ]]; then
                    procs+=(${BASH_REMATCH[1]});
                else
                    line=${line%% *};
                    line=${line##@(*/|-)};
                    procs+=($line);
                fi;
            done;
        fi;
    fi;
    COMPREPLY=($(compgen -X "<defunct>" -W '${procs[@]}' -- "$cur" ))
}
_posix_tar () 
{ 
    local long_opts short_opts basic_tar long_arg_none long_arg_opt long_arg_req short_arg_none short_arg_opt short_arg_req tar_mode tar_mode_arg old_opt_progress=0 old_opt_used=1 old_opt_parsed=();
    local tar_mode=none;
    local tar_mode_arg=;
    local cur prev words cword split;
    _init_completion -s || return;
    basic_tar=yes;
    tar_mode=none;
    short_arg_req="fb";
    short_arg_none="wmv";
    short_opts="$short_arg_req$short_arg_none";
    __tar_preparse_cmdline "${words[@]}";
    local ext tar untar;
    __tar_detect_ext;
    __tar_adjust_PREV_from_old_option;
    __tar_posix_prev_handle && return;
    __tar_try_mode && return;
    __tar_try_list_archive && return;
    _filedir
}
_quote_readline_by_ref () 
{ 
    if [[ $1 == \'* ]]; then
        printf -v $2 %s "${1:1}";
    else
        printf -v $2 %q "$1";
    fi;
    [[ ${!2} == \$* ]] && eval $2=${!2}
}
_realcommand () 
{ 
    type -P "$1" > /dev/null && { 
        if type -p realpath > /dev/null; then
            realpath "$(type -P "$1")";
        else
            if type -p greadlink > /dev/null; then
                greadlink -f "$(type -P "$1")";
            else
                if type -p readlink > /dev/null; then
                    readlink -f "$(type -P "$1")";
                else
                    type -P "$1";
                fi;
            fi;
        fi
    }
}
_rl_enabled () 
{ 
    [[ "$(bind -v)" == *$1+([[:space:]])on* ]]
}
_root_command () 
{ 
    local PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin;
    local root_command=$1;
    _command
}
_service () 
{ 
    local cur prev words cword;
    _init_completion || return;
    [[ $cword -gt 2 ]] && return;
    if [[ $cword -eq 1 && $prev == ?(*/)service ]]; then
        _services;
        [[ -e /etc/mandrake-release ]] && _xinetd_services;
    else
        local sysvdirs;
        _sysvdirs;
        COMPREPLY=($(compgen -W '`command sed -e "y/|/ /" \
            -ne "s/^.*\(U\|msg_u\)sage.*{\(.*\)}.*$/\2/p" \
            ${sysvdirs[0]}/${prev##*/} 2>/dev/null` start stop' -- "$cur"));
    fi
}
_services () 
{ 
    local sysvdirs;
    _sysvdirs;
    local IFS=' 	
' reset=$(shopt -p nullglob);
    shopt -s nullglob;
    COMPREPLY=($(printf '%s\n' ${sysvdirs[0]}/!($_backup_glob|functions|README)));
    $reset;
    COMPREPLY+=($({ systemctl list-units --full --all ||                      systemctl list-unit-files; } 2>/dev/null |         awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }'));
    if [[ -x /sbin/upstart-udev-bridge ]]; then
        COMPREPLY+=($(initctl list 2>/dev/null | cut -d' ' -f1));
    fi;
    COMPREPLY=($(compgen -W '${COMPREPLY[@]#${sysvdirs[0]}/}' -- "$cur"))
}
_shells () 
{ 
    local shell rest;
    while read -r shell rest; do
        [[ $shell == /* && $shell == "$cur"* ]] && COMPREPLY+=($shell);
    done 2> /dev/null < /etc/shells
}
_signals () 
{ 
    local -a sigs=($(compgen -P "$1" -A signal "SIG${cur#$1}"));
    COMPREPLY+=("${sigs[@]/#${1}SIG/${1}}")
}
_split_longopt () 
{ 
    if [[ "$cur" == --?*=* ]]; then
        prev="${cur%%?(\\)=*}";
        cur="${cur#*=}";
        return 0;
    fi;
    return 1
}
_sysvdirs () 
{ 
    sysvdirs=();
    [[ -d /etc/rc.d/init.d ]] && sysvdirs+=(/etc/rc.d/init.d);
    [[ -d /etc/init.d ]] && sysvdirs+=(/etc/init.d);
    [[ -f /etc/slackware-version ]] && sysvdirs=(/etc/rc.d);
    return 0
}
_terms () 
{ 
    COMPREPLY+=($(compgen -W "$({         command sed -ne 's/^\([^[:space:]#|]\{2,\}\)|.*/\1/p' /etc/termcap;
        { toe -a || toe; } | awk '{ print $1 }';
        find /{etc,lib,usr/lib,usr/share}/terminfo/? -type f -maxdepth 1             | awk -F/ '{ print $NF }';
    } 2>/dev/null)" -- "$cur"))
}
_tilde () 
{ 
    local result=0;
    if [[ $1 == \~* && $1 != */* ]]; then
        COMPREPLY=($(compgen -P '~' -u -- "${1#\~}"));
        result=${#COMPREPLY[@]};
        [[ $result -gt 0 ]] && compopt -o filenames 2> /dev/null;
    fi;
    return $result
}
_uids () 
{ 
    if type getent &> /dev/null; then
        COMPREPLY=($(compgen -W '$(getent passwd | cut -d: -f3)' -- "$cur"));
    else
        if type perl &> /dev/null; then
            COMPREPLY=($(compgen -W '$(perl -e '"'"'while (($uid) = (getpwent)[2]) { print $uid . "\n" }'"'"')' -- "$cur"));
        else
            COMPREPLY=($(compgen -W '$(cut -d: -f3 /etc/passwd)' -- "$cur"));
        fi;
    fi
}
_upvar () 
{ 
    echo "bash_completion: $FUNCNAME: deprecated function," "use _upvars instead" 1>&2;
    if unset -v "$1"; then
        if (( $# == 2 )); then
            eval $1=\"\$2\";
        else
            eval $1=\(\"\${@:2}\"\);
        fi;
    fi
}
_upvars () 
{ 
    if ! (( $# )); then
        echo "bash_completion: $FUNCNAME: usage: $FUNCNAME" "[-v varname value] | [-aN varname [value ...]] ..." 1>&2;
        return 2;
    fi;
    while (( $# )); do
        case $1 in 
            -a*)
                [[ -n ${1#-a} ]] || { 
                    echo "bash_completion: $FUNCNAME:" "\`$1': missing number specifier" 1>&2;
                    return 1
                };
                printf %d "${1#-a}" &> /dev/null || { 
                    echo bash_completion: "$FUNCNAME: \`$1': invalid number specifier" 1>&2;
                    return 1
                };
                [[ -n "$2" ]] && unset -v "$2" && eval $2=\(\"\${@:3:${1#-a}}\"\) && shift $((${1#-a} + 2)) || { 
                    echo bash_completion: "$FUNCNAME: \`$1${2+ }$2': missing argument(s)" 1>&2;
                    return 1
                }
            ;;
            -v)
                [[ -n "$2" ]] && unset -v "$2" && eval $2=\"\$3\" && shift 3 || { 
                    echo "bash_completion: $FUNCNAME: $1:" "missing argument(s)" 1>&2;
                    return 1
                }
            ;;
            *)
                echo "bash_completion: $FUNCNAME: $1: invalid option" 1>&2;
                return 1
            ;;
        esac;
    done
}
_usb_ids () 
{ 
    COMPREPLY+=($(compgen -W         "$(PATH="$PATH:/sbin" lsusb | awk '{print $6}')" -- "$cur"))
}
_user_at_host () 
{ 
    local cur prev words cword;
    _init_completion -n : || return;
    if [[ $cur == *@* ]]; then
        _known_hosts_real "$cur";
    else
        COMPREPLY=($(compgen -u -S @ -- "$cur"));
        compopt -o nospace;
    fi
}
_usergroup () 
{ 
    if [[ $cur == *\\\\* || $cur == *:*:* ]]; then
        return;
    else
        if [[ $cur == *\\:* ]]; then
            local prefix;
            prefix=${cur%%*([^:])};
            prefix=${prefix//\\};
            local mycur="${cur#*[:]}";
            if [[ $1 == -u ]]; then
                _allowed_groups "$mycur";
            else
                local IFS='
';
                COMPREPLY=($(compgen -g -- "$mycur"));
            fi;
            COMPREPLY=($(compgen -P "$prefix" -W "${COMPREPLY[@]}"));
        else
            if [[ $cur == *:* ]]; then
                local mycur="${cur#*:}";
                if [[ $1 == -u ]]; then
                    _allowed_groups "$mycur";
                else
                    local IFS='
';
                    COMPREPLY=($(compgen -g -- "$mycur"));
                fi;
            else
                if [[ $1 == -u ]]; then
                    _allowed_users "$cur";
                else
                    local IFS='
';
                    COMPREPLY=($(compgen -u -- "$cur"));
                fi;
            fi;
        fi;
    fi
}
_userland () 
{ 
    local userland=$(uname -s);
    [[ $userland == @(Linux|GNU/*) ]] && userland=GNU;
    [[ $userland == $1 ]]
}
_variables () 
{ 
    if [[ $cur =~ ^(\$(\{[!#]?)?)([A-Za-z0-9_]*)$ ]]; then
        if [[ $cur == \${* ]]; then
            local arrs vars;
            vars=($(compgen -A variable -P ${BASH_REMATCH[1]} -S '}' -- ${BASH_REMATCH[3]})) && arrs=($(compgen -A arrayvar -P ${BASH_REMATCH[1]} -S '[' -- ${BASH_REMATCH[3]}));
            if [[ ${#vars[@]} -eq 1 && -n $arrs ]]; then
                compopt -o nospace;
                COMPREPLY+=(${arrs[*]});
            else
                COMPREPLY+=(${vars[*]});
            fi;
        else
            COMPREPLY+=($(compgen -A variable -P '$' -- "${BASH_REMATCH[3]}"));
        fi;
        return 0;
    else
        if [[ $cur =~ ^(\$\{[#!]?)([A-Za-z0-9_]*)\[([^]]*)$ ]]; then
            local IFS='
';
            COMPREPLY+=($(compgen -W '$(printf %s\\n "${!'${BASH_REMATCH[2]}'[@]}")'             -P "${BASH_REMATCH[1]}${BASH_REMATCH[2]}[" -S ']}' -- "${BASH_REMATCH[3]}"));
            if [[ ${BASH_REMATCH[3]} == [@*] ]]; then
                COMPREPLY+=("${BASH_REMATCH[1]}${BASH_REMATCH[2]}[${BASH_REMATCH[3]}]}");
            fi;
            __ltrim_colon_completions "$cur";
            return 0;
        else
            if [[ $cur =~ ^\$\{[#!]?[A-Za-z0-9_]*\[.*\]$ ]]; then
                COMPREPLY+=("$cur}");
                __ltrim_colon_completions "$cur";
                return 0;
            else
                case $prev in 
                    TZ)
                        cur=/usr/share/zoneinfo/$cur;
                        _filedir;
                        for i in "${!COMPREPLY[@]}";
                        do
                            if [[ ${COMPREPLY[i]} == *.tab ]]; then
                                unset 'COMPREPLY[i]';
                                continue;
                            else
                                if [[ -d ${COMPREPLY[i]} ]]; then
                                    COMPREPLY[i]+=/;
                                    compopt -o nospace;
                                fi;
                            fi;
                            COMPREPLY[i]=${COMPREPLY[i]#/usr/share/zoneinfo/};
                        done;
                        return 0
                    ;;
                    TERM)
                        _terms;
                        return 0
                    ;;
                    LANG | LC_*)
                        COMPREPLY=($(compgen -W '$(locale -a 2>/dev/null)'                     -- "$cur" ));
                        return 0
                    ;;
                esac;
            fi;
        fi;
    fi;
    return 1
}
_xfunc () 
{ 
    set -- "$@";
    local srcfile=$1;
    shift;
    declare -F $1 &> /dev/null || { 
        __load_completion "$srcfile"
    };
    "$@"
}
_xinetd_services () 
{ 
    local xinetddir=/etc/xinetd.d;
    if [[ -d $xinetddir ]]; then
        local IFS=' 	
' reset=$(shopt -p nullglob);
        shopt -s nullglob;
        local -a svcs=($(printf '%s\n' $xinetddir/!($_backup_glob)));
        $reset;
        COMPREPLY+=($(compgen -W '${svcs[@]#$xinetddir/}' -- "$cur"));
    fi
}
asdf () 
{ 
    local command;
    command="$1";
    if [ "$#" -gt 0 ]; then
        shift;
    fi;
    case "$command" in 
        "shell")
            eval "$(asdf export-shell-version sh "$@")"
        ;;
        *)
            command asdf "$command" "$@"
        ;;
    esac
}
autols () 
{ 
    [[ $AUTOLS_DIR != $PWD ]] && lsd;
    AUTOLS_DIR="${PWD}"
}
colors () 
{ 
    local fgc bgc vals seq0;
    printf "Color escapes are %s\n" '\e[${value};...;${value}m';
    printf "Values 30..37 are \e[33mforeground colors\e[m\n";
    printf "Values 40..47 are \e[43mbackground colors\e[m\n";
    printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n";
    for fgc in {30..37};
    do
        for bgc in {40..47};
        do
            fgc=${fgc#37};
            bgc=${bgc#40};
            vals="${fgc:+$fgc;}${bgc}";
            vals=${vals%%;};
            seq0="${vals:+\e[${vals}m}";
            printf "  %-9s" "${seq0:-(default)}";
            printf " ${seq0}TEXT\e[m";
            printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m";
        done;
        echo;
        echo;
    done
}
complete_git_repos () 
{ 
    repo_list=`${GRM} list`;
    repo_concat_list="";
    for repo in ${repo_list};
    do
        repo_concat_list="${repo_concat_list} $repo";
    done;
    echo ${repo_concat_list}
}
dequote () 
{ 
    eval printf %s "$1" 2> /dev/null
}
ex () 
{ 
    if [ -f $1 ]; then
        case $1 in 
            *.tar.bz2)
                tar xjf $1
            ;;
            *.tar.gz)
                tar xzf $1
            ;;
            *.bz2)
                bunzip2 $1
            ;;
            *.rar)
                unrar x $1
            ;;
            *.gz)
                gunzip $1
            ;;
            *.tar)
                tar xf $1
            ;;
            *.tbz2)
                tar xjf $1
            ;;
            *.tgz)
                tar xzf $1
            ;;
            *.zip)
                unzip $1
            ;;
            *.Z)
                uncompress $1
            ;;
            *.7z)
                7z x $1
            ;;
            *)
                echo "'$1' cannot be extracted via ex()"
            ;;
        esac;
    else
        echo "'$1' is not a valid file";
    fi
}
grml () 
{ 
    source ~/.grm/grm.sh goto $(grm list | fzf)
}
quote () 
{ 
    local quoted=${1//\'/\'\\\'\'};
    printf "'%s'" "$quoted"
}
quote_readline () 
{ 
    local quoted;
    _quote_readline_by_ref "$1" ret;
    printf %s "$ret"
}
starship_precmd () 
{ 
    STATUS=$?;
    "${starship_precmd_user_func-:}";
    if [[ -n $STARSHIP_START_TIME ]]; then
        STARSHIP_END_TIME=$("/usr/local/bin/starship" time);
        STARSHIP_DURATION=$((STARSHIP_END_TIME - STARSHIP_START_TIME));
        PS1="$("/usr/local/bin/starship" prompt --status=$STATUS --jobs="$(jobs -p | wc -l)" --cmd-duration=$STARSHIP_DURATION)";
        unset STARSHIP_START_TIME;
    else
        PS1="$("/usr/local/bin/starship" prompt --status=$STATUS --jobs="$(jobs -p | wc -l)")";
    fi;
    PREEXEC_READY=true
}
starship_preexec () 
{ 
    local PREV_LAST_ARG=$1;
    if [ "$PREEXEC_READY" = "true" ]; then
        PREEXEC_READY=false;
        STARSHIP_START_TIME=$("/usr/local/bin/starship" time);
    fi;
    : "$PREV_LAST_ARG"
}
works () 
{ 
    FLAG='';
    OPTS=$(getopt -o "fd:h" -l "help" -- "$@");
    eval set -- "$OPTS";
    while :; do
        case "$1" in 
            '-f')
                FLAG=1;
                shift
            ;;
            '-d')
                DATA=$2;
                shift 2
            ;;
            '--')
                shift;
                break
            ;;
            '-h' | '--help')
                usage;
                exit 0
            ;;
            *)
                echo "[error] illegal option" 1>&2;
                usage 1>&2;
                exit 1
            ;;
        esac;
    done;
    [ $FLAG ] && cd "$HOME/works/$(ls $HOME/works/ | fzf --height 40%                                                                      --layout reverse                                                                  --tac                                                                             --info inline                                                                     --border                                                                          --preview-window right:80%                                                        --preview "lsd --tree --depth 2 -lA --color always $HOME/works/{}")" && return 0;
    workdir="$HOME/works/$(date -Idate)";
    mkdir -p "${workdir}" && cd "${workdir}"
}
