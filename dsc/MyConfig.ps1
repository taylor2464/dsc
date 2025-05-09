Configuration MyConfig {

    #  Previously:

    #  Import-DscResource -ModuleName Microsoft.Windows.DesiredStateConfiguration

    # Now using PSDscResources:
    Import-DscResource -ModuleName PSDscResources 
    # Define your resources using the PSDscResources module
    Environment EnvironmentExample
    {
        Ensure = "Present"  # You can also set Ensure to "Absent"
        Name   = "TestEnvironmentVariable"
        Value  = "TestValue"
    }
}

MyConfig