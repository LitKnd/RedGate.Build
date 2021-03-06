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

Describe 'Write-VSTSBuildNumber' {
    BeforeAll {
        # Redirect Write-Host to Write-Output so that we can capture it and check it.
        function global:Redirect-HostToOutput-ForTest { Write-Output $Args[0] }
        New-Alias -Name Write-Host -Value Redirect-HostToOutput-ForTest -Force -Scope Global
    }

    AfterAll {
        # Cleanup the alias we created for the tests
        Remove-Item alias:\Write-Host -Force
    }

    It 'should print the right output' {
        Write-VSTSBuildNumber '1.2.3.4' | Should Be '##vso[build.updatebuildnumber]1.2.3.4'
    }
}

Describe 'Write-VSTSImportNUnitReport' {
    BeforeAll {
        # Redirect Write-Host to Write-Output so that we can capture it and check it.
        function global:Redirect-HostToOutput-ForTest { Write-Output $Args[0] }
        New-Alias -Name Write-Host -Value Redirect-HostToOutput-ForTest -Force -Scope Global
    }

    AfterAll {
        # Cleanup the alias we created for the tests
        Remove-Item alias:\Write-Host -Force
    }

    It 'should print the right output' {
        Write-VSTSImportNUnitReport  'C:\folder\myresults.txt' | Should Be '##vso[results.publish type=NUnit;resultFiles=C:\folder\myresults.txt]'
    }
}
