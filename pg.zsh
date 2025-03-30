export PGDATA_LOCAL=~/Workspace/docker/postgres-volume/

pg_docker_run() {
  local version=${1:-latest}
  docker run \
    --name postgres \
    --net pgnw \
    -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
    -p 5432:5432 \
    -v "$PGDATA_LOCAL":/var/lib/postgresql/data \
    -d postgres:$version
}

psql() {
  docker exec -it -u postgres postgres psql "${argv[@]}"
}

pg_ctl() {
  docker exec -it -u postgres postgres pg_ctl "${argv[@]}"
}

pgbench() {
  docker exec -it -u postgres postgres pgbench "${argv[@]}"
}

pg_top() {
  docker exec -it -u postgres postgres pg_top "${argv[@]}"
}

__pg_install_pg_top() {
  docker exec postgres apt install -y cmake libbsd-dev libpq-dev libncurses-dev
  docker exec -w /tmp postgres curl https://gitlab.com/pg_top/pg_top/-/archive/main/pg_top-main.tar.gz | tar xzv
  docker exec -w /tmp/pg_top-main postgres cmake CMakeLists.txt
  docker exec -w /tmp/pg_top-main postgres make install
  docker exec -w /tmp postgres rm -rf pg_top-main
}
