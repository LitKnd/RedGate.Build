#requires -Version 4 -Modules Pester

$FullPathToModuleRoot = Resolve-Path $PSScriptRoot\..\..\..

. "$FullPathToModuleRoot\Private\NUnit\3\Get-NUnit3ConsoleExePath.ps1"

Describe 'Get-NUnit3ConsoleExePath' {

    Context 'Nunit 3.8.0' {
        $result = Get-NUnit3ConsoleExePath -NUnitVersion '3.8.0'

        It 'should return the right path' {
            $result | Should Be "$FullPathToModuleRoot\packages\NUnit.ConsoleRunner.3.8.0\tools\nunit3-console.exe"
        }
    }

    Context 'Nunit 3.2.0' {
        $result = Get-NUnit3ConsoleExePath -NUnitVersion '3.2.0'

        It 'should return the right path' {
            $result | Should Be "$FullPathToModuleRoot\packages\NUnit.ConsoleRunner.3.2.0\tools\nunit3-console.exe"
        }
    }

    Context 'Nunit 3.0.0' {
        $result = Get-NUnit3ConsoleExePath -NUnitVersion '3.0.0'

        It 'should return the right path' {
            $result | Should Be "$FullPathToModuleRoot\packages\NUnit.Console.3.0.0\tools\nunit3-console.exe"
        }
    }

    Context 'Nunit 2.6.4' {
        It "should throw Unexpected NUnit version" {
            { Get-NUnit3ConsoleExePath -NUnitVersion '2.6.4' } | Should Throw "Unexpected NUnit version '2.6.4'. This function only supports Nunit v3"
        }
    }

}
