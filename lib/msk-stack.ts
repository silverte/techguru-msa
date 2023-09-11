import * as msk from '@aws-cdk/aws-msk-alpha';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Stack, StackProps, Tags } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { LogGroup } from 'aws-cdk-lib/aws-logs';
import { Bucket } from 'aws-cdk-lib/aws-s3';
import * as cdk from 'aws-cdk-lib';

export class MskStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, 'Vpc', {
      vpcName: 'vpc-techguru',
    });

    const securityGroup = new ec2.SecurityGroup(this, 'MskSecurityGroup', {
      vpc,
      securityGroupName: 'scg-eda-msk',
    });
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(9092));
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(2181));

    const cluster = new msk.Cluster(this, 'Cluster', {
      clusterName: 'msk-eda',
      kafkaVersion: msk.KafkaVersion.V2_6_2,
      vpc,
      vpcSubnets: { subnetGroupName: 'Msk' },
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.SMALL),
      securityGroups: [securityGroup],
      encryptionInTransit: {
        clientBroker: msk.ClientBrokerEncryption.PLAINTEXT,
      },
      logging: {
        cloudwatchLogGroup: new LogGroup(this, 'msk-log-group', {}),
        s3: {
          bucket: new Bucket(this, 's3-msk-log'),
          prefix: 'msk',
        },
      },
      monitoring: {
        clusterMonitoringLevel: msk.ClusterMonitoringLevel.PER_TOPIC_PER_PARTITION,
      },
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      numberOfBrokerNodes: 1,
    });
    Tags.of(cluster).add('Name', 'mks-eda');

    new cdk.CfnOutput(this, 'bootstrap-brokers', {
      value: cluster.bootstrapBrokers,
      exportName: 'bootstrap-brokers',
    });

    new cdk.CfnOutput(this, 'zookeeper-connection-string', {
      value: cluster.zookeeperConnectionString,
      exportName: 'zookeeper-connection-string',
    });
  }
}
