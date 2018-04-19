# 0.5

- New `Update-ProjectProperties` cmdlet that can be used to set various properties of a C# project file, such as Version, AssemblyVersion, FileVersion and PackageReleaseNotes. This provides an alternative to `Update-AssemblyVersion` as we progressively move away from using `AssemblyInfo.cs` files for project properties.
- `Update-NuspecDependenciesVersions` now accepts the `-SpecificVersions` switch. Using the switch will use a specific version rather than a range for dependencies with three-part version numbers.

# 0.4

- `Invoke-SigningService` will now accept a NuGet package. The NuGet package is not directly signed itself. Instead, it is unpacked to a temporary folder, all the assembly dlls in the `lib` sub-folder are signed by the signing service, and then the NuGet package is reassembled. 

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
