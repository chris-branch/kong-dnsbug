#!/bin/bash

# Bring up DNS server
docker-compose up -d custom-dns

# Bring up kong cassandra database
docker-compose up -d kong-database
rc=$?; if [[ $rc != 0 ]]; then echo "Failed to run kong-database due to return code $rc";exit $rc; fi

echo "Running status check on kong-database container"
docker exec -it kong-database /bin/sh -c "if cqlsh -u cassandra -p cassandra < /dev/null; then exit 0; fi; exit 1;"
rc=$?

until [ $rc = "0" ]; do 
    echo "waiting for kong-database container to finish initializing. return code from last status check was $rc"
    sleep 5
    docker exec -it kong-database /bin/sh -c "if cqlsh -u cassandra -p cassandra < /dev/null; then exit 0; fi; exit 1;"
    rc=$?
done

# Bootstrap migrations and wait for it to finish
docker-compose run kong kong migrations bootstrap --v
rc=$?; if [[ $rc != 0 ]]; then echo "Failed to run kong migrations bootstrap due to return code $rc";exit $rc; fi

# Bring up Kong
docker-compose up -d kong
rc=$?; if [[ $rc != 0 ]]; then echo "Failed to bring up kong due to return code $rc";exit $rc; fi

# cleanup completed containers
docker-compose rm -f

echo "Kong docker environment up and running. Access it via http://localhost:8000 or admin via http://localhost:8001"
