#requires -Version 4 -Modules Pester

Describe 'Write-VSTSLoggingCommand' {
    BeforeAll {
        # Redirect Write-Host to Write-Output so that we can capture it and check it.
        function global:Redirect-HostToOutput-ForTest { Write-Output $Args[0] }
        New-Alias -Name Write-Host -Value Redirect-HostToOutput-ForTest -Force -Scope Global
    }

    AfterAll {
        # Cleanup the alias we created for the tests
        Remove-Item alias:\Write-Host -Force
    }


    It 'should handle missing -Properties' {
        Write-VSTSLoggingCommand 'area.action' 'message' | Should Be '##vso[area.action]message'
    }

    It 'should pass -Properties properly' {
        Write-VSTSLoggingCommand 'area.properties' 'this is a message' -Properties @{
            prop1 = 'value1'
            prop2 = 'value2'
        } | Should Be '##vso[area.properties prop2=value2;prop1=value1]this is a message'
    }

}
