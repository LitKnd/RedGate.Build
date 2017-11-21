
function Write-VSTSLoggingCommand([string]$Name, [string]$Message, [hashtable]$Properties) {
    if($Properties) {
        $propertiesString = ($Properties.GetEnumerator() |
            %{ "{0}={1}" -f $_.Key, $_.Value }) -join ';'
    }

    Write-Host "##vso[$Name $propertiesString]$Message" -Fore Magenta
}

Export-ModuleMember -Function *
