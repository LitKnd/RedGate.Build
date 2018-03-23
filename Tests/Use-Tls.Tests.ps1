#requires -Version 2 -Modules Pester

Describe 'Use-Tls' {
    Context 'When given a delegate that throws' {
        It 'should cause the exception to be thrown' {
            { Use-Tls { throw "test error message"; } } | Should -Throw "test error message"
        }
    }
}
