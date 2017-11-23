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
        # This parameter has several aliases (JarPath, VsixPath, ClickOnceApplicationPath and AssemblyPath) to help improve readability of your scripts.
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [Alias('JarPath', 'VsixPath', 'ClickOnceApplicationPath', 'AssemblyPath')]
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
        if ([String]::IsNullOrEmpty($SigningServiceUrl)) {
            throw 'Cannot sign assembly. -SigningServiceUrl was not specified and the SigningServiceUrl environment variable is not set.'
        }
        if (!(Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }

        # Only sign the file if it does not already have a valid Authenticode signature
        if(!$Force.IsPresent -and (Get-AuthenticodeSignature $FilePath).Status -eq 'Valid') {
            Write-Verbose "Skipping signing $FilePath. It is already signed"
            return $FilePath
        }

        # Determine the file type.
        $FileType = $Null
        switch ([System.IO.Path]::GetExtension($FilePath)) {
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

        # Make the web request to the signing service.
        $Headers = @{};
        Add-ToHashTableIfNotNull $Headers -Key 'FileType' -Value $FileType
        Add-ToHashTableIfNotNull $Headers -Key 'Certificate' -Value $Certificate
        Add-ToHashTableIfNotNull $Headers -Key 'Description' -Value $Description
        Add-ToHashTableIfNotNull $Headers -Key 'MoreInfoUrl' -Value $MoreInfoUrl
        Add-ToHashTableIfNotNull $Headers -Key 'HashAlgorithm' -Value $HashAlgorithm

        Write-Verbose "Signing $FilePath using $SigningServiceUrl"
        $Headers.Keys | ForEach { Write-Verbose "`t $_`: $($Headers[$_])" }

        $Response = Invoke-WebRequest `
            -Uri $SigningServiceUrl `
            -InFile $FilePath `
            -OutFile $FilePath `
            -Method Post `
            -ContentType 'binary/octet-stream' `
            -Headers $Headers

        # TODO: How should we check the response? Need to fail if the signing failed.

        return $FilePath
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
