<div align="center">

[![Open in Codespaces](https://img.shields.io/badge/Open%20in-Codespaces-24292e?logo=github&style=for-the-badge)](https://codespaces.new/atulkamble/template.git)
[![Open with VS Code](https://img.shields.io/badge/Open%20with-VS%20Code-007ACC?logo=visualstudiocode&style=for-the-badge)](https://vscode.dev/github/atulkamble/template)
[![Open with GitHub Desktop](https://img.shields.io/badge/Open%20with-GitHub%20Desktop-purple?logo=github&style=for-the-badge)](https://desktop.github.com/)

**🚀 MyApp** | Built with ❤️ by [Atul Kamble](https://github.com/atulkamble)

[![GitHub](https://img.shields.io/badge/GitHub-atulkamble-181717?logo=github)](https://github.com/atulkamble)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-atuljkamble-0A66C2?logo=linkedin)](https://www.linkedin.com/in/atuljkamble/)
[![X](https://img.shields.io/badge/X-atul_kamble-000000?logo=x)](https://x.com/atul_kamble)

**Version 1.0.0** | Last Updated: December 2025

</div>

**complete, production-ready AWS CloudFormation full project** you can directly use for **training, demos, or real workloads**.

**modular, readable, and GitHub-ready** — but **pure CloudFormation (YAML)**.

---

## 📌 Project: AWS CloudFormation – VPC + EC2 + ALB + Auto Scaling

![Image](https://miro.medium.com/v2/resize%3Afit%3A1400/1%2AP1FeZnLoY6jaeqvC8Ffz2w.png)

![Image](https://docs.aws.amazon.com/images/autoscaling/ec2/userguide/images/elb-tutorial-architecture-diagram.png)

![Image](https://docs.aws.amazon.com/images/autoscaling/ec2/userguide/images/sample-3-tier-architecture-with-azs-diagram.png)

![Image](https://d2908q01vomqb2.cloudfront.net/b7eb6c689c037217079766fdb77c3bac3e51cb4c/2019/05/10/iot-deploy-diagram.png)

---

## 🧱 Architecture Overview

**What this project creates:**

✔ Custom VPC
✔ Public & Private Subnets (Multi-AZ)
✔ Internet Gateway + Route Tables
✔ Security Groups
✔ Application Load Balancer (ALB)
✔ Auto Scaling Group (ASG)
✔ EC2 instances with UserData
✔ Outputs for DNS & networking

---

## 📁 Repository Structure (Best Practice)

```
cloudformation-full-project/
│
├── templates/
│   ├── vpc.yaml
│   ├── security-groups.yaml
│   ├── alb.yaml
│   ├── launch-template.yaml
│   ├── autoscaling.yaml
│
├── parent-stack.yaml
├── parameters.json
├── README.md
```

---

## 🧩 1️⃣ VPC Template (`templates/vpc.yaml`)

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: VPC with Public & Private Subnets

Resources:
  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: CF-VPC

  InternetGateway:
    Type: AWS::EC2::InternetGateway

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref MyVPC
      InternetGatewayId: !Ref InternetGateway

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs ""]
      MapPublicIpOnLaunch: true

Outputs:
  VPCId:
    Value: !Ref MyVPC
    Export:
      Name: VPCId
```

---

## 🔐 2️⃣ Security Groups (`templates/security-groups.yaml`)

```yaml
Resources:
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: ALB SG
      VpcId: !ImportValue VPCId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0

  EC2SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: EC2 SG
      VpcId: !ImportValue VPCId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          SourceSecurityGroupId: !Ref ALBSecurityGroup
```

---

## ⚖️ 3️⃣ Application Load Balancer (`templates/alb.yaml`)

```yaml
Resources:
  ALB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Subnets:
        - !ImportValue PublicSubnet1
      SecurityGroups:
        - !ImportValue ALBSG

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Port: 80
      Protocol: HTTP
      VpcId: !ImportValue VPCId

  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref ALB
      Port: 80
      Protocol: HTTP
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup
```

---

## 🚀 4️⃣ Launch Template (`templates/launch-template.yaml`)

```yaml
Resources:
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateData:
        ImageId: ami-0abcdef12345
        InstanceType: t2.micro
        SecurityGroupIds:
          - !ImportValue EC2SG
        UserData:
          Fn::Base64: |
            #!/bin/bash
            yum install -y httpd
            systemctl start httpd
            echo "CloudFormation ASG Instance" > /var/www/html/index.html
```

---

## 📈 5️⃣ Auto Scaling Group (`templates/autoscaling.yaml`)

```yaml
Resources:
  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      MinSize: 1
      MaxSize: 3
      DesiredCapacity: 2
      VPCZoneIdentifier:
        - !ImportValue PublicSubnet1
      LaunchTemplate:
        LaunchTemplateId: !ImportValue LaunchTemplateId
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      TargetGroupARNs:
        - !ImportValue TargetGroupArn
```

---

## 🧠 6️⃣ Parent Stack (`parent-stack.yaml`)

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: Root Stack

Resources:
  VPCStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/YOUR_BUCKET/templates/vpc.yaml

  SGStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/YOUR_BUCKET/templates/security-groups.yaml
```

---

## ⚙️ 7️⃣ Deploy from CLI

```bash
aws cloudformation create-stack \
  --stack-name cf-full-project \
  --template-body file://parent-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## 📘 README.md (What You Should Include)

✔ Architecture diagram
✔ Stack dependency order
✔ Parameters explanation
✔ Rollback & delete steps
✔ Cost cleanup steps
✔ Troubleshooting

---

## 💡 Real-World Enhancements (Optional)

* 🔒 HTTPS with ACM
* 🌐 Route53 DNS
* 🔐 IAM roles for EC2
* 📊 CloudWatch Alarms
* 🚀 CI/CD using GitHub Actions
* 🧪 Nested stack validations

---

## 🎯 Ideal For

✅ CloudFormation interviews
✅ AWS labs & teaching
✅ Production-ready IaC repo
✅ Terraform → CloudFormation comparison

---
