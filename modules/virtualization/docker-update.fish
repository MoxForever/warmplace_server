complete -c docker-update -f -d "Update and restart a Docker deployment"
complete -c docker-update -a "(__fish_docker_update_apps)" -d "App name"

function __fish_docker_update_apps --description "List available docker-deploy app names"
    systemctl list-unit-files --no-pager 2>/dev/null | grep 'docker-deploy-' | awk -F'docker-deploy-' '{print $2}' | awk -F'.service' '{print $1}' | sort -u
end
