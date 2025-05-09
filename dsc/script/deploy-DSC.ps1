Param (
    [Parameter(Mandatory=$True)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$True)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$True)]
    [string]$AutomationAccountName,
    [Parameter(Mandatory=$True)]
    [string]$StorageAccountName,
    [Parameter(Mandatory=$True)]
    [string]$ConfigurationPath,
    [Parameter(Mandatory=$False)]
    [string]$ActionAfterReboot = "ContinueConfiguration",
    [Parameter(Mandatory=$False)]
    [string]$ConfigurationMode = "ApplyAndAutocorrect",
    [Parameter(Mandatory=$False)]
    [int]$ConfigurationModeFrequencyMins = 15,
    [Parameter(Mandatory=$False)]
    [int]$RefreshFrequencyMins = 30,
    [Parameter(Mandatory=$False)]
    [bool]$RebootNodeIfNeeded = $true,
    [Parameter(Mandatory=$False)]
    [bool]$AllowModuleOverwrite = $true
)

# Do we want to verify the build server dependencies for compiling the configuration file?
# https://github.com/RamblingCookieMonster/PSDepend

# Compile the configuration file on the build server
if (Test-Path $ConfigurationPath) {
    & $ConfigurationPath
    $ConfigContent = Get-Content $ConfigurationPath -Raw
    # When we compile the configuration file, it will create a folder with the Configuration name in that file's content. The file name doesn't matter.
    $ConfigContent -match "Configuration\s(.*)\s{"
    $ConfigName = $Matches[1]
}
else {
    Write-Host "Configuration file not found at $ConfigurationPath"
    exit 1
}

# https://learn.microsoft.com/en-us/powershell/module/az.automation/import-azautomationdscnodeconfiguration?view=azps-13.2.0
Import-AzAutomationDscNodeConfiguration -Path ".\$($ConfigName)\localhost.mof" -ConfigurationName $ConfigName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName

# Capture Virtual Machines in the Resource Group (we may need to switch this to a subscription scope?)
$VMs = Get-AzVM -ResourceGroupName $ResourceGroupName

foreach ($vm in $VMs) {
    # VM Already has extension installed. Extensions is a list as there can be multiple extensions installed on a VM.
    if ($vm.Extensions.Id -like "*Microsoft.Powershell.DSC*") {
        continue
    }

    $params = @{  
        AzureVMName                    = $vm.Name
        ResourceGroupName              = $ResourceGroupName 
        AutomationAccountName          = $AutomationAccountName
        NodeConfigurationName          = "MyConfig.MyConfig"  
        ActionAfterReboot              = $ActionAfterReboot
        ConfigurationMode              = $ConfigurationMode 
        ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
        RefreshFrequencyMins           = $RefreshFrequencyMins 
        RebootNodeIfNeeded             = $RebootNodeIfNeeded 
        AllowModuleOverwrite           = $AllowModuleOverwrite
    }
    Register-AzAutomationDscNode @params

}
