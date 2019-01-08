#requires -Version 4 -Modules Pester

$FullPathToModuleRoot = Resolve-Path $PSScriptRoot\..\..\..

. "$FullPathToModuleRoot\Private\NUnit\3\Build-NUnit3CommandLineArguments.ps1"

Describe 'Build-NUnit3CommandLineArguments' {

    function Nunit3Parameters($assembly, $TestResult = 'TestResult') {
        "$assembly --result=`"$assembly.$TestResult.xml`" --noheader --labels=On --out=`"$assembly.$TestResult.TestOutput.txt`""
    }

    Context 'With minimum arguments' {
        $result = Build-NUnit3CommandLineArguments `
            -AssemblyPath 'my-test-assembly.dll'

        It 'should return the right value' {
            $result -join ' ' | Should Be (Nunit3Parameters 'my-test-assembly.dll')
        }
    }

    Context 'With all arguments' {
        $result = Build-NUnit3CommandLineArguments `
            -AssemblyPath 'my-test-assembly.dll' `
            -x86 $true `
            -Timeout 30000 `
            -FrameworkVersion 'net-4.0' `
            -Where 'mywherecondition' `
            -TestResultFilenamePattern 'SpecialPattern' `
            -ProcessIsolation 'Single'

        It 'should return the right value' {
            $result -join ' ' | Should Be "$(Nunit3Parameters 'my-test-assembly.dll' 'SpecialPattern') --x86 --timeout=30000 --framework=net-4.0 --where=mywherecondition --process=Single"
        }
    }

}
