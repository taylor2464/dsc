configuration Workstation
{
    param
    (
        [Parameter(Mandatory)]
        [string] $keyVaultName,
 
        [Parameter(Mandatory)]
        [string] $usernameSecretName,
 
        [Parameter(Mandatory)]
        [string] $passwordSecretName,
 
        [Parameter(Mandatory)]
        [string] $automationConnectionName
    )
 
    Import-DscResource -ModuleName PSDesiredStateConfiguration
 
    $automationConnection = Get-AutomationConnection -Name $automationConnectionName
    Connect-AzAccount -Tenant $automationConnection.TenantID -ApplicationId $automationConnection.ApplicationID -CertificateThumbprint $automationConnection.CertificateThumbprint
 
    $username = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $usernameSecretName).SecretValueText
 
    $password = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $passwordSecretName).SecretValue
 
    $credentials = New-Object System.Management.Automation.PSCredential ($username, $password)
 
    Node SampleWorkstation
    {
        User NonAdminUser
        {
            UserName = $username
            Password = $credentials
        }
    }
    # Define your resources using the PSDscResources module
    Environment EnvironmentExample
    {
        Ensure = "Present"  # You can also set Ensure to "Absent"
        Name   = "TestEnvironmentVariable"
        Value  = "TestValue"
    }

    Package VLC
    {
        Name = "VLC"
        ProductId = "" # PID is empty because it's an exe and those don't get PIDs. The field is required but can be left empty.
        Ensure = "Present"
        Path = "C:\Software\vlc-3.0.21-win64.exe"
        Arguments = "/S /L=1033"
    }
}