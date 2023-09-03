import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as rds from "aws-cdk-lib/aws-rds";
import { Construct } from "constructs";
import * as cdk from "aws-cdk-lib";

const MYSQL_ENGINE_VERSION = rds.AuroraMysqlEngineVersion.VER_2_11_3;
const RDS_INSTANCE_CLASS = ec2.InstanceClass.T3;
const RDS_INSTANCE_SIZE = ec2.InstanceSize.SMALL;
export const RDS_PORT = 3396;

export enum RdsName {
  CUSTOMER = "customer",
  ORDER = "order",
}

export type Parameters = {
  [key: string]: string;
};

export interface RdsConstructProps {
  readonly rdsName: RdsName;
  readonly vpc: ec2.IVpc;
  readonly securityGroups: ec2.ISecurityGroup[];
  readonly clusterParameters?: Parameters;
  readonly parameters?: Parameters;
  readonly rdsEngineVersion?: any;
  readonly instanceClass?: ec2.InstanceClass;
  readonly instanceSize?: ec2.InstanceSize;
}

export class RdsConstruct extends Construct {
  public readonly clusterParameterGroup: rds.ParameterGroup;
  public readonly parameterGroup: rds.ParameterGroup;
  public readonly cluster: rds.DatabaseCluster;

  /**
   * RDS Construct
   * - subnetGroup 생성: Access Controll Subnets
   * - clusterParameterGroup 생성: RDS 클러스터 파라미터 설정
   * - parameterGroup 생성: RDS 인스턴스 파라미터 설정
   * - RDS Cluster 생성: secrurityGroup 세팅 필요
   */
  constructor(scope: Construct, id: string, props: RdsConstructProps) {
    super(scope, id);
    const rdsVersion = props.rdsEngineVersion || MYSQL_ENGINE_VERSION;

    const subnetGroup = new rds.SubnetGroup(this, `RdsSubnetGroup-${props.rdsName}`, {
      description: "Subnet Group for RDS",
      vpc: props.vpc,
      subnetGroupName: `sng-rds-${props.rdsName}`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      vpcSubnets: { subnetGroupName: "Rds" },
    });

    this.clusterParameterGroup = new rds.ParameterGroup(this, `ClusterParameterGroup-${props.rdsName}`, {
      engine: rds.DatabaseClusterEngine.auroraMysql({
        version: rdsVersion,
      }),
      parameters: props.clusterParameters || {},
    });

    this.parameterGroup = new rds.ParameterGroup(this, `ParameterGroup-${props.rdsName}`, {
      engine: rds.DatabaseClusterEngine.auroraMysql({
        version: rdsVersion,
      }),
      parameters: props.parameters || {},
    });

    this.cluster = new rds.DatabaseCluster(this, `Database-${props.rdsName}`, {
      engine: rds.DatabaseClusterEngine.auroraMysql({
        version: rdsVersion,
      }),
      vpc: props.vpc,
      credentials: rds.Credentials.fromPassword("admin", new cdk.SecretValue("admin123")),
      writer: rds.ClusterInstance.provisioned("writer", {
        instanceType: ec2.InstanceType.of(
          props.instanceClass || RDS_INSTANCE_CLASS,
          props.instanceSize || RDS_INSTANCE_SIZE
        ),
        parameterGroup: this.parameterGroup,
        //enablePerformanceInsights: true,
        autoMinorVersionUpgrade: false,
        instanceIdentifier: `rds-${props.rdsName}-writer`,
      }),
      port: RDS_PORT,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      subnetGroup: subnetGroup,
      parameterGroup: this.clusterParameterGroup,
      clusterIdentifier: `rds-${props.rdsName}`,
      securityGroups: props.securityGroups,
      storageEncrypted: true,
    });
  }
}
