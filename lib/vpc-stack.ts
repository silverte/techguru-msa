import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

export class VpcStack extends Stack {
  public readonly vpc: ec2.Vpc;
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);

    this.vpc = new ec2.Vpc(this, 'TechGuru', {
      vpcName: 'vpc-techguru',
      availabilityZones: [
        Stack.of(this).availabilityZones[0],
        Stack.of(this).availabilityZones[1],
        Stack.of(this).availabilityZones[2],
      ],
      subnetConfiguration: [
        {
          cidrMask: 22,
          name: 'Ingress',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 22,
          name: 'App',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 26,
          name: 'Msk',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
        {
          cidrMask: 26,
          name: 'Rds',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
      ],
      natGatewayProvider: ec2.NatProvider.gateway(),
      natGateways: 3,
      natGatewaySubnets: {
        subnetGroupName: 'Ingress',
      },
    });
    this.vpc.addInterfaceEndpoint('codecommit', {
      service: ec2.InterfaceVpcEndpointAwsService.CODECOMMIT,
    });
    this.vpc.addInterfaceEndpoint('ec2', {
      service: ec2.InterfaceVpcEndpointAwsService.EC2,
    });
    this.vpc.addInterfaceEndpoint('ecr', {
      service: ec2.InterfaceVpcEndpointAwsService.ECR,
    });
    this.vpc.addInterfaceEndpoint('ecr-dkr', {
      service: ec2.InterfaceVpcEndpointAwsService.ECR_DOCKER,
    });
    this.vpc.addInterfaceEndpoint('eks', {
      service: ec2.InterfaceVpcEndpointAwsService.EKS,
    });
    this.vpc.addInterfaceEndpoint('elasticloadbalancing', {
      service: ec2.InterfaceVpcEndpointAwsService.ELASTIC_LOAD_BALANCING,
    });
    this.vpc.addInterfaceEndpoint('lambda', {
      service: ec2.InterfaceVpcEndpointAwsService.LAMBDA,
    });
    this.vpc.addInterfaceEndpoint('git-codecommit', {
      service: ec2.InterfaceVpcEndpointAwsService.CODECOMMIT_GIT,
    });
    this.vpc.addInterfaceEndpoint('logs', {
      service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
    });
    this.vpc.addInterfaceEndpoint('monitoring', {
      service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_MONITORING,
    });
    this.vpc.addInterfaceEndpoint('secretsmanager', {
      service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
    });
    this.vpc.addInterfaceEndpoint('sts', {
      service: ec2.InterfaceVpcEndpointAwsService.STS,
    });

    ec2.Vpc.fromLookup(this, 'VpcLookUp', {
      vpcName: 'vpc-techguru',
    });
  }
}
