#requires -Version 2 -Modules Pester


Describe 'Update-AssemblyVersion' {

    $XmlPath = "$([IO.Path]::GetTempPath())$([guid]::NewGuid()).csproj"
    $XmlPath2 = "$([IO.Path]::GetTempPath())$([guid]::NewGuid()).csproj"
    
    Context 'given an empty project file' {
        $Xml = [xml] @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
  </PropertyGroup>
</Project>
'@

        It 'should have a <Version/> element when the Version parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -Version '1.2.3.4-prerelease'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <Version>1.2.3.4-prerelease</Version>
  </PropertyGroup>
</Project>
'@
        }

        It 'should have a <Version/> element when the Version parameter is specified on all files' {
            $Xml.Save($XmlPath)
            $Xml.Save($XmlPath2)
            @($XmlPath, $XmlPath2) |Update-ProjectProperties -Version '1.2.3.4-prerelease'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <Version>1.2.3.4-prerelease</Version>
  </PropertyGroup>
</Project>
'@
        }

        It 'should have an <AssemblyVersion/> element when the AssemblyVersion parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -AssemblyVersion '1.2.3.4'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <AssemblyVersion>1.2.3.4</AssemblyVersion>
  </PropertyGroup>
</Project>
'@
        }

        It 'should have a <FileVersion/> element when the FileVersion parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -FileVersion '1.2.3.4'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <FileVersion>1.2.3.4</FileVersion>
  </PropertyGroup>
</Project>
'@
        }

        It 'should have a <PackageReleaseNotes/> element when the PackageReleaseNotes parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -PackageReleaseNotes 'RELEASE_NOTES'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <PackageReleaseNotes>RELEASE_NOTES</PackageReleaseNotes>
  </PropertyGroup>
</Project>
'@
        }
    }

    Context 'given a project file with existing properties' {
        $Xml = [xml] @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <Version>0.0.0.0</Version>
    <AssemblyVersion>0.0.0.0</AssemblyVersion>
    <FileVersion>0.0.0.0</FileVersion>
    <PackageReleaseNotes>original-release-notes</PackageReleaseNotes>
  </PropertyGroup>
</Project>
'@

        It 'should have an updated <Version/> element when the Version parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -Version '1.2.3.4-prerelease'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <Version>1.2.3.4-prerelease</Version>
    <AssemblyVersion>0.0.0.0</AssemblyVersion>
    <FileVersion>0.0.0.0</FileVersion>
    <PackageReleaseNotes>original-release-notes</PackageReleaseNotes>
  </PropertyGroup>
</Project>
'@
        }

        It 'should have an updated <AssemblyVersion/> element when the AssemblyVersion parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -AssemblyVersion '1.2.3.4'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <Version>0.0.0.0</Version>
    <AssemblyVersion>1.2.3.4</AssemblyVersion>
    <FileVersion>0.0.0.0</FileVersion>
    <PackageReleaseNotes>original-release-notes</PackageReleaseNotes>
  </PropertyGroup>
</Project>
'@
        }

        It 'should have an updated <FileVersion/> element when the FileVersion parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -FileVersion '1.2.3.4'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <Version>0.0.0.0</Version>
    <AssemblyVersion>0.0.0.0</AssemblyVersion>
    <FileVersion>1.2.3.4</FileVersion>
    <PackageReleaseNotes>original-release-notes</PackageReleaseNotes>
  </PropertyGroup>
</Project>
'@
        }

        It 'should have an updated <PackageReleaseNotes/> element when the PackageReleaseNotes parameter is specified' {
            $Xml.Save($XmlPath)
            Update-ProjectProperties -Path $XmlPath -PackageReleaseNotes 'RELEASE_NOTES'
            [IO.File]::ReadAllText($XmlPath) | Should Be @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <Version>0.0.0.0</Version>
    <AssemblyVersion>0.0.0.0</AssemblyVersion>
    <FileVersion>0.0.0.0</FileVersion>
    <PackageReleaseNotes>RELEASE_NOTES</PackageReleaseNotes>
  </PropertyGroup>
</Project>
'@
        }
    }

    Remove-Item $XmlPath
    Remove-Item $XmlPath2
}
