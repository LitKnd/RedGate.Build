<#
.SYNOPSIS
  Signs a .NET assembly, PowerShell, jar file, VSIX installer or ClickOnce application.
.DESCRIPTION
  Signs a .NET assembly, PowerShell, jar file, VSIX installer or ClickOnce application using the Redgate signing service.
.OUTPUTS
  The FilePath parameter, to enable call chaining.
.EXAMPLE
  $AssemblyPath = "$SourceDir\Build\$Configuration\RedGate.MyAwesomeProduct.dll"
  Invoke-SigningService -SigningServiceUrl 'https://signingservice.internal/sign' -AssemblyPath $AssemblyPath

  This shows how to sign a .NET dll, with the signing service URL being explicitly stated.
.EXAMPLE
  $VsixPath = "$SourceDir\Build\$Configuration\RedGate.MyAwesomeProduct.Installer.vsix"
  Invoke-SigningService -VsixPath $AssemblyPath -HashAlgorithm SHA1

  This shows how to sign a Visual Studio Installer file. The signing service URL is taken from the $env:SigningServiceUrl environment variable that is present on all of the build agents.
#>
function Invoke-SigningService {
    [CmdletBinding()]
    param(
        # The path of the file to be signed. The file will me updated in place with a corresponding signed version.
        # The path may reference a .NET assembly (.exe or .dll), a PowerShell file, a java Jar file, a Visual Studio Installer (.vsix) or a .NET ClickOnce application (.application).
        # This parameter has several aliases (JarPath, VsixPath, ClickOnceApplicationPath, AssemblyPath and NuGetPackagePath) to help improve readability of your scripts.
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Alias('JarPath', 'VsixPath', 'ClickOnceApplicationPath', 'AssemblyPath', 'NuGetPackagePath')]
        [string] $FilePath,

        # The url of the signing service. If unspecified, defaults to the $env:SigningServiceUrl environment variable.
        [Parameter(Mandatory = $False)]
        [string] $SigningServiceUrl = $env:SigningServiceUrl,

        # Indicates which signing certificate to use. Defaults to 'master'.
        [Parameter(Mandatory = $False)]
        [string] $Certificate = 'Master',

        # Allow overriding the signature algorithm.
        # Valid values are sha1, sha256.
        #
        # If not set, the default is:
        #
        # For binary files (.dll, .exe):
        #   dual sign using both sha1 and sha256.
        # For vsix files:
        #   vsix files cannot be dual signed. throw an error if -HashAlgorithm is not set.
        #   if targeting Visual Studio up to 2013, select sha1
        #   if targeting Visual Studio 2015+, select sha256
        #   Until such days that Microsoft release VS updates that allow VS 2013 to recognize sha256 ? or VS 2015 to accept sha1 ?
        # For msi, clickonce files:
        #   msi, clickonce files cannot be dual signed.
        #   Use sha256 by default
        # For jar files:
        #   use sha256 by default
        [Parameter(Mandatory = $False)]
        [ValidateSet('sha1', 'sha256')]
        [string] $HashAlgorithm,

        # An optional description. Defaults to 'Red Gate Software Ltd.'.
        [Parameter(Mandatory = $False)]
        [string] $Description = 'Red Gate Software Ltd.',

        # An optional URL that can be used to specify more information about the signed assembly by end-users. Defaults to 'http://www.red-gate.com'.
        [Parameter(Mandatory = $False)]
        [string] $MoreInfoUrl = 'http://www.red-gate.com',

        # If present, do not skip signing the file if it is already signed.
        # If the file is already signed, do resign it.
        [switch] $Force
    )
    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'VerbosePreference'
        $local:ProgressPreference = 'SilentlyContinue'
    }

    process {
        # Simple error checking.
        if ([string]::IsNullOrEmpty($SigningServiceUrl)) {
            throw 'Cannot sign file. -SigningServiceUrl was not specified and the SigningServiceUrl environment variable is not set.'
        }
        if (!(Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }

        $Null = Invoke-SigningServiceCommon `
            -FilePath $FilePath `
            -SigningServiceUrl $SigningServiceUrl `
            -Certificate $Certificate `
            -HashAlgorithm $HashAlgorithm `
            -Description $Description `
            -MoreInfoUrl $MoreInfoUrl `
            -Force:$Force.IsPresent

        return $FilePath
    }
}

function Invoke-SigningServiceCommon {
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [string] $SigningServiceUrl,
        [string] $Certificate,
        [string] $HashAlgorithm,
        [string] $Description,
        [string] $MoreInfoUrl,
        [switch] $Force
    )

    # Only sign the file if it does not already have a valid Authenticode signature
    if(!$Force.IsPresent -and (Get-AuthenticodeSignature $FilePath).Status -eq 'Valid') {
        Write-Verbose "Skipping signing $FilePath. It is already signed"
        return
    }

    # If we have a NuGet package, use the function that unpacks its contents and signs the contained assemblies ...
    if ([IO.Path]::GetExtension($FilePath) -eq '.nupkg') {
        Invoke-SigningServiceForNuGetPackage `
            -FilePath $FilePath `
            -SigningServiceUrl $SigningServiceUrl `
            -Certificate $Certificate `
            -HashAlgorithm $HashAlgorithm `
            -Description $Description `
            -MoreInfoUrl $MoreInfoUrl `
            -Force:$Force.IsPresent
    }
    
    # ... otherwise use the function that directly invokes the signing service.
    else {
        Invoke-SigningServiceForFile `
            -FilePath $FilePath `
            -SigningServiceUrl $SigningServiceUrl `
            -Certificate $Certificate `
            -HashAlgorithm $HashAlgorithm `
            -Description $Description `
            -MoreInfoUrl $MoreInfoUrl `
            -Force:$Force.IsPresent
    }
}

function Invoke-SigningServiceForFile {
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [string] $SigningServiceUrl,
        [string] $Certificate,
        [string] $HashAlgorithm,
        [string] $Description,
        [string] $MoreInfoUrl,
        [switch] $Force
    )
    
    # Determine the file type.
    $FileType = $Null
    switch ([IO.Path]::GetExtension($FilePath)) {
        '.exe' { $FileType = 'Exe' }
        '.msi' {
            $FileType = 'Exe'
            #  msi files cannot be double signed at the moment.
            #  so tell the signing service to use sha256
            if(!$HashAlgorithm) { $HashAlgorithm = 'sha256' }
        }
        '.dll' { $FileType = 'Exe' }
        '.vsix' {
            $FileType = 'Vsix'
            if(!$HashAlgorithm) {
                throw @'
Cannot sign vsix package. -HashAlgorithm was not specified.
Use sha1 if targeting VS 2013 and older. Use sha256 if targeting VS 2015+
'@
            }
        }
        '.jar' { $FileType = 'Jar' }
        '.application' { $FileType = 'ClickOnce' }
        '.manifest' { $fileType = 'ClickOnce' }
        '.ps1' { $fileType = 'PowerShell' }
        '.ps1xml' { $fileType = 'PowerShell' }
        '.psc1' { $fileType = 'PowerShell' }
        '.psd1' { $fileType = 'PowerShell' }
        '.psm1' { $fileType = 'PowerShell' }
        default { throw "Unsupported file type: $FilePath" }
    }
    
    $TempDir = New-TempDir
    try {
        # The output file from the signing service. We don't overwrite the original until the response has been validated.
        $OutFilePath = "$TempDir\$([IO.Path]::GetFileName($FilePath))"
        
        # Make the web request to the signing service.
        $Headers = @{};
        Add-ToHashTableIfNotNull $Headers -Key 'FileType' -Value $FileType
        Add-ToHashTableIfNotNull $Headers -Key 'Certificate' -Value $Certificate
        Add-ToHashTableIfNotNull $Headers -Key 'Description' -Value $Description
        Add-ToHashTableIfNotNull $Headers -Key 'MoreInfoUrl' -Value $MoreInfoUrl
        Add-ToHashTableIfNotNull $Headers -Key 'HashAlgorithm' -Value $HashAlgorithm

        Write-Verbose "Signing $FilePath using $SigningServiceUrl"
        $Headers.Keys | ForEach-Object { Write-Verbose "`t $_`: $($Headers[$_])" }

        Invoke-WebRequest `
            -Uri $SigningServiceUrl `
            -InFile $FilePath `
            -OutFile $OutFilePath `
            -Method Post `
            -ContentType 'binary/octet-stream' `
            -Headers $Headers
        
        # The signing service guarantees an error response if anything went wrong with signing,
        # so if we've got here, it's a good sign that the signing request succeeded.
        # See https://github.com/red-gate/SigningService/blob/master/SigningService/Controllers/HomeController.cs#L29
        
        # Sanity check the signature, as it's the only way we can be absolutely sure the signing worked.
        if ((Get-AuthenticodeSignature $OutFilePath).Status -ne 'Valid') {
            throw 'Signature validation failed on the file returned by the signing service'
        }
        
        # And finally overwrite the original input file with the signed version.
        Move-Item -Path $OutFilePath -Destination $FilePath -Force
    } finally {
        # Clean up.
        Remove-Item $TempDir -Recurse -Force
    }
}

function Invoke-SigningServiceForNuGetPackage {
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [string] $SigningServiceUrl,
        [string] $Certificate,
        [string] $HashAlgorithm,
        [string] $Description,
        [string] $MoreInfoUrl,
        [switch] $Force
    )
    
    Write-Verbose 'Creating temp working dir'
    $TempDir = New-TempDir
    try
    {
        # First copy the NuGet package to the temp dir, giving it a .zip extension (Expand-Archive requires a .zip extension).
        Write-Verbose 'Copying NuGet package to the working dir'
        $ZipFilePath = "$TempDir\package.zip"
        Copy-Item -Path $FilePath -Destination $ZipFilePath
    
        # Next extract the zip file to a folder.
        Write-Verbose 'Expanding NuGet package contents to the working dir'
        $ContentsDir = [string] (mkdir "$TempDir\Contents")
        Expand-Archive -Path $ZipFilePath -DestinationPath $ContentsDir

        # Sign each assembly in the libs sub-folder.
        Write-Verbose 'Signing assemblies in the lib sub-folder'
        $LibsDir = "$ContentsDir\lib"
        if (Test-Path $LibsDir) {
            Get-ChildItem -Path $LibsDir -File -Recurse -Include '*.dll' |
            ForEach-Object {
                Write-Verbose "Signing $($_.FullName.Substring($ContentsDir.Length + 1))"
                Invoke-SigningServiceCommon `
                    -FilePath $_.FullName `
                    -SigningServiceUrl $SigningServiceUrl `
                    -Certificate $Certificate `
                    -HashAlgorithm $HashAlgorithm `
                    -Description $Description `
                    -MoreInfoUrl $MoreInfoUrl `
                    -Force:$Force.IsPresent
            }
        }
    
        # Compress the modified contents back into the zip file (Compress-Archive requires a .zip extension).
        Write-Verbose 'Recompressing NuGet package contents from the working dir'
        Compress-Archive -Path "$ContentsDir\*" -DestinationPath $ZipFilePath -Force -CompressionLevel Optimal

        # Copy the zip file back over the original NuGet package file.    
        Copy-Item -Path $ZipFilePath -Destination $FilePath -Force
    }
    finally
    {
        Remove-Item $TempDir -Recurse -Force
    }
}

function Add-ToHashTableIfNotNull {
    param(
        [Parameter(Mandatory=$true)]
        [HashTable] $HashTable,
        [Parameter(Mandatory=$true)]
        [string] $Key,
        [string] $Value
    )

    if( $Value ) {
        $HashTable.Add($Key, $Value)
    }
}
