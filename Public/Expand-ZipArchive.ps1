<#
.SYNOPSIS
  Unzip a .zip archive to a directory
.DESCRIPTION
  Uses 7zip to extract a zip file containing files matching
  filename patterns passed in as $Files
.EXAMPLE
  Expand-ZipArchive -Archive .\Build\MyZip.zip -Destination .\Build\MyZip

  Extracts all files in the archive at .\Build\MyZip.zip to the path .\Build\MyZip
.NOTES
  Will call through to Expand-Archive if available (PowerShell 5.0, or if
  PowerShell Community Extensions are installed). Otherwise uses [System.Io.Compression.ZipFile]
#>
function Expand-ZipArchive {
  [CmdletBinding()]
  param(
      # A list of files/folders to be packaged. Single wildards (*) allowed.
      [Parameter(Mandatory=$true)]
      [string] $Archive,

      # The path to the created zip file
      [Parameter(Mandatory=$true)]
      [string] $Destination
  )

  try {
    Get-Command Expand-Archive | Out-Null

    Expand-Archive $Archive $Destination
  } catch {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Destination)
  }
}

New-Alias Unzip-Files Expand-ZipArchive
