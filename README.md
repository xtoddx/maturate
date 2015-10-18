# Maturate

Naturally grow your rails API through sane versioning.

#### Flow

docker build --tag=maturate .
docker run -it --rm -v $PWD:/usr/src/app gem build maturate.gemspec
