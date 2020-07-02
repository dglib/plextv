# Plex Media Server
Running a Plex Media Server on OpenShift 4.x

### Build your image
You can build your own image using my Dockerfile as a reference, you can find the latest version of the Plex Media Server here: \
https://www.plex.tv/media-server-downloads 

I prefer to build this with podman since it allow init/systemd: `podman build -t shaker242/plex .`

Note there is a section in the deployment for a 'claim' number... it only lasts 4 mins, I recommend deploying the environment without it to make sure everything is running. Once you have your code, put it in the deployment and just `oc apply -f plex-deployment.yaml`.