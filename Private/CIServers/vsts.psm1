function Write-VSTSBuildNumber([string] $buildNumber) {
    Write-VSTSLoggingCommand 'build.updatebuildnumber' $buildNumber
}
Set-Alias VSTS-BuildNumber Write-VSTSBuildNumber

function Write-VSTSImportNUnitReport([Parameter(ValueFromPipeline)][string]$path) {
	process {
		Write-VSTSLoggingCommand 'results.publish' '' @{ type='NUnit'; resultFiles=$path }
	}
}
Set-Alias VSTS-ImportNUnitReport Write-VSTSImportNUnitReport

function Write-VSTSPublishArtifact([Parameter(ValueFromPipeline)][string]$path) {
	process {
        # Not sure how to do it based on https://github.com/Microsoft/vsts-tasks/blob/master/docs/authoring/commands.md
        # build.uploadlog?
        # artifact.upload?
        # artifact.associate?
        # task.uploadfile?
        # task.addattachment?
		Write-Warning "Publishing Artifacts for VSTS is not implemented..."
	}
}
Set-Alias VSTS-PublishArtifact Write-VSTSPublishArtifact

function Write-VSTSLoggingCommand([string]$Name, [string]$Message, [hashtable]$Properties) {
    if($Properties) {
        $propertiesString = ($Properties.GetEnumerator() |
            %{ "{0}={1}" -f $_.Key, $_.Value }) -join ';'
        $propertiesString = ' ' + $propertiesString
    } else {
        $propertiesString = ''
    }

    Write-Host "##vso[$Name$propertiesString]$Message" -Fore Magenta
}

Export-ModuleMember -Function * -Alias *
