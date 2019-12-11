# README

```bash
curl https://raw.githubusercontent.com/chgeuer/azure_openhack_devops_utils_chgeuer/master/ \
    blue-green-watch.sh -o ./blue-green-watch.sh && \
    chmod +x ./blue-green-watch.sh && \
    watch -n 1 ./blue-green-watch.sh
```

- Deployment pipeline needs variable `helmReleaseName` having values like `api-poi`

## Docs

- [REST API Variablegroups - Update](https://docs.microsoft.com/en-us/rest/api/azure/devops/distributedtask/variablegroups/update?view=azure-devops-rest-5.1)
