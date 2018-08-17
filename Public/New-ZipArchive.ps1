<#
.SYNOPSIS
  Zip a list of files into a .zip archive
.DESCRIPTION
  Uses 7zip to create a zip file containing files matching
  filename patterns passed in as $Files
.EXAMPLE
  New-ZipArchive -OutputFile .\Build\Build.zip -BasePath .\Build -Files ".\Build\Release\*.exe", ".\Build\Release\*.dll"

  Packages all .exe and .dll files within Build\Release\ to a zip file created at Build\Build.zip
  Strips the -BasePath value from the file paths in the archive.
  Paths in the archive will be:
    Release\myproject.exe
    Release\mydll1.dll
    Release\mydll2.dll
.NOTES
  Currently zipping using 7z.exe, just because it proved faster at the time of writing as the equivalent powershell based solutions.
#>
function New-ZipArchive {
    [CmdletBinding()]
    param(
        # A list of files/folders to be packaged. Single wildards (*) allowed.
        [Parameter(Mandatory=$true)]
        [string[]] $Files,

        # The path to the created zip file
        [Parameter(Mandatory=$true)]
        [string] $OutputFile,

        # (Optional) The Base Path. This is the path that will be removed from each file path in the created archive.
        [Parameter(Mandatory=$false)]
        [string] $BasePath
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'VerbosePreference'

    # Copy the files matching $Files to a temp folder so that
    # we can easily 7zip it and preserve directory paths.
    $tempFolder = New-TempDir
    try {
        $7ZipExe = Get-7ZipExePath

        if(Test-Path $OutputFile) {
            Write-Verbose "Remove existing (previous?) file $OutputFile"
            Remove-Item $OutputFile -Force
        }

        Resolve-Path $Files | ForEach {
            if($BasePath) {
                $destination = $_.Path -replace ([Regex]::Escape($BasePath)), $tempFolder
            }
            if ($destination)
            {
                # Make sure the destination parent folder exists...
                New-Item (Split-Path $destination) -ItemType Directory -Force | Out-Null
            }
            else
            {
                # Or just copy to the root if there is no $BasePath
                $destination = $tempFolder
            }
            Copy-Item $_.Path -Destination $destination -Recurse -Force
        }

        Write-Verbose "Zipping to $OutputFile"
        Execute-Command {
            & $7ZipExe a -r $OutputFile "$tempFolder\*" | Write-Verbose
        }
    } finally {
        Write-Verbose "Deleting temp dir: $tempFolder"
        Remove-Item $tempFolder -Force -Recurse -ErrorACtion SilentlyContinue
    }
}

New-Alias Zip-Files New-ZipArchive -Force
