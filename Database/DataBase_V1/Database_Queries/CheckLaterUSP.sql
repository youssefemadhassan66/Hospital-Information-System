use HIS_V1

--CREATE PROCEDURE Create_NursingTask
--    @EncounterID INT,
--    @OrderedBy INT,
--    @TaskType NVARCHAR(50),
--    @ScheduledTime DATETIME
--AS BEGIN 
--    SET NOCOUNT ON 
--    BEGIN TRY
--        BEGIN TRANSACTION

--        IF @EncounterID IS NULL OR @OrderedBy IS NULL OR @TaskType IS NULL OR @ScheduledTime IS NULL
--            THROW 50001,'Encounter ID, Ordered By, Task Type and Scheduled Time are required',1;

--        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE EncounterID = @EncounterID)
--            THROW 50002,'Encounter not found',1;

--        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @OrderedBy AND IsActive = 1)
--            THROW 50003,'Ordering staff not found or inactive',1;

--        INSERT INTO Clinical_Management.NursingTasks(
--            EncounterID,
--            OrderedBy,
--            TaskType,
--            ScheduledTime,
--            Status
--        )
--        VALUES(
--            @EncounterID,
--            @OrderedBy,
--            @TaskType,
--            @ScheduledTime,
--            'Planned'
--        );

--        COMMIT TRANSACTION
--    END TRY
--    BEGIN CATCH
--        IF @@TRANCOUNT > 0 
--            ROLLBACK TRANSACTION;
--        DECLARE @Error NVARCHAR(4000) = 'Error creating nursing task: ' + ERROR_MESSAGE();
--        THROW 50000, @Error, 1;
--    END CATCH
--END
--GO

--CREATE PROCEDURE Update_NursingTask
--    @TaskID INT,
--    @TaskType NVARCHAR(50) = NULL,
--    @ScheduledTime DATETIME = NULL,
--    @Status NVARCHAR(20) = NULL,
--    @PerformedBy INT = NULL
--AS BEGIN 
--    SET NOCOUNT ON 
--    BEGIN TRY
--        BEGIN TRANSACTION

--        IF @TaskID IS NULL
--            THROW 50001,'Task ID is required',1;

--        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.NursingTasks WHERE TaskID = @TaskID)
--            THROW 50002,'Nursing task not found',1;

--        IF @Status IS NOT NULL AND @Status NOT IN ('Planned','Done','Skipped')
--            THROW 50003,'Invalid status',1;

--        IF @PerformedBy IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @PerformedBy AND IsActive = 1)
--            THROW 50004,'Performing staff not found or inactive',1;

--        UPDATE Clinical_Management.NursingTasks
--        SET TaskType = COALESCE(@TaskType, TaskType),
--            ScheduledTime = COALESCE(@ScheduledTime, ScheduledTime),
--            Status = COALESCE(@Status, Status),
--            PerformedBy = COALESCE(@PerformedBy, PerformedBy),
--            PerformedTime = CASE WHEN @Status = 'Done' AND PerformedTime IS NULL THEN GETDATE() ELSE PerformedTime END
--        WHERE TaskID = @TaskID;

--        COMMIT TRANSACTION
--    END TRY
--    BEGIN CATCH
--        IF @@TRANCOUNT > 0 
--            ROLLBACK TRANSACTION;
--        DECLARE @Error NVARCHAR(4000) = 'Error updating nursing task: ' + ERROR_MESSAGE();
--        THROW 50000, @Error, 1;
--    END CATCH
--END
--GO

--CREATE PROCEDURE GetNursingTasks_ByEncounter
--    @EncounterID INT
--AS BEGIN 
--    SET NOCOUNT ON 
--    BEGIN TRY
--        IF @EncounterID IS NULL
--            THROW 50001,'Encounter ID is required',1;

--        SELECT 
--            nt.TaskID,
--            nt.EncounterID,
--            nt.TaskType,
--            nt.ScheduledTime,
--            nt.PerformedTime,
--            nt.Status,
--            ob.FirstName + ' ' + ob.LastName AS OrderedByName,
--            pb.FirstName + ' ' + pb.LastName AS PerformedByName,
--            p.FirstName + ' ' + p.LastName AS PatientName
--        FROM Clinical_Management.NursingTasks nt
--        INNER JOIN Clinical_Management.Encounters e ON nt.EncounterID = e.EncounterID
--        INNER JOIN Patient_Management.Patient p ON e.PatientId = p.PatientID
--        LEFT JOIN Core_system.Staff ob ON nt.OrderedBy = ob.StaffID
--        LEFT JOIN Core_system.Staff pb ON nt.PerformedBy = pb.StaffID
--        WHERE nt.EncounterID = @EncounterID
--        ORDER BY nt.ScheduledTime;

--    END TRY
--    BEGIN CATCH
--        DECLARE @Error NVARCHAR(4000) = 'Error fetching nursing tasks: ' + ERROR_MESSAGE();
--        THROW 50000, @Error, 1;
--    END CATCH
--END
--GO

--CREATE PROCEDURE GetPending_NursingTasks
--    @WardID INT = NULL
--AS BEGIN 
--    SET NOCOUNT ON 
--    BEGIN TRY
--        SELECT 
--            nt.TaskID,
--            nt.EncounterID,
--            nt.TaskType,
--            nt.ScheduledTime,
--            p.FirstName + ' ' + p.LastName AS PatientName,
--            w.WardName,
--            ob.FirstName + ' ' + ob.LastName AS OrderedByName
--        FROM Clinical_Management.NursingTasks nt
--        INNER JOIN Clinical_Management.Encounters e ON nt.EncounterID = e.EncounterID
--        INNER JOIN Patient_Management.Patient p ON e.PatientId = p.PatientID
--        INNER JOIN Inpatient_Management.Admissions a ON e.EncounterId = a.EncounterId
--        INNER JOIN Inpatient_Management.Beds b ON a.BedID = b.BedID
--        INNER JOIN Inpatient_Management.Wards w ON b.WardID = w.WardID
--        LEFT JOIN Core_system.Staff ob ON nt.OrderedBy = ob.StaffID
--        WHERE nt.Status = 'Planned'
--        AND (@WardID IS NULL OR w.WardID = @WardID)
--        ORDER BY nt.ScheduledTime;

--    END TRY
--    BEGIN CATCH
--        DECLARE @Error NVARCHAR(4000) = 'Error fetching pending nursing tasks: ' + ERROR_MESSAGE();
--        THROW 50000, @Error, 1;
--    END CATCH
--END
--GO