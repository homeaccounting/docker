Teamcity build agent
========================

This is a teamcity build agent docker image, it uses docker in docker from https://github.com/jpetazzo/dind to allow you to start docker images inside of it :)
When starting the image as container you must set the TEAMCITY_SERVER environment variable to point to the teamcity server e.g. and optional AGENT_NAME variable.
```
docker run -e TEAMCITY_SERVER=http://localhost:8111 -e AGENT_NAME='Agent 1'
```

Optionally you can specify your ownaddress using the `TEAMCITY_OWN_ADDRESS` variable.

Linking example
--------
```
docker run -d --name=teamcity-agent-1 --link teamcity:teamcity --privileged -e TEAMCITY_SERVER=http://teamcity:8111 homeaccounting/teamcity-agent:latest
```

## What is inside

- node 6.2.0, npm 3.7.1
- docker 1.11, docker-compose 1.7.1
- openjdk 8


