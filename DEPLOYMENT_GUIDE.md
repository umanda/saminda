# Deployment Guide for Saminda Laravel Application

This guide provides step-by-step instructions for setting up, Dockerizing, and deploying the Saminda Laravel 12 application on AWS with CI/CD.

## Complete Deployment Process

### Phase 1: Local Development and Dockerization

1. **Set up project directory structure**

   ```bash
   mkdir -p docker/app docker/web
   ```

2. **Create Docker configuration files**

   Create the following files:
   - `docker-compose.yml` in the root directory
   - `docker/app/Dockerfile` for PHP application
   - `docker/web/Dockerfile` for Nginx
   - `docker/web/nginx.conf` for web server configuration
   - `.dockerignore` in the root directory

3. **Configure environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` to match Docker configuration:
   ```
   DB_CONNECTION=mysql
   DB_HOST=db
   DB_PORT=3306
   DB_DATABASE=saminda
   DB_USERNAME=saminda
   DB_PASSWORD=password
   ```

4. **Build and start Docker containers**

   ```bash
   docker-compose build
   docker-compose up -d
   ```

5. **Install dependencies and initialize application**

   ```bash
   docker-compose exec app composer install
   docker-compose exec app php artisan key:generate
   docker-compose exec app php artisan migrate
   docker-compose exec app php artisan storage:link
   ```

6. **Test the application locally**

   Open http://localhost in your browser to verify it works correctly.

### Phase 2: GitHub Repository Setup

1. **Initialize Git repository**

   ```bash
   git init
   ```

2. **Create `.gitignore` file**

   Create a `.gitignore` file in the root directory.

3. **Create a GitHub repository**

   - Go to https://github.com/new
   - Name your repository `saminda`
   - Configure as public or private
   - Click "Create repository"

4. **Push code to GitHub**

   ```bash
   git add .
   git commit -m "Initial commit with Dockerized Laravel application"
   git branch -M main
   git remote add origin https://github.com/your-username/saminda.git
   git push -u origin main
   ```

### Phase 3: AWS Infrastructure Setup

1. **Create AWS CloudFormation template**

   Create `saminda-infrastructure.yml` file.

2. **Create EC2 key pair** (if you don't already have one)

   - Navigate to EC2 Dashboard in AWS Console
   - Go to "Key Pairs" in the sidebar
   - Click "Create key pair"
   - Name it (e.g., `saminda-key`)
   - Download the `.pem` file and keep it secure

3. **Deploy CloudFormation stack**

   Using AWS CLI:
   ```bash
   aws cloudformation create-stack \
     --stack-name saminda-stack \
     --template-body file://saminda-infrastructure.yml \
     --parameters ParameterKey=KeyName,ParameterValue=saminda-key
   ```

   Or using AWS Console:
   - Go to CloudFormation in AWS Console
   - Click "Create stack" > "With new resources"
   - Upload the template
   - Specify parameters (key name, instance type, etc.)
   - Create the stack and wait for it to complete

4. **Get EC2 instance details**

   - Note the instance's public IP from CloudFormation outputs
   - Verify that the EC2 instance is running

### Phase 4: GitHub Actions CI/CD Setup

1. **Create GitHub Actions workflow**

   Create `.github/workflows/deploy.yml` file.

2. **Set up GitHub repository secrets**

   Go to repository Settings > Secrets and variables > Actions and add:

   - `SSH_PRIVATE_KEY`: Contents of your private key file (from the key pair)
     ```bash
     cat path/to/saminda-key.pem
     ```
   
   - `EC2_USER`: Username for EC2
     ```
     ec2-user
     ```
   
   - `EC2_HOST`: EC2 public IP or DNS
     ```
     xx.xx.xx.xx
     ```
   
   - `ENV_FILE`: Full content of production `.env` file
     ```
     APP_NAME=Saminda
     APP_ENV=production
     APP_KEY=base64:...
     APP_DEBUG=false
     APP_URL=http://xx.xx.xx.xx

     LOG_CHANNEL=stack
     LOG_DEPRECATIONS_CHANNEL=null
     LOG_LEVEL=error

     DB_CONNECTION=mysql
     DB_HOST=db
     DB_PORT=3306
     DB_DATABASE=saminda
     DB_USERNAME=saminda
     DB_PASSWORD=strong-password-here
     ...
     ```

### Phase 5: Initial Deployment

1. **Trigger first deployment**

   ```bash
   git commit --allow-empty -m "Trigger first deployment"
   git push origin main
   ```

2. **Monitor deployment progress**

   - Go to GitHub repository > Actions tab
   - Watch deployment progress and logs

3. **Verify deployment**

   - Open your application in a browser using the EC2 public IP
   - Test functionality to ensure everything works correctly

### Phase 6: Post-Deployment Configuration

1. **Set up domain name** (optional)

   - Register a domain or use existing one
   - Point DNS to your EC2 Elastic IP
   - Update `.env` with new domain

2. **Configure SSL** (recommended)

   ```bash
   # SSH into your EC2 instance
   ssh -i saminda-key.pem ec2-user@xx.xx.xx.xx

   # Install Certbot
   sudo amazon-linux-extras install epel
   sudo yum install certbot python-certbot-nginx

   # Obtain certificate
   sudo certbot --nginx -d yourdomain.com

   # Verify auto-renewal
   sudo certbot renew --dry-run
   ```

3. **Set up monitoring**

   - Configure CloudWatch monitoring
   - Set up application-level logging
   - Create alerts for critical issues

## Maintenance Tasks

### Deploying Updates

Updates are automatically deployed when you push to the `main` branch.

For manual updates:

```bash
# SSH into your EC2 instance
ssh -i saminda-key.pem ec2-user@xx.xx.xx.xx

