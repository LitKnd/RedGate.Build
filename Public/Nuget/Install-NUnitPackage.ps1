<#
.SYNOPSIS
  Install NUnit.Runners to RedGate.Build\packages
.DESCRIPTION
  Install the NUnit.Runners nuget package to RedGate.Build\packages
#>
function Install-NUnitPackage {
  [CmdletBinding()]
  param(
    # The version of the nuget package containing the NUnit executables (NUnit.Runners)
    [string] $Version = $DefaultNUnitVersion
  )
  Install-Package "NUnit.Runners" $Version
}
