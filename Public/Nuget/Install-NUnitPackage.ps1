<#
.SYNOPSIS
  Installs either NUnit.Runners, NUnit.Console or NUnit.ConsoleRunner to RedGate.Build\packages depending on the nunit version
.DESCRIPTION
  Install either NUnit.Runners, NUnit.Console or NUnit.ConsoleRunner to RedGate.Build\packages depending on the nunit version
#>
function Install-NUnitPackage {
  [CmdletBinding()]
  param(
    # The version of the nuget package containing the NUnit executables (NUnit.Runners (v < 3), NUnit.Console (3.0 <= v <= 3.1) or NUnit.ConsoleRunner (v > 3.1))
    [string] $Version = $DefaultNUnitVersion
  )
    $nunitRunnerPackageName = "NUnit.ConsoleRunner"
    if ($Version.StartsWith("3.0") -or $Version.StartsWith("3.1")) {
      $nunitRunnerPackageName = "NUnit.Console"
    }
	elseif ($Version.StartsWith("0.") -or $Version.StartsWith("1.") -or $Version.StartsWith("2.")){
      $nunitRunnerPackageName = "NUnit.Runners"
    }
  Install-Package "$nunitRunnerPackageName" $Version
}
