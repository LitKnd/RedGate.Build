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
  [string] $Version = '0.0.1',

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

Write-Info "Build parameters"
Write-Host "Version = $Version"
Write-Host "IsDefaultBranch = $IsDefaultBranch"
Write-Host "BranchName = $BranchName"
Write-Host "NugetFeedToPublishTo = $NugetFeedToPublishTo"
Write-Host "NugetFeedApiKey = ##redacted##"

Push-Location $PSScriptRoot
try {
  # Import the TeamCity module.
  Write-Info 'Importing TeamCity module'
  Import-Module '.\Private\teamcity.psm1' -DisableNameChecking -Force

  if(!$IsDefaultBranch -and $BranchName) {
    # If we are not building from master, append a pre-release suffix to the package version.
    $PackageSuffix = $BranchName -replace '[^a-zA-Z0-9\.\-_]', '' # Strip out any unwanted chars.
    if ($PackageSuffix.Length -gt 20) {
        $PackageSuffix = $PackageSuffix.Substring(0, 20)
    }
    $Version = "$Version-$PackageSuffix"
    # And let TeamCity know we've changed the  version number.
    TeamCity-SetBuildNumber($Version)
  }

  # Clean any previous build output.
  Write-Info 'Cleaning any prior build output'
  $NuGetPackagePath = ".\RedGate.Build.$Version.nupkg"
  if (Test-Path $NuGetPackagePath) {
    Write-Host "Deleting $NuGetPackagePath"
    Remove-Item $NuGetPackagePath
  }
  if (Get-Module Pester)
  {
    Write-Host 'Removing Pester module'
    Remove-Module Pester
  }
  $PesterPackagePath = '.\Pester'
  if (Test-Path $PesterPackagePath) {
    Write-Host "Deleting $PesterPackagePath"
    Remove-Item $PesterPackagePath -Force -Recurse
  }
  $PesterResultsPath = '.\TestResults.xml'
  if (Test-Path $PesterResultsPath)
  {
    Write-Host "Deleting $PesterResultsPath"
    Remove-Item $PesterResultsPath
  }
  if (Get-Module 'RedGate.Build')
  {
    Write-Host 'Removing RedGate.Build module'
    Remove-Module 'RedGate.Build'
  }

  # Download NuGet if necessary.
  $NuGetPath = '.\Private\nuget.exe'
  if(-not (Test-Path $NuGetPath)) {
    $NuGetUrl = "https://dist.nuget.org/win-x86-commandline/v4.3.0/nuget.exe"
    Write-Host "Downloading $nugetUrl to $NuGetPath"
    Invoke-WebRequest $NuGetUrl -OutFile $NuGetPath
  } else {
    Write-Host "$NuGetPath is present and is version $((Get-Item $NuGetPath).VersionInfo.ProductVersion)"
  }

  # Package the RedGate.Build module.
  Write-Info 'Creating RedGate.Build NuGet package'
  & $NuGetPath pack .\RedGate.Build.nuspec -NoPackageAnalysis -Version $Version
  if($LASTEXITCODE -ne 0) {
    throw "Could not nuget pack RedGate.Build. nuget returned exit code $LASTEXITCODE"
  }
  $Null = $NuGetPackagePath | Resolve-Path # Further verify that the package was built.

  # Obtain Pester.
  Write-Info 'Obtaining Pester'
  & $NuGetPath install Pester -Version 3.3.11 -OutputDirectory . -ExcludeVersion -PackageSaveMode nuspec
  Import-Module "$PesterPackagePath\tools\Pester.psm1" | Resolve-Path

  # Import the RedGate.Build module.
  Write-Info 'Importing the RedGate.Build module'
  Import-Module .\RedGate.Build.psm1 -Force

  # Run Pester tests.
  Write-Info 'Running Pester tests'
  Invoke-Pester -Script .\Tests\ -OutputFile $PesterResultsPath -OutputFormat NUnitXml
  if (!(Test-Path $PesterResultsPath)) {
    throw 'Pester tests results file unavailable'
  }
  TeamCity-ImportNUnitReport($PesterResultsPath | Resolve-Path)
  $TestResults = ([xml](Get-Content $PesterResultsPath)).'test-results'
  if($TestResults.Errors -ne '0' -or $TestResults.Failures -ne '0') {
    throw 'One or more tests failed.'
  }

  # Publish the NuGet package.
  Write-Info 'Publishing RedGate.Build NuGet package'
  if($IsDefaultBranch -and $NugetFeedToPublishTo -and $NugetFeedApiKey) {
    Write-Host 'Running NuGet publish'
    # Let's only push the packages from master when nuget feed info is passed in...
    & $NuGetPath push $NuGetPackagePath -Source $NugetFeedToPublishTo -ApiKey $NugetFeedApiKey
  } else {
    Write-Host 'Publish skipped'
  }

  Write-Info 'Build completed'
} finally {
  Pop-Location
}
