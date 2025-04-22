# trino-analytics

## Overview
This project demonstrates my (terrible) data engineering skills in handling large-scale log data using Trino and Amazon S3, while also utilizing the Parquet format for storage. The goal is to simulate, process, and transform high-traffic website log data to generate analytics suitable for executive reporting. This project emphasizes efficient data processing, query optimization, and performance.

# Architecture
#<img width="655" alt="Architecture" src="https://github.com/user-attachments/assets/c24b5e79-393a-4c1b-a2d9-e61b35d2aec4">

This architecture demonstrates how Trino is set up on **Amazon EKS** to process and analyze large-scale data stored in **S3**

### Components

1. **Trino Cluster on EKS**:
   - The **Trino Coordinator** is responsible for managing query planning, scheduling, and coordination among the worker nodes.
   - **Trino Worker Nodes** handle data processing tasks and work in parallel for efficient query execution.
   - The Trino cluster runs on Kubernetes pods within the **EKS Data Plane**.

2. **Hive Metastore**:
   - A **Hive Metastore** (deployed as a service) is used to manage metadata about the data stored in S3, enabling Trino to understand the schema and structure of the data in the S3 bucket.

3. **Amazon S3**:
   - An **S3 Bucket** is used to store raw and transformed log data in Parquet format.
   - The Trino workers read data from and write results to this S3 bucket, enabling large-scale data storage and retrieval.

4. **Amazon RDS**:
   - Amazon RDS (Relational Database Service) is used as the backend for the Hive Metastore, providing persistent metadata storage.

5. **Trino Client (e.g., DBeaver)**:
   - A Trino client, such as **DBeaver**, can be used to connect to the Trino cluster, execute queries, and retrieve analytical insights.

### Data Flow

1. **Log Data Storage**:
   - High-traffic website logs are stored in the S3 bucket in a raw format.

2. **Data Processing**:
   - Trino workers read data from the S3 bucket, process it using SQL queries, and transform it as required.

3. **Analytics Output**:
   - After processing, the transformed data is also stored back in the S3 bucket in Parquet format, partitioned by date for efficient querying.

4. **Metadata Management**:
   - The Hive Metastore provides metadata information to Trino, allowing it to handle complex queries with partitioned data efficiently. We use a postgres instance for storage.

This architecture allows scalable, cost-effective, and efficient data analytics processing, leveraging Trino’s query optimization, Kubernetes' orchestration capabilities, and S3's storage.

## How to run
### Set up Hive Metastore
To set up a Hive Metastore for our Trino cluster, we need to create a custom container image. As of now, there is no official standalone Hive Metastore container image, so we’ll build one ourselves using the latest Hive and Hadoop versions for better compatibility and future-proofing.

1. Hive and Hadoop Versions:
   - We will use Hive version 4.0.0 and Hadoop version 3.4.0 for our custom image.
   - This setup also utilizes AWS SDK v2 from the latest Hadoop update, which provides improved functionality for AWS services.
2. Building the Container Image:
   - The Dockerfile and entry point script needed to build the Hive Metastore container image are available under `hive-metastore/docker`. These have been used with some modifications from [here](https://github.com/trinodb/trino/blob/master/core/docker/Dockerfile)

```
cd hive-metastore/docker
# Log in to GHCR
docker login ghcr.io -u <GITHUB_USERNAME> -p <PERSONAL_ACCESS_TOKEN>

# Build the Docker image for Hive Metastore and tag it with the GHCR repository URI
docker build -t ghcr.io/<GITHUB_USERNAME>/hive-metastore:latest .

# Push the Docker image to the GHCR repository
docker push ghcr.io/<GITHUB_USERNAME>/hive-metastore:latest
```
### Setup EKS and AWS Resources
I have separated the cloud infrastructure and the cluster-level configurations into two distinct subdirectories for better modularity. To set up the AWS and EKS and then cluster configs we will create a `terraform.tfvars` file. For cloud-infra the file should look something like
```
name                                 = "<CLUSTER-NAME>"
region                               = "<REGION>"
kube_namespace_name                  = "trino"
cluster_endpoint_public_access_cidrs = ["<YOUR_IP>/32"]
vpc_cidr                             = "10.0.0.0/24"
kubeconfig_location                  = "../../local/kubeconfig.yaml"
kube_service_account_name            = "s3-access"
enable_eks                           = true
enable_rds                           = true
```
To run the TF files
```
cd terraform/cloud-infra
terraform init
terraform plan -var-file="terraform.tfvars" 
terraform apply -var-file="terraform.tfvars" 
```
After this set up the kubernetes config
```
aws eks --region <REGION> update-kubeconfig --name <CLUSTER-NAME>
kubectl config use-context arn:aws:eks:<REGION>:<ACCOUNT_ID>:cluster/<CLUSTER-NAME>
kubectl config current-context
```

For cluster-configs the file should look something like
```
name                      = "<cluster-name>"
region                    = "<region>"
kube_namespace_name       = "trino"
kube_service_account_name = "s3-access"
```
Run the TF files similarly just cd into terraform/cluster-config

### Start the cluster
1. Confirm the pods are up `kubectl get pods --namespace trino`
2. Start the cluster `kubectl port-forward service/trino 8080 --namespace trino`
