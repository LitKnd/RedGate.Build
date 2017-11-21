function Write-VSTSBuildNumber([string] $buildNumber) {
    Write-VSTSLoggingCommand 'build.updatebuildnumber' $buildNumber
}

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
