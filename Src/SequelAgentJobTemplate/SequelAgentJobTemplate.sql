BEGIN TRANSACTION DECLARE @ReturnCode INT 
SELECT 
  @ReturnCode = 0 DECLARE @UncategorizedLocal VARCHAR(30) = N '[Uncategorized (Local)]';
--
-- Create category is not already exists
--
IF NOT EXISTS (
  SELECT 
    [name] 
  FROM 
    msdb.dbo.syscategories 
  WHERE 
    [name] = @UncategorizedLocal 
    AND category_class = 1
) BEGIN EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N 'JOB', 
@type = N 'LOCAL', 
@name = @UncategorizedLocal IF (
  @@ERROR <> 0 
  OR @ReturnCode <> 0
) GOTO QuitWithRollback END --
-- Initialise variables
--
DECLARE @command VARCHAR(255);
DECLARE @databaseName VARCHAR(255) = '#{Hades}OmitSquareBrackets';
DECLARE @envChannel VARCHAR(255) = REPLACE(@databaseName, 'Hades', '');
DECLARE @jobId BINARY(16);
DECLARE @jobNamePrefix VARCHAR(255) = CASE @envChannel WHEN 'Dev' THEN 'Primary Dev' WHEN 'DevSecondary' THEN 'Secondary Dev' WHEN 'DevTertiary' THEN 'Tertiary Dev' WHEN 'DevQuaternary' THEN 'Quaternary Dev' WHEN 'DevQuinary' THEN 'Quinary Dev' WHEN 'Test' THEN 'Primary Test' WHEN 'TestSecondary' THEN 'Secondary Test' WHEN 'TestTertiary' THEN 'Tertiary Test' WHEN 'TestQuaternary' THEN 'Quaternary Test' WHEN 'TestQuinary' THEN 'Quinary Test' WHEN 'UAT' THEN 'Primary UAT' WHEN 'UATSecondary' THEN 'Secondary UAT' WHEN 'UATTertiary' THEN 'Tertiary UAT' WHEN 'UATQuaternary' THEN 'Quaternary UAT' WHEN 'UATQuinary' THEN 'Quinary UAT' WHEN 'Training' THEN 'Primary Training' WHEN 'TrainingSecondary' THEN 'Secondary Training' WHEN 'TrainingTertiary' THEN 'Tertiary Training' WHEN 'TrainingQuaternary' THEN 'Quaternary Training' WHEN 'TrainingQuinary' THEN 'Quinary Training' WHEN 'Hotfix' THEN 'Hotfix' WHEN 'Next' THEN 'Next' --This line should never be needed
WHEN '' THEN '' --Production
END;
DECLARE @jobName VARCHAR(255) = @jobNamePrefix + N ' Hades - Updater of things';
DECLARE @scheduleName VARCHAR(255) = N 'Schedule-' + @jobName;
DECLARE @stepId VARCHAR(255);
DECLARE @stepName VARCHAR(255);
--            
--Create job (albeit empty) if not exists
--
SELECT 
  @jobId = job_id 
FROM 
  msdb.dbo.sysjobs 
WHERE 
  ([name] = @jobName) IF (@jobId IS NULL) BEGIN EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name = @jobName, 
  @enabled = 1, 
  
  /* NOTE: 0=DISabled, 1=ENabled */
  @notify_level_eventlog = 0, 
  @notify_level_email = 0, 
  @notify_level_netsend = 0, 
  @notify_level_page = 0, 
  @delete_level = 0, 
  @description = N 'Tux''s baby', 
  @category_name = @UncategorizedLocal, 
  @owner_login_name = N 'sa', 
  @job_id = @jobId OUTPUT IF (
    @@ERROR <> 0 
    OR @ReturnCode <> 0
  ) GOTO QuitWithRollback END --
  -- Add job step(s) if does not exist
  --            
SET 
  @command = N 'EXEC DimensionsSync_SyncAll';
SET 
  @stepId = 1;
SET 
  @stepName = N 'DimensionsSync_SyncAll';
