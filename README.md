# Saminda - Laravel 12 Application

This repository contains a Laravel 12 application that has been Dockerized and configured for deployment on AWS EC2 with CI/CD automation.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Docker Configuration](#docker-configuration)
- [AWS Deployment](#aws-deployment)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Project Structure](#project-structure)
- [Maintenance and Operations](#maintenance-and-operations)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [Git](https://git-scm.com/downloads)
- [AWS CLI](https://aws.amazon.com/cli/) (for deployment)
- [GitHub](https://github.com/) account
- SSH key pair for EC2 access

## Local Development Setup

### Clone the Repository

```bash
git clone https://github.com/your-username/saminda.git
cd saminda
```

### Set Up Environment Variables

```bash
cp .env.example .env
```

Edit the `.env` file to set your local development variables:

```
APP_NAME=Saminda
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=saminda
DB_USERNAME=saminda
DB_PASSWORD=password
```

### Start the Docker Environment

```bash
docker-compose build
docker-compose up -d
```

### Install Dependencies and Set Up Application

```bash
docker-compose exec app composer install
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate
docker-compose exec app php artisan storage:link
```

The application should now be accessible at http://localhost.

## Docker Configuration

This project uses Docker for containerization with the following services:

- **app**: PHP 8.3 with Laravel application
- **web**: Nginx web server
- **db**: MySQL 8.0 database

### Key Docker Files

- `docker-compose.yml`: Defines the services, networks, and volumes
- `docker/app/Dockerfile`: PHP configuration
- `docker/web/Dockerfile`: Nginx configuration
- `docker/web/nginx.conf`: Nginx server configuration
- `.dockerignore`: Files excluded from Docker builds

### Docker Commands

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# View logs
docker-compose logs -f

# Execute commands in the app container
docker-compose exec app php artisan 
```

## AWS Deployment

### Infrastructure as Code

The AWS infrastructure is defined in `saminda-infrastructure.yml` using CloudFormation.

### Deploy Infrastructure

Using AWS CLI:

```bash
aws cloudformation create-stack \
  --stack-name saminda-stack \
  --template-body file://saminda-infrastructure.yml \
  --parameters ParameterKey=KeyName,ParameterValue=your-key-pair-name
```

Or via AWS Console:
1. Go to CloudFormation in AWS Console
2. Select "Create stack" > "With new resources"
3. Upload the `saminda-infrastructure.yml` file
4. Complete the parameters form and create the stack

### Manual Deployment (without CI/CD)

If you need to deploy manually:

```bash
# Connect to EC2 instance
ssh ec2-user@

# Create application directory
mkdir -p /var/www/saminda

# Clone repository
cd /var/www
git clone https://github.com/your-username/saminda.git

# Set up environment
cd saminda
cp .env.example .env
# Edit .env file with production values

# Start Docker environment
docker-compose build
docker-compose up -d

# Initialize application
docker-compose exec app composer install --no-dev --optimize-autoloader
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate --force
docker-compose exec app php artisan storage:link
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
```

## GitHub Actions CI/CD

This project uses GitHub Actions for Continuous Integration and Deployment.

### Workflow Configuration

The CI/CD pipeline is defined in `.github/workflows/deploy.yml` and executes when:
- Code is pushed to the `main` branch
- Manually triggered from the GitHub Actions tab

### Required GitHub Secrets

Set up the following secrets in your GitHub repository:

1. `SSH_PRIVATE_KEY`: Your private SSH key for EC2 access
2. `EC2_USER`: Username for EC2 (typically `ec2-user`)
3. `EC2_HOST`: Public IP or hostname of your EC2 instance
4. `ENV_FILE`: Complete content of your production `.env` file

### Triggering a Deployment

Any push to the `main` branch automatically triggers deployment. For manual deployment:

1. Go to your GitHub repository
2. Select "Actions" tab
3. Select the "Deploy Laravel to AWS EC2" workflow
4. Click "Run workflow" > "Run workflow"

## Project Structure

```
saminda/
├── app/                  # Laravel application code
├── bootstrap/            # Laravel bootstrap files
├── config/               # Laravel configuration
├── database/             # Migrations, seeds, and factories
├── docker/               # Docker configuration
│   ├── app/              # PHP Dockerfile
│   └── web/              # Nginx Dockerfile and config
├── public/               # Public assets
├── resources/            # Views, assets, and language files
├── routes/               # Application routes
├── storage/              # Storage for logs, cache, and uploads
├── tests/                # Test files
├── .dockerignore         # Files to exclude from Docker builds
├── .env.example          # Example environment variables
├── .github/              # GitHub Actions workflows
├── .gitignore            # Files to exclude from Git
├── docker-compose.yml    # Docker Compose configuration
└── saminda-infrastructure.yml  # AWS CloudFormation template
```

## Maintenance and Operations

### Database Backups

```bash
# Create a database backup
docker-compose exec db mysqldump -u saminda -p saminda > backup.sql

# Restore a database backup
docker-compose exec -T db mysql -u saminda -p saminda < backup.sql
```

### Log Management

```bash
# View Laravel logs
docker-compose exec app tail -f storage/logs/laravel.log

# Clear logs
docker-compose exec app php artisan log:clear
```

### Updates and Maintenance

```bash
# Update dependencies
docker-compose exec app composer update

# Pull latest code and redeploy
git pull
docker-compose down
docker-compose build
docker-compose up -d
docker-compose exec app php artisan migrate
docker-compose exec app php artisan optimize
```

### SSL/TLS Setup

For production, set up HTTPS:

1. Install Certbot on the EC2 instance
2. Obtain SSL certificates
3. Update Nginx configuration to use SSL
4. Update `.env` APP_URL to use https://

## Troubleshooting

### Common Issues

1. **Docker containers not starting**
   - Check logs: `docker-compose logs`
   - Verify ports aren't in use: `sudo netstat -tulpn | grep '80\|443\|3306'`

2. **Database connection issues**
   - Verify DB credentials in `.env`
   - Check if MySQL container is running: `docker-compose ps`

3. **Permission problems**
   - Fix storage permissions: `docker-compose exec app chmod -R 775 storage bootstrap/cache`
   - For composer permission issues, use the root user: `docker-compose exec --user=root app composer install`
   - If composer install fails with "Permission denied" errors, fix container permissions:
     ```bash
     docker-compose exec --user=root app bash -c "chown -R saminda:saminda /var/www/html/vendor"
     ```

4. **Deployment failures**
   - Check GitHub Actions logs for errors
   - Verify GitHub secrets are correct
   - Test SSH connection manually: `ssh -i your-key.pem ec2-user@<ec2-ip>`

### Getting Help

If you encounter issues:

1. Check Docker and Laravel logs
2. Review application logs in `storage/logs/laravel.log`
3. Verify EC2 instance system logs

## License

[MIT License](LICENSE)