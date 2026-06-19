## Day 1 - Phase 1 starts

What I did: Verified environment (AWS, Terraform, Kimchi all good). Fixed AGENTS.md to use us-east-1 instead of eu-central-1. Updated account ID in AGENTS.md from the template default to my own. Launched Kimchi in plan mode, confirmed it read AGENTS.md correctly. Switched to execute mode and scaffolded the Terraform directory structure: 2 environments (dev, prod) and 7 modules (vpc, eks, ecr, rds, dns, secrets, karpenter). 38 empty .tf files total.

What I learned: Terraform projects follow a modules-and-environments split. Modules are reusable recipes (VPC, EKS, etc). Environments instantiate those recipes with their own parameters. Each module needs main.tf, variables.tf, outputs.tf, versions.tf. This pattern is universal across serious Terraform codebases.

What I still need to understand: What actually goes inside variables.tf vs main.tf? When does something become a variable vs hardcoded? That's tomorrow when we write the VPC module.
