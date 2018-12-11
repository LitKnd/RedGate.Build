<#
.SYNOPSIS
  Takes a dependency version number and return a valid dependency version range for use in a nuspec file.
.DESCRIPTION
  Takes a version of the form a.b.c[.d][-branchName], returns the version range to set in the nuspec
  [a.b.c[.d][-branchName], a+1.0.0)
.PARAMETER SpecificVersion
  A switch parameter that will enforce the use of a specific version rather than a range of versions, even if the version number passed in is semantically versioned. This can be used to prevent run-time assembly loading problems, for instance when several applications are running within the same application domain (i.e. SSMS plugins). 
.EXAMPLE
  Get-DependencyVersionRange
#>

function Get-DependencyVersionRange
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeLine = $True)]
        [ValidateNotNullOrEmpty()]
        [string] $Version,
        [switch] $SpecificVersion
    )
    
    process {        
        if($Version.Contains('-'))
        {
            $currentVersion = $Version.Split('-', 2)[0]
            $branchSuffix = "-$($Version.Split('-', 2)[1])"
        } else
        {
            $currentVersion = $Version
            $branchSuffix = ""
        }

        $versionParts = $currentVersion.Split(".")
        if ($versionParts.Length -eq 3 -And -Not $SpecificVersion) #https://semver.org/
        {
            $nextMajorVersion = [int] $versionParts[0] + 1
            $nextMajorVersionString = "$nextMajorVersion.0.0$branchSuffix"
            return "[$Version, $nextMajorVersionString)"
        }
        else
        {
            return '[' + $Version + ']'
        }
    }
}
