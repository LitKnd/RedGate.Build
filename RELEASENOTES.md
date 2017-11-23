# 0.3

- Add support for Powershell files to `Invoke-SigningService` [#77](https://github.com/red-gate/RedGate.Build/pull/77)
- Add new helper functions to write integration messages to CI servers other than Teamcity [#74](https://github.com/red-gate/RedGate.Build/pull/74)
    - VSTS
        - `Write-VSTSBuildNumber` (alias: `VSTS-BuildNumber`)
        - `Write-VSTSImportNUnitReport` (alias: `VSTS-ImportNUnitReport`)
        - `Write-VSTSLoggingCommand` (alias: `VSTS-LoggingCommand`)
    - Generic. (Will call the Teamcity or VSTS functions when Teamcity or VSTS is detected)
        - `Write-CIBuildNumber` (alias `CI-BuildNumber`)
        - `Write-CIPublishArtifact` (alias: `CI-PublishArtifact`)

# 0.2

- First version with release notes [#76](https://github.com/red-gate/RedGate.Build/pull/76)
