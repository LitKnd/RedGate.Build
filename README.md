RedGate.Build
==================
A Powershell module that contains useful functions we use in our Powershell builds.

We're mostly using Invoke-Build, although this module should also work when used with Psake.

Feel free to contribute!

# How to build

We use [Invoke-Build](https://github.com/nightroman/Invoke-Build)
```powershell
.\build.cmd ? # Get a list of available tasks
.\build.cmd   # Run a build with the default tasks
```
