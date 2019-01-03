﻿# These are default comments that Visual Studio includes in AssemblyInfo.cs, and are thus uninteresting.
$AssemblyInfoCommentsToIgnore = @(
    '// General Information about an assembly is controlled through the following',
    '// set of attributes. Change these attribute values to modify the information',
    '// associated with an assembly.',
    '// Setting ComVisible to false makes the types in this assembly not visible',
    '// to COM components.  If you need to access a type in this assembly from',
    '// COM, set the ComVisible attribute to true on that type.',
    '// The following GUID is for the ID of the typelib if this project is exposed to COM',
    '// Version information for an assembly consists of the following four values:',
    '//',
    '//      Major Version',
    '//      Minor Version',
    '//      Build Number',
    '//      Revision',
    '// You can specify all the values or you can default the Build and Revision Numbers',
    "// by using the '*' as shown below:",
    '// [assembly: AssemblyVersion("1.0.*")]',
    '//In order to begin building localizable applications, set',
    '//<UICulture>CultureYouAreCodingWith</UICulture> in your .csproj file',
    '//inside a <PropertyGroup>.  For example, if you are using US english',
    '//in your source files, set the <UICulture> to en-US.  Then uncomment',
    '//the NeutralResourceLanguage attribute below.  Update the "en-US" in',
    '//the line below to match the UICulture setting in the project file.',
    '//[assembly: NeutralResourcesLanguage("en-US", UltimateResourceFallbackLocation.Satellite)]',
    '//(used if a resource is not found in the page,',
    '// or application resource dictionaries)',
    '//(used if a resource is not found in the page,',
    '// app, or any theme specific resource dictionaries)'
)

# Visual Studio puts the ThemeInfo attribute on multiple lines with comments, which is hard to parse later.
# This function uses multiline regexes to collapse it to one line without comments to make parsing easier.
function CollapseDefaultThemeInfoToOneLine([String] $assemblyInfo) {
    return $assemblyInfo `
        -replace '(?m)//\s*where theme specific resource dictionaries are located\s*$', '' `
        -replace '(?m)//\s*\(used if a resource is not found in the page,\s*$', '' `
        -replace '(?m)//\s*or application resource dictionaries\)\s*$', '' `
        -replace '(?m)//\s*where the generic resource dictionary is located\s*$', '' `
        -replace '(?m)//\s*app, or any theme specific resource dictionaries\)\s*$', '' `
        -replace '(?m)^\s*\[\s*assembly\s*:\s*ThemeInfo\s*\(\s*(ResourceDictionaryLocation\.(None|SourceAssembly|ExternalAssembly))\s*,\s*(ResourceDictionaryLocation\.(None|SourceAssembly|ExternalAssembly))\s*\)\s*\]\s*$', '[assembly: ThemeInfo($1, $3)]'
}

$UsingStatementRegex = '^using\s+[\w.]+\s*;$'
$AssemblyAttributeSingleParameterRegex = '^\[\s*assembly\s*:\s*(\w+)\s*\(\s*(\w*|typeof\(\w+\)|"([^"\\])*")\s*\)\s*\]$'
$AssemblyAttributeThemeInfoRegex = '^\[\s*assembly\s*:\s*ThemeInfo\s*\(\s*(ResourceDictionaryLocation\.(None|SourceAssembly|ExternalAssembly))\s*,\s*(ResourceDictionaryLocation\.(None|SourceAssembly|ExternalAssembly))\s*\)\s*\]$'

<#
.SYNOPSIS
  Rewrites an AssemblyInfo file in a standardized, opitionated way.
.DESCRIPTION
  Rewrites an AssemblyInfo file in a standardized, opitionated way. ComVisible, Guid, BootstrapperApplication, ThemeInfo, and InternalsVisibleTo are preserved, but all other properties are standardized. But, if the original AssemblyInfo.cs file contains unexpected/custom contents, then this cmdlet will throw an error, to avoid overriding intended changes.
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
.PARAMETER ProjectName
  The name of the project file, eg 'RedGate.SqlClone.Core'.
