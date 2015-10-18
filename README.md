# Maturate

Naturally grow your rails API through sane versioning.

#### Flow

docker build --tag=maturate .
docker run -it --rm -v $PWD:/usr/src/app maturate rake
docker run -it --rm -v $PWD:/usr/src/app maturate gem build maturate.gemspec
