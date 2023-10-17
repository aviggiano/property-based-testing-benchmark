# property-based-testing-benchmark
Property-based testing benchmark

# Usage

## Build

```
docker build . -t benchmark
```

## Run local benchmark

```
docker run -t benchmark -- --tool foundry --project abdk-math-64x64
```

## Run cloud benchmark

_WIP_

```
cd infrastructure
terraform init
terraform apply
curl -XPOST --data '{"tool":"foundry","project":"uniswap-v2"} https://example.com/
```