#requires -Version 4 -Modules Pester

Describe 'Rewrite-AssemblyInfos' {
    $rootDir = New-TempDir
    
    $solutionFile = Join-Path $rootDir 'Rewrite-AssemblyInfos.Test.sln'
    $normalProjectName = 'Test.NormalProject'
    $differentProductProjectName = 'Test.ProjectWithDifferentProductName'
    $differentVersionProjectName = 'Test.ProjectWithDifferentVersion'
    @"
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "$normalProjectName", "$normalProjectName\$normalProjectName.csproj", "{1BD528BC-3372-4BFB-9F42-39179C6F0270}"
EndProject
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "$differentProductProjectName", "$differentProductProjectName\$differentProductProjectName.csproj", "{074559C6-669F-42FB-818E-AA687230B5F4}"
EndProject
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "$differentVersionProjectName", "$differentVersionProjectName\$differentVersionProjectName.csproj", "{85D5BBB6-7385-43C8-87D3-CE9A9E04CC64}"
EndProject
"@ | Out-File $solutionFile -Encoding UTF8
    
    $normalProjectDir = [string] (mkdir (Join-Path $rootDir $normalProjectName))
    @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <AssemblyName>$normalProjectName</AssemblyName>
    <RootNamespace>$normalProjectName</RootNamespace>
  </PropertyGroup>
</Project>
"@ | Out-File (Join-Path $normalProjectDir "$normalProjectName.csproj") -Encoding UTF8
    $normalProjectPropertiesDir = [string] (mkdir (Join-Path $normalProjectDir 'Properties'))
    $normalProjectAssemblyInfo = Join-Path $normalProjectPropertiesDir 'AssemblyInfo.cs'
    @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("$normalProjectName")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("$normalProjectName")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2018")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

"@ | Out-File $normalProjectAssemblyInfo -Encoding UTF8

    $differentProductProjectDir = [string] (mkdir (Join-Path $rootDir $differentProductProjectName))
    @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <AssemblyName>$differentProductProjectName</AssemblyName>
    <RootNamespace>$differentProductProjectName</RootNamespace>
  </PropertyGroup>
</Project>
"@ | Out-File (Join-Path $differentProductProjectDir "$differentProductProjectName.csproj") -Encoding UTF8
    $differentProductProjectPropertiesDir = [string] (mkdir (Join-Path $differentProductProjectDir 'Properties'))
    $differentProductProjectAssemblyInfo = Join-Path $differentProductProjectPropertiesDir 'AssemblyInfo.cs'
    @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("$differentProductProjectName")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("$differentProductProjectName")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2018")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

"@ | Out-File $differentProductProjectAssemblyInfo -Encoding UTF8

    $differentVersionProjectDir = [string] (mkdir (Join-Path $rootDir $differentVersionProjectName))
    @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <AssemblyName>$differentVersionProjectName</AssemblyName>
    <RootNamespace>$differentVersionProjectName</RootNamespace>
  </PropertyGroup>
</Project>
"@ | Out-File (Join-Path $differentVersionProjectDir "$differentVersionProjectName.csproj") -Encoding UTF8
    $differentVersionProjectPropertiesDir = [string] (mkdir (Join-Path $differentVersionProjectDir 'Properties'))
    $differentVersionProjectAssemblyInfo = Join-Path $differentVersionProjectPropertiesDir 'AssemblyInfo.cs'
    @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("$differentVersionProjectName")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("$differentVersionProjectName")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2018")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

"@ | Out-File $differentVersionProjectAssemblyInfo -Encoding UTF8

    $expectedNormalProjectAssemblyInfo = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("$normalProjectName")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]
[assembly: AssemblyInformationalVersion("1.2.3.456-branch-name")]

"@
    $expectedDifferentProductProjectAssemblyInfo = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("$differentProductProjectName")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("Alternate product name")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("1.2.3.456")]
[assembly: AssemblyFileVersion("1.2.3.456")]
[assembly: AssemblyInformationalVersion("1.2.3.456-branch-name")]

"@
    $expectedDifferentVersionProjectAssemblyInfo = @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("$differentVersionProjectName")]
[assembly: AssemblyCompany("Red Gate Software Ltd")]
[assembly: AssemblyProduct("SQL Dummy")]
[assembly: AssemblyCopyright("Copyright © Red Gate Software Ltd 2019")]

[assembly: ComVisible(false)]

[assembly: AssemblyVersion("2.3.4.567")]
[assembly: AssemblyFileVersion("2.3.4.567")]
[assembly: AssemblyInformationalVersion("2.3.4.567-branch-name")]

"@
    $productNameOverrides = @{
        $differentProductProjectName = 'Alternate product name'
    }
    $versionOverrides = @{
        $differentVersionProjectName = [Version] '2.3.4.567'
    }
    Rewrite-AssemblyInfos -SolutionFile $solutionFile -ProductName 'SQL Dummy' -Version '1.2.3.456' -InfoVersionSuffix '-branch-name' -Year '2019' -ProductNameOverrides $productNameOverrides -VersionOverrides $versionOverrides
    It 'AssemblyInfo for normal project should be rewritten normally' {
        $actualNormalProjectAssemblyInfo = Get-Content $normalProjectAssemblyInfo -Raw -Encoding UTF8
        $actualNormalProjectAssemblyInfo | Should Be $expectedNormalProjectAssemblyInfo
    }
    It 'AssemblyInfo for project with product name override should have alternate product name' {
        $actualDifferentProductProjectAssemblyInfo = Get-Content $differentProductProjectAssemblyInfo -Raw -Encoding UTF8
        $actualDifferentProductProjectAssemblyInfo | Should Be $expectedDifferentProductProjectAssemblyInfo
    }
    It 'AssemblyInfo for project with version override should have alternate version' {
        $actualDifferentVersionProjectAssemblyInfo = Get-Content $differentVersionProjectAssemblyInfo -Raw -Encoding UTF8
        $actualDifferentVersionProjectAssemblyInfo | Should Be $expectedDifferentVersionProjectAssemblyInfo
    }
    Remove-Item -Recurse $rootDir
}
