## Day 1 - Phase 1 starts

What I did: Verified environment (AWS, Terraform, Kimchi all good). Fixed AGENTS.md to use us-east-1 instead of eu-central-1. Updated account ID in AGENTS.md from the template default to my own. Launched Kimchi in plan mode, confirmed it read AGENTS.md correctly. Switched to execute mode and scaffolded the Terraform directory structure: 2 environments (dev, prod) and 7 modules (vpc, eks, ecr, rds, dns, secrets, karpenter). 38 empty .tf files total.
What I learned: Terraform projects follow a modules-and-environments split. Modules are reusable recipes (VPC, EKS, etc). Environments instantiate those recipes with their own parameters. Each module needs main.tf, variables.tf, outputs.tf, versions.tf. This pattern is universal across serious Terraform codebases.
What I still need to understand: What actually goes inside variables.tf vs main.tf? When does something become a variable vs hardcoded? That's tomorrow when we write the VPC module.

TODO: backend.tf uses dynamodb_table parameter which is deprecated.
The replacement is use_lockfile. Need to research what use_lockfile
actually does and migrate when next refactoring.

## Day 1 evening - Phase 1 VPC applied

What I did: Wrote a Terraform VPC module with Kimchi's help. Wired it into the dev environment. Connected the dev environment to my real S3 state backend. Ran terraform init, validate, plan, and apply against my actual AWS account. Created 21 resources in roughly 90 seconds.

What broke and how I fixed it: Pasted my AWS secret key in a chat by accident. Rotated the key, cleaned up profile config, and learned to scan for secrets before pasting any terminal output anywhere. Also realized my local repo was still pointing at the source author's GitHub, not mine. Created my own repo and switched the remote.

What I learned today:
- A VPC is your private slice of AWS. Without it, nothing else can be built.
- Subnets need specific Kubernetes tags or EKS will refuse to use them.
- The "default_tags" block in the AWS provider stamps every resource with consistent metadata. Free organizational discipline.
- Public subnets have a route to an Internet Gateway. That route is what makes them "public." Take it away and the same subnet becomes private.
- Security groups can reference each other by ID, not just by IP. This is the cleanest way to express "anything in the EKS node group can reach RDS."
- terraform plan -out plan.out + terraform apply plan.out is the safe pattern. Never apply without a saved plan.
- State in S3 + DynamoDB lock = team-safe Terraform. Never trust local state on a real project.

What I still need to understand:
- The "use_lockfile" backend parameter (replacement for dynamodb_table). Need to research.
- IRSA (the thing AGENTS.md keeps mentioning for the EKS module). I will learn it tomorrow.

Cost so far: $0. VPC is free. Apply took 90 seconds, and I have my first piece of real cloud infrastructure.

## EKS module insights, written while terraform apply runs

IAM roles vs IAM users: A user has a permanent password. A role is an identity that something else assumes temporarily. EKS needs a role because it does things on my behalf in my account (creating EC2 instances, attaching ENIs, managing load balancers). Nodes need a role because each EC2 instance must register with the cluster and pull container images.

The OIDC trick: An EKS cluster comes with a built-in identity issuer URL. When I register that URL as an OIDC provider in IAM, IAM agrees to trust tokens signed by the cluster. Now a pod in the cluster can prove "I am pod X with service account Y" and IAM will hand it temporary AWS credentials. This is IRSA. The alternative is giving every node every permission, which is overkill.

Why the launch template exists: AWS-managed node groups create their own security group by default. But my VPC already has a carefully crafted eks_node SG with RDS rules and inter-node rules. Launch template lets me override AWS's default and use my SG. Without this, my pods would never reach RDS.

Cost decision I made: t3.small instead of t4g.small in us-east-1 because Graviton free trial is us-east-2 only. Cost of two t3.small nodes 24/7 is roughly $30/month, but with stop-env.sh discipline I expect to spend $5 to $10 total this phase. Tradeoff documented.


