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

        It 'should pass where clause as an argument' {
            $ExpectedWhereClause = 'cat == TestWhereClause';
            
            Invoke-NUnit3ForAssembly -Assembly 'build.ps1' -NUnitVersion '3.0.0' -EnableCodeCoverage $true -Where $ExpectedWhereClause
            
            Assert-MockCalled Invoke-DotCoverForExecutable -ModuleName RedGate.Build -Times 1 -ParameterFilter {$TargetArguments -like "*$ExpectedWhereClause*"} -Scope It
        }
    }
}
