﻿using System;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.VisualStudio.Shell;
using Task = System.Threading.Tasks.Task;

namespace VsixSequelAgentJob
{
    [PackageRegistration(UseManagedResourcesOnly = true, AllowsBackgroundLoading = true)]
    [Guid(VsixSequelAgentJobPackage.PackageGuidString)]
    public sealed class VsixSequelAgentJobPackage : AsyncPackage
    {
        public const string PackageGuidString = "f016edd0-faa5-4ee8-9088-705389659b8d";

        protected override async Task InitializeAsync(CancellationToken cancellationToken, IProgress<ServiceProgressData> progress)
        {
            await this.JoinableTaskFactory.SwitchToMainThreadAsync(cancellationToken);
        }
    }
}
