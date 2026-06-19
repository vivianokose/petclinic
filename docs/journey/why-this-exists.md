## AWS access keys and rotation

What it is: Long-lived credentials that give programmatic access to AWS. Anyone with the key + secret can do anything the IAM user is allowed to do.

Why I need it: Locally, the AWS CLI uses these to authenticate API calls. Terraform, kubectl (for EKS), and Kimchi all read these credentials through the AWS CLI.

What I learned the hard way: Secret keys must NEVER appear in chat logs, screenshots, blog posts, Slack messages, git commits, or anywhere outside a vault or local config file. I leaked mine once in a chat. The fix is rotation. Deactivate, delete, create new, update locally. Takes 5 minutes. If a key leaks publicly (like in a GitHub commit), AWS sometimes auto-quarantines the account.

How to avoid it next time: Before pasting anything from a terminal into a chat, scan for: access keys (AKIA*), secret keys (40-char random strings), private keys (BEGIN RSA), passwords. When in doubt, paste-then-redact.
