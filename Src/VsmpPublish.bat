CD D:\_Dgit\_MINE_ACTIVE\OpenInApp.Launcher\src\packages\Microsoft.VSSDK.BuildTools.16.4.1057\tools\vssdk\bin 

.\VsixPublisher.exe publish -payload "..\..\..\..\..\..\..\VsixItemTemplateSqlScriptAgentJob\Src\ItemTemplate.VsixPackage\bin\Debug\\VsixSequelAgentJob.vsix" -publishManifest "..\..\..\..\..\..\..\VsixItemTemplateSqlScriptAgentJob\Src\VsmpPublish.json" -personalAccessToken ""

echo off

REM "vsmp_pat"REM https://docs.microsoft.com/en-us/visualstudio/extensibility/walkthrough-publishing-a-visual-studio-extension-via-command-line?view=vs-2017
REM https://docs.microsoft.com/en-us/visualstudio/extensibility/walkthrough-publishing-a-visual-studio-extension-via-command-line?view=vs-2019








REM ${VSInstallDir}\VSSDK\VisualStudioIntegration\Tools\Bin\
REM https://docs.microsoft.com/en-us/visualstudio/extensibility/walkthrough-publishing-a-visual-studio-extension-via-command-line?view=vs-2017#publishmanifest-file