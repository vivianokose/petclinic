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
