#!/bin/bash

# Interactive EC2 Instance Creator
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo -e "${BLUE}🚀 Interactive EC2 Instance Creator${NC}"
echo "=================================="

# Get instance name
read -p "Enter instance name: " INSTANCE_NAME
if [ -z "$INSTANCE_NAME" ]; then
    print_error "Instance name is required!"
    exit 1
fi

# Select instance type
echo ""
echo "Select instance type:"
echo "1) t2.micro (Free tier eligible)"
echo "2) t2.small"
echo "3) t2.medium"
echo "4) t3.micro"
echo "5) t3.small"
echo "6) t3.medium"
read -p "Choose (1-6): " TYPE_CHOICE

case $TYPE_CHOICE in
    1) INSTANCE_TYPE="t2.micro" ;;
    2) INSTANCE_TYPE="t2.small" ;;
    3) INSTANCE_TYPE="t2.medium" ;;
    4) INSTANCE_TYPE="t3.micro" ;;
    5) INSTANCE_TYPE="t3.small" ;;
    6) INSTANCE_TYPE="t3.medium" ;;
    *) INSTANCE_TYPE="t2.micro"; print_warning "Invalid choice, using t2.micro" ;;
esac

# Select region
echo ""
echo "Select AWS region:"
echo "1) us-east-1 (N. Virginia)"
echo "2) us-west-2 (Oregon)"
echo "3) eu-west-1 (Ireland)"
echo "4) ap-southeast-1 (Singapore)"
echo "5) Use configured region"
read -p "Choose (1-5): " REGION_CHOICE

case $REGION_CHOICE in
    1) AWS_REGION="us-east-1" ;;
    2) AWS_REGION="us-west-2" ;;
    3) AWS_REGION="eu-west-1" ;;
    4) AWS_REGION="ap-southeast-1" ;;
    *) AWS_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1") ;;
esac

# Get key pair name
echo ""
read -p "Enter key pair name (will create if doesn't exist): " KEY_PAIR
if [ -z "$KEY_PAIR" ]; then
    KEY_PAIR="${INSTANCE_NAME}-key"
    print_info "Using default key pair name: $KEY_PAIR"
fi

# Enable monitoring
echo ""
read -p "Enable detailed monitoring? (y/n): " ENABLE_MONITORING
MONITORING_FLAG=""
if [ "$ENABLE_MONITORING" = "y" ] || [ "$ENABLE_MONITORING" = "Y" ]; then
    MONITORING_FLAG="--monitoring State=enabled"
    print_info "Detailed monitoring enabled"
fi

# Storage size
echo ""
read -p "Root volume size in GB (default: 8): " VOLUME_SIZE
VOLUME_SIZE=${VOLUME_SIZE:-8}

# Show configuration
echo ""
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo "Instance Name: $INSTANCE_NAME"
echo "Instance Type: $INSTANCE_TYPE"
echo "Region: $AWS_REGION"
echo "Key Pair: $KEY_PAIR"
echo "Volume Size: ${VOLUME_SIZE}GB"
echo "Monitoring: $([ -n "$MONITORING_FLAG" ] && echo "Enabled" || echo "Disabled")"

echo ""
read -p "Proceed with creation? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    print_warning "Operation cancelled"
    exit 0
fi

echo ""
print_status "Starting EC2 instance creation..."

# Get latest Ubuntu 22.04 LTS AMI
print_info "Fetching latest Ubuntu 22.04 LTS AMI for $AWS_REGION..."
AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" \
    --region "$AWS_REGION" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

if [ "$AMI_ID" = "None" ] || [ -z "$AMI_ID" ]; then
    print_error "Could not find Ubuntu AMI in region $AWS_REGION"
    exit 1
fi
print_status "Found Ubuntu AMI: $AMI_ID"

# Get default VPC and subnet
print_info "Finding default VPC and subnet..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region "$AWS_REGION" --query 'Vpcs[0].VpcId' --output text)
if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
    print_error "No default VPC found in region $AWS_REGION"
    exit 1
fi

SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region "$AWS_REGION" --query 'Subnets[0].SubnetId' --output text)
if [ "$SUBNET_ID" = "None" ] || [ -z "$SUBNET_ID" ]; then
    print_error "No subnets found in default VPC"
    exit 1
fi

print_status "Using VPC: $VPC_ID, Subnet: $SUBNET_ID"

# Create or use existing key pair
if ! aws ec2 describe-key-pairs --key-names "$KEY_PAIR" --region "$AWS_REGION" &>/dev/null; then
    print_info "Creating new key pair: $KEY_PAIR"
    aws ec2 create-key-pair --key-name "$KEY_PAIR" --region "$AWS_REGION" --query 'KeyMaterial' --output text > "${KEY_PAIR}.pem"
    chmod 400 "${KEY_PAIR}.pem"
    print_status "Key pair saved as: ${KEY_PAIR}.pem"
else
    print_info "Using existing key pair: $KEY_PAIR"
fi

# Create or use existing security group
SG_NAME="${INSTANCE_NAME}-sg"
if aws ec2 describe-security-groups --group-names "$SG_NAME" --region "$AWS_REGION" &>/dev/null; then
    SG_ID=$(aws ec2 describe-security-groups --group-names "$SG_NAME" --region "$AWS_REGION" --query 'SecurityGroups[0].GroupId' --output text)
    print_info "Using existing security group: $SG_ID"
else
    print_info "Creating security group: $SG_NAME"
    SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" --description "Security group for $INSTANCE_NAME" --vpc-id "$VPC_ID" --region "$AWS_REGION" --query 'GroupId' --output text)
    print_status "Created security group: $SG_ID"
fi

# Add security group rules (suppress output)
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$AWS_REGION" &>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$AWS_REGION" &>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$AWS_REGION" &>/dev/null || true

# Launch EC2 instance
print_info "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_PAIR" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --associate-public-ip-address \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":$VOLUME_SIZE,\"VolumeType\":\"gp3\"}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=CreatedBy,Value=InteractiveScript}]" \
    --region "$AWS_REGION" \
    $MONITORING_FLAG \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    print_error "Failed to launch instance"
    exit 1
fi

print_status "Instance launched: $INSTANCE_ID"
print_info "Waiting for instance to be running..."

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress,State.Name]' \
    --output text)

PUBLIC_IP=$(echo $INSTANCE_INFO | cut -d' ' -f1)
PRIVATE_IP=$(echo $INSTANCE_INFO | cut -d' ' -f2)
STATE=$(echo $INSTANCE_INFO | cut -d' ' -f3)

# Display results
echo ""
echo -e "${GREEN}🎉 EC2 Instance Successfully Created!${NC}"
echo "========================================"
echo "Instance Name: $INSTANCE_NAME"
echo "Instance ID: $INSTANCE_ID"
echo "Instance Type: $INSTANCE_TYPE"
echo "State: $STATE"
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"
echo "Region: $AWS_REGION"
echo "Security Group: $SG_ID"
echo ""
echo -e "${BLUE}🔗 Connection Details:${NC}"
echo "SSH Command: ssh -i ${KEY_PAIR}.pem ubuntu@$PUBLIC_IP"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Wait 2-3 minutes for the instance to fully initialize"
echo "2. Connect using the SSH command above"
echo "3. Update packages: sudo apt update && sudo apt upgrade -y"
echo ""
echo -e "${RED}💰 Cost Warning:${NC}"
echo "Remember to terminate the instance when done:"
echo "aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $AWS_REGION"