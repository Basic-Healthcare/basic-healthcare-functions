# Basic Healthcare Functions - Content Lake

A Python-based Azure Functions application for managing a healthcare content lake using Azure Data Lake Storage Gen2. This project demonstrates how to build a secure, scalable data lake solution for AI and analytics purposes.

## 🏗️ Architecture

This solution includes:

- **Azure Functions (Python)** - Serverless compute for data processing
- **Azure Data Lake Storage Gen2** - Scalable data lake with hierarchical namespace
- **Application Insights** - Monitoring and observability
- **Managed Identity** - Secure authentication without secrets
- **Terraform** - Infrastructure as Code
- **GitHub Actions** - CI/CD pipeline

## 📁 Project Structure

```
├── function_app.py              # Main Azure Functions application
├── host.json                    # Azure Functions host configuration
├── local.settings.json          # Local development settings
├── requirements.txt             # Python dependencies
├── test_functions.py           # Unit tests
├── azure.yaml                  # Azure Developer CLI configuration
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions deployment pipeline
└── infra/                      # Terraform infrastructure
    ├── main.tf                 # Main infrastructure configuration
    ├── variables.tf            # Variable definitions
    ├── outputs.tf              # Output values
    └── terraform.tfvars.json   # Environment-specific variables
```

## 🚀 API Endpoints

### Health Check
- **GET** `/api/health`
- Returns the health status of the function app

### Data Lake Operations
- **POST** `/api/datalake/upload` - Upload files to the data lake
- **GET** `/api/datalake/list` - List files in the data lake containers

## 🛠️ Setup & Deployment

### Prerequisites

1. **Azure Subscription** with appropriate permissions
2. **GitHub Repository** with the following secrets configured:
   - `AZURE_CREDENTIALS` - Service principal credentials for Azure login
3. **Terraform** (handled by GitHub Actions)
4. **Python 3.11** (for local development)

### Azure Credentials Setup

Create a service principal and configure GitHub secrets:

```bash
# Create service principal
az ad sp create-for-rbac --name "basic-healthcare-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth

# Add the output as AZURE_CREDENTIALS secret in GitHub
```

**✅ AZURE_CREDENTIALS secret has been configured!**

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd basic-healthcare-functions
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure local settings**
   ```bash
   cp local.settings.json.example local.settings.json
   # Edit local.settings.json with your Azure Storage connection string
   ```

4. **Run locally**
   ```bash
   func start
   ```

### Infrastructure Configuration

1. **Update Terraform variables**
   
   Edit `infra/terraform.tfvars.json`:
   ```json
   {
     "environment_name": "dev",
     "location": "East US 2"
   }
   ```

2. **Deploy via GitHub Actions**
   
   Push to the `main` branch to trigger automatic deployment:
   ```bash
   git add .
   git commit -m "Deploy healthcare functions"
   git push origin main
   ```

## 🔒 Security Features

- **Managed Identity** - No secrets stored in code
- **RBAC** - Least privilege access to Azure resources
- **TLS 1.2** - Secure communication
- **Application Insights** - Security monitoring

## 📊 Data Lake Structure

The data lake is organized into three containers:

- **`raw`** - Incoming data in original format
- **`processed`** - Cleaned and transformed data
- **`curated`** - Analysis-ready data for AI/ML workloads

## 🧪 Testing

Run the test suite:

```bash
python -m pytest test_functions.py -v
```

## 📖 Usage Examples

### Upload a file to the data lake

```bash
curl -X POST "https://<function-app-name>.azurewebsites.net/api/datalake/upload?code=<function-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "container": "raw",
    "blob_name": "patient-data/2024/01/patient-001.json",
    "content": "{\"patientId\": \"001\", \"data\": \"sample\"}"
  }'
```

### List files in the data lake

```bash
curl "https://<function-app-name>.azurewebsites.net/api/datalake/list?container=raw&code=<function-key>"
```

## 🚨 Monitoring

- **Application Insights** provides comprehensive monitoring
- **Health check endpoint** for uptime monitoring
- **GitHub Actions** provide deployment visibility

## 🔄 CI/CD Pipeline

The GitHub Actions workflow includes:

1. **Test** - Run Python unit tests
2. **Terraform Plan** - Validate infrastructure changes
3. **Terraform Apply** - Deploy infrastructure (main branch only)
4. **Function Deploy** - Deploy Python functions
5. **Health Check** - Verify deployment success

## 📄 License

This project is licensed under the MIT License.