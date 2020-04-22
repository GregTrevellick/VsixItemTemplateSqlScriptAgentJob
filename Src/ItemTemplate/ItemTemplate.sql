IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'fnDoesJobStepExist')
)
BEGIN
    DROP FUNCTION fnDoesJobStepExist;
END;
GO
 
 
CREATE FUNCTION [dbo].fnDoesJobStepExist
(
                @jobName VARCHAR(255),
                @stepId VARCHAR(255)
)
RETURNS BIT
BEGIN
   DECLARE @output BIT;
                IF EXISTS
                               (SELECT 1
                              FROM [msdb].[dbo].[sysjobs] a WITH(NOLOCK)
                               INNER JOIN [msdb].[dbo].[sysjobsteps] b WITH(NOLOCK) ON a.job_id = b.job_id
                               WHERE a.[Name] = @jobName and b.step_id = @stepId)
               BEGIN
                              SET @output = 1;
               END
               ELSE
               BEGIN
                               SET @output = 0;
                END
    RETURN @output;
END;




BEGIN TRANSACTION

	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	DECLARE @UncategorizedLocal VARCHAR(30) = N'[Uncategorized (Local)]';

	--
	-- Create category is not already exists
	--
	IF NOT EXISTS (SELECT [name]
					FROM msdb.dbo.syscategories
					WHERE [name] = @UncategorizedLocal AND category_class = 1)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_category
			 @class = N'JOB'
			,@type = N'LOCAL'
			,@name = @UncategorizedLocal
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END 

	--
	-- Initialise variables
	--
	DECLARE @command VARCHAR(255);                           --gregt nvarchar(max) ????
	DECLARE @databaseName VARCHAR(255) = N'MyDb';
	DECLARE @jobId BINARY (16);
	DECLARE @jobName VARCHAR(255) = N'MyJobName' + '_' + @databaseName;
	DECLARE @stepId VARCHAR(255);
	DECLARE @stepName VARCHAR(255);

	--            
	--Create job (albeit empty) if not exists
	--
	SELECT @jobId = job_id
	FROM msdb.dbo.sysjobs
	WHERE [name] = @jobName

	IF (@jobId IS NULL)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_job 
			 @job_name = @jobName
			,@enabled = 1 /* NOTE: 0=DISabled, 1=ENabled */
			,@notify_level_eventlog = 0
			,@notify_level_email = 0
			,@notify_level_netsend = 0
			,@notify_level_page = 0
			,@delete_level = 0
			,@description = N'My job description'
			,@category_name = @UncategorizedLocal
			,@owner_login_name = N'sa'
			,@job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	--
	-- Add job step(s) if does not exist
	--            

	SET @command = N'--My first sequel statement e.g. EXEC MyFirstSproc';
	SET @stepId = 1;
	SET @stepName = N'My first step';
	IF (dbo.fnDoesJobStepExist(@jobName, @stepId) = 0)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			 @job_id = @jobId
			,@step_id = @stepId
			,@step_name = @stepName
			,@cmdexec_success_code = 0
			,@on_success_action = 3
			,@on_success_step_id = 0
			,@on_fail_action = 2
			,@on_fail_step_id = 0
			,@retry_attempts = 0
			,@retry_interval = 0
			,@os_run_priority = 0
			,@subsystem = N'TSQL'
			,@command = @command
			,@database_name = @databaseName
			,@flags = 0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		EXEC msdb.dbo.sp_update_jobstep 
			 @job_id = @jobId
			,@step_id = @stepId	--The parameters below are an exact copy of those used in sp_add_jobstep above
			,@step_name = @stepName
			,@cmdexec_success_code = 0
			,@on_success_action = 3
			,@on_success_step_id = 0
			,@on_fail_action = 2
			,@on_fail_step_id = 0
			,@retry_attempts = 0
			,@retry_interval = 0
			,@os_run_priority = 0
			,@subsystem = N'TSQL'
			,@command = @command
			,@database_name = @databaseName
			,@flags = 0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END

	SET @command = N'--My second sequel statement e.g. EXEC MySecondSproc';
	SET @stepId = 2;
	SET @stepName = N'My second step';
	IF (dbo.fnDoesJobStepExist(@jobName, @stepId) = 0)
	BEGIN
		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
			 @job_id = @jobId
			,@step_id = @stepId
			,@step_name = @stepName
			,@cmdexec_success_code = 0
			,@on_success_action = 1
			,@on_success_step_id = 0
			,@on_fail_action = 2
			,@on_fail_step_id = 0
			,@retry_attempts = 0
			,@retry_interval = 0
			,@os_run_priority = 0
			,@subsystem = N'TSQL'
			,@command = @command
			,@database_name = @databaseName
			,@flags = 0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END
	ELSE
	BEGIN
		EXEC msdb.dbo.sp_update_jobstep 
			 @job_id = @jobId
			,@step_id = @stepId	--The parameters below are an exact copy of those used in sp_add_jobstep above
			,@step_name = @stepName
			,@cmdexec_success_code = 0
			,@on_success_action = 1
			,@on_success_step_id = 0
			,@on_fail_action = 2
			,@on_fail_step_id = 0
			,@retry_attempts = 0
			,@retry_interval = 0
			,@os_run_priority = 0
			,@subsystem = N'TSQL'
			,@command = @command
			,@database_name = @databaseName
			,@flags = 0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END 

	--
	-- Set job start step id (not sure if truly needed but when scripting out an existing job this always appears)
	--
	EXEC @ReturnCode = msdb.dbo.sp_update_job 
 		 @job_id = @jobId
		,@start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 
	
	--
	-- sp_add_jobserver (not sure what this does, but when scripting out an existing job this always appears)
	--
	BEGIN TRY
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId
			,@server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	END TRY

	BEGIN CATCH -- Ignore error 14269 ("Job 'xxxxx' is already targeted at server 'MB-SQL-X-XX'")
		IF ((SELECT ERROR_NUMBER() AS ErrorNumber) <> 14269)
		BEGIN
			GOTO QuitWithRollback
		END
	END CATCH;

COMMIT TRANSACTION
GOTO EndSave 

QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
	
EndSave:
GO
