complete -c docker-update -f -d "Update and restart a Docker deployment"
complete -c docker-update -n "__fish_seen_subcommand_from_list" -a "(__fish_docker_update_apps)" -d "App name"

function __fish_docker_update_apps
    systemctl list-unit-files 2>/dev/null | string match 'docker-deploy-*' | string replace 'docker-deploy-' '' | string replace '.service' ''
end
