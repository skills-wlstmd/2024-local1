sudo yum -y install openssl-devel gcc
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make distclean
make redis-cli BUILD_TLS=yes
sudo install -m 755 src/redis-cli /usr/local/bin/

redis-cli -h skills-redis-cluster-ro.tctbtd.ng.0001.apn2.cache.amazonaws.com:6378 -c -p 6378
redis-cli -h skills-redis-cluster-001.skills-redis-cluster.tctbtd.apn2.cache.amazonaws.com -p 6378 cluster info