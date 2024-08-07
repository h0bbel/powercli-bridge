# powercli-bridge

## Flowchart

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
    M --> O[Force];
    O --> P[Check vCenter VM Host];
    P --> Q[Hosts Maintenance Mode];
    Q --> R[Connect vCenter Host];
    R --> S[vCenter Host Maintenance Mode];
    S --> T[Shut down vCenter VM];
    T --> U[vCenter Host Maintenance Mode];
    U --> V[Completed];
    