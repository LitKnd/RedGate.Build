<#
.SYNOPSIS
  Merge multiple dotcover coverage reports into a single report.
.DESCRIPTION
  Find all the *.coverage.snap in a folder and merge them together using
    1 dotcover merge
    2 dotcover zip
  If running within Teamcity, let Teamcity know where the merged coverage snapshot is.
  If outside of teamcity use 'dotcover report' to create a html report for human beings to read.
#>
function Merge-CoverageReports {
  [CmdletBinding()]
  param(
    # The folder containing the coverage reports to be merged.
    [Parameter(Mandatory=$true)]
    [Alias('OutputDir')]
    [string] $SnapshotsDir,

    # Also find coverage reports in child folders.
    [switch] $Recurse,

    # The folder where the merged coverage report will be saved.
    # If not set, this will default to the value of -SnapshotsDir
    [string] $CoverageOutputDir,

    #The version of dotCover nuget package to use.
    [Parameter(Mandatory = $False)]
    [string] $DotCoverVersion = $DefaultDotCoverVersion
  )

  if(!$CoverageOutputDir) {
      $CoverageOutputDir = $SnapshotsDir
  }

  if(!(Test-Path $CoverageOutputDir)) {
      New-Item $CoverageOutputDir -ItemType Directory -Force | Out-Null
  }

  $DotCoverPath = Get-DotCoverExePath -DotCoverVersion $DotCoverVersion

  $MergedSnapshotPath = "$CoverageOutputDir\coverage.dcvr"
  # Use -ErrorAction SilentlyContinue to survive windows "path is too long" errors.
  $snapshots = (Get-ChildItem $SnapshotsDir -Filter *.coverage.snap -Recurse:$Recurse.IsPresent -ErrorAction SilentlyContinue).FullName
  Write-Verbose "Merging snapshots: `r`n$snapshots`r`n`r`nto $MergedSnapshotPath"

  & $DotCoverPath merge /Source="$($snapshots -join ';')" /Output="$MergedSnapshotPath"
  & $DotCoverPath report /Source="$MergedSnapshotPath" /Output="$CoverageOutputDir\report.html" /reporttype=HTML

  # Let Teamcity know where the current dotcover.exe we are using is
  TeamCity-ConfigureDotNetCoverage -key 'dotcover_home' -value ($DotCoverPath | Split-Path)
  # Let Teamcity know where the report is.
  TeamCity-ImportDotNetCoverageResult 'dotcover' $MergedSnapshotPath
}
