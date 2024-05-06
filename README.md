# Visual Studio Code Tunnel Server

This Docker image will create an instance of Visual Studio Code Server with the [Remote Tunnel extension](https://code.visualstudio.com/docs/remote/tunnels) configured. You can then access it via a web browser.

This was created to enable quick access to demo (_non-production!_) environments where you may not be able to access the environment from the public internet (e.g., behind an Azure virtual network).

> ![CAUTION]
> Do not install this in a production environment. The security of this configuraiton has not been validated.

## Configuration

Review the [Dockerfile](Dockerfile) for all parameters. No parameters are required as default values are configured where needed.

| Parameter | Default | Description |
| --- | --- | --- |
| `VSCODE_TUNNEL_AUTH` | `microsoft` | Remote Tunnels can authenticate with Microsoft or GitHub credentials. You can enter `microsoft` or `github` here. |
| `VSCODE_TUNNEL_NAME` | `hostname` | The name of the remote tunnel. Defaults to the container's hostname. |
| `VSCODE_EXTENSIONS` | none | Comma-separated extension IDs to be installed by default. You can still manually install extensions. E.g.: `humao.rest-client,GitHub.copilot-chat` |

## Running the Tunnel Server

### Docker

Here's an example of using `docker run` to launch the container on a host:

```bash
docker run --rm --name mytunnel \
  -e VSCODE_TUNNEL_AUTH=github \
  -e VSCODE_TUNNEL_NAME=mytunnel \
  -e VSCODE_EXTENSIONS=humao.rest-client,GitHub.copilot-chat myreg.azurecr.io/vscodetunnel:latest
```

This example will launch the container using GitHub authentication with the name `mytunnel` and it will install the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) and [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=github.copilot-chat) extensions.

### Azure Container Instances

An easy way to launch this in an Azure network is using [Azure Container Instances](https://learn.microsoft.com/en-us/azure/container-instances/), using the Azure CLI command `az container create`:

```bash
# Ensure you are logged in with:
# az login

# Some parameters
RG=my-resource-group # Existing resource group
LOC=westus3
IMAGE=myreg.azurecr.io/vscodetunnel:latest
CONTAINER_NAME=acr-tunnel1
REG_USER="anonymous" # prevents auth prompt
REG_PASS="."
VNET=vnet-name # optional - for VNet integration
SUBNET=subnet-name # optional/required with VNet - will be delegated to ACI
VSCODE_TUNNEL_NAME=mytunnel
VSCODE_TUNNEL_AUTH=microsoft
VSCODE_EXTENSIONS=humao.rest-client,GitHub.copilot-chat

# Create the container instance
az container create -g $RG --name "$CONTAINER_NAME" -l $LOC \
  --image $IMAGE \
  --vnet "$VNET" --subnet "$SUBNET" \
  --registry-username "$REG_USER" --registry-password "$REG_PASS" \
  --environment-variables VSCODE_TUNNEL_NAME=$VSCODE_TUNNEL_NAME VSCODE_TUNNEL_AUTH=$VSCODE_TUNNEL_AUTH VSCODE_EXTENSIONS=$VSCODE_EXTENSIONS

# Get logs to see login code and/or URL
az container logs -g $RG --name "$CONTAINER_NAME"

# Cleanup - delete the container instance
az container delete -g $RG --name "$CONTAINER_NAME" --yes
```

#### Mounting a Git Repository

One handy feature of Azure Container Instances is the ability to automatically clone a git repository to the machine.  You can specify additional args:

- `--gitrepo-url` The git repository URL
- `--gitrepo-mount-path` The container path where the git repo should be mounted. Recommended to use the `/workspace` directory.
- `--gitrepo-dir` The target directory path in the git repository. Optional - defaults to `.`

## Accessing the Tunnel

Once the container is running, view the container logs. There you will see the device login URL for Microsoft or GitHub, along with a device code. Follow the instructions in your local web browser to authenticate the tunnel.

Once the authenticaiton is completed, view the container logs again. You will see `Open this link in your browser` followed by a URL to access the server. Open that URL in your local web browser. You will need to use the same authentication as the previous step.
