export AUTO_SPARK_CLEANER_VERSION="0.0.1"

SPARK_COMMAND=(
    "spark-shell" "spark-sql" "spark-submit"
)

TEMP_FILE=(
    "_temp_dirs"
)

function _color_echo() {
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    # ... ADD MORE COLORS
    NC="\033[0m" # No Color
    printf "${(P)1}${2} ${NC}\n"
}

function _rm_temp_file() {
    local rm_file=$1
    file_modify_time=$(stat _temp_dirs | grep Modify | cut -d ":" -f2,3,4 | date -f - +"%s")
    if [[ $file_modify_time -gt $LAST_COMMAND_START ]]; then
        /bin/rm -rf $rm_file
        _color_echo "YELLOW" "Auto delete $rm_file after cmd: $LAST_COMMAND (by zsh-spark-cleaner.plugin.zsh)"
    fi
}

function _clean_spark_temp() {
    for rm_file in $TEMP_FILE; do
        if [[ -f $rm_file ]]; then
            _rm_temp_file "$rm_file"
        fi
    done
}

function _auto_spark_cleaner() {
    # Immediately store the exit code before it goes away
    local exit_code="$?"

    if [[ -z "$LAST_COMMAND" && -z "$LAST_COMMAND_START" ]]; then
        return
    fi
    for cmd in $SPARK_COMMAND; do
        if [[ "$LAST_COMMAND_FULL" == "$cmd"* ]]; then
            _clean_spark_temp
        fi
    done

    # Empty tracking so that notifications are not
    # triggered for any commands not run (e.g ctrl+C when typing)
    _reset_command_tracking
}

function _command_track() {
    # $1 is the string the user typed, but only when history is enabled
    # $2 is a single-line, size-limited version of the command that is always available
    # To still do something useful when history is disabled, although with reduced functionality, fall back to $2 when $1 is empty
    LAST_COMMAND="${1:-$2}"
    LAST_COMMAND_FULL="$3"
    LAST_COMMAND_START="$(date +"%s")"
}

function _reset_command_tracking() {
    # Command start time in seconds since epoch
    unset LAST_COMMAND_START
    # Full command that the user has executed after alias expansion
    unset LAST_COMMAND_FULL
    # Command that the user has executed
    unset LAST_COMMAND
}

function disable_auto_spark_cleaner() {
    add-zsh-hook -D preexec _command_track
    add-zsh-hook -D precmd _auto_spark_cleaner
}

function enable_auto_spark_cleaner() {
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _command_track
    add-zsh-hook precmd _auto_spark_cleaner
}

_reset_command_tracking

enable_auto_spark_cleaner
