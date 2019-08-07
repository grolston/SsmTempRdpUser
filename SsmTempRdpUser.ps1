function Test-IsAdmin {
  ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}#close Test-IsAdmin

function Get-HoursFromNow {

  [int]$HoursFromNow = Read-Host -Prompt "Enter the how many hours temporary account should exist"
  while(($HoursFromNow -GT 12) -OR ($HoursFromNow -LT 1)){

      Write-Warning "Hour entered is greater than 12 or less than 1, please enter value 1 to 12"
      [int]$HoursFromNow = Read-Host -Prompt "Enter integer the how many hours temporary account should exist (values from 1 to 12)"
  }
  $HoursFromNow
}#close Get-HoursFromNow

function Add-RdpUser {
<#
.Synopsis
 Create local admin user for short-term use
.DESCRIPTION
 Create a temporary local user that belongs to the admin group
 which can RDP to the server for access and torubleshooting.
 The local user will be deleted within 6 hours of creation.
.EXAMPLE
  Add-RdpUser -Username george -Password '$up3r$3cr3t'
#>
  Param(
      # The username for the local account
      [Parameter(Mandatory=$true,
                  ValueFromPipelineByPropertyName=$false,
                  Position=0)]
      [string]$Username,

      # Password to set for your temporary user
      [Parameter(Mandatory=$true,
                  ValueFromPipelineByPropertyName=$false,
                  Position=0)]
      [SecureString]$Password,
      # HoursFromNow help description
      [Parameter(Mandatory=$true,
                  ValueFromPipelineByPropertyName=$false,
                  Position=0)]
      [int]$HoursFromNow
  )

  BEGIN{
      $BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($Password)
      $_password = [system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR)
  }

  PROCESS{

  $Comment = "User added on $(Get-Date) by $($env:USERNAME) for $HoursFromNow"
  write-host "Adding User $Username"
  net user $Username $_password /add /comment:$Comment /fullname:"Temporary $Username" /passwordchg:NO
  write-host "Removing password variable"
  Remove-Variable $_password
  Write-Host "Adding $Username to local admin group"
  net localgroup Administrators /add $Username
  $ScriptString ="net user $Username /DELETE"
  $ScriptBlock = [Scriptblock]::Create($ScriptString )
  $RunAt = $(Get-Date).AddHours($HoursFromNow)
  $trigger = New-JobTrigger -Once -At $RunAt
  Write-Host "Creating scheduled deletion for $Username in $HoursFromNow hours from now at $Runat"
  Register-ScheduledJob -Name "Remove Temp User $Username" -Trigger $trigger -ScriptBlock $scriptBlock
  Write-Host "Scheduled delete for $Username registered"

  }
  END{}

}#close Add-RdpUser

if(!(Test-IsAdmin)){
  write-error "Session is not running with local administrative privileges. User account cannot be created." -ErrorAction Stop
}

if($PSVersionTable.PSVersion.Major -LT 3){
  write-error "PowerShell Version not supported. Please have PowerShell 3 or greater." -ErrorAction Stop
}

$Username = Read-Host -Prompt "Enter the username"
$Password = Read-Host -Prompt "Enter the password containing 12 characters containing at least two numeric values"
$Password = ConvertTo-SecureString $Password
[int]$HoursFromNow = Get-HoursFromNow

Add-RdpUser -Username $Username -Password $Password -HoursFromNow $HoursFromNow