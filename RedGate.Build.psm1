[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ciServersModule = Import-Module $PSScriptRoot\Private\CIServers.psm1 -DisableNameChecking -PassThru


Get-ChildItem "$PSScriptRoot\Private\" -Filter *.ps1 -Recurse |
    ForEach {
      . $_.FullName
    }


Get-ChildItem "$PSScriptRoot\Public\" -Filter *.ps1 -Recurse |
    ForEach {
      . $_.FullName
      Export-ModuleMember -Function $_.BaseName
    }


if ($Host.Name -ne "Default Host") {
  Write-Host "RedGate.Build is using its own nuget.exe. Version $((Get-Item $nugetExe).VersionInfo.FileVersion)"
}

# Export all the functions from the CIServers module
Get-Command -Module $ciServersModule -CommandType Function | Export-ModuleMember

# Always export all aliases.
Export-ModuleMember -Alias *

# For debug purposes, uncomment this to export all functions of this module.
# Export-ModuleMember -Function *
