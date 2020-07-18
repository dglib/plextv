# Plex Media Server w/ MACVLAN
Running a Plex Media Server on OpenShift 4.x

### Build your image
You can build your own image using my Dockerfile as a reference, or just pull the image I created as shaker242/plex:latest. \
`podman build -t ORG/REPO:TAG .`

Notes:
1.  There is a section in the deployment for a 'claim' number... it only lasts 4 mins, I recommend deploying the environment without it to make sure everything is running. Once you have verified the plex pod is running to your liking, obtain your code from https://plex.tv/claim, put it in the deployment and just `oc apply -f plex-deployment.yaml`.
2. You can find your timezone here: https://en.wikipedia.org/wiki/List_of_tz_mediabase_time_zones 
3. You can find the latest version of the Plex Media Server here: https://www.plex.tv/media-server-downloads 

Q. Why MACVLAN? \
A. To improve quality by accessing the Plex Media Server directly, ie put the Pod on the same physical network as the device/s accessing plex. \

Q. Will remote access still work? \
A. Yes. However, at this point I am only getting "Indirect" remote access to work. This means it is being proxied through Plex Web.

---
## Install Plex Media Server / MACVLAN Style

Install the macvlan addition network. \
`oc edit networks.operator.openshift.io cluster`

```
 additionalNetworks:
  - name: macvlan-net
    namespace: default
    rawCNIConfig: '{ "cniVersion": "0.3.1", "name": "home.land", "type": "macvlan",
      "master": "ens224", "mode": "bridge", "ipam": { "type": "dhcp" } }'
    type: Raw
```
Verify the new network exists in the default namespace. \
`oc get network-attachment-definitions -n default` 

Verify the settings. \
`oc describe network-attachment-definitions macvlan-net -n default`

Create the Plex namespace. \
`oc create ns plex`

Test Pod attachment. \
`oc -n plex create -f test-pod.yaml`

Verify net1 attached to macvlan. \
`oc -n plex exec test-pod -- ip addr show | grep net1`

```
4: net1@if109: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    inet 192.168.11.27/24 brd 192.168.11.255 scope global net1
```

Use the same RBAC in the main directory. \
`oc -n plex create -f ../plex-rbac.yaml`

Create the Deploymnet. \
`oc -n plex create -f plex-deployment.yaml`

Expose port 32400 of the Pod for remote access. \
`oc -n plex create -f plex-service.yaml`

Create the Route for remote access. \
`oc -n plex create -f plex-route.yaml`

---
To Do:
1. Detail setting up VMware vSwitch/Port-Groups
2. Detail setting up pfsense 1:1 NAT
3. Detail setting up MACVLAN
4. Consider/Test using a static IP vs DHCP
5. Consider removing eth0 from the pod to prevent dual IP assignments, eth0=OpenShift SDN & net1=MACVLAN
6. Pending the above, should I create a local service and route to access the pod for configuration?

Notes:
1. In this configuration I have set each of 3 lab nodes to use MACVLAN. If you choose to isolate MACVLAN to a specific node(s), use node lables on your deployment.


---
## If you'd like to try this as a 'single' pod.

Modify and copy static-pod.yaml into one of your host/worker node systems under /etc/kubernetes