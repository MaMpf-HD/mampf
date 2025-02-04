[private]
help:
    @just --list --justfile {{source_file()}}

# Downloads the latest database dump from the production server
download-db-dump:
    #!/usr/bin/env bash
    set -e

    # User input: proxy jump
    echo "To connect to the remote server you might need a proxy jump. Enter the host name (or leave empty):"
    read proxy_jump_destination
    proxy_jump_cmd="-J $proxy_jump_destination"

    # User input for remote server & dump folder
    echo "Enter the remote user and host in the format user@host "
    read remote_user_host
    echo "Enter the path to the folder that contains the database dumps on the remote server, e.g. /a/b/db"
    read remote_dump_folder

    # Latest file
    latest_file=$(ssh $proxy_jump_cmd "$remote_user_host" "ls -t $remote_dump_folder | head -n 1")
    if [ -z "$latest_file" ]; then
        echo "No files found in the remote folder."
        exit 1
    fi
    echo ""
    echo "Latest file found: $latest_file"

    # Download file
    echo "We will now download this file to the local machine into the folder db/backups/prod/"
    echo -n "Are you sure you want to continue? (y/n) "
    read confirmation
    if [ "$confirmation" != "y" ]; then
        echo "Operation cancelled."
        exit 1
    fi
    local_dir={{justfile_directory()}}/db/backups/prod/
    mkdir -p "$local_dir"
    scp -C $proxy_jump_cmd "$remote_user_host:$remote_dump_folder/$latest_file" "$local_dir"
