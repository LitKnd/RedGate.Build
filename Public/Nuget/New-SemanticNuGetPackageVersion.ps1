#requires -Version 2

<#
.SYNOPSIS
  Obtains a semantic NuGet package version based on the build version number and branch name.
.DESCRIPTION
  Obtains a semantic NuGet package version based on a 3 or 4-digit build version number, the branch name and whether or not the branch is the default branch.
.OUTPUTS
  A NuGet version string based on the input parameters. The string is also suitable for use as an assembly's AssemblyInformationalVersion attribute value.
.EXAMPLE
  New-SemanticNuGetPackageVersion -Version '1.2.3' -BranchName 'master' -IsDefaultBranch $True

  Returns '1.2.3'. This shows how this cmdlet might be invoked on the default master branch with a three digit version number.
.EXAMPLE
  New-SemanticNuGetPackageVersion -Version '1.2.3.4' -BranchName 'master' -IsDefaultBranch $True

  Returns '1.2.3'. This shows how this cmdlet might be invoked on the default master branch with a four digit version number. The fourth Revision number is ignored.
.EXAMPLE
  New-SemanticNuGetPackageVersion -Version '1.2.3' -BranchName 'SomeBranch' -IsDefaultBranch $False

  Returns '1.2.3-SomeBranch'. This shows how this cmdlet might be invoked on a feature branch, resulting in a pre-release version string.
.EXAMPLE
  New-SemanticNuGetPackageVersion -Version '1.2.3.4' -BranchName 'SomeBranch' -IsDefaultBranch $False

  Returns '1.2.3-SomeBranch0004'. This shows how this cmdlet might be invoked on a feature branch, resulting in a pre-release version string that includes the revision number.
.EXAMPLE
  New-SemanticNuGetPackageVersion -Version '1.2.3.4' -BranchName 'SomeBranch' -IsDefaultBranch $False -RevisionSuffixLength 3

  Returns '1.2.3-SomeBranch004'. This shows how this cmdlet might be invoked on a feature branch, resulting in a pre-release version string that includes the revision number that is only 3 characters long, rather than the usual 4.
#>
function New-SemanticNuGetPackageVersion
{
    [CmdletBinding()]
    param(
        # A three or four digit version number of the form Major.Minor.Patch.Revision.
        [Parameter(Mandatory = $true)]
        [version] $Version,

        # The name of the current source control branch. e.g. 'master' or 'my-feature'. This is only used when IsDefaultBranch is false, in order to determine the pre-release version suffix. If the branch name is too long, this cmdlet will try to shorten it to satisfy the 20 character limit for the pre-release suffix. Nonetheless, you should try to avoid long branch names.
        [Parameter(Mandatory = $true)]
        [string] $BranchName,

        # Indicates whether or not BranchName represents the default branch for the source control system currently in use. Please note that this is not a switch parameter - you must specify this value explicitly.
        [Parameter(Mandatory = $true)]
        [bool] $IsDefaultBranch,
        
        # The minimum number of characters at the end of a pre-release suffix that is devoted to the digits of the revision number. Defaults to 4 (e.g. '1.0.0-MyBranch0236'). You could reduce this to 3 if your revision numbers never exceed 999, to free up an additional character for the branch name. You could reduce this to zero if you don't want the revision number to appear in the suffix at all (or just specify a 3-digit version for the -Version parameter instead).
        [Parameter(Mandatory = $false)]
        [int] $RevisionSuffixLength = 4
    )
    
    # Parameter validation.
    if (-not $Version) {
        throw "Missing 'Version' parameter"
    }
    $Parts = $Version.ToString().Split('.')
    if ($Parts.Length -lt 3 -or $Parts.Length -gt 4) {
        throw "Version parameter must include 3 or 4 digits: Actual value = $Version"
    }
    if (-not $BranchName) {
        throw "Missing 'BranchName' parameter"
    }
    if ($RevisionSuffixLength -lt 0) {
        throw "Negative RevisionSuffixLength parameter not permitted: Actual value = $RevisionSuffixLength"
    }
    if ($RevisionSuffixLength -gt 6) {
        throw "RevisionSuffixLength parameter cannot exceed 6: Actual value = $RevisionSuffixLength"
    }

    # The semantic version is based on the first 3 digits of the version number.
    $SemanticVersion = $Version.ToString(3)

    # If this is the default branch, there's no pre-release suffix. Just return the semantic version number.
    if ($IsDefaultBranch)
    {
        return $SemanticVersion
    }

    # Otherwise establish the pre-release suffix from the branch name.
    $PreReleaseSuffix = $BranchName
    
    # Remove invalid characters from the suffix.
    $PreReleaseSuffix = $PreReleaseSuffix -replace '[/]', '-'
    $PreReleaseSuffix = $PreReleaseSuffix -replace '[^0-9A-Za-z-]', ''

    # Shorten the suffix if necessary, to satisfy NuGet's 20 character limit.
    if ($PreReleaseSuffix.Length -gt 20) {
        $PreReleaseSuffix = $PreReleaseSuffix.SubString(0, 20)
    }

    # If we have a fourth revision number and a non-zero RevisionSuffixLength,
    # then we include the revision number in the PreReleaseSuffix.
    if ($Parts.Length -eq 4 -and $RevisionSuffixLength -gt 0) {
        # Determine the revision suffix...
        $RevisionSuffix = $Version.Revision.ToString("D$RevisionSuffixLength")

        # ... truncate the pre-release suffix if necessary...
        if ($PreReleaseSuffix.Length + $RevisionSuffix.Length -gt 20) {
            $PreReleaseSuffix = $PreReleaseSuffix.Substring(0, 20 - $RevisionSuffix.Length)
        }

        # ... and then combine the pre-release suffix with the revision number.
        $PreReleaseSuffix = "$PreReleaseSuffix$RevisionSuffix"
    }

    # And finally compose the full NuGet package semantic version.
    return "$SemanticVersion-$PreReleaseSuffix"
}
