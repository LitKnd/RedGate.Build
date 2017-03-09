<#
.SYNOPSIS
    Recursively get a list of packages.config in a directory

.DESCRIPTION
    Recursively get a list of packages.config in a directory

.OUTPUTS
    A list of paths to packages.config files
#>
Function Get-NugetPackageConfigs
{
    [CmdletBinding()]
    [OutputType([Nullable])]
    Param
    (
        # The root directory to search recursively for 'packages.config' files
        [Parameter(Mandatory, Position=0)]
        $RootDir
    )

    Get-ChildItem $RootDir -Recurse -Filter 'packages.config' `
        | Where-Object{ $_.fullname -notmatch "\\(.build)|(packages)\\" } `
        | Resolve-Path
}
