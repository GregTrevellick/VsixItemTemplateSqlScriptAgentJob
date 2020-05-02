BEGIN TRANSACTION

	-- Initialise variables
	DECLARE @command VARCHAR(255);                           --gregt nvarchar(max) ????
	DECLARE @databaseName VARCHAR(255) = N'MyDb';
	DECLARE @jobId BINARY (16);
	DECLARE @jobName VARCHAR(255) = N'MyJobName' + '_' + @databaseName;
	DECLARE @ReturnCode INT = 0;
	------------------------------------SELECT @ReturnCode = 0
	DECLARE @stepId VARCHAR(255);
	DECLARE @stepName VARCHAR(255);
       
	-- Create empty job (see also https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-job)
	SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE [name] = @jobName
	IF (@jobId IS NULL)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_job 
			 @description = N'My job description'
			,@enabled = 1--gregt is enabled the default ?
			,@job_id = @jobId OUTPUT
			,@job_name = @jobName
			,@owner_login_name = N'sa'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	-- Add job steps (see also https://docs.microsoft.com/en-us/sql/ssms/agent/create-a-transact-sql-job-step)
	SET @command = N'--My first sequel statement e.g. EXEC MyFirstSproc';
	SET @stepId = 1;
	SET @stepName = N'My first step';
	IF NOT EXISTS 
		(SELECT 1
		FROM msdb.dbo.sysjobs j WITH(NOLOCK)
		INNER JOIN msdb.dbo.sysjobsteps s WITH(NOLOCK) ON j.job_id = s.job_id 
		WHERE a.[Name] = @jobName and b.step_id = @stepId)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			 @command = @command
			,@database_name = @databaseName
			,@flags = 0
			,@job_id = @jobId
			,@on_success_action = 3
			,@step_id = @stepId
			,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		EXEC msdb.dbo.sp_update_jobstep 
			 @command = @command
			,@database_name = @databaseName
			,@flags = 0
			,@job_id = @jobId
			,@on_success_action = 3 --gregt dedupe
			,@step_id = @stepId	
			,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	-- Add last step
	SET @command = N'--My second sequel statement e.g. EXEC MySecondSproc';
	SET @stepId = 2;
	SET @stepName = N'My second step';
	IF NOT EXISTS 
		(SELECT 1
		FROM msdb.dbo.sysjobs a WITH(NOLOCK)
		INNER JOIN msdb.dbo.sysjobsteps b WITH(NOLOCK) ON a.job_id = b.job_id 
		WHERE a.[Name] = @jobName and b.step_id = @stepId)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			 @command = @command
			,@database_name = @databaseName
			,@flags = 0
			,@job_id = @jobId
			,@step_id = @stepId
			,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		EXEC msdb.dbo.sp_update_jobstep 
			 @command = @command
			,@database_name = @databaseName
			,@flags = 0
			,@job_id = @jobId
			,@step_id = @stepId	--The parameters below are an exact copy of those used in sp_add_jobstep above
			,@step_name = @stepName
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END 



	-- Set job start step id (not sure if truly needed but when scripting out an existing job this always appears)
	------gregt try without this bit & see what happens....
	------EXEC @ReturnCode = msdb.dbo.sp_update_job 
	------@job_id = @jobId
	------	,@start_step_id = 1
	------IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 
	
	

	-- sp_add_jobserver (not sure what this does, but when scripting out an existing job this always appears)
	------gregt try without this bit & see what happens....
	------------BEGIN TRY
	------------	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId
	------------		,@server_name = N'(local)'
	------------	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	------------END TRY
	-----
	------------BEGIN CATCH -- Ignore error 14269 ("Job 'xxxxx' is already targeted at server 'MB-SQL-X-XX'")
	------------	IF ((SELECT ERROR_NUMBER() AS ErrorNumber) <> 14269)
	------------	BEGIN
	------------		GOTO QuitWithRollback
	------------	END
	------------END CATCH;

COMMIT TRANSACTION
GOTO EndSave 

QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	
EndSave:
GO
