<#
.SYNOPSIS
  Rewrites all the AssemblyInfo files in a solution in a standardized, opitionated way.
.DESCRIPTION
  Rewrites all the AssemblyInfo files in a solution in a standardized, opitionated way. If any of the original AssemblyInfo.cs files contains unexpected/custom contents, then this cmdlet will throw an error, to avoid overriding intended changes. This cmdlet should be used on a solution before the solution is compiled, so that the compiled assemblies properties are correctly set.
.NOTES
  This cmdlet standardises AssemblyInfo.cs properties to the following:
  AssemblyTitle = project name
  AssemblyCompany = "Red Gate Software Ltd"
  AssemblyProduct = product name from -ProductName or -ProductNameOverrides
  AssemblyCopyright = "Copyright © Red Gate Software Ltd <year from -Year>"
  ComVisible = preserved, or false if not present before
  Guid = preserved
  AssemblyVersion = version from -Version or -VersionOverrides
  AssemblyFileVersion = version from -Version or -VersionOverrides
  BootstrapperApplication = preserved
  ThemeInfo = preserved
  InternalsVisibleTo = preserved
.PARAMETER SolutionFile
  The path to the solution file.
.PARAMETER ProductName
  The name of the product, eg 'SQL Clone'.
.PARAMETER Version
  The version of the product.
.PARAMETER Year
  The copyright year.
.PARAMETER ProductNameOverrides
  A hashtable from project name (eg 'RedGate.SqlDummy.Core') to product name, if some DLLs within a solution should have a different product name to the rest.
.PARAMETER VersionOverrides
  A hashtable from project name (eg 'RedGate.SqlDummy.Core') to version, if some DLLs within a solution should have a different version to the rest.
.EXAMPLE
  $year = git log -1 --format=%cd --date=format:%Y
  Rewrite-AssemblyInfos -SolutionFile $SolutionFile -ProductName 'SQL Compare' -Version $Version -Year $year

  This shows basic usage, where there is only one product name and version, and the year is based off the last git commit.
.EXAMPLE
  $year = git log -1 --format=%cd --date=format:%Y
  $productNameOverrides = @{
    'RedGate.Owin.Html5Mode' = 'RedGate.Owin.Html5Mode'
    'RedGate.Owin.Html5Mode.Tests' = 'RedGate.Owin.Html5Mode'
  }
  $versionOverrides = @{
    'RedGate.SqlClone.PowerShell' = $PsVersion
  }
  Rewrite-AssemblyInfos -SolutionFile $SolutionFile -ProductName 'SQL Clone' -Version $Version -Year $year -ProductNameOverrides $productNameOverrides -VersionOverrides $versionOverrides

  This shows more advanced usage, where some DLLs have a different product name or version.
#>
function Rewrite-AssemblyInfos {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string] $SolutionFile,
        [Parameter(Mandatory = $true)][string] $ProductName,
        [Parameter(Mandatory = $true)][System.Version] $Version,
        [Parameter(Mandatory = $true)][int] $Year,
        [Parameter(Mandatory = $false)][Hashtable] $ProductNameOverrides,
        [Parameter(Mandatory = $false)][Hashtable] $VersionOverrides
    )
    
    $projects = Get-ProjectsFromSolution $SolutionFile | Where-Object { $_.Project.EndsWith('.csproj') }
    $assemblyInfos = $projects | ForEach-Object { return @{
            Project      = $_.Project
            AssemblyInfo = $_.Project -replace '(\\|/|^)[^\\]+$', '\Properties\AssemblyInfo.cs'
        } }
    $missingAssemblyInfos = $assemblyInfos | Where-Object { !(Test-Path $_.AssemblyInfo) }
    assert ($null -eq $missingAssemblyInfos) @"
Some projects are missing AssemblyInfo files:
$($missingAssemblyInfos | Out-String)
"@
    $assemblyInfos | ForEach-Object {
        $xml = [xml] (Get-Content $_.Project)
        $projectname = $xml.Project.PropertyGroup.AssemblyName | Where-Object { $_ }
        $rootnamespace = $xml.Project.PropertyGroup.RootNamespace | Where-Object { $_ }
        $v = if ($VersionOverrides -and $VersionOverrides[$ProjectName]) { $VersionOverrides[$ProjectName] } else { $Version }
        $thisproductname = if ($ProductNameOverrides -and $ProductNameOverrides[$ProjectName]) { $ProductNameOverrides[$ProjectName] } else { $ProductName }
        Rewrite-AssemblyInfo -ProjectName $projectname -ProductName $thisproductname -RootNamespace $rootnamespace -AssemblyInfoPath $_.AssemblyInfo -Version $v -Year $year
    }
}
