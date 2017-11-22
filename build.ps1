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

function Write-Info($Message) {
    Write-Host "#### $Message ####" -ForegroundColor Yellow
}

Write-Verbose "Build parameters"
Write-Verbose "BuildNumber = $BuildNumber"
Write-Verbose "IsDefaultBranch = $IsDefaultBranch"
Write-Verbose "BranchName = $BranchName"
Write-Verbose "NugetFeedToPublishTo = $NugetFeedToPublishTo"
Write-Verbose "NugetFeedApiKey = ##redacted##"

Push-Location $PSScriptRoot
try {
    # Clean any previous build output.
    Write-Info 'Cleaning any prior build output'
    Get-Module Pester, RedGate.Build | Remove-Module
    Get-Item 'Redgate.Build.*.nupkg', 'Pester', 'TestResults.xml' -ErrorAction 0 | Remove-Item -Force -Recurse

    # Download NuGet if necessary.
    $NuGetPath = '.\Private\nuget.exe'
    if(-not (Test-Path $NuGetPath)) {
        Invoke-WebRequest 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile $NuGetPath
    } else {
        Write-Host "$NuGetPath is present and is version $((Get-Item $NuGetPath).VersionInfo.ProductVersion)"
    }

    # Import the RedGate.Build module.
    Write-Info 'Importing the RedGate.Build module'
    Import-Module .\RedGate.Build.psm1 -Force

    $Notes = Read-ReleaseNotes -ReleaseNotesPath .\RELEASENOTES.md
    $Version = [System.Version] "$($Notes.Version).$BuildNumber"
    TeamCity-SetBuildNumber $Version
    $NugetPackageVersion = New-NugetPackageVersion -Version $Version -BranchName $BranchName -IsDefaultBranch $IsDefaultBranch


    # Package the RedGate.Build module.
    Write-Info 'Creating RedGate.Build NuGet package'
    & $NuGetPath pack .\RedGate.Build.nuspec -NoPackageAnalysis -Version $NugetPackageVersion
    if($LASTEXITCODE -ne 0) {
        throw "Could not nuget pack RedGate.Build. nuget returned exit code $LASTEXITCODE"
    }

    # Obtain Pester.
    Write-Info 'Obtaining Pester'
    & $NuGetPath install Pester -Version 3.3.11 -OutputDirectory . -ExcludeVersion -PackageSaveMode nuspec
    Import-Module .\Pester\tools\Pester.psm1

    # Run Pester tests.
    Write-Info 'Running Pester tests'
    $results = Invoke-Pester -Script .\Tests\ -OutputFile .\TestResults.xml -OutputFormat NUnitXml -PassThru
    Resolve-Path .\TestResults.xml | TeamCity-ImportNUnitReport

    if($results.FailedCount -gt 0) {
        throw "$($results.FailedCount) test(s) failed."
    }

    # Publish the NuGet package.
    Write-Info 'Publishing RedGate.Build NuGet package'
    if($IsDefaultBranch -and $NugetFeedToPublishTo -and $NugetFeedApiKey) {
        Write-Host 'Running NuGet publish'
        # Let's only push the packages from master when nuget feed info is passed in...
        & $NuGetPath push "RedGate.Build.$Version.nupkg" -Source $NugetFeedToPublishTo -ApiKey $NugetFeedApiKey
    } else {
        Write-Host 'Publish skipped'
    }

    Write-Info 'Build completed'
} finally {
    Pop-Location
}
