

* I separated the Terraform code from the application code for several reasons:
	*	*Maintainability*: Infrastructure and application code can be managed and updated independently.
	*	*Security*: Sensitive information, like AWS credentials, is stored as GitHub secrets, reducing exposure risks.
	*	*Clarity*: This separation clarifies the project’s architecture, distinguishing infrastructure from application logic.
	*	*Collaboration*: Teams can work concurrently on infrastructure and application code, improving workflow efficiency.





# GitHub Actions Workflow
I set up a workflow using GitHub Actions. The following GitHub Actions workflow triggers AWS CodePipeline whenever there are code changes:


```yaml
name: Trigger AWS CodePipeline

on:
  push:
    branches: [main]

jobs:
  build:
    name: Trigger-pipeline
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Trigger AWS CodePipeline
        run: |
          aws codepipeline start-pipeline-execution --name bitcube-pipeline
```



# Docker File
I created a Dockerfile to Dockerize the application with the following content:


```
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build 

EXPOSE 3000

CMD ["npm", "run", "dev"]
```


# buildspec.yml File
This file automates building a Docker image from your application code and pushing that image to an AWS ECR repository, facilitating a smooth CI/CD pipeline.
* Deployment Automation: CodeDeploy automates the deployment of applications, ensuring that the process is consistent and reliable.
* Hooks and Scripts: Using lifecycle event hooks (like ApplicationStop, BeforeInstall, AfterInstall, etc.) allows you to execute custom scripts at various stages of the deployment, providing control over the deployment process.
* I'll use the  scripts to deploy the application on an Amazon EC2 instance. They reside in the *scripts* directory.

```
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
```


# appspec.yml File
The provided YAML file is specifically for AWS CodeDeploy. AWS CodeDeploy is a service that automates the process of deploying applications to various compute services, such as Amazon EC2 instances, AWS Lambda functions, or on-premises servers.
Deployment Automation: CodeDeploy automates the deployment of applications, ensuring that the process is consistent and reliable.




```
version: 0.0
os: linux
files:
  - source: /
    destination: /home/ec2-user/app

hooks:
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 300
      runas: root
  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 3600
      runas: root
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 300
      runas: root
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 3600
      runas: root
  ValidateService:
    - location: scripts/validate_service.sh
      timeout: 3600
      runas: root
```



