# image-common
Common packages and configuration files for Nimbix base images. This will
retrofit existing Docker images for better execution on JARVICE.

If you have an image derived from a non-Nimbix base, and you want to improve
its execution on JARVICE, there is now a simple way to do this in your
Dockerfile without having to change your FROM line.  Currently, we only
support CentOS and Ubuntu "trusty" with this trick (we will soon add xenial).
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

