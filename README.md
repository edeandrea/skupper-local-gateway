# What is this repo?

These instructions are for working with the [Quarkus Superheroes sample](https://github.com/quarkusio/quarkus-super-heroes). They allow you to use [Skupper](https://skupper.io) to proxy traffic of one of the individual services to your local laptop where you can run that service in [Quarkus Dev Mode](https://quarkus.io/guides/dev-mode-differences).

# Skupper Setup instructions

These instructions have only been tested on macOS Monterey on a Macbook M1Pro.

1. Create [`laptop-rest-villains.yaml`](laptop-rest-villains.yaml) or [`laptop-rest-fights.yaml`](laptop-rest-fights.yaml)
    - If using `laptop-rest-fights.yaml`, in `/etc/hosts`, add entry for `fights-kafka` -> `localhost`
2. Execute these commands:
   ```shell
   PROJECT_NAME=<my_project>
   LAPTOP_FILE_NAME=<laptop_file_name>

   oc project $PROJECT_NAME
   skupper init
   mkdir -p bundle/$LAPTOP_FILE_NAME
   skupper gateway generate-bundle ${LAPTOP_FILE_NAME}.yaml bundle/$LAPTOP_FILE_NAME
   cd bundle/$LAPTOP_FILE_NAME
   gzip -dc ${LAPTOP_FILE_NAME}.tar.gz | tar xvf -
   chmod +x launch.sh
   ```

3. Copy [`captureports.py`](captureports.py) into `bundle/<laptop_file_name>`
4. Patch `bundle/<laptop_file_name>/launch.sh` by replacing the last `elif` with contents from [`launch.sh`](launch.sh)
5. Execute `./launch.sh -t docker`
6. In a new terminal window, execute `skupper expose service <service_name> --address <service_name> --port <incoming_service_port> --target-port <outgoing_service_port> --protocol http`
    - If proxying [`rest-fights`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-fights) you'll also need to expose some other downstream services (`apicurio`, `rest-heroes`, `rest-villains`, & the kafka broker) so that outgoing requests from the local service return back to the cluster
        - Execute these commands:
           ```shell
           skupper expose service rest-villains --address rest-villains-forward --port 80 --target-port 80 --protocol http
           skupper expose service rest-heroes --address rest-heroes-forward --port 80 --target-port 80 --protocol http
           skupper expose service apicurio --address apicurio-forward --port 8080 --target-port 8080 --protocol http
           skupper expose service fights-kafka --address fights-kafka-forward --port 9092 --target-port 9092 --protocol tcp
           ```
7. Start local service
    - If proxying [`rest-fights`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-fights), first add some configuration in [`src/main/resources/application.properties`](https://github.com/quarkusio/quarkus-super-heroes/blob/main/rest-fights/src/main/resources/application.properties) so that it will connect to other outbound services that are still on the cluster. If you don't specify these then [Quarkus Dev Services](https://quarkus.io/guides/dev-services) will start a local Kafka broker & Apicurio instance.
       ```properties
       ## Skupper proxy
       kafka.bootstrap.servers=PLAINTEXT://fights-kafka:9092
       mp.messaging.connector.smallrye-kafka.apicurio.registry.url=http://localhost:8086
       ```
    - If proxying [`rest-heroes`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-heroes) or [`rest-villains`](https://github.com/quarkusio/quarkus-super-heroes/tree/main/rest-villains), there isn't any additional configuration needed.
    - Once config is done, start the local service in [Dev Mode](https://quarkus.io/guides/dev-mode-differences) (`mvnw quarkus:dev` or `quarkus dev`).

Now the traffic on your Kubernetes/OpenShift cluster will route through your local laptop & back out to the cluster.
