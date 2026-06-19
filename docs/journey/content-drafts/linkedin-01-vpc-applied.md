LinkedIn Posts


I built my first AWS VPC with Terraform today.

For someone whose background is biochemistry, "VPC" sounded like jargon until two days ago. Now I have one running in my AWS account, made of 21 resources I described in code:

- A virtual private network with CIDR 10.0.0.0/16
- Two public subnets across two availability zones
- An internet gateway with a default route
- Four security groups (for EKS, RDS, and a future ALB)
- All tagged consistently, all version controlled, all defined in Terraform

What I learned that I want to share with other beginners:

1. Infrastructure as Code is not a magic skill. It is reading documentation, writing files, validating them, planning, and applying. The discipline matters more than the cleverness.

2. terraform plan -out plan.out is non-negotiable. Apply only the plan you reviewed. This is how you avoid the "wait, why did it destroy that?" moment.

3. Pasting a secret key in a chat by accident is a great way to learn key rotation. Do it once, fix it fast, never do it again.

4. Reading the resources my AI agent generates, line by line, is what turns code into knowledge. If I cannot explain it, I do not understand it.

This is part of my DevOps journey through the DMI Cohort 2 program. Next up: EKS, which is the actual Kubernetes cluster that will run on this VPC.

If you are pivoting into DevOps from another field, here is what I wish someone had told me: you do not need a Computer Science degree. You need patience, documentation, and the willingness to break things in a sandbox.

#DevOps #Terraform #AWS #100DaysOfCloud #WomenInTech #CareerPivot
