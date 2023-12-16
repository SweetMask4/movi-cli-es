#!/bin/bash

# Script para buscar y reproducir películas, series y anime de Cuevana3

# Dependencias requeridas: mpv, yt-dlp, fzf, curl

others_base_url="https://cuevana3.ch"
anime_base_url="https://monoschinos2.com"
doramas_base_url="https://www.doramasyt.com"
spn_search_endpoint="/buscar?q="
movies_search_endpoint="/search.html?keyword="
dir="$HOME/.cache/movies"
state_file="$dir/state"
bookmarks="$dir/bookmarks"
history="$dir/history"
dir_downloads="$HOME/Downloads/movies"

[ ! -d "$dir" ] && mkdir "$dir"

# checks if dependencies are present
dep_ch() {
    for dep; do
        command -v "$dep" >/dev/null || die "Program \"$dep\" not found. Please install it."
    done
}

die() {
    printf "\33[2K\r\033[1;31m%s\033[0m\n" "$*" >&2
    exit 1
}

dep_ch "curl" "sed" "grep" "mpv" "fzf" "yt-dlp" "ffmpeg" || true


downloads() {
    local title_m3u8
    local m3u8_part1
    local m3u8_part2
    local mp4
    [ ! -d "$dir_downloads" ] && mkdir "$dir_downloads"
    [ -n "$1" ] || die "No hay enlace"
    title_m3u8=$(echo "$titleG" | cut -d '/' -f 5 | tr '-' ' ')

    for mp4 in "${@}"; do
        m3u8_part1=$(curl -s "$mp4" | grep m3u8 | cut -d\" -f 2 | sed 's/master\.m3u8.*//')
        m3u8_part2=$(curl -s "$mp4" | grep m3u8 | cut -d\" -f 2 | xargs curl -s | grep index)

        if ffmpeg -protocol_whitelist "file,http,https,tcp,tls" -i "$m3u8_part1$m3u8_part2" -c copy "$dir_downloads/$title_m3u8.mp4"; then
            return 0  # Successful download, return from the function
        fi
    done

    # If the loop completes without a successful download, return failure
    return 1
}

get_links(){
    local get_url
    case "$1" in
        *ver/anime*) get_url=$(printf "%s" "$1" | sed 's#^#https://monoschinos2.com/#' | sed 's#ver/anime#ver#' | tr ' ' '-') ;;
        *ver/dorama*) get_url=$(printf "%s" "$1" | sed 's#^#https://www.doramasyt.com/#' | sed 's#ver/dorama#ver#' | tr ' ' '-') ;;
        *anime*) get_url=$(printf "%s" "$1" | sed 's#^#https://monoschinos2.com/#' | tr ' ' '-') ;;
        *dorama*) get_url=$(printf "%s" "$1" | sed 's#^#https://www.doramasyt.com/#' | tr ' ' '-') ;;
        *) get_url=$(printf "%s" "$others_base_url$1" | tr ' ' '-') ;;
    esac
    echo "$get_url"
}

get_episode() {
    case "$1" in
        *anime*) anime=$(curl -s "$1" | grep episodio | cut -d\" -f 2 | sed 's#^300\s*##' | sed '/^$/d' | sed 's#^https://monoschinos2.com/##' | sed 's/ver\//ver\/anime\//g' | tr '-' ' ' ) ;;
        *dorama*) dorama=$(curl -s "$1" | grep episodio | cut -d\" -f 2 | sed 's#^https://www.doramasyt.com/##' | sed 's/ver\//ver\/dorama\//g'  | tr '-' ' ') ;;
        *serie*) title=$(echo "$1" | cut -d '/' -f 5)
            serie=$(curl -s "$1" | grep episodio | grep "$title" | cut -d\" -f 2 | tr '-' ' ') ;;
        *pelicula*|*) movie=$1 ;;
    esac

    selecte=$(printf "%s" "$anime" "$dorama" "$serie" "$movie" | fzf)
    if [[ "$selecte" == *"serie"* || "$selecte" == *"episodio"* || "$selecte" == *"ver"* || "$selecte" == *"anime"* ]]; then
        episode_list=$(get_links "$selecte")
        echo "$episode_list"
    else
        movies_list=$movie
        echo "$movies_list"
    fi
}

