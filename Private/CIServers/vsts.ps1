function Write-VSTSLoggingCommand([string]$Name, [string]$Message, [hashtable]$Properties) {
    function escape([string]$value) {
        ([char[]] $value |
                %{ switch ($_)
                        {
                                "|" { "||" }
                                "'" { "|'" }
                                "`n" { "|n" }
                                "`r" { "|r" }
                                "[" { "|[" }
                                "]" { "|]" }
                                ([char] 0x0085) { "|x" }
                                ([char] 0x2028) { "|l" }
                                ([char] 0x2029) { "|p" }
                                default { $_ }
                        }
                } ) -join ''
        }

    if($Properties) {
        $propertiesString = ($Properties.GetEnumerator() |
            %{ "{0}='{1}'" -f $_.Key, (escape $_.Value) }) -join ';'
    }


    Write-Host "##vso[$Name $propertiesString]$Message" -Fore Magenta
}
