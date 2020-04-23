REM https://docs.microsoft.com/en-us/visualstudio/extensibility/walkthrough-publishing-a-visual-studio-extension-via-command-line?view=vs-2017

CD D:

"D:\_Dgit\_MINE_ACTIVE\OpenInApp.Launcher\src\packages\Microsoft.VSSDK.BuildTools.15.8.3252\tools\vssdk\bin\VsixPublisher.exe" publish -payload "D:\_Dgit\_MINE_ACTIVE\VsixItemTemplateSqlScriptAgentJob\Src\ItemTemplate.VsixPackage\bin\Debug\\VsixSequelAgentJob.vsix" -publishManifest "D:\_Dgit\_MINE_ACTIVE\VsixItemTemplateSqlScriptAgentJob\Src\VsmpPublish.json" -personalAccessToken "vsmp_pat"
