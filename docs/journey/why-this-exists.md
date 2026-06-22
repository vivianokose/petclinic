## AWS access keys and rotation

What it is: Long-lived credentials that give programmatic access to AWS. Anyone with the key + secret can do anything the IAM user is allowed to do.

Why I need it: Locally, the AWS CLI uses these to authenticate API calls. Terraform, kubectl (for EKS), and Kimchi all read these credentials through the AWS CLI.

What I learned the hard way: Secret keys must NEVER appear in chat logs, screenshots, blog posts, Slack messages, git commits, or anywhere outside a vault or local config file. I leaked mine once in a chat. The fix is rotation. Deactivate, delete, create new, update locally. Takes 5 minutes. If a key leaks publicly (like in a GitHub commit), AWS sometimes auto-quarantines the account.

How to avoid it next time: Before pasting anything from a terminal into a chat, scan for: access keys (AKIA*), secret keys (40-char random strings), private keys (BEGIN RSA), passwords. When in doubt, paste-then-redact.


## IRSA (IAM Roles for Service Accounts)

What it is: A way to give individual Kubernetes pods temporary AWS credentials, scoped to a specific IAM role.

Why I need it: Pods often need to do things in AWS (read S3, pull secrets, update load balancers). Without IRSA, you either hard-code credentials (insecure) or give the whole node broad IAM permissions (overprivileged). IRSA scopes credentials per service account, per pod.

How it works: EKS hosts an OIDC issuer. AWS IAM trusts the issuer. Pods get signed tokens from EKS. They exchange those tokens with STS for temporary AWS credentials.

What breaks without it: Pods cannot safely access AWS APIs. External Secrets Operator and AWS Load Balancer Controller both depend on it.

## Why no launch template for EKS managed node groups

What I tried first: A custom launch template attached to the managed node group to inject our VPC's eks_node security group.

What broke: The vpc_security_group_ids in the launch template did not propagate cleanly to the node group at creation. The node group failed to launch instances. EKS add-ons that depend on running pods (coredns, ebs-csi-driver) stuck in Pending for 41 minutes before timing out.

What I do instead: Let the AWS-managed node group create its own security group automatically. Set disk_size and instance_types directly on the node group resource. If we need to add custom rules to the auto-created SG later (for example to allow RDS access), we add them as standalone aws_vpc_security_group_ingress_rule resources after the node group exists.

When to use a launch template: When you need things AWS-managed node groups do not support natively. Custom AMIs, complex network interfaces, EC2 user data scripts. For standard cluster setups with default networking, skip it.

The lesson: when documentation pushes you toward a more complex pattern (launch template) when a simpler one (disk on node group) works for your needs, go simpler. Add complexity only when a real requirement forces you to.

## Why the EBS CSI driver is not installed in Phase 1

What it is: An EKS add-on that lets pods request persistent storage on EBS volumes.

Why it failed to install initially: The EBS CSI controller pod tries to make AWS API calls to create and attach volumes. Without IRSA (IAM Roles for Service Accounts) mapping a service account to an IAM role with EBS permissions, the controller has no AWS credentials and crash loops trying to authenticate.

What I am doing instead: Removed the add-on from Phase 1. Will add it back in Phase 4 when I set up IRSA properly. Phase 1 and Phase 2 (RDS) do not need persistent volumes.

Lesson: Add-ons that need AWS API access need IRSA. Installing them without IRSA results in healthy-looking pods that cannot do their job. EKS reports the add-on as DEGRADED or CREATING, which is correct from AWS's perspective.

## Why the EBS CSI driver is not installed in Phase 1

What it is: An EKS add-on that lets pods request persistent storage on EBS volumes.

Why it failed to install initially: The EBS CSI controller pod tries to make AWS API calls to create and attach volumes. Without IRSA (IAM Roles for Service Accounts) mapping a service account to an IAM role with EBS permissions, the controller has no AWS credentials and crash loops trying to authenticate.

What I am doing instead: Removed the add-on from Phase 1. Will add it back in Phase 4 when I set up IRSA properly. Phase 1 and Phase 2 (RDS) do not need persistent volumes.

Lesson: Add-ons that need AWS API access need IRSA. Installing them without IRSA results in healthy-looking pods that cannot do their job. EKS reports the add-on as DEGRADED or CREATING, which is correct from AWS's perspective.

## What I learned by failing five times in a row

Real engineering is not "code works first try." Real engineering is the discipline 
to diagnose calmly when things fail. Every senior engineer I will ever interview with 
has stories like this one. The difference between a junior and a senior is not that 
seniors have fewer failures. It is that seniors stay calm, ask better questions, 
and write down what they learned.

I now know how to read a Terraform plan, decode an EKS error, manually create AWS 
resources to isolate the failure, and fix configuration issues without panic. None 
of that is on a certification syllabus. All of it matters in the actual job.
