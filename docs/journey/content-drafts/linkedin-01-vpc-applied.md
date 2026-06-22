LinkedIn Posts

#1

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


#2
I built a working Kubernetes cluster on AWS this week.

The story isn't "I followed a tutorial and it worked." The story is:

Day 1: VPC applied clean. 21 resources, $0 cost. Took 90 seconds.

Day 2: First EKS attempt failed because the guide I was using specified 
Kubernetes 1.29, which AWS no longer supports for new clusters.

Second attempt failed because of a launch-template-plus-managed-node-group 
quirk that has no clean error message. Spent two hours diagnosing it.

Third attempt failed because I picked the wrong AMI variant. AL2_x86_64 
was deprecated on Kubernetes 1.33+. Switched to AL2023_x86_64_STANDARD.

Fourth attempt failed because of a Terraform race condition between add-ons 
and the node group. Fixed by reordering the depends_on relationships.

Fifth attempt: clean apply. Two Ready nodes. CoreDNS, vpc-cni, kube-proxy 
all running. Working cluster.

I am a biochemistry graduate, learning DevOps. I had no Kubernetes context 
six weeks ago. What I learned is that real engineering is not "code works 
first try." Real engineering is the discipline to diagnose calmly when 
things fail, to make small targeted fixes, and to write down what you 
learned so the next person (or the next you) does not have to suffer 
through the same lessons.

This is part of my DMI Cohort 2 DevOps journey. Next up: RDS MySQL, then 
ArgoCD, then deploying the actual application.

#DevOps #AWS #Kubernetes #100DaysOfCloud #WomenInTech #CareerPivot

#3


