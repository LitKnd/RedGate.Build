<#
.SYNOPSIS
  Install JetBrains.dotCover.CommandLineTools to RedGate.Build\packages
.DESCRIPTION
  Install the JetBrains.dotCover.CommandLineTools nuget package to RedGate.Build\packages
#>
function Install-DotCoverPackage {
  [CmdletBinding()]
  param(
    # The version of the nuget package containing DotCover.exe (JetBrains.dotCover.CommandLineTools)
    [string] $Version = $DefaultDotCoverVersion
  )

  Install-Package JetBrains.dotCover.CommandLineTools $Version
}
