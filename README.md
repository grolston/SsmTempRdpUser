# AWS SSM Temporary RDP User

The repo contains a single script which can be run from the command line in the AWS SSM console to create a temporary local admin account.

Run the command:

```powershell
  ## set TLS for windows ps session
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  ## command to start interactive temporary rdp user
  iex $(iwr 'https://raw.githubusercontent.com/grolston/SsmTempRdpUser/master/SsmTempRdpUser.ps1' -UseBasicParsing).Content
```