Terraform state recovery: When my first EKS apply failed due to the 1.29 version error,
Terraform did not lose track of what had already been created. The launch template and
IAM roles were already in AWS, and the next plan showed only the 7 resources that still
needed to be made. State is what makes Terraform restartable. Bash scripts cannot do this.

Tainted resources: when Terraform creates a resource but it ends up in a broken state
(timeout, error during config), Terraform marks it as "tainted" in state. The next plan
sees the taint and proposes destroy-and-recreate. This is how Terraform self-heals from
partial failures without needing manual intervention. You see the `-/+` symbol in the
plan to indicate destroy-and-replace.

## End of session 1 - EKS deferred to tomorrow

Tonight: applied VPC successfully (21 resources). Then attempted EKS twice. First try failed on Kubernetes 1.29 retirement (AWS no longer supports it for new clusters, picked 1.34). Second try failed on launch template + managed node group interaction: launch template did not get the vpc_security_group_ids attribute into AWS for reasons I will dig into, node group never created, add-ons stuck Pending waiting for nodes.

What I am taking away: EKS managed node groups + launch templates have known interaction quirks. The cleaner production pattern is to skip the launch template and let AWS-managed node groups create their own SG, then add ingress rules to that SG separately. Tomorrow I rebuild EKS without a launch template.

Cost so far: ~$0.30 in EKS control plane time. Budget alert quiet. Destroying tonight to stop the meter.

Lesson: failed apply does not mean failed learning. The diagnostics I ran tonight (aws eks describe-cluster, kubectl describe pods, aws ec2 describe-launch-template-versions) are exactly the kind of debugging skills the role demands. I would not have learned them if everything just worked.

Terraform provider validation catches typos before AWS sees them. The list of valid 
enum values is compiled into the provider plugin. When I typed AL2023_x86_64 instead 
of AL2023_x86_64_STANDARD, Terraform refused to even submit the plan. This is one 
of the reasons terraform validate matters - it surfaces these kinds of errors 
instantly.

## Phase 1 complete - working EKS cluster

After two days, three failed apply attempts, four distinct errors, and one diagnostic 
manual node group creation via AWS CLI, I have a working EKS cluster on AWS.

Final cluster state:
- Kubernetes 1.34, AL2023_x86_64_STANDARD AMI
- 2x t3.small nodes Ready, spread across us-east-1a and us-east-1b
- coredns, kube-proxy, vpc-cni add-ons all Running
- OIDC provider configured for future IRSA setup
- All Terraform outputs resolving correctly

The four errors I worked through:
1. Kubernetes 1.29 retired by AWS for new clusters → upgraded to 1.34
2. Launch template + managed node group SG injection silently failing → removed the launch template entirely
3. AL2_x86_64 not supported for Kubernetes 1.33+ → switched to AL2023_x86_64_STANDARD
4. Add-ons in parallel-create race with node group → added explicit depends_on from add-on to node group

Things I learned that no tutorial would have taught me:
- Provider validation catches enum typos before AWS sees them (saved me on AL2023_x86_64_STANDARD)
- Failed apply does not corrupt state. Whatever succeeded is tracked, only the failure 
  is missing. Retry just resumes.
- When in doubt, create the resource manually via AWS CLI to see the real error AWS 
  returns. If AWS accepts what Terraform sent, the problem is Terraform timing or 
  dependencies, not the request itself.
- EKS add-ons that need AWS API access (like aws-ebs-csi-driver) require IRSA. Installing 
  them without IRSA gives you a healthy-looking pod that cannot do its job.
- The aws_eks_addon resource is opinionated about waiting for ACTIVE state. If something 
  upstream is broken, the add-on apply times out at 20 minutes and the real error is 
  buried under the timeout.

Cost so far: ~$1.20 in EKS control plane time across the failed attempts. The budget 
alert at $20 has not triggered. Well within target.

Next phase: stop the environment to save cost while I write content, then come back 
fresh for Phase 2 (RDS MySQL).
