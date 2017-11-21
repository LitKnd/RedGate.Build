Import-Module $PSScriptRoot\CIServers\teamcity.psm1 -Force
Import-Module $PSScriptRoot\CIServers\vsts.psm1 -Force

function Get-CIServer {
    if($env:TF_BUILD) { return 'VSTS' }
    return 'Teamcity' # Default to Teamcity to match our old behaviour
}

function Write-CIBuildNumber([string]$buildNumber) {
    & "Write-$(Get-CIServer)BuildNumber" $buildNumber
}

function Write-CIImportNUnitReport([Parameter(ValueFromPipeline)][string]$path) {
    process {
        & "Write-$(Get-CIServer)ImportNUnitReport" $path
    }
}

Export-ModuleMember -Function * -Alias *