.PARAMETER ProductName
  The name of the product, eg 'SQL Clone'.
.PARAMETER RootNamespace
  The root namespace of the project, eg 'RedGate.SqlClone.Core'. This is currently only used for WiX Bootstrapper projects.
.PARAMETER AssemblyInfoPath
  The path of the AssemblyInfo.cs file to rewrite.
.PARAMETER Version
  The version of the assembly.
.PARAMETER Year
  The copyright year.
#>
function Rewrite-AssemblyInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string] $ProjectName,
        [Parameter(Mandatory = $true)][string] $ProductName,
        [Parameter(Mandatory = $false)][string] $RootNamespace,
        [Parameter(Mandatory = $true)][string] $AssemblyInfoPath,
        [Parameter(Mandatory = $true)][System.Version] $Version,
        [Parameter(Mandatory = $true)][int] $Year
    )
    
    $filename = $AssemblyInfoPath
    $rawinput = Get-Content $filename -Raw
    $input = (CollapseDefaultThemeInfoToOneLine($rawinput)).Split("`r`n")
    $usings = New-Object System.Collections.Generic.SortedSet[string]
    $usings.Add('System.Reflection') | Out-Null
    $usings.Add('System.Runtime.InteropServices') | Out-Null
    $output = ''
    $data = @{ InternalsVisibleTo = New-Object System.Collections.Generic.SortedSet[string] }
    foreach ($line in $input) {
        $line = $line.Trim()
        if ($line -eq '') { continue }
        if ($AssemblyInfoCommentsToIgnore.Contains($line)) { continue }
        if ($line -match $UsingStatementRegex) { continue }
        if ($line -match $AssemblyAttributeSingleParameterRegex) {
            switch ($matches[1]) {
                { @('AssemblyCompany', 'AssemblyConfiguration', 'AssemblyCopyright', 'AssemblyCulture', 'AssemblyDescription', 'AssemblyFileVersion', 'AssemblyProduct', 'AssemblyTitle', 'AssemblyTrademark', 'AssemblyVersion', 'ComVisible', 'Guid') -contains $_ } {
                    if ($null -ne $data[$_]) { throw "$_ is set multiple times in $filename" }
                    $data[$_] = $matches[2]
                }
                BootstrapperApplication {
                    if ($null -ne $data.BootstrapperApplication) { throw "BootstrapperApplication is set multiple times in $filename" }
                    $data.BootstrapperApplication = $matches[2]
                    $usings.Add('Microsoft.Tools.WindowsInstallerXml.Bootstrapper') | Out-Null
                    if ($RootNamespace) {
                        $usings.Add($RootNamespace) | Out-Null
                    }
                }
                InternalsVisibleTo {
                    $data.InternalsVisibleTo.Add($matches[2]) | Out-Null
                    $usings.Add('System.Runtime.CompilerServices') | Out-Null
                }
                default {
                    throw "Unknown attribute $_ in $filename"
                }
            }
            continue
        }
        if ($line -match $AssemblyAttributeThemeInfoRegex) {
            if ($null -ne $data.ThemeInfo) { throw "ThemeInfo is set multiple times in $filename" }
            $data.ThemeInfo = $matches[1] + ', ' + $matches[3]
            $usings.Add('System.Windows') | Out-Null
            continue
        }
        throw "Unexpected line in $($filename):" + [System.Environment]::NewLine + $line
    }
    
    $output = $usings | Where-Object { $_.StartsWith('System.') } | ForEach-Object { "using $_;" } | out-string
    $output += $usings | Where-Object { -not $_.StartsWith('System.') } | ForEach-Object { "using $_;" } | out-string
    $output += [System.Environment]::NewLine
    if ($data.AssemblyTitle -and $data.AssemblyTitle -ne '"' + $ProjectName + '"') { throw "Unexpected AssemblyTitle in $($filename): $($data.AssemblyTitle) instead of ""$ProjectName""" }
    $output += '[assembly: AssemblyTitle("' + $ProjectName + '")]' + [System.Environment]::NewLine
    if ($data.AssemblyDescription -and $data.AssemblyDescription -ne '""') { $output += '[assembly: AssemblyDescription(' + $data.AssemblyDescription + ')]' + [System.Environment]::NewLine }
    if ($data.AssemblyConfiguration -and $data.AssemblyConfiguration -ne '""') { throw "Unexpected AssemblyConfiguration in $($filename): $($data.AssemblyConfiguration)" }
    if ($data.AssemblyCompany -and $data.AssemblyCompany -ne '""' -and $data.AssemblyCompany -ne '"Red Gate Software Ltd"') { throw "Unexpected AssemblyCompany in $($filename): $($data.AssemblyCompany) instead of ""Red Gate Software Ltd""" }
    $output += '[assembly: AssemblyCompany("Red Gate Software Ltd")]' + [System.Environment]::NewLine
    if ($data.AssemblyProduct -and $data.AssemblyProduct -ne '""' -and $data.AssemblyProduct -ne '"' + $ProjectName + '"') { throw "Unexpected AssemblyProduct in $($filename): $($data.AssemblyProduct) instead of ""$correctProductName""" }
    $output += '[assembly: AssemblyProduct("' + $ProductName + '")]' + [System.Environment]::NewLine
    if ($data.AssemblyCopyright -and $data.AssemblyCopyright -ne '""' -and -not $data.AssemblyCopyright -match '"Copyright ©  20[1-9][0-9]"' -and -not $data.AssemblyCopyright -match '"Copyright © Red Gate Software Ltd 20[1-9][0-9]"') { throw "Unexpected AssemblyCopyright in $($filename): $($data.AssemblyCopyright) instead of ""Copyright © Red Gate Software Ltd $year""" }
    $output += '[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd ' + $year + '")]' + [System.Environment]::NewLine
    if ($data.AssemblyTrademark -and $data.AssemblyTrademark -ne '""') { throw "Unexpected AssemblyTrademark in $($filename): $($data.AssemblyTrademark)" }
    if ($data.AssemblyCulture -and $data.AssemblyCulture -ne '""') { throw "Unexpected AssemblyCulture in $($filename): $($data.AssemblyCulture)" }

    $output += [System.Environment]::NewLine
    $ComVisible = if ($data.ComVisible) { $data.ComVisible } else { 'false' }
    $output += '[assembly: ComVisible(' + $ComVisible + ')]' + [System.Environment]::NewLine
    if ($null -eq $data.Guid) { throw "Guid not set in $filename" }
    $output += '[assembly: Guid(' + $data.Guid + ')]' + [System.Environment]::NewLine

    if ($data.ThemeInfo) {
        $output += [System.Environment]::NewLine + '[assembly: ThemeInfo(' + $data.ThemeInfo + ')]' + [System.Environment]::NewLine
    }

    if ($data.BootstrapperApplication) {
        $output += [System.Environment]::NewLine + '[assembly: BootstrapperApplication(' + $data.BootstrapperApplication + ')]' + [System.Environment]::NewLine
    }

    $output += @"

[assembly: AssemblyVersion("$Version")]
[assembly: AssemblyFileVersion("$Version")]

"@

    if ($data.InternalsVisibleTo.Count -ge 1) {
        $output += [System.Environment]::NewLine
        $output += $data.InternalsVisibleTo | ForEach-Object { "[assembly: InternalsVisibleTo($_)]" } | Out-String
    }

    $output = $output.TrimEnd()
    if ($output -ne $rawinput.TrimEnd()) {
        $output | Out-File $filename -Encoding UTF8
    }
}