search_globar(){
    local anime_url="${anime_base_url}${spn_search_endpoint}$1"
    results_anime=$(curl -s "$anime_url" | grep "$1" | grep href | cut -d\" -f 2 | tr '-' ' ' | sed 's#^https://monoschinos2.com/##')
    local dorama_url="${doramas_base_url}${spn_search_endpoint}$1"
    results_dorama=$( curl -s "$dorama_url" | grep "dorama/" | cut -d\" -f 2 | sed 's#^https://www.doramasyt.com/##' |  tr '-' ' ' )
    local others_url="${others_base_url}${movies_search_endpoint}$1"
    results_others=$(curl -s "$others_url" | grep "$1" | grep href | cut -d\" -f 2 | tr '-' ' ' )

    if [ -n "$results_anime" ]; then
        echo "$results_anime"
    fi

    if [ -n "$results_dorama" ]; then
        echo "$results_dorama"
    fi

    if [ -n "$results_others" ]; then
        echo "$results_others"
    fi

}

get_video_links() {
    local video_links
    local links_base64
    local excluded_sites=("filemoon" "dood" "azipcd")
    case "$1" in
        *ver*|*anime*) mapfile -t links_base64 < <(curl -s "$1" | grep -o 'data-player="[^"]*"' | awk -F'"' '{print $2}' | sort | uniq)
            for link in "${links_base64[@]}"; do
                decoded_link=$(printf "%s" "$link" | base64 -d | cut -d '=' -f 2)
                excluded=false
                for site in "${excluded_sites[@]}"; do
                    if [[ $decoded_link == *"$site"* ]]; then
                        excluded=true
                        break
                    fi
                done
                if [ "$excluded" = false ]; then
                    links_decoders+=("$decoded_link")
                fi
            done
            video_links=("${links_decoders[@]}")  # Store all decoded links in video_links
            ;;
        *) mapfile -t video_links < <(curl -s "$1" | grep data-video | awk '!/dood|azipcdn|pelisplay/' | cut -d\" -f2 | grep https) ;;
    esac
    echo "${video_links[@]}"
}

next(){
    local video_links
    local title
    title=$(echo "$1" | cut -d '/' -f5 | tr -d '0-9' )
    next_episode=$(curl -s "$1" | grep "$title" | cut -d\" -f 2 | uniq -d )
    result_url=$next_episode
    titleG="$next_episode"
    links=$(get_video_links "$next_episode")
    [ -n "$links" ] || die "no hay enlaces disponible"
    replay "${links[@]}"
}

play(){
    local options=("Reproducir" "Siguiente" "Agregar a favoritos" "Descargar" "Volver al menú" "Salir")
    local choice
    while true ; do
        choice=$(printf '%s\n' "${options[@]}" | fzf )
        case "$choice" in
            'Reproducir') replay "$1" ;;
            'Siguiente') next "$result_url" ;;
            'Descargar') downloads "$1" ;;
            'Salir' ) break  ;;
        esac
    done
}

replay(){
    title=$(echo "$titleG" | cut -d '/' -f 5 | tr '-' ' ')
    for link in "${@}"; do
        if mpv --title="$title" "$link";
        then
            echo "bien"
            # history "$result_url"
        else
            break 2
        fi
    done
}

last_viewed(){
    local links
    if [ -f "$state_file" ];
    then
        result_url=$(cat "$state_file")
        links=$(get_video_links "$result_url")
        [ -n "$links" ] || die "no hay enlaces disponible"
        replay "${links[@]}"
    else
        die "no hay ultima vez"
    fi
}

bookmarks(){
    local select_bookmarks
    case "$1" in
        'save') if ! pgrep -Fxq "$2" "$bookmarks";
            then
                echo "$2" >> "$bookmarks"
            fi ;;
        'show') if [ -f "$bookmarks" ];
            then
                select_bookmarks=$(fzf < "$bookmarks" )
                result_url=$select_bookmarks
                links=$(get_video_links "$result_url")
                [ -n "$links" ] || die "no hay enlaces disponible"
                replay "${links[@]}"
            else
                die "No hay favoritos"
            fi
    esac
}

history(){
    local select_history
    case "$1" in
        'save') if ! grep -Fxq "$2" "$history";
            then
                echo "$2" >> "$history"
            fi ;;
        'show') if [ -f "$history" ];
            then
                select_history=$( fzf < "$history" )
                result_url=$select_history
                links=$(get_video_links "$result_url")
                [ -n "$links" ] || die "no hay enlaces disponible"
                replay "${links[@]}"

            fi ;;
    esac
}

main(){
    local query
    local lists
    local choice
    local title
    printf "\33[2K\r\033[1;36mBuscar: \033[0m" && read -r query
    query=$(printf "%s" "$query" | sed "s| |+|g")
    lists=$(search_globar "$query")
    [ -n "$lists" ] || die "No hay resultados"
    choice=$(printf "%s" "$lists" | fzf )
    get_url=$(get_links "$choice")
    title=$(echo "$get_url" | cut -d '/' -f5 | tr '-' ' ')
    result_url=$(get_episode "$get_url")
    [ -n "$result_url" ] || die "No hay episodios"
    links=$(get_video_links "$result_url")
    [ -n "$links" ] || die "No hay enlaces disponibles"
    export titleG="$result_url"
    play "${links[@]}"
}

menu() {
    local options=("Buscar" "Ultimo visto" "Historial" "Favoritos")
    local choice

    choice=$(printf '%s\n' "${options[@]}" | fzf)
    while true; do
        case "$choice" in
            "Buscar") main ;;
            "Ultimo visto") last_viewed ;;
            "Historial") history show ;;
            "Favoritos") bookmarks show ;;
            "Salir") break ;;
            *) die "Opción inválida. Inténtalo nuevamente." ;;
        esac
    done
}
menu
