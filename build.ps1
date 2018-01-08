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

$NugetExe = Resolve-Path "$PSScriptRoot\packages\NuGet.CommandLine\tools\NuGet.exe"

Write-Verbose "Build parameters"
Write-Verbose "BuildNumber = $BuildNumber"
Write-Verbose "IsDefaultBranch = $IsDefaultBranch"
Write-Verbose "BranchName = $BranchName"
Write-Verbose "NugetFeedToPublishTo = $NugetFeedToPublishTo"
Write-Verbose "NugetFeedApiKey = ##redacted##"

# Synopsis: Clean any previous build output.
task Clean {
    Get-Module Pester, RedGate.Build | Remove-Module -Verbose
    Get-Item "$PSScriptRoot\Redgate.Build.*.nupkg", "$PSScriptRoot\TestResults.xml", "$PSScriptRoot\.temp" -ErrorAction 0 | Remove-Item -Force -Recurse -Verbose
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

    $escapedReleaseNotes = $Notes.Content -replace '"','\"'

    exec {
        & $NugetExe pack $PSScriptRoot\RedGate.Build.nuspec `
            -NoPackageAnalysis `
            -Version $NugetPackageVersion `
            -Properties "releaseNotes=$escapedReleaseNotes;year=$((Get-Date).year)"
    }
}

# Synopsis: Run Pester tests.
task Tests Pack, {
    $results = Invoke-Pester -Script .\Tests\ -OutputFile .\TestResults.xml -OutputFormat NUnitXml -PassThru
    Resolve-Path .\TestResults.xml | TeamCity-ImportNUnitReport
    assert ($results.FailedCount -eq 0) "$($results.FailedCount) test(s) failed."
}

# Synopsis: Push the nuget package to a nuget feed
task PublishNugetPackage -If($NugetFeedToPublishTo -and $NugetFeedApiKey) Pack, {
    exec {
        & $NugetExe push "RedGate.Build.$NugetPackageVersion.nupkg" -Source $NugetFeedToPublishTo -ApiKey $NugetFeedApiKey
    }
}

task Build Clean, Tests, PublishNugetPackage

task . Build
