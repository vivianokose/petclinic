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
