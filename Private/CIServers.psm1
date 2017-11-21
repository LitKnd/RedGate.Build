
if($env:TEAMCITY_VERSION) {
    $CIServer = 'Teamcity'
} elseif($env:TF_BUILD) {
    $CIServer = 'VSTS'
} else {
    $CIServer = 'Unknown'
}

. $PSScriptRoot\CIServers\teamcity.ps1 -Force
. $PSScriptRoot\CIServers\vsts.ps1 -Force



Export-ModuleMember -Function * -Alias * -Variable CIServer
