#requires -Version 4 -Modules Pester

$FullPathToModuleRoot = Resolve-Path $PSScriptRoot\..\..\..

Describe 'Invoke-NUnit3ForAssembly' {

    Context 'Nunit 2.6.4' {
        It "should throw Unexpected NUnit version" {
            { Invoke-NUnit3ForAssembly -Assembly 'myassembly.dll' -NUnitVersion '2.6.4' } | Should Throw "Unexpected NUnit version '2.6.4'. This function only supports Nunit v3"
        }
    }
    
    Context 'Nunit 3.0.0' {
        Mock -ModuleName RedGate.Build Invoke-DotCoverForExecutable { }
        Mock -ModuleName RedGate.Build Push-Location { }
        Mock -ModuleName RedGate.Build Pop-Location { }
        Mock -ModuleName RedGate.Build Execute-Command { }

        It 'should pass where clause as an argument' {
            $ExpectedWhereClause = 'cat == TestWhereClause';
            
            Invoke-NUnit3ForAssembly -Assembly 'build.ps1' -NUnitVersion '3.0.0' -EnableCodeCoverage $true -Where $ExpectedWhereClause
            
            Assert-MockCalled Invoke-DotCoverForExecutable -ModuleName RedGate.Build -Times 1 -ParameterFilter {$TargetArguments -like "*$ExpectedWhereClause*"} -Scope It
        }

        It 'should pass working directory as an argument' {
            $ExpectedWorkingDirectory = 'd:\working\directory\'

            Invoke-NUnit3ForAssembly -Assembly 'build.ps1' -NUnitVersion '3.0.0' -EnableCodeCoverage $true -TargetWorkingDirectory $ExpectedWorkingDirectory

            Assert-MockCalled Invoke-DotCoverForExecutable -ModuleName RedGate.Build -Times 1 -ParameterFilter {$TargetWorkingDirectory -eq $ExpectedWorkingDirectory} -Scope It
        }

        It 'should set working directory when no code coverage' {
            $ExpectedWorkingDirectory = 'd:\working\directory\'

            Invoke-NUnit3ForAssembly -Assembly 'build.ps1' -NUnitVersion '3.0.0' -EnableCodeCoverage $false -TargetWorkingDirectory $ExpectedWorkingDirectory

            Assert-MockCalled Push-Location -ModuleName RedGate.Build -Times 1 -ParameterFilter {$Path -eq $ExpectedWorkingDirectory} -Scope It
            Assert-MockCalled Pop-Location -ModuleName RedGate.Build -Times 1 -Scope It
        }

        It 'should not set working directory when parameter not passed' {
            Invoke-NUnit3ForAssembly -Assembly 'build.ps1' -NUnitVersion '3.0.0' -EnableCodeCoverage $false

            Assert-MockCalled Push-Location -ModuleName RedGate.Build -Exactly 0 -Scope It
            Assert-MockCalled Pop-Location -ModuleName RedGate.Build -Exactly 0 -Scope It
        }
    }
}
