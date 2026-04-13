# GitHub MCP Server on OpenShift

This bundle contains:

- `chart/`: a Helm chart for OpenShift
- `Dockerfile.ocp`: a build recipe for a custom image that combines:
  - the official GitHub MCP Server binary
  - Supergateway, which exposes the stdio-only MCP server over HTTP
- `scripts/entrypoint.sh`: container entrypoint used by the image

## Why a wrapper image is needed

GitHub currently documents the local GitHub MCP Server as a local/containerized server and shows the local binary being run as `github-mcp-server stdio`. The same repository also has an issue showing that the stock Docker image exits immediately in Kubernetes because it does not run as a persistent daemon.

Supergateway is designed to expose stdio-based MCP servers over SSE, WebSocket, or Streamable HTTP, which makes it a practical bridge for OpenShift.

## Recommended deployment model

Use this chart with the included custom image:
- `github-mcp-server` runs as a child process over stdio
- `supergateway` exposes it on `/mcp`
- OpenShift Route exposes the service externally

## Build the image

```bash
cd github-mcp-server-openshift-chart

podman build -f Dockerfile.ocp   -t quay.io/YOUR_ORG/github-mcp-server-supergateway:0.32.0 .
podman push quay.io/YOUR_ORG/github-mcp-server-supergateway:0.32.0
```

## Install the chart

```bash
helm upgrade --install github-mcp ./chart   --namespace mcp   --create-namespace   --set image.repository=quay.io/YOUR_ORG/github-mcp-server-supergateway   --set image.tag=0.32.0   --set github.personalAccessToken=YOUR_GITHUB_PAT
```

For better secret hygiene, create a secret separately and reference it:

```bash
oc create secret generic github-mcp-token   --from-literal=GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_GITHUB_PAT   -n mcp

helm upgrade --install github-mcp ./chart   --namespace mcp   --create-namespace   --set image.repository=quay.io/YOUR_ORG/github-mcp-server-supergateway   --set image.tag=0.32.0   --set github.existingSecret=github-mcp-token
```

## Example values override

```yaml
image:
  repository: quay.io/acme/github-mcp-server-supergateway
  tag: "0.32.0"

github:
  existingSecret: github-mcp-token
  readOnly: true
  toolsets: "repos,issues,pull_requests,actions"

route:
  enabled: true
  path: /mcp

supergateway:
  stateful: true
  streamableHttpPath: /mcp
```

## Client URL

Once deployed:

```bash
oc get route github-mcp-github-mcp-server
```

Your MCP endpoint will typically be:

```text
https://<route-host>/mcp
```

## Notes

- Read-only mode is enabled by default.
- For GitHub Enterprise Server or data-residency GitHub Enterprise Cloud, set `github.host`.
- The chart supports `GITHUB_TOOLSETS`, `GITHUB_TOOLS`, `GITHUB_DYNAMIC_TOOLSETS`, `GITHUB_READ_ONLY`, and the server name/title overrides through values.
