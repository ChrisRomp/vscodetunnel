# Visual Studio Code Tunnel Server

This Docker image will create an instance of Visual Studio Code Server with the [Remote Tunnel extension](https://code.visualstudio.com/docs/remote/tunnels) configured. You can then access it via a web browser.

This was created to enable quick access to demo (_non-production!_) environments where you may not be able to access the environment from the public internet (e.g., behind an Azure virtual network).

> [!CAUTION]
> Do not install this in a production environment. The security of this configuration has not been validated.

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
docker run --name mytunnel \
  -e VSCODE_TUNNEL_AUTH=github \
  -e VSCODE_TUNNEL_NAME=mytunnel \
  -e VSCODE_EXTENSIONS=humao.rest-client,GitHub.copilot-chat \
  ghcr.io/chrisromp/vscodetunnel:latest
```

You can add the `--detach` argument to have the container run in the background. See the full `docker run` command syntax in the [documentation](https://docs.docker.com/reference/cli/docker/container/run/#options).

This example will launch the container using GitHub authentication with the name `mytunnel` and it will install the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) and [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=github.copilot-chat) extensions.

### Azure Container Instances

An easy way to launch this in an Azure network is using [Azure Container Instances](https://learn.microsoft.com/en-us/azure/container-instances/), using the Azure CLI command `az container create`:

```bash
# Ensure you are logged in with:
# az login

# Some parameters
RG=my-resource-group # Existing resource group
LOC=westus3
IMAGE=ghcr.io/chrisromp/vscodetunnel:latest
CONTAINER_NAME=acr-tunnel1
VNET=vnet-name # optional - for VNet integration
SUBNET=subnet-name # optional/required with VNet - will be delegated to ACI
VSCODE_TUNNEL_NAME=$CONTAINER_NAME # reuse container name or change
VSCODE_TUNNEL_AUTH=microsoft
VSCODE_EXTENSIONS=humao.rest-client,GitHub.copilot-chat

# Create the container instance
az container create -g $RG --name "$CONTAINER_NAME" -l $LOC \
  --image $IMAGE \
  --vnet "$VNET" --subnet "$SUBNET" \
  --environment-variables VSCODE_TUNNEL_NAME=$VSCODE_TUNNEL_NAME VSCODE_TUNNEL_AUTH=$VSCODE_TUNNEL_AUTH VSCODE_EXTENSIONS=$VSCODE_EXTENSIONS

# Get logs to see login code and/or URL
az container logs -g $RG --name "$CONTAINER_NAME"

# Cleanup - delete the container instance
az container delete -g $RG --name "$CONTAINER_NAME" --yes
```

#### Virtual Network Integration

Azure Container Instances can bind the container to a private virtual network to enable accessing private network resources for testing. You can provide it a virtual network name and a subnet name, or a subnet resource ID. See the full command syntax in the [documentation](https://learn.microsoft.com/en-us/cli/azure/container?view=azure-cli-latest#az-container-create).

> [!NOTE]
> This will require delegation of the subnet to the `Microsoft.ContainerInstance/containerGroups` service. You may want to create an additional subnet in your virtual network for this. The CLI command enables passing of parameters to create the subnet, e.g., `--subnet-address-prefix`.

> [!NOTE]
> Outbound virtual network rules may restrict access to dev tunnels resources. See the [Dev Tunnels documentation](https://learn.microsoft.com/en-us/azure/developer/dev-tunnels/security#domains) for a list of outbound hosts required.

#### Mounting a Git Repository

One handy feature of Azure Container Instances is the ability to automatically clone a git repository to the machine.  You can specify additional args:

- `--gitrepo-url` The git repository URL
- `--gitrepo-mount-path` The container path where the git repo should be mounted. Recommended to use the `/workspace` directory.
- `--gitrepo-dir` The target directory path in the git repository. Optional - defaults to `.`

## Accessing the Tunnel

Once the container is running, view the container logs. There you will see the device login URL for Microsoft or GitHub, along with a device code. Follow the instructions in your local web browser to authenticate the tunnel.

Once the authentication is completed, view the container logs again. You will see `Open this link in your browser` followed by a URL to access the server. Open that URL in your local web browser. You will need to use the same authentication as the previous step.

## Disclaimer

This package is provided for testing and demonstration purposes only. No support is provided (but please feel free to open an issue if you find a bug).

Please see the [MIT LICENSE](LICENSE) for full text and terms.
