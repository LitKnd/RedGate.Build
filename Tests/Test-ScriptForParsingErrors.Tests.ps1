#requires -Version 4 -Modules Pester

Describe 'Test-ScriptForParsingErrors' {

    Context 'When a script has no error' {

        Mock -ModuleName RedGate.Build Get-Content {
            return @(
                '$i = 1',
                '$i++',
                'throw "this is a test error"'
            )
        } -ParameterFilter {$Path -eq 'script.ps1'}

        It 'should not throw any exception' {
            {Test-ScriptForParsingErrors -Path 'script.ps1'} | Should Not Throw
        }
    }

    Context 'When a script cannot be parsed' {

        Mock -ModuleName RedGate.Build Get-Content {
            return @(
                '$i=;',
                'throw "this is a test error"'
            )
        } -ParameterFilter {$Path -eq 'script.ps1'}

        It 'should rethrow any parsing exception' {
            {Test-ScriptForParsingErrors -Path 'script.ps1'} | Should Throw "You must provide a value expression following the '=' operator."
        }
    }
}
