<#
.SYNOPSIS
  Execute NUnit tests from a single assembly using NUnit 3
.DESCRIPTION
  1. Install required Nuget Packages to get nunit3-console.exe and dotcover.exe
  2. Use nunit3-console.exe and dotcover.exe to execute NUnit tests with dotcover coverage
.EXAMPLE
  Invoke-NUnit3ForAssembly -AssemblyPath .\bin\debug\test.dll -NUnitVersion '3.0.0'
    Execute the NUnit tests from test.dll using nunit 3.0.0 (nuget package will be installed if need be.).
.EXAMPLE
  Invoke-NUnit3ForAssembly -AssemblyPath .\bin\debug\test.dll -NUnitVersion '3.0.0' -EnableCodeCoverage $true
    Execute the NUnit tests from test.dll and wrap nunit3-console.exe with dotcover.exe to provide code coverage.
    Code coverage report will be saved as .\bin\debug\test.dll.coverage.snap
    Use the Merge-CoverageReports function in order to publish coverage stats to Teamcity
.NOTES
  See also: Merge-CoverageReports
#>
function Invoke-NUnit3ForAssembly {
  [CmdletBinding()]
  param(
    # The path of the assembly to execute tests from
    [Parameter(Mandatory=$true)]
    [string] $AssemblyPath,
    # The version of the nuget package containing the NUnit executables (NUnit.Console)
    [string] $NUnitVersion = '3.0.0',
    # If specified, pass --x86 to nunit3-console
    [switch] $x86,
    # If specified, the framework version to be used for tests. (pass --framework=XX to nunit3-console). e.g. 'net-4.6', 'net-4.7'
    [string] $FrameworkVersion = $null,
    # NUnit3 Test selection EXPRESSION indicating what tests will be run
    # example: "method =~ /DataTest*/ && cat = Slow"
    [string] $Where,
    # The pattern used to generate the test result filename.
    # For MyAssembly.Test.dll, if TestResultFilenamePattern is 'TestResult',
    # the test result filename would be 'MyAssembly.Test.dll.TestResult.xml'
    [string] $TestResultFilenamePattern = 'TestResult',
    # Process isolation - see https://github.com/nunit/docs/wiki/Console-Command-Line
    [ValidateSet('Single', 'Separate', 'Multiple')]
    [string] $ProcessIsolation = $null,
    # Set to $true to enable code coverage using dotcover
    [bool] $EnableCodeCoverage = $false,
    # The version of the nuget package containing DotCover.exe (JetBrains.dotCover.CommandLineTools)
    [string] $DotCoverVersion = $DefaultDotCoverVersion,
    # The dotcover filters passed to dotcover.exe
    [string] $DotCoverFilters = '',
    # The dotcover filters passed to dotcover.exe
    [string] $DotCoverAttributeFilters = '',
    # The dotcover process filters passed to dotcover.exe. Requires dotcover version 2016.2 or later
    [string] $DotCoverProcessFilters = '+:nunit3-console.exe;+:nunit-*.exe',
    # The working directory of the test process
    [string] $TargetWorkingDirectory
  )

  Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'VerbosePreference'

  if(!$NunitVersion.StartsWith('3.')) {
      throw "Unexpected NUnit version '$NUnitVersion'. This function only supports Nunit v3"
  }

  $AssemblyPath = Resolve-Path $AssemblyPath

  Write-Output "Executing tests from $AssemblyPath. (code coverage enabled: $EnableCodeCoverage)"

  try {

    $NunitArguments = Build-NUnit3CommandLineArguments `
      -AssemblyPath $AssemblyPath `
      -x86 $x86.IsPresent `
      -Where $Where `
      -FrameworkVersion $FrameworkVersion `
      -TestResultFilenamePattern $TestResultFilenamePattern `
      -ProcessIsolation $ProcessIsolation

    $NunitExecutable = Get-NUnit3ConsoleExePath -NUnitVersion $NUnitVersion

    if( $EnableCodeCoverage ) {

      Invoke-DotCoverForExecutable `
        -TargetExecutable $NunitExecutable `
        -TargetArguments $NunitArguments `
        -OutputFile "$AssemblyPath.$TestResultFilenamePattern.coverage.snap" `
        -DotCoverVersion $DotCoverVersion `
        -Filters $DotCoverFilters `
        -AttributeFilters $DotCoverAttributeFilters `
        -ProcessFilters $DotCoverProcessFilters `
        -TargetWorkingDirectory $TargetWorkingDirectory

    } else {

      if (![string]::IsNullOrWhiteSpace($TargetWorkingDirectory)) {
        Push-Location $TargetWorkingDirectory
      }

      Execute-Command {
        & $NunitExecutable $NunitArguments
      }
    }

  } finally {
      [bool] $isTeamcity = (Get-CIServer) -eq 'Teamcity'
      Publish-ResultsAndLogs `
        -AssemblyPath $AssemblyPath `
        -TestResultFilenamePattern $TestResultFilenamePattern `
        -ImportResultsToCIServer (!$isTeamcity) # Do not import results to Teamcity since NUnit 3 uses service messages to integrate with Teamcity on its own.
      
        if (![string]::IsNullOrWhiteSpace($TargetWorkingDirectory)) {
        Pop-Location
      }
  }

}
