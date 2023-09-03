import { App } from "aws-cdk-lib";
import { VpcStack } from "../lib/vpc-stack";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as blueprints from "@aws-quickstart/eks-blueprints";
import * as eks from "aws-cdk-lib/aws-eks";
import { MskStack } from "../lib/msk-stack";
import { RdsOrderStack } from "../lib/rds-order-stack";
import { RdsCustomerStack } from "../lib/rds-customer-stack";

const stackProps = {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
};

const app = new App();

const vpcStack = new VpcStack(app, "Vpc", stackProps);

const vpc = ec2.Vpc.fromLookup(vpcStack, "Vpc", {
  vpcName: "vpc-techguru",
});

console.log(vpc.vpcId);

const addOns: Array<blueprints.ClusterAddOn> = [
  new blueprints.addons.ArgoCDAddOn(),
  new blueprints.addons.CalicoOperatorAddOn(),
  new blueprints.addons.MetricsServerAddOn(),
  new blueprints.addons.ClusterAutoScalerAddOn(),
  new blueprints.addons.AwsLoadBalancerControllerAddOn(),
  new blueprints.addons.VpcCniAddOn(),
  new blueprints.addons.CoreDnsAddOn(),
  new blueprints.addons.KubeProxyAddOn(),
];

blueprints.EksBlueprint.builder()
  .version(eks.KubernetesVersion.V1_27)
  .account(stackProps.env.account)
  .region(stackProps.env.region)
  .addOns(...addOns)
  .withBlueprintProps({})
  .resourceProvider(blueprints.GlobalResources.Vpc, new blueprints.VpcProvider(vpc.vpcId))
  .useDefaultSecretEncryption(false) // set to false to turn secret encryption off (non-production/demo cases)
  .build(app, "Eks");

//new MskStack(app, "Msk", stackProps);

new RdsCustomerStack(app, "RdsCustomer", stackProps);

new RdsOrderStack(app, "RdsOrder", stackProps);

app.synth();
