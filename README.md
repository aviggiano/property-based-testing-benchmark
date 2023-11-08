# property-based-testing-benchmark

Property-based testing benchmark

## Description

This project aims to provide a comprehensive benchmark analysis of the performance and effectiveness of different property-based testing tools against real-world DeFi [projects](./projects/).

- [Halmos](https://github.com/a16z/halmos)
- [Foundry](https://github.com/foundry-rs/foundry/)
- [Echidna](https://github.com/crytic/echidna)
- [Medusa](https://github.com/crytic/medusa)

## Usage

Launch the benchmark [infrastructure](./infrastructure/) with Terraform:

```bash
cd infrastructure
terraform init
terraform apply
```

Run the benchmark

```bash
python3 -m benchmark producer --full-benchmark
```

Analyse the results

```bash
python3 -m benchmark analyser
```

## Project structure

- [Dockerfile](./Dockerfile): Install all referenced tools and [benchmark](./benchmark/) scripts
- [infrastructure](./infrastructure): Set of Terraform configuration files that will launch
  - SQS: queue of [job messages](./benchmark/parser.py)
  - S3: bucket of [job outputs](./benchmark/runner.py)
  - ECS: cluster of [consumer](./benchmark/consumer.py) components, responsible for reading the SQS queue and launching [runner](./benchmark/runner.py) tasks that execute the benchmark and upload results to S3
  - ECR: registry that hosts the Docker image
  - IAM: access controls for Docker containers to manage the referenced resources
  - VPC: networking required for ECS
- [benchmark](./benchmark/): Benchmark scripts
  - [producer](./benchmark/producer.py): Push job messages to the queue
  - [consumer](./benchmark/consumer.py): Pull messages from the queue and launch a new task to run the benchmark
  - [runner](./benchmark/runner.py): Run benchmark jobs, and analyse benchmark results
  - [analyser](./benchmark/analyser.py): Analyse benchmark results

## Contribute

Contributions are welcome. Feel free to open an issue or pull request.
