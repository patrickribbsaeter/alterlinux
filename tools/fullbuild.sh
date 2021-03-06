#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

channnels=(
    "xfce"
    "xfce-pro"
    "lxde"
    "cinnamon"
    "i3"
    "gnome"
)

architectures=(
    "x86_64"
    "i686"
)

locale_list=(
    "ja"
    "en"
)

work_dir="${script_path}/temp"
simulation=false
retry=5

all_channel=false

# Show an INFO message
# $1: message string
msg_info() {
    local _msg_opts="-a fullbuilid -s 5"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} info "${1}"
}

# Show an Warning message
# $1: message string
msg_warn() {
    local _msg_opts="-a fullbuilid -s 5"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} warn "${1}"
}

# Show an debug message
# $1: message string
msg_debug() {
    if [[ "${debug}" = true ]]; then
        local _msg_opts="-a fullbuilid -s 5"
        if [[ "${1}" = "-n" ]]; then
            _msg_opts="${_msg_opts} -o -n"
            shift 1
        fi
        "${script_path}/tools/msg.sh" ${_msg_opts} debug "${1}"
    fi
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
msg_error() {
    local _msg_opts="-a fullbuilid -s 5"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} error "${1}"
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
}


trap_exit() {
    local status=${?}
    echo
    msg_error "fullbuild.sh has been killed by the user."
    exit ${status}
}


build() {
    local _exit_code=0

    options="${share_options} --arch ${arch} --lang ${lang} ${cha}"

    if [[ ! -e "${work_dir}/fullbuild.${cha}_${arch}_${lang}" ]]; then
        if [[ "${simulation}" = true ]]; then
            echo "build.sh ${share_options} --lang ${lang} --arch ${arch} ${cha}"
            _exit_code="${?}"
        else
            msg_info "Build the ${lang} version of ${cha} on the ${arch} architecture."
            sudo bash ${script_path}/build.sh ${options}
            _exit_code="${?}"
            if [[ "${_exit_code}" = 0 ]]; then
                touch "${work_dir}/fullbuild.${cha}_${arch}_${lang}"
            else
                msg_error "build.sh finished with exit code ${_exit_code}. Will try again."
            fi
        fi
    fi
    sudo pacman -Sccc --noconfirm > /dev/null 2>&1
}

_help() {
    echo "usage ${0} [options] [channel]"
    echo
    echo " General options:"
    echo "    -a <options>       Set other options in build.sh"
    echo "    -c                 Build all channel (DO NOT specify the channel !!)"
    echo "    -d                 Use the default build.sh arguments. (${default_options})"
    echo "    -g                 Use gitversion"
    echo "    -h                 This help message"
    echo "    -l <locale>        Set the locale to build"
    echo "    -m <architecture>  Set the architecture to build"
    echo "    -r <interer>       Set the number of retries"
    echo "                       Defalut: ${retry}"
    echo "    -s                 Enable simulation mode"
    echo "    -t                 Build the tarball as well"
    echo
    echo " !! WARNING !!"
    echo " Do not set channel or architecture with -a."
    echo " Be sure to enclose the build.sh argument with '' to avoid mixing it with the fullbuild.sh argument."
    echo " Example: ${0} -a '-b -k zen'"
    echo
    echo "Run \"build.sh -h\" for channel details."
    echo -n " Channel: "
    "${script_path}/build.sh" --channellist
}


share_options="--noconfirm"
default_options="--boot-splash --cleanup --user alter --password alter"

while getopts 'a:dghr:sctm:l:' arg; do
    case "${arg}" in
        a) share_options="${share_options} ${OPTARG}" ;;
        c) all_channel=true ;;
        d) share_options="${share_options} ${default_options}" ;;
        m) architectures=(${OPTARG}) ;;
        g)
            if [[ ! -d "${script_path}/.git" ]]; then
                msg_error "There is no git directory. You need to use git clone to use this feature."
                exit 1
            else
                share_options="${share_options} --gitversion"
            fi
            ;;
        s) simulation=true;;
        r) retry="${OPTARG}" ;;
        t) share_options="${share_options} --tarball" ;;
        l) locale_list=(${OPTARG});;
        h) _help ; exit 0 ;;
        *) _help ; exit 1 ;;
    esac
done
shift $((OPTIND - 1))


if [[ "${all_channel}" = true  ]]; then
    if [[ -n "${*}" ]]; then
        msg_error "Do not specify the channel." "1"
    else
        channnels=($("${script_path}/build.sh" --channellist))
    fi
elif [[ -n "${*}" ]]; then
    channnels=(${@})
fi

if [[ "${simulation}" = true ]]; then
    retry=1
fi

msg_info "Options: ${share_options}"
msg_info "Press Enter to continue or Ctrl + C to cancel."
read


trap 'trap_exit' 1 2 3 15

if [[ ! -d "${work_dir}" ]]; then
    mkdir -p "${work_dir}"
fi

for cha in ${channnels[@]}; do
    for arch in ${architectures[@]}; do
        for lang in ${locale_list[@]}; do
            for i in $(seq 1 ${retry}); do
                if [[ -n $(cat "${script_path}/channels/${cha}/architecture" | grep -h -v ^'#' | grep -x "${arch}") ]]; then
                    build
                fi
            done
        done
    done
done


if [[ "${simulation}" = false ]]; then
    msg_info "All editions have been built"
fi
