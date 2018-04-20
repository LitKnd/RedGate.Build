#requires -Version 2 -Modules Pester

Describe 'ConvertTo-ShellEscaped' {

    $MemberDefinition = @"
[DllImport("shell32.dll", SetLastError = true)]
private static extern IntPtr CommandLineToArgvW([MarshalAs(UnmanagedType.LPWStr)] string lpCmdLine, out int pNumArgs);

public static string[] ToMainMethodArgsArray(string processArguments)
{
    int argc;

    var argv = CommandLineToArgvW("dummy.exe " + processArguments, out argc); // We need to pass in an exe name for this imported function to work.
    if (argv == IntPtr.Zero)
    {
        throw new Exception(String.Format("Failed to convert '{0}' to args array", processArguments));
    }

    try
    {
        var args = new string[argc - 1]; // We don't care about the first argument. It's just dummy.exe
        for (var i = 0; i < args.Length; i++)
        {
            var p = Marshal.ReadIntPtr(argv, (i + 1) * IntPtr.Size);
            args[i] = Marshal.PtrToStringUni(p);
        }
        return args;
    }
    finally
    {
        Marshal.FreeHGlobal(argv);
    }
}
"@

    $Helper = Add-Type -MemberDefinition $MemberDefinition -Name 'Helper' -Namespace 'System.Runtime.InteropServices' -PassThru

    function RoundTrip([string] $Original) {
        $Escaped = ConvertTo-ShellEscaped $Original
        $Unescaped = $Helper::ToMainMethodArgsArray($Escaped)
        return $Unescaped
    }

    function Check([string] $Original) {
        [string[]] $Unescaped = RoundTrip($Original)
        $Unescaped | Should Not Be $Null
        $Unescaped.Count | Should Be 1
        $Unescaped[0] | Should Be $Original
    }

    It 'should handle a single input string' {
        ConvertTo-ShellEscaped 'abc' | Should Be 'abc'
    }
    It 'should handle multiple input strings' {
        ConvertTo-ShellEscaped @('abc', 'def') | Should Be 'abc def'
    }
    It 'should handle multiple input strings pipeline' {
        @('abc', @('def', 'ghi')) | ConvertTo-ShellEscaped | Should Be @('abc', 'def ghi')
    }

    It 'should handle empty string' { Check('') }
    It 'should handle space' { Check('') }
    It 'should handle space prefixing a word' { Check(' abc') }
    It 'should handle space following a word' { Check('abc ') }
    It 'should handle space between two words' { Check('ab cd') }

    It 'should handle tab' { Check('`t') }
    It 'should handle tab prefixing a word' { Check('`tabc') }
    It 'should handle tab following a word' { Check('abc`t') }
    It 'should handle tab between two words' { Check('ab`tcd') }

    It 'should handle two adjacent whitespace (tab and space)' { Check('`t ') }

    It 'should handle "ab' { Check('"ab') }
    It 'should handle a"b' { Check('a"b') }
    It 'should handle ab"' { Check('ab"') }

    It 'should handle a\b' { Check('a\b') }
    It 'should handle a\\b' { Check('a\\b') }
    It 'should handle a\\\b' { Check('a\\\b') }

    It 'should handle a\' { Check('a\') }
    It 'should handle a\\' { Check('a\\') }
    It 'should handle a\\\' { Check('a\\\') }

    It 'should handle a b\' { Check('a b\') }
    It 'should handle a b\\' { Check('a b\\') }
    It 'should handle a b\\\' { Check('a b\\\') }

    It 'should handle a"b' { Check('a"b') }
    It 'should handle a\"b' { Check('a\"b') }
    It 'should handle a\\"b' { Check('a\\"b') }
    It 'should handle a\\\"b' { Check('a\\\"b') }

    It 'should handle a"' { Check('a"') }
    It 'should handle a\"' { Check('a\"') }
    It 'should handle a\\"' { Check('a\\"') }
    It 'should handle a\\\"' { Check('a\\\"') }

    It 'should handle double-quotes' { Check('"') }
    It 'should handle a pair of double-quotes' { Check('""') }
    It 'should handle double-quotes prefixing a word' { Check('"abc') }
    It 'should handle double-quotes following a word' { Check('abc"') }
    It 'should handle double-quotes between two words' { Check('ab"cd') }
    It 'should handle a pair of double-quotes between two words' { Check('ab""cd') }

    It 'should handle single-quotes' { Check("'") }
    It 'should handle a pair of single-quotes' { Check("''") }
    It 'should handle single-quotes prefixing a word' { Check("'abc") }
    It 'should handle single-quotes following a word' { Check("abc'") }
    It 'should handle single-quotes between two words' { Check("ab'cd") }
    It 'should handle a pair of single-quotes between two words' { Check("ab''cd") }

    It 'should handle trailing backslash' { Check('abc\') }
    It 'should handle quoted string with a trailing backslash' { Check('"abc\"') }
    It 'should handle backslash followed by double-quotes in the middle of the string' { Check('ab\"cd') }
    It 'should handle a folder path' { Check('c:\Temp') }
    It 'should handle a folder path with a trailing backslash' { Check('c:\Temp\') }
    It 'should handle a folder path with a space in it' { Check('c:\Another Temp') }
    It 'should handle a folder path with a space in it and a trailing backslash' { Check('c:\Another Temp\') }
    It 'should handle common characters' { Check('£$%^&<>{}=+-~#``') }
}
