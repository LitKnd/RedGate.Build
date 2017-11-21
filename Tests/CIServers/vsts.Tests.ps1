#requires -Version 4 -Modules Pester

Describe 'Write-VSTSLoggingCommand' {

    # Redirect Write-Host to Write-Output so that we can capture it and check it.
    function global:Redirect-HostToOutput-ForTest { Write-Output $Args[0] }
    New-Alias -Name Write-Host -Value Redirect-HostToOutput-ForTest -Force -Scope Global

    It 'should handle missing -Properties' {
        Write-VSTSLoggingCommand 'area.action' 'message' | Should Be '##vso[area.action ]message'
    }

    # Cleanup the alias we created for the tests
    Remove-Item alias:\Write-Host -Force
}
