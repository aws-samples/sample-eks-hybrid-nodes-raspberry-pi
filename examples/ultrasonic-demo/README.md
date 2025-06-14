# Ultrasonic Sensor Demo for EKS Hybrid Nodes

This demo showcases how to deploy an ultrasonic distance sensor application on EKS Hybrid Nodes running on Raspberry Pi. The application consists of a backend service that reads sensor data and stores it in DynamoDB, and a frontend dashboard for visualization.

## Architecture

- **Backend**: Python service running on Raspberry Pi that reads data from an ultrasonic sensor and writes to DynamoDB
- **Frontend**: Flask web application that retrieves and visualizes the sensor data

## Prerequisites

- EKS cluster with hybrid nodes configured (follow the main repository setup instructions)
- Raspberry Pi with an ultrasonic sensor connected (HC-SR04 or similar)
- AWS DynamoDB table named `eks-timeseries` (or update the environment variable)
- AWS IAM permissions for DynamoDB access

## Setup Instructions

### 1. Build and Deploy the Backend Service

```bash
# Navigate to the backend directory
cd ultrasonic-backend

# Build the Docker image
docker build . -t <your_backend_image_name>:latest

# Push the image to your repository
docker push <your_backend_image_name>:latest

# Update the manifest.yaml with your image repository
# Replace <your_backend_image_name> with your actual image repository
```

### 2. Build and Deploy the Frontend Service

```bash
# Navigate to the frontend directory
cd ultrasonic-frontend

# Build the Docker image
docker build . -t <your_frontend_image_name>:latest

# Push the image to your repository
docker push <your_frontend_image_name>:latest

# Update the manifest.yaml with your image repository
# Replace <your_frontend_image_name> with your actual image repository
```

### 3. Create a Public ECR Repository (Optional)

If you don't have a container registry, you can create a public ECR repository:

1. Open the Amazon ECR console at https://console.aws.amazon.com/ecr/
2. Choose your preferred region from the navigation bar
3. Select "Public repositories" from the left navigation pane
4. Click "Create repository"
5. Enter a repository name (e.g., "eks-hybrid-ultrasonic-demo")
6. Add optional tags if desired
7. Click "Create repository"
8. Follow the "View push commands" instructions to authenticate and push your images

### 4. Deploy the Application

After building and pushing your images:

```bash
# Deploy the backend (runs on the Raspberry Pi hybrid node)
kubectl apply -f ultrasonic-backend/manifest.yaml

# Deploy the frontend and dashboard
kubectl apply -f ultrasonic-frontend/dashboard.yaml
```

## Accessing the Dashboard

Once deployed, you can access the dashboard using:

```bash
# Get the LoadBalancer URL for the frontend service
kubectl get svc ultrasonic-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Navigate to this URL in your browser to view the ultrasonic sensor dashboard.

## Environment Variables

### Backend Service
- `TABLE_NAME`: DynamoDB table name (default: "eks-timeseries")
- `WRITE_INTERVAL`: Interval between writes to DynamoDB in seconds (default: 60)
- `DYNAMO_REGION`: AWS region for DynamoDB (default: "eu-west-1")
- `SAMPLING_INTERVAL`: Sensor sampling interval in seconds (default: 20)
- `PIN_TRIGGER`: GPIO pin for ultrasonic sensor trigger (default: 4)
- `PIN_ECHO`: GPIO pin for ultrasonic sensor echo (default: 17)

### Frontend Service
- `TABLE_NAME`: DynamoDB table name (default: "eks-timeseries")
- `DYNAMO_REGION`: AWS region for DynamoDB (default: "eu-west-1")

## Troubleshooting

- Ensure your Raspberry Pi has the necessary GPIO libraries installed
- Verify that your IAM roles have appropriate permissions for DynamoDB
- Check the pod logs for any errors: `kubectl logs -f <pod-name>`
- Verify the ultrasonic sensor is properly connected to the specified GPIO pins

## Security Considerations

This demo uses environment variables for configuration. In a production environment, consider using AWS Secrets Manager or Parameter Store for sensitive configuration.

## License

This project is licensed under the MIT License - see the LICENSE file at the root of this repository for details.