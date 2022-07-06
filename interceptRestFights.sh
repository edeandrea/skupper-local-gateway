#!/bin/bash -e

oc patch route rest-fights -p '{"spec":{"port":{"targetPort":"http"}}}'
skupper expose service rest-fights --address rest-fights --port 80 --target-port 8082 --protocol http
skupper expose service rest-villains --address rest-villains-forward --port 80 --target-port 80 --protocol http
skupper expose service rest-heroes --address rest-heroes-forward --port 80 --target-port 80 --protocol http
skupper expose service apicurio --address apicurio-forward --port 8080 --target-port 8080 --protocol http
skupper expose service fights-kafka --address fights-kafka-forward --port 9092 --target-port 9092 --protocol tcp