# image-common
Common packages and configuration files for Nimbix base images. This will
retrofit existing Docker images for better execution on JARVICE.

If you have an image derived from a non-Nimbix base, and you want to improve
its execution on JARVICE, there is now a simple way to do this in your
Dockerfile without having to change your FROM line.  Currently, we only
support CentOS and Ubuntu with this trick.
Verified distributions:
Verified distributions:
* CentOS 6 (x86_64)
* CentOS 7 (x86_64, ppc64le)
* Ubuntu 14.04 Trusty (amd64)
* Ubuntu 16.04 Xenial (amd64, ppc64le)

Just add this to the end of your Dockerfile:

# Ubuntu
```bash
RUN apt-get -y update && \
    apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22
```

# Ubuntu (with Nimbix desktop)
```bash
RUN apt-get -y update && \
    apt-get -y install curl && \
    curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash -s -- --setup-nimbix-desktop

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22

# for standalone use
EXPOSE 5901
EXPOSE 443
```

# CentOS
```bash
RUN curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22
```

# CentOS (with Nimbix desktop)
```bash
RUN curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh \
        | bash -s -- --setup-nimbix-desktop

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22

# for standalone use
EXPOSE 5901
EXPOSE 443
```

This does several things:
 1. installs recommended packages for running on JARVICE
 2. makes sure SSH actually starts (important when using `nvidia/` base images for example)
 3. sets up the nimbix user, and gives it passwordless sudo access
 4. configures JARVICE "emulation" for local testing (see our PushToCompute tutorial for more on that)
 5. preserves the Docker environment variables and makes sure they are set when you run in JARVICE as well

# Docker build caching of **install-nimbix.sh** layer

While developing an app and subsequently running multiple docker builds, it
can be easy to be thrown off by the caching of successfully built layers.
Docker will not be able to pick up changes to **install-nimbix.sh** in the
**image-common** git repository.  Thus, if the layer's **RUN** instruction has
not changed, it may not be rebuilt if it has previously executed successfully.

Using an easily updatable **ENV** instruction is a simple way to invalidate
a layer and force it to be rebuilt.  Simply add an instruction like this
before your **RUN** of **install-nimbix.sh** or any other layers
you wish to easily invalidate by changing the **SERIAL_NUMBER**:
```bash
# Update SERIAL_NUMBER to force rebuild of subsequent layers
#   (i.e. don't use cached layers)
ENV SERIAL_NUMBER 20171009.1713
```

Allow more control by using **--build-arg** with a local **docker build**
command line:
```bash
# Update SERIAL_NUMBER to force rebuild of subsequent layers
#   (i.e. don't use cached layers)
ARG SERIAL_NUMBER
ENV SERIAL_NUMBER ${SERIAL_NUMBER:-20171009.1713}
```

