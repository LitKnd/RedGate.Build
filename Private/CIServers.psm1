
function Get-CIServer {
    if($env:TEAMCITY_VERSION) { return 'Teamcity' }
    if($env:TF_BUILD) { return 'VSTS' }
    return 'Unknown'
}

Import-Module $PSScriptRoot\CIServers\teamcity.psm1 -Force
Import-Module $PSScriptRoot\CIServers\vsts.psm1 -Force


function Write-CIBuildNumber([string]$buildNumber) {
    switch (Get-CIServer)
    {
        'Teamcity' { Write-TeamCityBuildNumber $buildNumber }
        'VSTS' { Write-VSTSBuildNumber $buildNumber }
        Default { $buildNumber }
    }
}

Export-ModuleMember -Function * -Alias *
