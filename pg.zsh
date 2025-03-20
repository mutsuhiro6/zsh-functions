export PGDATA_LOCAL=~/Workspace/docker/postgres-volume/

pg_docker_run() {
  local version=${1:-latest}
  docker run \
    --name postgres \
    --net pgnw \
    -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
    -p 5432:5432 \
    -v /Users/mutsuhiro/Workspace/docker/postgres-volume/:/var/lib/postgresql/data \
    -d postgres:$version
}

psql() {
  docker exec -it postgres psql "$@"
}
