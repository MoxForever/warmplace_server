complete -c docker-update -f -d "Update and restart a Docker deployment"
complete -c docker-update -n "__fish_use_subcommand_from_list" -a "(__fish_docker_update_apps)" -d "App name"

function __fish_docker_update_apps --description "List available docker-deploy app names"
    systemctl list-unit-files --no-pager 2>/dev/null | grep -oP '(?<=docker-deploy-)\w+(?=\.service)' | sort -u
end
