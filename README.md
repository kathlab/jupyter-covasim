# Jupyter Notebook with Covasim

This docker project creates a container with Jupyter Notebook and Covasim. __The web gui of Covasim currently does not work!__

Docker requirements:
---

Add buildkit to: /etc/docker/daemon.json
---
```
{
  "features": {
    "buildkit" : true
  }
}
```

Build Docker image
---

```
$ docker build -f Dockerfile -t local/jupytercovasim:latest .
```

Deploy container:
---

```
$ docker compose -d -f docker-compose.yaml up
```

Re-run container:
---

```
$ docker start jupytercovasim
```

Get local URL to Juypter Notebook
---

```
$ docker logs jupytercovasim
then copy URL from logs output
```