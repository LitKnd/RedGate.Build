# 1.5

- `Rewrite-AssemblyInfos` now takes an `-AssemblyVersionMajorOnly` switch, which sets `AssemblyVersion` to be "MAJOR.0.0.0", where MAJOR is the major version of the project. `AssemblyFileVersion` is still always set to the full version of the project.

# 1.4

- `Rewrite-AssemblyInfos` now writes out `AssemblyInformationalVersion` attribute, and takes an `-InfoVersionSuffix` parameter that adds a suffix to it.

# 1.3

- `Invoke-NUnit3ForAssembly` now accepts the optional `-Timeout` parameter, which sets NUnit's `--timeout` option, setting a timeout for each test case in milliseconds.
- `Rewrite-AssemblyInfos` now preserves `AssemblyTitle` and `CLSCompliant`.

# 1.2

- New `Rewrite-AssemblyInfos` cmdlet that normalizes AssemblyInfo.cs files in a standardized way.

# 1.1

- `Invoke-NUnit3ForAssembly` now accepts the optional `-ProcessIsolation` parameter, which sets NUnit's `--process` option.

# 1.0

- `Invoke-NUnitForAssembly` and `Invoke-NUnit3ForAssembly`, when run with code coverage enabled, by default only cover the NUnit process itself, any not any subprocesses. This can be overridden using the `-DotCoverProcessFilters` parameter.
- `-DotNotImportResultsToTeamcity` has been renamed to `-DoNotImportResultsToTeamcity` (removing the extra t).
- Fixed issues where certain cmdlets where not working for pipelines.

# 0.6

- `Update-NuspecDependenciesVersions` now accepts the `-SpecificVersions` switch. Using the switch will use a specific version rather than a range for dependencies with three-part version numbers.
- `Invoke-NUnit3ForAssembly` and `Invoke-DotCoverForExecutable` now accept the optional `-TargetWorkingDirectory` parameter to specify the working directory for the tests to run in.
- `Remove-IgnoredTests` now supports the NUnit 3 results xml format and uses an xslt transform to perform the removal.

# 0.5

- New `Update-ProjectProperties` cmdlet that can be used to set various properties of a C# project file, such as Version, AssemblyVersion, FileVersion and PackageReleaseNotes. This provides an alternative to `Update-AssemblyVersion` as we progressively move away from using AssemblyInfo.cs files for project properties.
- `Select-ReleaseNotes` now preserves whitespace.

# 0.4

- `Invoke-SigningService` will now accept a NuGet package. The NuGet package is not directly signed itself. Instead, it is unpacked to a temporary folder, all the assembly dlls in the 'lib' sub-folder are signed by the signing service, and then the NuGet package is reassembled.

# 0.3

- `Invoke-NUnitForAssembly` and `Invoke-NUnit3ForAssembly` can now import test results in both Teamcity and VSTS [#79](https://github.com/red-gate/RedGate.Build/pull/79)
- Add support for Powershell files to `Invoke-SigningService` [#77](https://github.com/red-gate/RedGate.Build/pull/77)
- Add new helper functions to write integration messages to CI servers other than Teamcity [#74](https://github.com/red-gate/RedGate.Build/pull/74), [#78](https://github.com/red-gate/RedGate.Build/pull/78)
    - VSTS
        - `Write-VSTSBuildNumber` (alias: `VSTS-BuildNumber`)
        - `Write-VSTSImportNUnitReport` (alias: `VSTS-ImportNUnitReport`)
        - `Write-VSTSLoggingCommand` (alias: `VSTS-LoggingCommand`)
    - Generic. (Will call the Teamcity or VSTS functions when Teamcity or VSTS is detected)
        - `Write-CIBuildNumber` (alias `CI-BuildNumber`)
        - `Write-CIPublishArtifact` (alias: `CI-PublishArtifact`)

# 0.2

- First version with release notes [#76](https://github.com/red-gate/RedGate.Build/pull/76)
