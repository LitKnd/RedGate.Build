<#
.SYNOPSIS
  Installs either NUnit.Runners or NUnit.Console to RedGate.Build\packages depending on the nunit version
.DESCRIPTION
  Install either NUnit.Runners or NUnit.Console to RedGate.Build\packages depending on the nunit version
#>
function Install-NUnitPackage {
  [CmdletBinding()]
  param(
    # The version of the nuget package containing the NUnit executables (NUnit.Runners (v < 3) or NUnit.Console (v >= 3)
    [string] $Version = $DefaultNUnitVersion
  )
    $nunitRunnerPackageName = "NUnit.Console"
    if ($Version.StartsWith("2.")){
      $nunitRunnerPackageName = "NUnit.Runners"
    }
  Install-Package "$nunitRunnerPackageName" $Version
}
