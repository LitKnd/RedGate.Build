#requires -Version 4 -Modules Pester

Describe 'Invoke-SigningService' {

    $testExeFile = New-Item 'TestDrive:\myfile.exe' -ItemType File
    $testVsixFile = New-Item 'TestDrive:\myfile.vsix' -ItemType File

    Context '-SigningServiceUrl is not passed in' {


        It 'should use value of $env:SigningServiceUrl' {
            Mock Invoke-WebRequest {} `
                -Module RedGate.Build `
                -Verifiable `
                -ParameterFilter { $Uri -eq 'https://mysigningservice.example.com' }

            $env:SigningServiceUrl = 'https://mysigningservice.example.com'
            $testExeFile | Invoke-SigningService

            Assert-VerifiableMock
        }

        It 'should fail if $env:SigningServiceUrl is not set' {
            $env:SigningServiceUrl = $null
            {$testExeFile | Invoke-SigningService} |
                Should Throw 'Cannot sign assembly. -SigningServiceUrl was not specified and the SigningServiceUrl environment variable is not set.'
        }
    }

    Context 'When signing an .vsix file' {
        It 'should raise an error if -HashAlgorithm was not specified' {
            { $testVsixFile | Invoke-SigningService -SigningServiceUrl 'whatever'} |
                Should Throw 'Cannot sign vsix package. -HashAlgorithm was not specified.'
        }
    }
}
