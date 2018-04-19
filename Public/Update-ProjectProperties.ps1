<#
.SYNOPSIS
  Updates various properties in a VS2017-style project file.

.DESCRIPTION
  Updates various properties in a VS2017-style project file, including the Version, AssemblyVersion, FileVersion and PackageReleaseNotes.
  
  Please note that it may be simpler and more appropriate to inject these properties into msbuild via the command-line, rather than manipulating the project files.
  This cmdlet is primarily useful if you need to specify different properties across different projects in your solution.

.PARAMETER Path
  The path of the project file to update.

.PARAMETER Version
  The Version of the project, this defines the version of any output NuGet package. Is equivalent to the value of the AssemblyInformationalVersionAttribute.

.PARAMETER AssemblyVersion
  The AssemblyVersion of the project, this defines the runtime compatibility version of the output assembly. Is equivalent to the value of the AssemblyVersionAttribute.

.PARAMETER FileVersion
  The FileVersion of the project, this defines the file version of the output assembly. Is equivalent to the value of the AssemblyFileVersionAttribute.

.PARAMETER PackageReleaseNotes
  The PackageReleaseNotes of the project, this defines the release notes for any output NuGet package.

.OUTPUTS
  The input Path parameter, to facilitate command chaining.
#>
function Update-ProjectProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeLine = $True)]
        [string] $Path,

        [Parameter(Mandatory = $False)]
        [string] $Version,

        [Parameter(Mandatory = $False)]
        [version] $AssemblyVersion,

        [Parameter(Mandatory = $False)]
        [version] $FileVersion,

        [Parameter(Mandatory = $False)]
        [string] $PackageReleaseNotes
    )

    if (-not (Test-Path $Path)) {
        throw "Project file not found: $Path"
    }

    $ProjectXml = [xml] (Get-Content $Path)
    $PropertyGroupElement = ($ProjectXml | Select-Xml -XPath '/Project[@Sdk]/PropertyGroup[1]').Node
    if ($PropertyGroupElement) {
        Write-Verbose "Updating properties in project file $Path"
        Update-Property $ProjectXml $PropertyGroupElement 'Version' $Version
        Update-Property $ProjectXml $PropertyGroupElement 'AssemblyVersion' $AssemblyVersion
        Update-Property $ProjectXml $PropertyGroupElement 'FileVersion' $FileVersion
        Update-Property $ProjectXml $PropertyGroupElement 'PackageReleaseNotes' $PackageReleaseNotes

        $ProjectXml.Save($Path)
    } else {
        Write-Warning "Project file format not supported. Skipping $Path"
    }

    # Return the input Path to enable pilelining.
	return $Path
}

function Update-Property
{
    [CmdletBinding()]
    param (
        [Xml.XmlDocument] $XmlDocument,
        [Xml.XmlElement] $ParentElement,
        [string] $PropertyName,
        [string] $PropertyValue
    )

    if ($PropertyValue) {
        Write-Verbose "  Setting property $PropertyName to $PropertyValue"
        $PropertyElement = ($ParentElement | Select-Xml -XPath $PropertyName).Node
        if (-not $PropertyElement) {
            $PropertyElement = $XmlDocument.CreateElement($PropertyName)
            $Null = $ParentElement.AppendChild($PropertyElement)
        }
        $PropertyElement.InnerText = $PropertyValue
    }
}
