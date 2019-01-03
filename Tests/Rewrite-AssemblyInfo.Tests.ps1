#requires -Version 4 -Modules Pester

Describe 'Rewrite-AssemblyInfo' {
    Context 'Default AssemblyInfo.cs for normal projects' {
        $initialAssemblyInfo = @"
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

// General Information about an assembly is controlled through the following
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("ClassLibrary1")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("ClassLibrary1")]
[assembly: AssemblyCopyright("Copyright ©  2018")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Setting ComVisible to false makes the types in this assembly not visible
// to COM components.  If you need to access a type in this assembly from
// COM, set the ComVisible attribute to true on that type.
[assembly: ComVisible(false)]

// The following GUID is for the ID of the typelib if this project is exposed to COM
[assembly: Guid("7b9e7270-e52f-4029-92cf-467917f81886")]

// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version
//      Build Number
//      Revision
//
// You can specify all the values or you can default the Build and Revision Numbers
// by using the '*' as shown below:
// [assembly: AssemblyVersion("1.0.*")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]                
"@
        $expectedOutput = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("ClassLibrary1")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]
[assembly: Guid("7b9e7270-e52f-4029-92cf-467917f81886")]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        It 'Should rewrite minimal AssemblyInfo.cs' {
            $filename = (New-TemporaryFile).FullName
            $initialAssemblyInfo | Out-File $filename -Encoding UTF8
            Rewrite-AssemblyInfo -ProjectName 'ClassLibrary1' -ProductName 'SQL Dummy' -RootNamespace 'ClassLibrary1' -AssemblyInfoPath $filename -Version '1.2.3.456' -Year '2019'
            $actualOutput = Get-Content $filename -Raw -Encoding UTF8
            $actualOutput | Should Be $expectedOutput
        }
    }
}
