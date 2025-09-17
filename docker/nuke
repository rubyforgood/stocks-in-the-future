#!/bin/bash

# This script destroys all Docker containers and images.
# SOURCE: https://gist.github.com/JeffBelback/5687bb02f3618965ca8f

echo '------------------------------------------'
echo 'Killing and removing all Docker containers'
for i in $(docker ps -a -q)
do
  docker kill $i; wait;
  docker rm -f $i; wait;
done;

echo '--------------------------------------'
echo 'Killing and removing all Docker images'
for i in $(docker images -a -q)
do
  docker kill $i; wait;
  docker rmi -f $i; wait;
done;

echo '------------'
echo 'docker ps -a'
docker ps -a

echo '----------------'
echo 'docker images -a'
docker images -a
