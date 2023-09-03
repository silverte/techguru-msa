import { Stack, StackProps } from "aws-cdk-lib";
import { Construct } from "constructs";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import { RDS_PORT, RdsConstruct, RdsName } from "./rds-construct";

export class RdsOrderStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps) {
    super(scope, id, props);

    const vpc = ec2.Vpc.fromLookup(this, "Vpc", {
      vpcName: "vpc-techguru",
    });

    const securityGroup = new ec2.SecurityGroup(this, "RdsOrderSecurityGroup", {
      vpc,
      securityGroupName: "scg-order-rds",
    });
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(RDS_PORT));

    new RdsConstruct(this, "Order", {
      rdsName: RdsName.ORDER,
      vpc,
      securityGroups: [securityGroup],
    });
  }
}
