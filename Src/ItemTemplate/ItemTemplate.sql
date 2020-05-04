BEGIN TRANSACTION

	-- Variables  gregt sort alpha
	DECLARE @Command NVARCHAR(MAX);
	--DECLARE	@Count BIGINT;
	DECLARE @DatabaseName SYSNAME = N'OverdriveDev';--N'MyDatabase';
	DECLARE @JobDescription nvarchar(512) =  N'Job name e.g. Lorem ipsum dolor sit amet';
	DECLARE @JobId UNIQUEIDENTIFIER;
	DECLARE @JobName SYSNAME = N'Gregt_Test1';--N'MyJobName' + '_' + @DatabaseName;
	DECLARE	@JobStepExists BIGINT;
	DECLARE @JobStepExistsSql NVARCHAR(MAX) = N'SELECT @JobStepExists = COUNT(*) FROM msdb.dbo.sysjobs j WITH(NOLOCK) INNER JOIN msdb.dbo.sysjobsteps s WITH(NOLOCK) ON j.job_id = s.job_id WHERE j.[Name] = ''' + @JobName + N''' AND s.step_id = @StepId';
    DECLARE @OnSuccessActionGoToNextStep TINYINT = 3;--gregt shorten name
    DECLARE @OnSuccessActionQuitJobReportingSuccess TINYINT = 1;--gregt shorten name
	DECLARE @OwnerLoginName SYSNAME = N'sa';
	DECLARE @ReturnCode INT = 0;
	DECLARE @ServerName NVARCHAR(30) = N'(local)';
	DECLARE @StepId INT;
	DECLARE @StepName SYSNAME;
	--DECLARE @AddJobStepSproc NVARCHAR(20) = N'sp_add_jobstep';
	--DECLARE @UpdateJobStepSproc NVARCHAR(20) = N'sp_update_jobstep';
	--DECLARE @UpsertJobStepSproc NVARCHAR(20);

	-- Create job (https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-job)
	SELECT @JobId = job_id FROM msdb.dbo.sysjobs WHERE [name] = @JobName
	IF (@JobId IS NULL)
	BEGIN
		-- Add job (https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-job-transact-sql)
		EXEC @ReturnCode = msdb.dbo.sp_add_job 
				 @description = @JobDescription
				,@enabled = 1 -- 1=enabled, 0=disabled
				,@job_id = @JobId OUTPUT
				,@job_name = @JobName
				,@owner_login_name = @OwnerLoginName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		-- Add target server (https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobserver-transact-sql)
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver
				 @job_id = @JobId 
				,@server_name = @ServerName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	-- Create first job step https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-transact-sql-job-step
	SET @Command = N'Your step 1 sequel here';
	SET @StepId = 1;
	SET @StepName = N'Step 1 name e.g. Lorem ipsum dolor sit amet';
	EXEC sp_executesql @JobStepExistsSql, N'@JobStepExists BIGINT OUTPUT, @StepId INT', @JobStepExists = @JobStepExists OUTPUT, @StepId = @StepId
	IF (@JobStepExists = 0)
	BEGIN
		-- Add step https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobstep-transact-sql
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @OnSuccessActionGoToNextStep
				,@step_id = @StepId
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		--SET @UpsertJobStepSproc = @AddJobStepSproc;
	END
	ELSE
	BEGIN
		-- Update step https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-update-jobstep-transact-sql
		EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @OnSuccessActionGoToNextStep
				,@step_id = @StepId	
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		--SET @UpsertJobStepSproc = @UpdateJobStepSproc;
	END
	--EXEC sp_executesql @UpsertJobStepSql;
	--IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	-- Create last job step https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-transact-sql-job-step	
	SET @Command = N'Your step 2 sequel here';
	SET @StepId = 2;
	SET @StepName = N'Step 2 name e.g. Lorem ipsum dolor sit amet';
	EXEC sp_executesql @JobStepExistsSql, N'@JobStepExists BIGINT OUTPUT, @StepId INT', @JobStepExists = @JobStepExists OUTPUT, @StepId = @StepId
	IF (@JobStepExists = 0)
	BEGIN
		-- Add step (https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobstep-transact-sql)
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @OnSuccessActionQuitJobReportingSuccess
				,@step_id = @StepId
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		--SET @UpsertJobStepSproc = @AddJobStepSproc;
	END
	ELSE
	BEGIN
		-- Update step (https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-update-jobstep-transact-sql)
		EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @OnSuccessActionQuitJobReportingSuccess
				,@step_id = @StepId	
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		--SET @UpsertJobStepSproc = @UpdateJobStepSproc;
	END 
	--EXEC sp_executesql @UpsertJobStepSql;
	--IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave 

QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	
EndSave:
