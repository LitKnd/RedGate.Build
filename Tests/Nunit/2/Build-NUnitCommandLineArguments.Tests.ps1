#requires -Version 4 -Modules Pester

$FullPathToModuleRoot = Resolve-Path $PSScriptRoot\..\..\..

. "$FullPathToModuleRoot\Private\NUnit\2\Build-NUnitCommandLineArguments.ps1"

Describe 'Build-NUnitCommandLineArguments' {

    function Nunit2Parameters($assembly, $TestResult = 'TestResult') {
        "$assembly /xml=`"$assembly.$TestResult.xml`" /nologo /nodots /noshadow /labels /out:`"$assembly.$TestResult.TestOutput.txt`" /err:`"$assembly.$TestResult.TestError.txt`""
    }

    Context 'With minimum arguments' {
        $result = Build-NUnitCommandLineArguments `
            -AssemblyPath 'my-test-assembly.dll'

        It 'should return the right value' {
            $result -join ' ' | Should Be (Nunit2Parameters 'my-test-assembly.dll')
        }
    }

    Context 'With all arguments' {
        $result = Build-NUnitCommandLineArguments `
            -AssemblyPath 'my-test-assembly.dll' `
            -FrameworkVersion 'net-4.0' `
            -ExcludedCategories 'exclude1', 'exclude2' `
            -IncludedCategories 'include1', 'include2' `
            -TestResultFilenamePattern 'SpecialPattern'

        It 'should return the right value' {
            $result -join ' ' | Should Be "$(Nunit2Parameters 'my-test-assembly.dll' 'SpecialPattern') /framework:net-4.0 /exclude:exclude1;exclude2 /include:include1;include2"
        }
    }

}
