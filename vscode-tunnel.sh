#!/bin/sh
set -e

# Use tunnel name arg or hostname as default
TUNNEL_NAME=${VSCODE_TUNNEL_NAME:-$HOSTNAME}

if [ $# -eq 0 ]; then
    echo "Logging in..."

    # If $VSCODE_ACCESS_TOKEN is specified, use it to log in
    if [ -n "$VSCODE_TUNNEL_ACCESS_TOKEN" ]; then
        echo "Using provided access token for $VSCODE_TUNNEL_AUTH..."
        code tunnel user login --provider $VSCODE_TUNNEL_AUTH --access-token $VSCODE_TUNNEL_ACCESS_TOKEN
    else
        code tunnel user login --provider $VSCODE_TUNNEL_AUTH
    fi

    # Dynamically build the command for args provided
    command="code tunnel --accept-server-license-terms --name $TUNNEL_NAME"
    if [ -n "$VSCODE_EXTENSIONS" ]; then
        # Split the extensions by comma and add them to the command
        OLDIFS=$IFS
        IFS=','
        set -- $VSCODE_EXTENSIONS
        IFS=$OLDIFS
        for extension do
            command="$command --install-extension $extension"
        done
    fi

    echo "Starting tunnel server..."
    eval "$command &"
    PID=$!
    trap "kill $PID" INT TERM
    wait $PID
    echo "Unregistering tunnel..."
    code tunnel unregister
else
    exec "$@"
fi
