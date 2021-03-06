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
      [String]$Password,
      # HoursFromNow help description
      [Parameter(Mandatory=$true,
                  ValueFromPipelineByPropertyName=$false,
                  Position=0)]
      [int]$HoursFromNow
  )

  BEGIN{}

  PROCESS{



    $Comment = "User added on $(Get-Date) by $($env:USERNAME) for $HoursFromNow"
    # Create new local Admin user for script purposes
    $Computer = [ADSI]"WinNT://$env:COMPUTERNAME,Computer"
    write-host "Adding User $Username"
    $LocalAdmin = $Computer.Create("User", $UserName )
    $LocalAdmin.SetPassword($Password)
    $LocalAdmin.SetInfo()
    write-host "Removing password variable"
    Remove-Variable -Name Password
    $LocalAdmin.FullName = "$UserName from Cloud Command"
    $LocalAdmin.SetInfo()
    $LocalAdmin.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
    $LocalAdmin.SetInfo()

    ## Add to local admin group
    Write-Host "Adding $Username to local admin group"
    NET LOCALGROUP "Administrators" $UserName /add

    ## Scheduled removal
    $JobName = "Remove temp user $Username"
    $ScriptString ="NET USER $Username /DELETE; Unregister-ScheduledJob -Name $JobName"
    $ScriptBlock = [Scriptblock]::Create($ScriptString)
    $RunAt = $(Get-Date).AddHours($HoursFromNow)
    $trigger = New-JobTrigger -Once -At $Runat
    Write-Host "Creating scheduled deletion for $Username in $HoursFromNow hours from now at $Runat"
    Register-ScheduledJob -Name "Remove User $Username" -Trigger $trigger -ScriptBlock $scriptBlock
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
$Password = Read-Host -Prompt "Enter the password containing 12 characters containing at least two numeric values" -AsSecureString

[int]$HoursFromNow = Get-HoursFromNow
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$StrPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
Add-RdpUser -Username $Username -Password $StrPass -HoursFromNow $HoursFromNow