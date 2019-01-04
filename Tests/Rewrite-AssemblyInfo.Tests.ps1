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
            Remove-Item $filename
            $actualOutput | Should Be $expectedOutput
        }
    }
    Context 'Default AssemblyInfo.cs for WPF projects' {
        $initialAssemblyInfo = @"
using System.Reflection;
using System.Resources;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Windows;

// General Information about an assembly is controlled through the following
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("WpfApp1")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("WpfApp1")]
[assembly: AssemblyCopyright("Copyright ©  2019")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Setting ComVisible to false makes the types in this assembly not visible
// to COM components.  If you need to access a type in this assembly from
// COM, set the ComVisible attribute to true on that type.
[assembly: ComVisible(false)]

//In order to begin building localizable applications, set
//<UICulture>CultureYouAreCodingWith</UICulture> in your .csproj file
//inside a <PropertyGroup>.  For example, if you are using US english
//in your source files, set the <UICulture> to en-US.  Then uncomment
//the NeutralResourceLanguage attribute below.  Update the "en-US" in
//the line below to match the UICulture setting in the project file.

//[assembly: NeutralResourcesLanguage("en-US", UltimateResourceFallbackLocation.Satellite)]


[assembly: ThemeInfo(
    ResourceDictionaryLocation.None, //where theme specific resource dictionaries are located
                                     //(used if a resource is not found in the page,
                                     // or application resource dictionaries)
    ResourceDictionaryLocation.SourceAssembly //where the generic resource dictionary is located
                                              //(used if a resource is not found in the page,
                                              // app, or any theme specific resource dictionaries)
)]


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
using System.Windows;

[assembly: AssemblyTitle("WpfApp1")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]

[assembly: ThemeInfo(ResourceDictionaryLocation.None, ResourceDictionaryLocation.SourceAssembly)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        It 'Should rewrite minimal AssemblyInfo.cs' {
            $filename = (New-TemporaryFile).FullName
            $initialAssemblyInfo | Out-File $filename -Encoding UTF8
            Rewrite-AssemblyInfo -ProjectName 'WpfApp1' -ProductName 'SQL Dummy' -RootNamespace 'WpfApp1' -AssemblyInfoPath $filename -Version '1.2.3.456' -Year '2019'
            $actualOutput = Get-Content $filename -Raw -Encoding UTF8
            Remove-Item $filename
            $actualOutput | Should Be $expectedOutput
        }
    }
    Context 'Default AssemblyInfo.cs for WiX bootstrapper projects' {
        $initialAssemblyInfo = @"
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using Microsoft.Tools.WindowsInstallerXml.Bootstrapper;
using RedGate.SqlClone.Installer.BootstrapperApplication;

// General Information about an assembly is controlled through the following 
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("RedGate.SqlClone.Installer.BootstrapperApplication")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("RedGate.SqlClone.Installer.BootstrapperApplication")]
[assembly: AssemblyCopyright("Copyright ©  2016")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Setting ComVisible to false makes the types in this assembly not visible 
// to COM components.  If you need to access a type in this assembly from 
// COM, set the ComVisible attribute to true on that type.
[assembly: ComVisible(false)]

// The following GUID is for the ID of the typelib if this project is exposed to COM
[assembly: Guid("f00e5a4d-9bf7-49e1-9c39-e51045904d45")]

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

[assembly: BootstrapperApplication(typeof(NoUiBootstrapper))]

"@
        $expectedOutput = @"
using System.Reflection;
using System.Runtime.InteropServices;
using Microsoft.Tools.WindowsInstallerXml.Bootstrapper;
using RedGate.SqlClone.Installer.BootstrapperApplication;

[assembly: AssemblyTitle("RedGate.SqlClone.Installer.BootstrapperApplication")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Clone")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]
[assembly: Guid("f00e5a4d-9bf7-49e1-9c39-e51045904d45")]

[assembly: BootstrapperApplication(typeof(NoUiBootstrapper))]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        It 'Should rewrite minimal AssemblyInfo.cs' {
            $filename = (New-TemporaryFile).FullName
            $initialAssemblyInfo | Out-File $filename -Encoding UTF8
            Rewrite-AssemblyInfo -ProjectName 'RedGate.SqlClone.Installer.BootstrapperApplication' -ProductName 'SQL Clone' -RootNamespace 'RedGate.SqlClone.Installer.BootstrapperApplication' -AssemblyInfoPath $filename -Version '1.2.3.456' -Year '2019'
            $actualOutput = Get-Content $filename -Raw -Encoding UTF8
            Remove-Item $filename
            $actualOutput | Should Be $expectedOutput
        }
    }
    Context 'Custom AssemblyDescription' {
        $initialAssemblyInfo = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("ClassLibrary2")]
[assembly: AssemblyDescription("This is a custom description")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2018")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        $expectedOutput = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("ClassLibrary2")]
[assembly: AssemblyDescription("This is a custom description")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        It 'AssemblyDescription should be preserved' {
            $filename = (New-TemporaryFile).FullName
            $initialAssemblyInfo | Out-File $filename -Encoding UTF8
            Rewrite-AssemblyInfo -ProjectName 'ClassLibrary2' -ProductName 'SQL Dummy' -RootNamespace 'ClassLibrary2' -AssemblyInfoPath $filename -Version '1.2.3.456' -Year '2019'
            $actualOutput = Get-Content $filename -Raw -Encoding UTF8
            Remove-Item $filename
            $actualOutput | Should Be $expectedOutput
        }
    }
    Context 'ComVisible set to true' {
        $initialAssemblyInfo = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("ClassLibrary3")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2018")]

[assembly: ComVisible(true)]
[assembly: Guid("89249987-80cd-4d20-aafc-d0322f2bd58a")]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        $expectedOutput = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("ClassLibrary3")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(true)]
[assembly: Guid("89249987-80cd-4d20-aafc-d0322f2bd58a")]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        It 'ComVisible should be preserved' {
            $filename = (New-TemporaryFile).FullName
            $initialAssemblyInfo | Out-File $filename -Encoding UTF8
            Rewrite-AssemblyInfo -ProjectName 'ClassLibrary3' -ProductName 'SQL Dummy' -RootNamespace 'ClassLibrary3' -AssemblyInfoPath $filename -Version '1.2.3.456' -Year '2019'
            $actualOutput = Get-Content $filename -Raw -Encoding UTF8
            Remove-Item $filename
            $actualOutput | Should Be $expectedOutput
        }
    }
    Context 'Custom InternalsVisibleTo' {
        $initialAssemblyInfo = @"
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("ClassLibrary4")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2018")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

[assembly: InternalsVisibleTo("DynamicProxyGenAssembly2")]
[assembly: InternalsVisibleTo("ClassLibrary2")]

"@
        $expectedOutput = @"
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("ClassLibrary4")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

[assembly: InternalsVisibleTo("ClassLibrary2")]
[assembly: InternalsVisibleTo("DynamicProxyGenAssembly2")]

"@
        It 'AssemblyDescription should be preserved' {
            $filename = (New-TemporaryFile).FullName
            $initialAssemblyInfo | Out-File $filename -Encoding UTF8
            Rewrite-AssemblyInfo -ProjectName 'ClassLibrary4' -ProductName 'SQL Dummy' -RootNamespace 'ClassLibrary4' -AssemblyInfoPath $filename -Version '1.2.3.456' -Year '2019'
            $actualOutput = Get-Content $filename -Raw -Encoding UTF8
            Remove-Item $filename
            $actualOutput | Should Be $expectedOutput
        }
    }
    Context 'Empty AssemblyInfo.cs' {
        $initialAssemblyInfo = @"

"@
        $expectedOutput = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("NewProject")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]

"@
        It 'Should write minimal AssemblyInfo.cs' {
            $filename = (New-TemporaryFile).FullName
            $initialAssemblyInfo | Out-File $filename -Encoding UTF8
            Rewrite-AssemblyInfo -ProjectName 'NewProject' -ProductName 'SQL Dummy' -RootNamespace 'NewProject' -AssemblyInfoPath $filename -Version '1.2.3.456' -Year '2019'
            $actualOutput = Get-Content $filename -Raw -Encoding UTF8
            Remove-Item $filename
            $actualOutput | Should Be $expectedOutput
        }
    }
}
