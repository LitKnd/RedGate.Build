#requires -Version 2 -Modules Pester

Describe 'Use-Tls' {
    Context 'When given a delegate' {
        It 'TLS 1.2 should be enabled' {
            Use-Tls {
                [Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12 | Should -Be ([Net.SecurityProtocolType]::Tls12)
            }
        }
    }
    Context 'When given a delegate that throws' {
        It 'should cause the exception to be thrown' {
            { Use-Tls { throw "test error message"; } } | Should -Throw "test error message"
        }
    }
}
