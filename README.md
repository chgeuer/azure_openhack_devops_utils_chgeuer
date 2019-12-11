# README

```bash
#!/bin/bash
repo="chgeuer/azure_openhack_devops_utils_chgeuer"
script="blue-green-watch.sh"
url="https://raw.githubusercontent.com/${repo}/master/${script}"
curl --silent "${url}" -o "./${script}" && \
    chmod +x "./${script}" && \
    watch -n 1 "./${script}"
```

- Deployment pipeline needs variable `helmReleaseName` having values like `api-poi`

## Docs

- [REST API Variablegroups - Update](https://docs.microsoft.com/en-us/rest/api/azure/devops/distributedtask/variablegroups/update?view=azure-devops-rest-5.1)
