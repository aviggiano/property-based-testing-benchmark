# property-based-testing-benchmark
Property-based testing benchmark

# Usage

## Build

```
docker build . -t benchmark
```

## Run benchmark

```
cd infrastructure
terraform init
terraform apply
export $(terraform output | sed 's/\s*=\s*/=/g' | xargs)
cd ..
python3 -m benchmark producer --send-message '{"tool":"foundry","project":"abdk-math-64x64","test":"test_","mutant":""}'
```