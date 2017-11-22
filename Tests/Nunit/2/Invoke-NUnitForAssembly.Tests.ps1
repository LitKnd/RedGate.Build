#requires -Version 4 -Modules Pester

$FullPathToModuleRoot = Resolve-Path $PSScriptRoot\..\..\..

Describe 'Invoke-NUnitForAssembly' {

    Context 'Nunit 4.0' {
        It "should throw Unexpected NUnit version" {
            { Invoke-NUnitForAssembly -Assembly 'myassembly.dll' -NUnitVersion '4.0' } | Should Throw "Unexpected NUnit version '4.0'. This function only supports Nunit v2"
        }
    }

    Context 'Nunit 3.0' {
        It "should throw Unexpected NUnit version" {
            { Invoke-NUnitForAssembly -Assembly 'myassembly.dll' -NUnitVersion '3.0' } | Should Throw "NUnit version '3.0' is not supported by this function. Use Invoke-NUnit3ForAssembly instead."
        }
    }

    Context 'Run real NUnit tests' {
        $tempFolder = New-Item "$FullPathToModuleRoot\.temp\nunit" -ItemType Directory -Force -Verbose
        # nunit2-test.dll is a NUnit assembly (compiled against NUnit 2.6.4) with a single test that will always pass.
        Copy-Item $PSScriptRoot\nunit2-test.dll -Destination $tempFolder -Verbose

        Install-Package -Name NUnit.Runners -Version 2.6.4
        Copy-Item $FullPathToModuleRoot\packages\NUnit.Runners.2.6.4\tools\nunit.framework.dll -Destination $tempFolder -Verbose

        It 'Should not throw exceptions when TestResultFilenamePattern is empty' {
            Invoke-NUnitForAssembly `
                -AssemblyPath $tempFolder\nunit2-test.dll `
                -NUnitVersion '2.6.4' `
                -TestResultFilenamePattern $null
        }

    }
}
