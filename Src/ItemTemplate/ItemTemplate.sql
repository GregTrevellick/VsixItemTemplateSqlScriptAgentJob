BEGIN TRANSACTION

	-- Variables
	--gregt make variables start with a capital
	DECLARE @command NVARCHAR(MAX);
	DECLARE @databaseName SYSNAME = N'MyDb';
	DECLARE @jobId UNIQUEIDENTIFIER;                                                ---------------------------BINARY (16);
	DECLARE @jobName SYSNAME = N'MyJobName' + '_' + @databaseName;                      ------------VARCHAR(255) = 
    DECLARE @on_success_action_GoToNextStep TINYINT = 3; -- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobstep-transact-sql?view=sql-server-ver15#arguments 
	DECLARE @ReturnCode INT = 0;
	DECLARE @stepId INT;
	DECLARE @stepName SYSNAME;

	-- Create job (https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-job)
	SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE [name] = @jobName
	IF (@jobId IS NULL)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_job 
				 @description = N'My job description'
				--,@enabled = 0 -- Uncomment to create the job in disabled state
				,@job_id = @jobId OUTPUT
				,@job_name = @jobName
				,@owner_login_name = N'sa'
		-- Add target server (https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-jobserver-transact-sql)
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	-- Add first job step (https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-transact-sql-job-step)
	SET @command = N'EXEC MySproc';
	SET @stepId = 1;
	SET @stepName = N'MySproc';
	IF NOT EXISTS 
		(SELECT 1
		FROM msdb.dbo.sysjobs j WITH(NOLOCK)
		INNER JOIN msdb.dbo.sysjobsteps s WITH(NOLOCK) ON j.job_id = s.job_id 
		WHERE j.[Name] = @jobName and s.step_id = @stepId)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				 @command = @command
				,@database_name = @databaseName
				,@job_id = @jobId
				,@on_success_action = @on_success_action_GoToNextStep
				,@step_id = @stepId
				,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
				 @command = @command
				,@database_name = @databaseName
				,@job_id = @jobId
				,@on_success_action = @on_success_action_GoToNextStep
				,@step_id = @stepId	
				,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	-- Add last job step
	SET @command = N'EXEC MyLastSproc';
	SET @stepId = 2;
	SET @stepName = N'MyLastSproc';
	IF NOT EXISTS 
		(SELECT 1
		FROM msdb.dbo.sysjobs j WITH(NOLOCK)
		INNER JOIN msdb.dbo.sysjobsteps s WITH(NOLOCK) ON j.job_id = s.job_id 
		WHERE j.[Name] = @jobName and s.step_id = @stepId)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
				 @command = @command
				,@database_name = @databaseName
				,@job_id = @jobId
				,@step_id = @stepId
				,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
				 @command = @command
				,@database_name = @databaseName
				,@job_id = @jobId
				,@step_id = @stepId	--The parameters below are an exact copy of those used in sp_add_jobstep above
				,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END 

COMMIT TRANSACTION
GOTO EndSave 

QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	
EndSave:
