<#
.SYNOPSIS
  Unzip a .zip archive to a directory
.DESCRIPTION
  Extracts a zip file to the specified destination directory
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

  if(Get-Command Expand-Archive -ErrorAction 0) {
    Expand-Archive $Archive $Destination
  } else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Destination)
  }
}

New-Alias Unzip-Files Expand-ZipArchive -Force
