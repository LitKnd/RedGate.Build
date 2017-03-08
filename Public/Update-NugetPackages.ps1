<#
        .SYNOPSIS
        Updates a solution with the NuGet Packages IDs supplied
        .DESCRIPTION
        Updates a solution with the NuGet Packages IDs supplied        
        .PARAMETER Solution
        The name of the .sln file
        .PARAMETER PackageIds
        An array of nuget Package IDs to update
#>
#requires -Version 2
function Update-NugetPackages
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Solution,
        
        [Parameter(Mandatory = $true)]
        [string[]] $PackageIds
    )
    $NugetPackageParam = $PackageIds | ForEach-Object {
        "-id", $_
    }

    exec {
        & $NugetExe update $Solution -Verbosity detailed -noninteractive $NugetPackageParam
    }
}