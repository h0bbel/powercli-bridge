# powercli-bridge

HTTPS is now default, with a self signed cert.

## Description

Currently this connects to a vCenter, configures DRS/HA/vCLS for shutdown.

Cycles through running VMs and shuts them down or alternately powers them off (hard)

Then hosts that are not running the vCenter VM are put into Maintenance Mode, before it finally directly connects to the host running vCenter and places it in Maintenance Mode while shutting down vCenter.

The ESXi host running vCenter is stored in a state file so that it can be picked up again by a future startup action.

## Example Usage

``` shell
curl --location 'https://localhost:8085/api/v1/ups/shutdown' \
--header 'X-API-KEY: 123456'
```

### Environment Variables Required

#### vSphere Related

| ENV Variable      | Description                                                                |
| ----------------- | -------------------------------------------------------------------------- |
| vCenterVMName     | vCenter VM name - used to exclude the vCenter VM in the shutdown procedure |
| vCenterServerFQDN | vCenter FQDN name, used for the PowerCLI connection                        |
| vCenterUsername   | vCenter username, ex. <administrator@vsphere.local>                        |
| vCenterPassword   | vCenter password                                                           |

#### PODE / REST API Related

| ENV Variable    | Description |
| --------------- | ----------- |
| X_PODE_API_KEY | API Key     |

`X_PODE_API_KEY ` is any key you want to use. Can for instance be generated with [API Key Generator](https://www.akto.io/tools/api-key-generator)

## #Flowchart

```mermaid
flowchart TD
style E fill:#F3522F,stroke:#333,stroke-width:2px

    A[Start] --> B(Connect to vCenter);
    B --> C{Check Environment};
    C --> D[vSAN] --> E[TODO];
    C --> F[No vSAN] --> G[DRS Level];
    G --> H[HA Status];
    H --> I[vCLS Retreat Mode];
    I --> J[Shut down powered on VMs];
    J --> K[Shutdown];
    J --> L[Force];
    K --> M[Shut Down VM second pass];
    L --> M[Shut Down VM second pass];
    M --> O[Force Remaining VMs];
    O --> P[Check vCenter VM Host];
    P --> Q[Hosts Maintenance Mode];
    Q --> R[Connect vCenter Host];
    R --> S[vCenter Host Maintenance Mode];
    S --> T[Shut down vCenter VM];
    T --> U[vCenter Host Maintenance Mode];
    U --> V[Completed];
