<#
        .SYNOPSIS
        Extract a list of PackageIDs from 'packages.config' found in a folder
        .DESCRIPTION
        Searches a directory to recursively for 'packages.config' files 
        and extracts a unique list of Nuget Package IDs
        .PARAMETER RootDir
        The root directory to search recursively for 'packages.config' files
        .OUTPUTS
        An array of Nuget PackageID strings
#>
#requires -Version 2
function Get-NugetPackageIds
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootDir
    )
    # Find all the packages.config
    $packageConfigs = Get-ChildItem "$RootDir" -Recurse -Filter "packages.config" `
                      | Where-Object{ $_.fullname -notmatch "\\(.build)|(packages)\\" } `
                      | Resolve-Path
    
    return $packageConfigs | ForEach-Object {
        ([Xml]($_ | Get-Content)).packages.package.id
    } `
    | Select-Object -Unique
}