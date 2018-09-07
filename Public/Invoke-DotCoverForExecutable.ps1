<#
.SYNOPSIS
  Performs coverage analysis of a .NET application.
.DESCRIPTION
  Use 'dotcover.exe' to perform coverage analysis of the specified .NET executable.
.PARAMETER TargetExecutable
  The path of the target executable.
.PARAMETER TargetArguments
  The arguments to pass to the target executable.
.PARAMETER OutputFile
  The output XML file containing the detailed coverage information.
.PARAMETER DotCoverVersion
  The version of dotCover nuget package to use.
.PARAMETER Filters
  Coverage filters for dotCover, to indicate what should and should not be covered.
.PARAMETER AttributeFilters
  Attribute coverage filters for dotCover, to indicate what should and should not be covered.
.PARAMETER ProcessFilters
  Process coverage filters for dotCover, to indicate what should and should not be covered. Requires Dot Cover 2016.2 or later.
.PARAMETER TargetWorkingDirectory
  The working directory of the target executable.
#>
function Invoke-DotCoverForExecutable {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $True)]
    [string] $TargetExecutable,

    [Parameter(Mandatory = $False)]
    [string[]] $TargetArguments,

    [Parameter(Mandatory = $True)]
    [string] $OutputFile,

    [Parameter(Mandatory = $False)]
    [string] $DotCoverVersion = $DefaultDotCoverVersion,

    [Parameter(Mandatory = $False)]
    [Alias('DotCoverFilters')]
    [string] $Filters = '',

    [Parameter(Mandatory = $False)]
    [string] $AttributeFilters = '',

    [Parameter(Mandatory = $False)]
    [string] $ProcessFilters = '',

    [Parameter(Mandatory = $False)]
    [string] $TargetWorkingDirectory
  )

  $DotCoverArguments = @(
    'cover',
    "/TargetExecutable=$TargetExecutable",
    "/Output=$OutputFile",
    '/ReturnTargetExitCode'
  )

  if (![string]::IsNullOrWhiteSpace($Filters)) {
    $DotCoverArguments += "/Filters=$Filters"
  }

  if (![string]::IsNullOrWhiteSpace($AttributeFilters)) {
    $DotCoverArguments += "/AttributeFilters=$AttributeFilters"
  }

  if (![string]::IsNullOrWhiteSpace($ProcessFilters)) {
    $DotCoverArguments += "/ProcessFilters=$ProcessFilters"
  }

  if ($TargetArguments) {
    $EscapedTargetArguments = ConvertTo-ShellEscaped $TargetArguments
    $DotCoverArguments += "/TargetArguments=$EscapedTargetArguments"
  }

  if (![string]::IsNullOrWhiteSpace($TargetWorkingDirectory)) {
    $DotCoverArguments += "/TargetWorkingDir=`"$TargetWorkingDirectory`""
  }

  $DotCoverPath = Get-DotCoverExePath -DotCoverVersion $DotCoverVersion

  & $DotCoverPath $DotCoverArguments

  if ($LastExitCode -ne 0) {
    throw "dotCover exited with code $LastExitCode."
  }
}
