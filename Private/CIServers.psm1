
if($env:TEAMCITY_VERSION) {
    $CIServer = 'Teamcity'
} elseif($env:TF_BUILD) {
    $CIServer = 'VSTS'
} else {
    $CIServer = 'Unknown'
}

Import-Module $PSScriptRoot\CIServers\teamcity.psm1 -Force
Import-Module $PSScriptRoot\CIServers\vsts.psm1 -Force


function Write-CIBuildNumber([string]$buildNumber) {
    switch ($CIServer)
    {
        'Teamcity' { Write-TeamCityBuildNumber $buildNumber }
        'VSTS' { Write-VSTSBuildNumber $buildNumber }
        Default { $buildNumber }
    }
}

Export-ModuleMember -Function * -Alias * -Variable CIServer
