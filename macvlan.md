
create the namespace "plex" \
`oc create ns plex`

edit the cno to add "additionalNetworks" \
`oc edit networks.operator.openshift.io cluster`

```
  additionalNetworks:
  - name: homeland
    namespace: plex
    simpleMacvlanConfig:
      ipamConfig:
        type: static
        staticIPAMConfig:
          addresses:
          - address: 192.168.11.11/24
            gateway: 192.168.11.1
          routes:
          - destination: 0.0.0.0/0
            gateway: 192.168.11.1
          dns:
            nameservers:
            - 192.168.11.1
            domain: home.land
            search:
            - home.land
            - redcloud.land
    type: SimpleMacvlan
```

verify it is attached to the namespace "plex" \
`oc get network-attachment-definitions -n plex`

full example :
```
ipamConfig:
  type: static
  staticIPAMConfig:
    addresses:
    - address: 192.168.11.11/24
      gateway: 192.168.11.1
    routes:
    - destination: 0.0.0.0/0
      gateway: 192.168.11.1
    dns:
      nameservers:
      - 192.168.11.1
      domain: home.land
      search:
      - home.land
      - redcloud.land
```