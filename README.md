# WORK IN PROGRESS

# docker-machine-driver-outscale

Outscale Driver Plugin for docker-machine.

# Requierements

`docker-machine` is required, see [machine-drivers/machine](https://github.com/machine-drivers/machine).

# Installing pre-built binaries

Install the latest release for your environment from the [releases list](https://github.com/outscale-dev/docker-machine-driver-outscale/releases).

# Installing from source

To compile the `docker-machine-driver-outscale` driver:

```bash
git clone https://github.com/outscale-dev/docker-machine-driver-outscale.git
cd docker-machine-driver-outscale
make install
```

## Run

You will need your [Access Key and Secret Key](https://wiki.outscale.net/display/EN/About+Access+Keys).

```bash
docker-machine create --driver outscale --outscale-access-key XXX --amazonec2-secret-key YYY --outscale-region eu-west-1 vm01
```

### Options

| Argument | Env | Default | Description
| --- | --- | --- | ---
| `outscale-token` | `OUTSCALE_TOKEN` | None | **required** Outscale APIv4 Token (see [here](https://developers.outscale.com/api/v4#section/Personal-Access-Token))
| `outscale-root-pass` | `OUTSCALE_ROOT_PASSWORD` | *generated* | The Outscale Instance `root_pass` (password assigned to the `root` account)
| `outscale-authorized-users` | `OUTSCALE_AUTHORIZED_USERS` | None | Outscale user accounts (separated by commas) whose Outscale SSH keys will be permitted root access to the created node
| `outscale-label` | `OUTSCALE_LABEL` | *generated* | The Outscale Instance `label`, unless overridden this will match the docker-machine name.  This `label` must be unique on the account.
| `outscale-region` | `OUTSCALE_REGION` | `us-east` | The Outscale Instance `region` (see [here](https://api.outscale.com/v4/regions))
| `outscale-instance-type` | `OUTSCALE_INSTANCE_TYPE` | `g6-standard-4` | The Outscale Instance `type` (see [here](https://api.outscale.com/v4/outscale/types))
| `outscale-image` | `OUTSCALE_IMAGE` | `outscale/ubuntu18.04` | The Outscale Instance `image` which provides the Linux distribution (see [here](https://api.outscale.com/v4/images)).
| `outscale-ssh-port` | `OUTSCALE_SSH_PORT` | `22` | The port that SSH is running on, needed for Docker Machine to provision the Outscale.
| `outscale-ssh-user` | `OUTSCALE_SSH_USER` | `root` | The user as which docker-machine should log in to the Outscale instance to install Docker.  This user must have passwordless sudo.
| `outscale-docker-port` | `OUTSCALE_DOCKER_PORT` | `2376` | The TCP port of the Outscale that Docker will be listening on
| `outscale-swap-size` | `OUTSCALE_SWAP_SIZE` | `512` | The amount of swap space provisioned on the Outscale Instance
| `outscale-stackscript` | `OUTSCALE_STACKSCRIPT` | None | Specifies the Outscale StackScript to use to create the instance, either by numeric ID, or using the form *username*/*label*.
| `outscale-stackscript-data` | `OUTSCALE_STACKSCRIPT_DATA` | None | A JSON string specifying data that is passed (via UDF) to the selected StackScript.
| `outscale-create-private-ip` | `OUTSCALE_CREATE_PRIVATE_IP` | None | A flag specifying to create private IP for the Outscale instance.
| `outscale-tags` | `OUTSCALE_TAGS` | None | A comma separated list of tags to apply to the Outscale resource
| `outscale-ua-prefix` | `OUTSCALE_UA_PREFIX` | None | Prefix the User-Agent in Outscale API calls with some 'product/version'

## Notes

* When using the `outscale/containerlinux` `outscale-image`, the `outscale-ssh-user` will default to `core`
* A `outscale-root-pass` will be generated if not provided.  This password will not be shown. Rely on `docker-machine ssh`, `outscale-authorized-users`, or [Outscale's Rescue features](https://www.outscale.com/docs/quick-answers/outscale-platform/reset-the-root-password-on-your-outscale/) to access the node directly.

### Docker Volume Driver

The [Docker Volume plugin for Outscale Block Storage](https://github.com/outscale/docker-volume-outscale) can be installed while reusing the docker-machine properties:

```sh
MACHINE=my-docker-machine

docker-machine create -d outscale $MACHINE

eval $(docker-machine env $MACHINE)

# Region and Label are not needed. They would be inferred.  Included here for illustration purposes.
docker plugin install --alias outscale outscale/docker-volume-outscale:latest \
  outscale-token=$(docker-machine inspect $MACHINE -f "{{ .Driver.APIToken }}") \
  outscale-region=$(docker-machine inspect $MACHINE -f "{{ .Driver.Region }}") \
  outscale-label=$(docker-machine inspect $MACHINE -f "{{ .Driver.InstanceLabel }}")

docker run -it --rm --mount volume-driver=outscale,source=test-vol,destination=/test,volume-opt=size=25 alpine

docker volume rm test-vol
```

## Debugging

Detailed run output will be emitted when using the OutscaleGo `OUTSCALE_DEBUG=1` option along with the `docker-machine` `--debug` option.

```bash
OUTSCALE_DEBUG=1 docker-machine --debug  create -d outscale --outscale-token=$OUTSCALE_TOKEN machinename
```

## Examples

### Simple Example

```bash
OUTSCALE_TOKEN=e332cf8e1a78427f1368a5a0a67946ad1e7c8e28e332cf8e1a78427f1368a5a0 # Should be 65 lowercase hex chars

docker-machine create -d outscale --outscale-token=$OUTSCALE_TOKEN outscale
eval $(docker-machine env outscale)
docker run --rm -it debian bash
```

```bash
$ docker-machine ls
NAME      ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER        ERRORS
outscale    *        outscale   Running   tcp://45.79.139.196:2376           v18.05.0-ce

$ docker-machine rm outscale
About to remove outscale
WARNING: This action will delete both local reference and remote instance.
Are you sure? (y/n): y
(default) Removing outscale: 8753395
Successfully removed outscale
```

### Provisioning Docker Swarm

The following script serves as an example for creating a [Docker Swarm](https://docs.docker.com/engine/swarm/) with master and worker nodes using the Outscale Docker machine driver and private networking.

This script is provided for demonstrative use.  A production swarm environment would require hardening.

1. Create an `install.sh` bash script using the source below.  Run `bash install.sh` and provide a Outscale APIv4 Token when prompted.

    ```sh
    #!/bin/bash
    set -e

    read -p "Outscale Token: " OUTSCALE_TOKEN
    # OUTSCALE_TOKEN=...
    OUTSCALE_ROOT_PASSWORD=$(openssl rand -base64 32); echo Password for root: $OUTSCALE_ROOT_PASSWORD
    OUTSCALE_REGION=eu-central

    create_node() {
        local name=$1
        docker-machine create \
        -d outscale \
        --outscale-label=$name \
        --outscale-instance-type=g6-nanode-1 \
        --outscale-image=outscale/ubuntu18.04 \
        --outscale-region=$OUTSCALE_REGION \
        --outscale-token=$OUTSCALE_TOKEN \
        --outscale-root-pass=$OUTSCALE_ROOT_PASSWORD \
        --outscale-create-private-ip \
        $name
    }

    get_private_ip() {
        local name=$1
        docker-machine inspect  -f '{{.Driver.PrivateIPAddress}}' $name
    }

    init_swarm_master() {
        local name=$1
        local ip=$(get_private_ip $name)
        docker-machine ssh $name "docker swarm init --advertise-addr ${ip}"
    }

    init_swarm_worker() {
        local master_name=$1
        local worker_name=$2
        local master_addr=$(get_private_ip $master_name):2377
        local join_token=$(docker-machine ssh $master_name "docker swarm join-token worker -q")
        docker-machine ssh $worker_name "docker swarm join --token=${join_token} ${master_addr}"
    }

    # create master and worker node
    create_node swarm-master-01 & create_node swarm-worker-01

    # init swarm master
    init_swarm_master swarm-master-01

    # init swarm worker
    init_swarm_worker swarm-master-01 swarm-worker-01

    # install the docker-volume-outscale plugin on each node
    for NODE in swarm-master-01 swarm-worker-01; do
      eval $(docker-machine env $NODE)
      docker plugin install --alias outscale outscale/docker-volume-outscale:latest outscale-token=$OUTSCALE_TOKEN
    done
    ```

1. After provisioning succeeds, check the Docker Swarm status.  The output should show active an swarm leader and worker.

    ```sh
    $ eval $(docker-machine env master01)
    $ docker node ls

    ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
    f8x7zutegt2dn1imeiw56v9hc *   master01            Ready               Active              Leader              18.09.0
    ja8b3ut6uaivz5hf98gah469y     worker01            Ready               Active                                  18.09.0
    ```

1. [Create and scale Docker services](https://docs.docker.com/engine/reference/commandline/service_create/) (left as an excercise for the reader).

    ```bash
    $ docker service create --name my-service --replicas 3 nginx:alpine
    $ docker node ps master01 worker01
    ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
    7cggbrqfqopn         \_ my-service.1    nginx:alpine        master01            Running             Running 4 minutes ago
    7cggbrqfqopn         \_ my-service.1    nginx:alpine        master01            Running             Running 4 minutes ago
    v7c1ni5q43uu        my-service.2        nginx:alpine        worker01            Running             Running 4 minutes ago
    2w6d8o3hdyh4        my-service.3        nginx:alpine        worker01            Running             Running 4 minutes ago
    ```

1. Cleanup the resources

    ```sh
    docker-machine rm worker01 -y
    docker-machine rm master01 -y
    ```

## Discussion / Help

Feel free to contact us through Github issues.

## License

> Copyright 2015 TH
>
> Copyright 2014 Docker, Inc.
>
> Copyright 2021 Outscale SAS <support@outscale.com>

This project is compliant with [REUSE](https://reuse.software/).

Run `make reuse` to check that all files correctly referenced with the corresponding license.

This reprository has been created using [docker-machine-driver-linode](https://github.com/linode/docker-machine-driver-linode) and
[machine-drivers/machine](https://github.com/machine-drivers/machine) reprositories as a base reference.
