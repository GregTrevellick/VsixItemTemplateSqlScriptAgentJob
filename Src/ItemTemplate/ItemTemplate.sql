BEGIN TRANSACTION

	-- Variables
	DECLARE @Command NVARCHAR(MAX);
	DECLARE @DatabaseName SYSNAME = N'MyDatabase';
	DECLARE @JobDescription nvarchar(512) =  N'My job description';
	DECLARE @JobId UNIQUEIDENTIFIER;
	DECLARE @JobName SYSNAME = N'MyJobName' + '_' + @DatabaseName;
	DECLARE @JobStepExists NVARCHAR(MAX) = N'SELECT 1 FROM msdb.dbo.sysjobs j WITH(NOLOCK) INNER JOIN msdb.dbo.sysjobsteps s WITH(NOLOCK) ON j.job_id = s.job_id WHERE j.[Name] = @JobName AND s.step_id = @StepId';
    DECLARE @OnSuccessActionGoToNextStep TINYINT = 3;
    DECLARE @onSuccessActionQuitJobReportingSuccess TINYINT = 1;--gregt check text and value
	DECLARE @OwnerLoginName SYSNAME = N'sa';
	DECLARE @ReturnCode INT = 0;
	DECLARE @ServerName NVARCHAR(30) = N'(local)';
	DECLARE @StepId INT;
	DECLARE @StepName SYSNAME;

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
	SET @Command = N'EXEC MySproc';
	SET @StepId = 1;
	SET @StepName = N'MySproc';
	--IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs j WITH(NOLOCK) INNER JOIN msdb.dbo.sysjobsteps s WITH(NOLOCK) ON j.job_id = s.job_id WHERE j.[Name] = @JobName AND s.step_id = @StepId)
	IF NOT EXISTS (SELECT 1 = EXEC @JobStepExists)
	BEGIN
		-- Add step https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobstep-transact-sql
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @onSuccessActionGoToNextStep
				,@step_id = @StepId
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		-- Update step https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-update-jobstep-transact-sql
		EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @onSuccessActionGoToNextStep
				,@step_id = @StepId	
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	-- Create last job step https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-transact-sql-job-step	
	SET @Command = N'EXEC MyLastSproc';
	SET @StepId = 2;
	SET @StepName = N'MyLastSproc';
	--IF NOT EXISTS (SELECT 1	FROM msdb.dbo.sysjobs j WITH(NOLOCK) INNER JOIN msdb.dbo.sysjobsteps s WITH(NOLOCK) ON j.job_id = s.job_id WHERE j.[Name] = @JobName AND s.step_id = @StepId)
	IF NOT EXISTS (EXEC @JobStepExists)
	BEGIN
		-- Add step (https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobstep-transact-sql)
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @onSuccessActionQuitJobReportingSuccess
				,@step_id = @StepId
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		-- Update step (https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-update-jobstep-transact-sql)
		EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
				 @Command = @Command
				,@database_name = @DatabaseName
				,@job_id = @JobId
				,@on_success_action = @onSuccessActionQuitJobReportingSuccess
				,@step_id = @StepId	
				,@step_name = @StepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END 

COMMIT TRANSACTION
GOTO EndSave 

QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	
EndSave:
