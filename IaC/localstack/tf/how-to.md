### Install and Setup LocalStack
```bash
# Install LocalStack with pip
pip install localstack

# Or use Docker (recommended)
docker pull localstack/localstack
```

#### Start LocalStack
```bash
# Using the LocalStack CLI
localstack start

# Or using Docker
docker run -d --name localstack \
  -p 4566:4566 \
  -p 4571:4571 \
  -e SERVICES=ec2,route53,cloudformation \
  -e DEBUG=1 \
  localstack/localstack
```