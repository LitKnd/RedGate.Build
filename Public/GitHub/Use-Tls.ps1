
<#
        .SYNOPSIS
        Temporarily sets security protocol to use TLS 1.2
        .DESCRIPTION
        Sets the encryption provider to use TLS 1.2, putting it back again once the given code block has exited or thrown
        .PARAMETER delegate
        A code block (typically involving one or more web requests) to be executed
#>
#requires -Version 2
function Use-Tls
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $delegate
    )
    Try {
        $oldSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $delegate
    }
    Finally {
        [System.Net.ServicePointManager]::SecurityProtocol = $oldSecurityProtocol
    }
}
