# AWS SSM Temporary RDP User

The repo contains a single script which can be run from the command line in the AWS SSM console to create a temporary local admin account.

Run the command:

```powershell
  iex $(iwr 'https://raw.githubusercontent.com/grolston/SsmTempRdpUser/master/SsmTempRdpUser.ps1' -UseBasicParsing).Content
```
