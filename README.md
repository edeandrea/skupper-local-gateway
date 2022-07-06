# What is this repo?

These instructions are for working with the [Quarkus Superheroes sample](https://github.com/quarkusio/quarkus-super-heroes). They allow you to use [Skupper](https://skupper.io) to proxy traffic of one of the individual services to your local laptop where you can run that service in [Quarkus Dev Mode](https://quarkus.io/guides/dev-mode-differences).

## Skupper Setup instructions

These instructions have only been tested on macOS Monterey on a Macbook M1Pro. You need to follow this for each & every namespace you want to proxy. The bundle that skupper generates is specific to a Kubernetes namespace.

Before beginning, make sure your application is already deployed into Kubernetes/OpenShift.

1. Create a `laptop.yaml` file, or use [`laptop-rest-villains.yaml`](laptop-rest-villains.yaml) or [`laptop-rest-fights.yaml`](laptop-rest-fights.yaml)

    > **IMPORTANT:** If using `laptop-rest-fights.yaml`, in `/etc/hosts`, add entry for `fights-kafka` -> `localhost`

2. In a terminal, execute `./generateBundle.sh <my_project> <laptop_file_name>`
    - Make sure to replace
        - `<my_project>` with the name of your Kubernetes namespace/OpenShift project
        - `<laptop_file_name>` with the name of the laptop yaml file without the `.yaml` extension (i.e. `laptop-rest-fights`)
4. Patch `bundle/<laptop_file_name>/launch.sh` by replacing the entire last `elif [ "$type" == "docker" ] || [ "$type" == "podman" ]; then` block with contents from [`launch.sh`](launch.sh)
5. Execute `cd bundle/<laptop_file_name>`
6. Execute `./launch.sh -t docker`
7. Open a new terminal window to the root directory of this project & start the proxying by launching the appropriate intercept script:
    - Execute `./interceptRestFights.sh` to proxy [`rest-fights`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-fights)
    - Execute `./interceptRestVillains.sh` to proxy [`rest-villains`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-villains)
    - Or execute the appropriate `skupper expose` commands based on what you're trying to expose. You can look inside [`interceptRestFights.sh`](interceptRestFights.sh) or [`interceptRestVillains.sh`](interceptRestVillains.sh) for examples.
8. Start local service
    - If proxying [`rest-fights`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-fights), first add some configuration in [`src/main/resources/application.properties`](https://github.com/quarkusio/quarkus-super-heroes/blob/main/rest-fights/src/main/resources/application.properties) so that it will connect to other outbound services that are still on the cluster. If you don't specify these then [Quarkus Dev Services](https://quarkus.io/guides/dev-services) will start a local Kafka broker & Apicurio instance.
       ```properties
       ## Skupper proxy
       kafka.bootstrap.servers=PLAINTEXT://fights-kafka:9092
       mp.messaging.connector.smallrye-kafka.apicurio.registry.url=http://localhost:8086
       ```
    - If proxying [`rest-villains`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-villains), there isn't any additional configuration needed.
    - Once config is done, start the local service in [Dev Mode](https://quarkus.io/guides/dev-mode-differences) (`mvnw quarkus:dev` or `quarkus dev`).

Now the traffic on your Kubernetes/OpenShift cluster will route through your local laptop & back out to the cluster. The database (MongoDB for `rest-fights` or PostgreSQL for `rest-heroes`/`rest-villains`) will be running locally and managed by [Quarkus Dev Services](https://quarkus.io/guides/dev-services).

## Undo the setup
To undo what you've done you basically have to unexpose everything you've exposed.

1. Stop the local running service
2. For every `skupper expose service` you performed above, perform a `skupper unexpose service <service_name> --address <address>`
3. Execute `./remove.sh`
4. Execute `skupper delete` to clean up skupper from the namespace
5. Sometimes the Kubernetes `Service` does not get cleaned up properly (the `selector` remains looking for the `skupper-router`). If that happens you can simply re-deploy the `Service`
    - For `rest-fights`, find the `Service` in https://github.com/quarkusio/quarkus-super-heroes/blob/main/rest-fights/deploy/k8s/java17-openshift.yml and re-deploy it
    - For `rest-villains`, find the `Service` in https://github.com/quarkusio/quarkus-super-heroes/blob/main/rest-villains/deploy/k8s/java17-openshift.yml and re-deploy it

If you proxied `rest-fights` you'll notice after returning to the UI that the fight results now differ from the event statistics. This is because the event statistics is reading from the Kafka topic whereas the fights UI is reading from the MongoDB database. When the proxy was in place, a local instance of MongoDB was used, but outgoing messages were still sent to the Kafka topic on the cluster.

You can also simply delete the namespace :)