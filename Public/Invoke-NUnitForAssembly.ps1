<#
.SYNOPSIS
  Execute NUnit tests from a single assembly
.DESCRIPTION
  1. Install required Nuget Packages to get nunit-console.exe and dotcover.exe
  2. Use nunit-console.exe and dotcover.exe to execute NUnit tests with dotcover coverage
.EXAMPLE
  Invoke-NUnitForAssembly -AssemblyPath .\bin\debug\test.dll -NUnitVersion '2.6.2' -IncludedCategories 'working'
    Execute the NUnit tests from test.dll using nunit 2.6.2 (nuget package will be installed if need be.).
    And pass '/include:working' to nunit-console.exe
.EXAMPLE
  Invoke-NUnitForAssembly -AssemblyPath .\bin\debug\test.dll -EnableCodeCoverage $true
    Execute the NUnit tests from test.dll and wrap nunit-console.exe with dotcover.exe to provide code coverage.
    Code coverage report will be saved as .\bin\debug\test.dll.coverage.snap
    Use the Merge-CoverageReports function in order to publish coverage stats to Teamcity
.NOTES
  See also: Merge-CoverageReports
#>
function Invoke-NUnitForAssembly {
  [CmdletBinding()]
  param(
    # The path of the assembly to execute tests from
    [Parameter(Mandatory=$true)]
    [string] $AssemblyPath,
    # The version of the nuget package containing the NUnit executables (NUnit.Runners)
    [string] $NUnitVersion = $DefaultNUnitVersion,
    # Whether to use nunit x86 or nunit x64 (default)
    [switch] $x86,
    # If specified, the framework version to be used for tests. (pass /framework=XX to nunit-console). e.g. 'net-4.6', 'net-4.7'
    [string] $FrameworkVersion = $null,
    # A list of excluded test categories
    [string[]] $ExcludedCategories = @(),
    # A list of incuded test categories
    [string[]] $IncludedCategories = @(),
    # The pattern used to generate the test result filename.
    # For MyAssembly.Test.dll, if TestResultFilenamePattern is 'TestResult',
    # the test result filename would be 'MyAssembly.Test.dll.TestResult.xml'
    [string] $TestResultFilenamePattern = 'TestResult',
    # Set to $true to enable code coverage using dotcover
    [bool] $EnableCodeCoverage = $false,
    # The version of the nuget package containing DotCover.exe (JetBrains.dotCover.CommandLineTools)
    [string] $DotCoverVersion = $DefaultDotCoverVersion,
    # The dotcover filters passed to dotcover.exe
    [string] $DotCoverFilters = '',
    # The dotcover filters passed to dotcover.exe
    [string] $DotCoverAttributeFilters = '',
    # The dotcover process filters passed to dotcover.exe. Requires dotcover version 2016.2 or later
    [string] $DotCoverProcessFilters = '',
    # If set, do not import test results automatically to Teamcity.
    # In this case it is the responsibility of the caller to call 'TeamCity-ImportNUnitReport "$AssemblyPath.$TestResultFilenamePattern.xml"'
    [switch] $DotNotImportResultsToTeamcity
  )

  Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'VerbosePreference'

  if($NunitVersion.StartsWith('3.')) {
      throw "NUnit version '$NUnitVersion' is not supported by this function. Use Invoke-NUnit3ForAssembly instead."
  }

  if(!$NunitVersion.StartsWith('2.')) {
      throw "Unexpected NUnit version '$NUnitVersion'. This function only supports Nunit v2"
  }

  $AssemblyPath = Resolve-Path $AssemblyPath

  Write-Output "Executing tests from $AssemblyPath. (code coverage enabled: $EnableCodeCoverage)"

  try {

    $NunitArguments = Build-NUnitCommandLineArguments `
      -AssemblyPath $AssemblyPath `
      -FrameworkVersion $FrameworkVersion `
      -ExcludedCategories $ExcludedCategories `
      -IncludedCategories $IncludedCategories `
      -TestResultFilenamePattern $TestResultFilenamePattern

    $NunitExecutable = Get-NUnitConsoleExePath -NUnitVersion $NUnitVersion -x86:$x86.IsPresent

    if( $EnableCodeCoverage ) {

      Invoke-DotCoverForExecutable `
        -TargetExecutable $NunitExecutable `
        -TargetArguments $NunitArguments `
        -OutputFile "$AssemblyPath.$TestResultFilenamePattern.coverage.snap" `
        -DotCoverVersion $DotCoverVersion `
        -Filters $DotCoverFilters `
        -AttributeFilters $DotCoverAttributeFilters `
        -ProcessFilters $DotCoverProcessFilters

    } else {

      Execute-Command {
        & $NunitExecutable $NunitArguments
      }

    }

  } finally {
      Publish-ResultsAndLogs `
        -AssemblyPath $AssemblyPath `
        -TestResultFilenamePattern $TestResultFilenamePattern `
        -ImportResultsToCIServer (!$DotNotImportResultsToTeamcity.IsPresent)
  }

}
