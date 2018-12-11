<#
.SYNOPSIS
  Updates the AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion attributes in a source file.
.DESCRIPTION
  Updates the AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion attributes in a source file, typically AssemblyInfo.cs. This cmdlet should be used on the AssemblyInfo.cs files of each project in a solution before the solution is compiled, so that the build version number is correctly injected into the compiled assemblies.
.PARAMETER SourceFilePath
  The path of the source file that contains the AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion attributes.
.PARAMETER Version
  The Assembly Version to be injected into the source file.
.PARAMETER FileVersion
  The optional Assembly File Version to be injected into the source file. If unspecified, defaults to the value of the Version parameter.
 .PARAMETER InformationalVersion
  The optional Assembly Informational Version to be injected into the source file. If unspecified, defaults to the value of the Version parameter.
.PARAMETER Encoding
  The optional encoding of the source file. Defaults to UTF8 without emitting a BOM [i.e. new UTF8Encoding(false)].
.OUTPUTS
  The input SourceFilePath parameter, to facilitate command chaining.
.EXAMPLE
  'AssemblyInfo.cs' | Update-AssemblyVersion -Version '1.2.0.12443'

  This shows the minimal correct usage, whereby the SourceFilePath is piped to the cmdlet, along with the require Version parameter.
.EXAMPLE
  'AssemblyInfo.cs' | Update-AssemblyVersion -Version $BuildNumber -InformationalVersion $NuGetPackageVersion

  This shows more typical usage, whereby Version is provided by a the curent build number and InformationalVersion is provided by the NuGet package version (which can include a pre-release package suffix).
#>
#requires -Version 3
function Update-AssemblyVersion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeLine = $True)]
        [string] $SourceFilePath,

        [Parameter(Mandatory = $True)]
        [version] $Version,

        [Parameter(Mandatory = $False)]
        [version] $FileVersion,

        [Parameter(Mandatory = $False)]
        [string] $InformationalVersion,

        [Parameter(Mandatory = $False)]
        [System.Text.Encoding] $Encoding
    )

    process {
        # If no encoding is specified, use UTF8 without emitting a BOM. We use this rather than
        # System.Text.Encoding.UTF8 because that emits BOMs, against recommended practice.
        if (!$Encoding) {
            $Encoding = New-Object 'System.Text.UTF8Encoding' $False
        }

        # Fallback to defaults for FileVersion and InformationalVersion if necessary.
        if (!$FileVersion) { $FileVersion = $Version }
        if (!$InformationalVersion) { $InformationalVersion = [string] $FileVersion }

        # Log what we're about to do.
        Write-Verbose 'Updating version numbers:'
        Write-Verbose "  Version = $Version"
        Write-Verbose "  FileVersion = $FileVersion"
        Write-Verbose "  InformationalVersion = $InformationalVersion"

        # Read the file contents, update the assembly version attributes, then save it again.
        Resolve-Path $SourceFilePath | ForEach-Object {
            Write-Verbose "  SourceFile = $_"
            $CurrentContents = [System.IO.File]::ReadAllText($_, $Encoding)
            $NewContents = $CurrentContents `
                -replace '(?<=AssemblyVersion\s*\(\s*@?")[0-9\.\*]*(?="\s*\))', $Version.ToString() `
                -replace '(?<=AssemblyFileVersion\s*\(\s*@?")[0-9\.\*]*(?="\s*\))', $FileVersion.ToString() `
                -replace '(?<=AssemblyInformationalVersion\s*\(\s*@?")[a-zA-Z0-9\.\*\-]*(?="\s*\))', $InformationalVersion
            [System.IO.File]::WriteAllText($_, $NewContents, $Encoding)
        }
        
        # Return the input SoureFilePath to enable pilelining.
        return $SourceFilePath
    }
}
