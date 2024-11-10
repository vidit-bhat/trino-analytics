# trino-analytics

## Overview
This project demonstrates data engineering skills in handling large-scale log data using Trino and Amazon S3, while also utilizing the Parquet format for storage. The goal is to simulate, process, and transform high-traffic website log data to generate analytics suitable for executive reporting. This project emphasizes efficient data processing, query optimization, and performance.

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
   - The Hive Metastore provides metadata information to Trino, allowing it to handle complex queries with partitioned data efficiently.

This architecture allows scalable, cost-effective, and efficient data analytics processing, leveraging Trino’s query optimization, Kubernetes' orchestration capabilities, and S3's storage.

## How to run
