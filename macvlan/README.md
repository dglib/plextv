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

Q. What is not covered in this README? \
A. Setting up your networking, I have to leave that mostly to you; however, I have included some notes at the end that may help.

---
## The MACVLAN Setup

1. Install the macvlan addition network. \
`oc edit networks.operator.openshift.io cluster`

> This configuration is used to set a static IP of 192.168.11.200 for the plex-pod, assigned to a separate interface (ens224) and not the default (ens192) used for the nodes / vxlan themselves.

```
  additionalNetworks:
  - name: macvlan-plex
    namespace: default
    rawCNIConfig: '{ "cniVersion": "0.3.1", "name": "plex", "master": "ens224", "type":
      "macvlan", "ipam": { "type": "static", "addresses": [ { "address": "192.168.11.200/24",
      "gateway": "192.168.11.1" } ] } }'
    type: Raw
```
2. Verify the new network exists in the default namespace. \
`oc get network-attachment-definitions -n default` 

3. Verify the settings. \
`oc describe network-attachment-definitions macvlan-plex -n default`

4. Create the Plex namespace. \
`oc create ns plex`

5. Use the same RBAC in the main directory. \
`oc -n plex create -f ../plex-rbac.yaml`

6. Apply RBAC to the SA. \
`oc adm policy add-scc-to-user anyuid -z plex-sa -n plex`

7. Test Pod attachment. \
`oc -n plex create -f test-pod.yaml`

8. Verify net1 attached to macvlan. \
`oc -n plex exec test-pod -- ip addr show | grep net1`

```
4: net1@if109: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    inet 192.168.11.27/24 brd 192.168.11.255 scope global net1
```
- ping 192.168.11.200

9. With a successful ping, remove the test pod to prevent an IP conflict. \
`oc -n plex delete -f test-pod.yaml`

10. Create the Deploymnet. \
`oc -n plex create -f plex-deployment.yaml`

>Optional: Create an nfs share for your /media and /config \
`oc -n plex create -f plex-nfs`

*Since you are using MACVLAN, Services and Routes are not required.*

11. Access your plex server for management: 192.168.11.200:32400/manage


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
2. Once everything checks out, you may have to load a new claim key and reapply the deployment. \
`oc apply -f plex-deployment.yaml`
3. Keeping your /media directory on NFS allows one way to remote mount and upload content.
4. I have removed /transcode since I mostly use plex locallying; thus transcoding isn't used, to improve perfomanace consider /transcode (ing) in memory. See plex-deployment.yaml for an example.
5. Each node in my cluster has a second interface (ens224) assigned to it, since DHCP is on this network, I remoted into to each node and reset the secondary interface to non-used IP assignments.
    ```
    Example:
    a. ssh core@worker-0
    b. nmcli connection show
    c. sudo nmcli connection mod 'Wired connection 2' ipv4.method manual ipv4.addresses 10.10.10.10/29 connection.autoconnect yes
    d. ifconfig ens224 10.10.10.10/29 
    e. sudo systemctl restart NetworkManager
    ```