IF (
  dbo.fnDoesJobStepExist(@jobName, @stepId) = 0
) BEGIN EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @jobId, 
@step_id = @stepId, 
@step_name = @stepName, 
@cmdexec_success_code = 0, 
@on_success_action = 3, 
@on_success_step_id = 0, 
@on_fail_action = 2, 
@on_fail_step_id = 0, 
@retry_attempts = 0, 
@retry_interval = 0, 
@os_run_priority = 0, 
@subsystem = N 'TSQL', 
@command = @command, 
@database_name = @databaseName, 
@flags = 0 IF (
  @@ERROR <> 0 
  OR @ReturnCode <> 0
) GOTO QuitWithRollback END ELSE BEGIN EXEC msdb.dbo.sp_update_jobstep @job_id = @jobId, 
@step_id = @stepId, 
--The parameters below are an exact copy of those used in sp_add_jobstep above
@step_name = @stepName, 
@cmdexec_success_code = 0, 
@on_success_action = 3, 
@on_success_step_id = 0, 
@on_fail_action = 2, 
@on_fail_step_id = 0, 
@retry_attempts = 0, 
@retry_interval = 0, 
@os_run_priority = 0, 
@subsystem = N 'TSQL', 
@command = @command, 
@database_name = @databaseName, 
@flags = 0 IF (
  @@ERROR <> 0 
  OR @ReturnCode <> 0
) GOTO QuitWithRollback END 


SET 
  @command = N 'EXEC PESSync_SyncAll';
SET 
  @stepId = 7;
SET 
  @stepName = N 'PESSync_SyncAll';
IF (
  dbo.fnDoesJobStepExist(@jobName, @stepId) = 0
) BEGIN EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @jobId, 
@step_id = @stepId, 
@step_name = @stepName, 
@cmdexec_success_code = 0, 
@on_success_action = 1, 
@on_success_step_id = 0, 
@on_fail_action = 2, 
@on_fail_step_id = 0, 
@retry_attempts = 0, 
@retry_interval = 0, 
@os_run_priority = 0, 
@subsystem = N 'TSQL', 
@command = @command, 
@database_name = @databaseName, 
@flags = 0 IF (
  @@ERROR <> 0 
  OR @ReturnCode <> 0
) GOTO QuitWithRollback END ELSE BEGIN EXEC msdb.dbo.sp_update_jobstep @job_id = @jobId, 
@step_id = @stepId, 
--The parameters below are an exact copy of those used in sp_add_jobstep above
@step_name = @stepName, 
@cmdexec_success_code = 0, 
@on_success_action = 1, 
@on_success_step_id = 0, 
@on_fail_action = 2, 
@on_fail_step_id = 0, 
@retry_attempts = 0, 
@retry_interval = 0, 
@os_run_priority = 0, 
@subsystem = N 'TSQL', 
@command = @command, 
@database_name = @databaseName, 
@flags = 0 IF (
  @@ERROR <> 0 
  OR @ReturnCode <> 0
) GOTO QuitWithRollback END --
-- Set job start step id (not sure if truly needed but when scripting out an existing job this always appears)
--
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, 
@start_step_id = 1 IF (
  @@ERROR <> 0 
  OR @ReturnCode <> 0
) GOTO QuitWithRollback --Schedules should be set up manually, hence commented out below.
--This avoids shared schedule id's across environments / channels.
--Also means we can create the job in an enabled state if we want, without the job automatically running potentially against our will.
--EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=@scheduleName,
--                             @enabled=1,  /* NOTE: 0=DISabled, 1=ENabled */
--                             @freq_type=4,
--                             @freq_interval=1,
--                             @freq_subday_type=4,
--                             @freq_subday_interval=5,
--                             @freq_relative_interval=0,
--                             @freq_recurrence_factor=0,
--                             @active_start_date=20191024, /* If copying this file for another agent job use a new date here */
--                             @active_end_date=99991231,
--                             @active_start_time=0,
--                             @active_end_time=235959,
--                             @schedule_uid=N'addd36db-7433-4010-ab08-d3825c280078' /* If copying this file for another agent job use a new guid here */
--IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
--
-- sp_add_jobserver (not sure what this does, but when scripting out an existing job this always appears)
--
BEGIN TRY EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, 
@server_name = N '(local)' IF (
  @@ERROR <> 0 
  OR @ReturnCode <> 0
) GOTO QuitWithRollback END TRY BEGIN CATCH -- Ignore error 14269 ("Job 'xxxxx' is already targeted at server 'MB-SQL-X-XX'")
IF (
  (
    SELECT 
      ERROR_NUMBER() AS ErrorNumber
  ) <> 14269
) BEGIN GOTO QuitWithRollback END END CATCH;
COMMIT TRANSACTION GOTO EndSave QuitWithRollback : IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION EndSave : GO
