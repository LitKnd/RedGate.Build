<#
.SYNOPSIS
  Pack, test and publish RedGate.Build

.DESCRIPTION
  1. nuget pack RedGate.Build.nuspec
  2. If Nuget Feed Url and Api key are passed in, publish the RedGate.Build package

.PARAMETER Version
  The version of the nuget package.

.PARAMETER IsDefaultBranch
  True when building from master. If False, '-prerelease' is appended to the package version.

.PARAMETER NugetFeedToPublishTo
  A url to a NuGet feed the package will be published to.

.PARAMETER NugetFeedApiKey
  The Api Key that allows pushing to the feed passed in as -NugetFeedToPublishTo.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $False)]
  [string] $BuildNumber = '0',

  [Parameter(Mandatory = $False)]
  [bool] $IsDefaultBranch = $False,

  [Parameter(Mandatory = $False)]
  [string] $BranchName = 'dev',

  [Parameter(Mandatory = $False)]
  [string] $NugetFeedToPublishTo,

  [Parameter(Mandatory = $False)]
  [string] $NugetFeedApiKey
)


$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue' #important for Invoke-WebRequest to perform well when executed from Teamcity.

$NugetExe = Resolve-Path "$PSScriptRoot\packages\NuGet.CommandLine\tools\NuGet.exe"

function Write-Info($Message) {
    Write-Host "#### $Message ####" -ForegroundColor Yellow
}

Write-Verbose "Build parameters"
Write-Verbose "BuildNumber = $BuildNumber"
Write-Verbose "IsDefaultBranch = $IsDefaultBranch"
Write-Verbose "BranchName = $BranchName"
Write-Verbose "NugetFeedToPublishTo = $NugetFeedToPublishTo"
Write-Verbose "NugetFeedApiKey = ##redacted##"

# Synopsis: Clean any previous build output.
task Clean {
    Get-Module Pester, RedGate.Build | Remove-Module -Verbose
    Get-Item "$PSScriptRoot\Redgate.Build.*.nupkg", "$PSScriptRoot\TestResults.xml" -ErrorAction 0 | Remove-Item -Force -Verbose
}

# Synopsis: Copy nuget.exe where RedGate.Build expects it
task CopyNuget {
    Copy-Item $NugetExe -Destination "$PSScriptRoot\Private" -Force -Verbose
}

# Synopsis: Import modules used by the build
task ImportModules CopyNuget, {
    Import-Module $PSScriptRoot\RedGate.Build.psm1 -Force
    Import-Module $PSScriptRoot\packages\Pester\tools\Pester.psm1 -Force
}

# Synopsis: Generate the version infos based on the release notes, branch name and build number.
task GenerateVersionInfo ImportModules, {
    $script:Notes = Read-ReleaseNotes -ReleaseNotesPath .\RELEASENOTES.md
    $script:Version = [System.Version] "$($Notes.Version).$BuildNumber"
    TeamCity-SetBuildNumber $Version
    $script:NugetPackageVersion = New-NugetPackageVersion -Version $Version -BranchName $BranchName -IsDefaultBranch $IsDefaultBranch
}

# Synopsis: Create the RedGate.Build nuget package
task Pack GenerateVersionInfo, {
    exec {
        & $NugetExe pack $PSScriptRoot\RedGate.Build.nuspec -NoPackageAnalysis -Version $NugetPackageVersion
    }
}

# Synopsis: Run Pester tests.
task Tests ImportModules, {
    $results = Invoke-Pester -Script .\Tests\ -OutputFile .\TestResults.xml -OutputFormat NUnitXml -PassThru
    Resolve-Path .\TestResults.xml | TeamCity-ImportNUnitReport
    assert ($results.FailedCount -eq 0) "$($results.FailedCount) test(s) failed."
}

# Synopsis: Push the nuget package to a nuget feed
task PublishNugetPackage -If($IsDefaultBranch -and $NugetFeedToPublishTo -and $NugetFeedApiKey) Pack, {
    exec {
        & $NugetExe push "RedGate.Build.$Version.nupkg" -Source $NugetFeedToPublishTo -ApiKey $NugetFeedApiKey
    }
}

task Build Clean, Tests, Pack, PublishNugetPackage

task . Build
