if [ $1 = "del" ]; then
    echo "deleting the existing container"
    for ind in `seq 1 6`; do \
        docker ps -a --filter "name=redis-$ind" | docker stop redis-$ind && docker rm -fv redis-$ind
    done
fi    
ips=
docker network ls|grep red_cluster > /dev/null || docker network create --driver bridge red_cluster
docker_redis_port_default=6379
for ind in `seq 1 6`; do \
    docker run -d \
    -v $PWD/cluster-config.conf:/usr/local/etc/redis/redis.conf \
    --name "redis-$ind" \
    --net red_cluster \
    -p $(($docker_redis_port_default+$ind)):6379 \
    redis redis-server /usr/local/etc/redis/redis.conf; \

    ip=$(docker inspect -f '{{ (index .NetworkSettings.Networks "red_cluster").IPAddress }}' redis-$ind)
    ips="$ips $ip:6379"
done

echo "container are created and running"

# echo 'yes' | docker run -i --rm --net red_cluster ruby sh -c '\
#  gem install redis \
#  && wget http://download.redis.io/redis-stable/src/redis-trib.rb \
#  && ruby redis-trib.rb create --replicas 1 \
#  '"$(for ind in `seq 1 6`; do \
#   echo -n "$(docker inspect -f \
#   '{{(index .NetworkSettings.Networks "red_cluster").IPAddress}}' \
#   "redis-$ind")"':6379 '; \
#   done)"


echo 'yes' | docker exec -i redis-$ind redis-cli --cluster create $ips --cluster-replicas 1  

for i in `seq 1 6`; 
do
  docker exec redis-$i redis-cli cluster nodes
done