# Navigate to application directory
cd /var/www/saminda

# Pull latest changes from repository
git pull

# Restart Docker containers
docker-compose down
docker-compose build
docker-compose up -d

# Run migrations
docker-compose exec -T app php artisan migrate --force

# Clear caches
docker-compose exec -T app php artisan optimize
```

### Database Management

```bash
# SSH into your EC2 instance
ssh -i saminda-key.pem ec2-user@xx.xx.xx.xx

# Create database backup
cd /var/www/saminda
docker-compose exec db mysqldump -u saminda -p saminda > ~/saminda-backup-$(date +%Y%m%d).sql

# Copy backup to local machine
exit
scp -i saminda-key.pem ec2-user@xx.xx.xx.xx:~/saminda-backup-*.sql ./backups/
```

### Performance Optimization

1. **Enable Laravel cache optimizations**

   ```bash
   docker-compose exec app php artisan config:cache
   docker-compose exec app php artisan route:cache
   docker-compose exec app php artisan view:cache
   ```

2. **Database indexing**

   ```bash
   # Add indexes to frequently queried columns
   docker-compose exec app php artisan make:migration add_indexes_to_*_table
   ```

3. **Implement Redis for caching** (optional)

   - Add Redis container to `docker-compose.yml`
   - Configure Laravel to use Redis for cache and session

## Troubleshooting

### Application not accessible

1. Check if Docker containers are running:
   ```bash
   docker-compose ps
   ```

2. Verify security group inbound rules allow traffic:
   - Go to EC2 > Security Groups
   - Verify ports 80 and 443 are open

3. Check application logs:
   ```bash
   docker-compose logs -f app
   docker-compose logs -f web
   ```

### Database connection issues

1. Verify database service is running:
   ```bash
   docker-compose ps db
   ```

2. Check database connection details in `.env`

3. Attempt to connect manually:
   ```bash
   docker-compose exec db mysql -u saminda -p
   ```

### Deployment failures

1. Check GitHub Actions workflow logs

2. Verify SSH connectivity:
   ```bash
   ssh -i saminda-key.pem ec2-user@xx.xx.xx.xx
   ```

3. Check file permissions on EC2:
   ```bash
   ls -la /var/www/saminda
   sudo chmod -R 775 /var/www/saminda/storage
   sudo chown -R ec2-user:ec2-user /var/www/saminda
   ```

### Permission denied Errors on Containers

   - Fix storage permissions: `docker-compose exec app chmod -R 775 storage bootstrap/cache`
   - For composer permission issues, use the root user: `docker-compose exec --user=root app composer install`
   - If composer install fails with "Permission denied" errors, fix container permissions:
        ```bash
        docker-compose exec --user=root app bash -c "chown -R saminda:saminda /var/www/html/vendor"
        ```

## Scaling Considerations

When your application grows:

1. **Vertical scaling**:
   - Upgrade EC2 instance type for more resources

2. **Horizontal scaling**:
   - Use Auto Scaling Groups
   - Implement Elastic Load Balancer
   - Extract database to RDS
   - Move static assets to S3 with CloudFront

3. **Container orchestration**:
   - Migrate to ECS or Kubernetes for better container management

## Security Practices

1. **Environment security**:
   - Restrict SSH access to trusted IPs
   - Use environment-specific `.env` files
   - Enable database encryption

2. **Application security**:
   - Keep Laravel and packages updated
   - Use HTTPS only
   - Implement CSRF protection
   - Set up proper authentication and authorization
   - Enable Laravel security headers

3. **Infrastructure security**:
   - Use IAM roles with least privilege
   - Set up VPC network isolation
   - Implement AWS WAF for application firewall
   - Configure backup and disaster recovery