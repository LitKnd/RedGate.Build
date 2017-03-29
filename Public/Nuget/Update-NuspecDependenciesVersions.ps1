<#
.SYNOPSIS
  Update the dependencies versions inside a given nuspec file.
.DESCRIPTION
  Update the dependencies versions inside the nuspec files by looking
  at the list of nuget packages that are being used in the VS solution.
#>
function Update-NuspecDependenciesVersions {
    [CmdletBinding()]
    param(
        # The path to the .nuspec that is going to be updated
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeLine = $True)]
        [string] $NuspecFilePath,

        # A list of nuget packages.config file paths.
        [Parameter(Mandatory = $True, Position = 1)]
        [string[]] $PackagesConfigPaths,

        # A hashtable of package id/versions we DO want to override in the nuspec.
        [Hashtable] $PackageVersionOverride,

        # A list of names of packages whose versions should not be changed.
        [string[]] $doNotUpdate
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'VerbosePreference'

        # Load the nuget packages
        $nugetPackages = Get-NugetPackagesFromConfigFiles -PackagesConfigPaths $PackagesConfigPaths
        # Remove any .Obfuscated suffix we may have on some packages to catch version clashes between unobfuscated and obfuscated versions.
        $nugetPackages | ForEach { $_.id = $_.id -replace '.obfuscated', '' }

        Test-NugetPackagesVersionsAreConsistent -NugetPackages $nugetPackages

        # Add/Override packages using versions from $PackageVersionOverride
        if( $PackageVersionOverride ) {
            $PackageVersionOverride.Keys | ForEach {
                $packageToOverride = $nugetPackages | where Id -eq $_
                if($packageToOverride) {
                    # found existing package. Override its version
                    $packageToOverride.Version = $PackageVersionOverride[$_]
                } else {
                    #this package is not listed. Add it.
                    $nugetPackages += [PSCustomObject] @{
                        Id = $_
                        Version = $PackageVersionOverride[$_]
                    }
                }
            }
        }
    }

    process {
        Write-Verbose "Processing $NuspecFilePath"
        $NuspecFilePath = Resolve-Path $NuspecFilePath

        $nuspec = [xml] (Get-Content $NuspecFilePath)
        # Update dependencies in groups
        $nuspec.package.metadata.dependencies.group.dependency | Update-Dependency -NugetPackages $nugetPackages -DoNotUpdate $doNotUpdate
        # Update dependencies outside of groups
        $nuspec.package.metadata.dependencies.dependency | Update-Dependency -NugetPackages $nugetPackages -DoNotUpdate $doNotUpdate

        $nuspec.Save($NuspecFilePath)
        Write-Verbose "Processed $NuspecFilePath"
    }

}

function Update-Dependency() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeLine = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 1)]
        $NugetPackages,
        # A list of names of packages whose versions should not be changed.
        [string[]] $doNotUpdate = $()

    )

    process {
        if($InputObject -eq $null) { return }

        $baseId = $InputObject.id -replace '.obfuscated', ''
        if($doNotUpdate -contains $baseId) { return }

        # Update the version of the dependency with the one from $nugetPackages
        $version = $NugetPackages | where Id -eq $baseId | select -ExpandProperty Version
        if($version) {
            $InputObject.version = Get-DependencyVersionRange $version
            Write-Verbose "Set dependency of $($InputObject.id) to $($InputObject.version)"
        } else {
            Write-Verbose "Keeping dependency of $($InputObject.id) to $($InputObject.version)"
        }
    }

}
