#!/bin/bash -e

skupper expose service rest-villains --address rest-villains --port 80 --target-port 8084 --protocol http