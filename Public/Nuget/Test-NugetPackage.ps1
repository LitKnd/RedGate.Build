<#
        .SYNOPSIS
        Determines whether or not a specific version of a Nuget Package exists.
        .DESCRIPTION
        Determines whether or not a specific version of a Nuget Package exists.
        Currently attempt to install the package, returning $True if successful and
        $False on error.
        .PARAMETER Name
        The name/id of the nuget package to test for.
        .PARAMETER Version
        The version of the nuget package to test for.
        .OUTPUTS
        $True if the package exists. $False if not.
#>
#requires -Version 2
function Test-NugetPackage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $Version
    )

    try {
        $PackagePath = Install-Package -Name $Name -Version $Version -ErrorAction SilentlyContinue
        return $PackagePath -ne $Null
    } catch {
        return $False
    }
}
