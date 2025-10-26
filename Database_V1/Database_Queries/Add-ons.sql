-- =============================================
-- OUTPATIENT QUEUE MANAGEMENT SYSTEM
-- =============================================
-- Main Queue Table
CREATE TABLE Outpatient_Management.PatientQueue (
    QueueID INT IDENTITY(1,1) PRIMARY KEY,
    QueueNumber NVARCHAR(20) NOT NULL UNIQUE,  -- e.g., "A001", "B015"
    QueueDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    
    -- Patient & Appointment Info
    PatientID INT NOT NULL,
    AppointmentID INT NULL,  -- NULL if walk-in
    PhysicianID INT NOT NULL,
    DepartmentID INT NOT NULL,
    
    -- Queue Status
    QueueStatus NVARCHAR(20) DEFAULT 'Waiting' CHECK (QueueStatus IN (
        'Waiting',      -- Patient checked in, waiting to be called
        'Called',       -- Patient has been called
        'InProgress',   -- Patient is currently with doctor
        'Completed',    -- Consultation completed
        'NoShow',       -- Patient didn't respond to call
        'Cancelled',    -- Patient left or cancelled
        'Transferred'   -- Transferred to another doctor/department
    )),
    
    -- Priority Management
    Priority NVARCHAR(20) DEFAULT 'Normal' CHECK (Priority IN (
        'Emergency',    -- Emergency cases
        'Urgent',       -- Urgent but not emergency
        'Senior',       -- Senior citizens/disabled
        'Appointment',  -- Pre-scheduled appointments
        'Normal',       -- Regular walk-ins
        'Follow-up'     -- Follow-up visits
    )),
    
    -- Visit Type
    VisitType NVARCHAR(20) DEFAULT 'Walk-in' CHECK (VisitType IN (
        'Walk-in',      -- Patient came without appointment
        'Appointment',  -- Pre-scheduled
        'Emergency',    -- Emergency case
        'Follow-up'     -- Follow-up visit
    )),
    
    -- Timing Information
    CheckInTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    EstimatedWaitTime INT NULL,  -- In minutes
    CalledTime DATETIME2 NULL,
    ConsultationStartTime DATETIME2 NULL,
    ConsultationEndTime DATETIME2 NULL,
    
    -- Queue Position
    SequenceNumber INT NOT NULL,  -- Actual sequence within the day
    CurrentPosition INT NULL,     -- Current position in queue (updates as people are served)
    
    -- Additional Information
    ChiefComplaint NVARCHAR(500) NULL,
    Notes NVARCHAR(1000) NULL,
    
    -- Station/Counter Info
    CheckInCounter NVARCHAR(20) NULL,  -- Which counter patient checked in at
    CheckInBy INT NOT NULL,  -- Staff who checked in the patient
    
    -- Transfer Information (if patient moved to different doctor)
    TransferredFromQueueID INT NULL,
    TransferredToQueueID INT NULL,
    TransferReason NVARCHAR(200) NULL,
    
    -- System Fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    
    -- Foreign Keys
    CONSTRAINT FK_Queue_Patient FOREIGN KEY (PatientID) 
        REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Queue_Appointment FOREIGN KEY (AppointmentID) 
        REFERENCES Scheduling.Appointments(AppointmentID),
    CONSTRAINT FK_Queue_Physician FOREIGN KEY (PhysicianID) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Queue_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_Queue_CheckInBy FOREIGN KEY (CheckInBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Queue_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Users(UserID),
    CONSTRAINT FK_Queue_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Users(UserID),
    
    -- Business Rules
    CONSTRAINT CK_Queue_Times CHECK (
        (CalledTime IS NULL OR CalledTime >= CheckInTime) AND
        (ConsultationStartTime IS NULL OR ConsultationStartTime >= CheckInTime) AND
        (ConsultationEndTime IS NULL OR ConsultationEndTime >= ConsultationStartTime)
    )
);

-- Queue Configuration per Department/Physician
CREATE TABLE Outpatient_Management.QueueConfiguration (
    ConfigID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentID INT NULL,
    PhysicianID INT NULL,
    
    -- Queue Prefix (e.g., "A" for Cardiology, "B" for Neurology)
    QueuePrefix NVARCHAR(5) NOT NULL,
    
    -- Average consultation time (minutes)
    AverageConsultationTime INT DEFAULT 15,
    
    -- Maximum patients per day
    MaxPatientsPerDay INT NULL,
    
    -- Queue display settings
    DisplayOnScreen BIT DEFAULT 1,
    DisplayOrder INT NULL,
    
    -- Token number settings
    StartingNumber INT DEFAULT 1,
    ResetDaily BIT DEFAULT 1,  -- Reset counter daily
    
    IsActive BIT DEFAULT 1,
    
    CONSTRAINT FK_QueueConfig_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_QueueConfig_Physician FOREIGN KEY (PhysicianID) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT CK_QueueConfig_DeptOrPhysician CHECK (
        DepartmentID IS NOT NULL OR PhysicianID IS NOT NULL
    )
);

-- Queue Call History (for tracking when patients were called)
CREATE TABLE Outpatient_Management.QueueCallHistory (
    CallID INT IDENTITY(1,1) PRIMARY KEY,
    QueueID INT NOT NULL,
    CallNumber INT NOT NULL,  -- How many times patient was called
    CalledTime DATETIME2 DEFAULT GETDATE(),
    CalledBy INT NOT NULL,
    ResponseStatus NVARCHAR(20) CHECK (ResponseStatus IN (
        'Responded',    -- Patient came
        'NoResponse',   -- Patient didn't respond
        'Delayed'       -- Patient asked for delay
    )),
    Notes NVARCHAR(200) NULL,
    
    CONSTRAINT FK_CallHistory_Queue FOREIGN KEY (QueueID) 
        REFERENCES Outpatient_Management.PatientQueue(QueueID),
    CONSTRAINT FK_CallHistory_CalledBy FOREIGN KEY (CalledBy) 
        REFERENCES Core_system.Staff(StaffID)
);

-- Display Board Configuration (for screens in waiting area)
CREATE TABLE Outpatient_Management.DisplayBoards (
    BoardID INT IDENTITY(1,1) PRIMARY KEY,
    BoardName NVARCHAR(100) NOT NULL,
    Location NVARCHAR(100) NOT NULL,  -- e.g., "Main Lobby", "2nd Floor"
    DisplayType NVARCHAR(20) CHECK (DisplayType IN (
        'General',      -- Shows all queues
        'Department',   -- Shows specific department
        'Physician'     -- Shows specific physician
    )),
    DepartmentID INT NULL,
    PhysicianID INT NULL,
    IsActive BIT DEFAULT 1,
    
    CONSTRAINT FK_DisplayBoard_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_DisplayBoard_Physician FOREIGN KEY (PhysicianID) 
        REFERENCES Core_system.Staff(StaffID)
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Most common queries
CREATE INDEX IX_Queue_Date_Status ON Outpatient_Management.PatientQueue(QueueDate, QueueStatus);
CREATE INDEX IX_Queue_Physician_Date ON Outpatient_Management.PatientQueue(PhysicianID, QueueDate, QueueStatus);
CREATE INDEX IX_Queue_Department_Date ON Outpatient_Management.PatientQueue(DepartmentID, QueueDate, QueueStatus);
CREATE INDEX IX_Queue_Patient ON Outpatient_Management.PatientQueue(PatientID, QueueDate);
CREATE INDEX IX_Queue_CheckInTime ON Outpatient_Management.PatientQueue(CheckInTime);
CREATE INDEX IX_Queue_Number ON Outpatient_Management.PatientQueue(QueueNumber, QueueDate);

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- 1. Generate Queue Number for New Patient
GO
CREATE PROCEDURE usp_GenerateQueueNumber
    @PatientID INT,
    @PhysicianID INT,
    @DepartmentID INT,
    @AppointmentID INT = NULL,
    @VisitType NVARCHAR(20) = 'Walk-in',
    @Priority NVARCHAR(20) = 'Normal',
    @ChiefComplaint NVARCHAR(500) = NULL,
    @CheckInCounter NVARCHAR(20) = NULL,
    @CheckInByStaffID INT,
    @CreatedByUserID INT,
    @QueueID INT OUTPUT,
    @QueueNumber NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @QueueDate DATE = CAST(GETDATE() AS DATE);
        DECLARE @QueuePrefix NVARCHAR(5);
        DECLARE @NextSequence INT;
        DECLARE @EstimatedWait INT;
        
        -- Get queue prefix from configuration
        SELECT TOP 1 @QueuePrefix = QueuePrefix
        FROM Outpatient_Management.QueueConfiguration
        WHERE (PhysicianID = @PhysicianID OR DepartmentID = @DepartmentID)
          AND IsActive = 1
        ORDER BY PhysicianID DESC;  -- Prefer physician-specific config
        
        -- Default prefix if none configured
        IF @QueuePrefix IS NULL
            SET @QueuePrefix = 'Q';
        
        -- Get next sequence number for today
        SELECT @NextSequence = ISNULL(MAX(SequenceNumber), 0) + 1
        FROM Outpatient_Management.PatientQueue
        WHERE PhysicianID = @PhysicianID
          AND QueueDate = @QueueDate;
        
        -- Generate queue number (e.g., A001, A002)
        SET @QueueNumber = @QueuePrefix + RIGHT('000' + CAST(@NextSequence AS VARCHAR), 3);
        
        -- Calculate estimated wait time
        SELECT @EstimatedWait = 
            COUNT(*) * ISNULL(qc.AverageConsultationTime, 15)
        FROM Outpatient_Management.PatientQueue pq
        LEFT JOIN Outpatient_Management.QueueConfiguration qc 
            ON qc.PhysicianID = pq.PhysicianID
        WHERE pq.PhysicianID = @PhysicianID
          AND pq.QueueDate = @QueueDate
          AND pq.QueueStatus IN ('Waiting', 'Called', 'InProgress');
        
        -- Insert queue record
        INSERT INTO Outpatient_Management.PatientQueue (
            QueueNumber, QueueDate, PatientID, AppointmentID, PhysicianID, 
            DepartmentID, QueueStatus, Priority, VisitType, SequenceNumber,
            CurrentPosition, EstimatedWaitTime, ChiefComplaint, 
            CheckInCounter, CheckInBy, CreatedBy
        )
        VALUES (
            @QueueNumber, @QueueDate, @PatientID, @AppointmentID, @PhysicianID,
            @DepartmentID, 'Waiting', @Priority, @VisitType, @NextSequence,
            @NextSequence, @EstimatedWait, @ChiefComplaint,
            @CheckInCounter, @CheckInByStaffID, @CreatedByUserID
        );
        
        SET @QueueID = SCOPE_IDENTITY();
        
        -- Update appointment status if exists
        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'Confirmed'
            WHERE AppointmentId = @AppointmentID;
        END
        
        COMMIT TRANSACTION;
        
        -- Return success
        SELECT @QueueID AS QueueID, 
               @QueueNumber AS QueueNumber,
               @EstimatedWait AS EstimatedWaitTime,
               @NextSequence AS Position;
               
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- 2. Call Next Patient in Queue
GO
CREATE PROCEDURE usp_CallNextPatient
    @PhysicianID INT,
    @CalledByStaffID INT,
    @QueueID INT OUTPUT,
    @QueueNumber NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @QueueDate DATE = CAST(GETDATE() AS DATE);
        
        -- Get next patient in queue (considering priority)
        SELECT TOP 1 
            @QueueID = QueueID,
            @QueueNumber = QueueNumber
        FROM Outpatient_Management.PatientQueue
        WHERE PhysicianID = @PhysicianID
          AND QueueDate = @QueueDate
          AND QueueStatus = 'Waiting'
        ORDER BY 
            CASE Priority
                WHEN 'Emergency' THEN 1
                WHEN 'Urgent' THEN 2
                WHEN 'Senior' THEN 3
                WHEN 'Appointment' THEN 4
                WHEN 'Follow-up' THEN 5
                WHEN 'Normal' THEN 6
            END,
            CheckInTime ASC;
        
        IF @QueueID IS NULL
        BEGIN
            -- No patients waiting
            SELECT 0 AS QueueID, NULL AS QueueNumber, 'No patients in queue' AS Message;
            COMMIT TRANSACTION;
            RETURN;
        END
        
        -- Update queue status
        UPDATE Outpatient_Management.PatientQueue
        SET QueueStatus = 'Called',
            CalledTime = GETDATE(),
            UpdatedAt = GETDATE(),
            UpdatedBy = @CalledByStaffID
        WHERE QueueID = @QueueID;
        
        -- Record call history
        INSERT INTO Outpatient_Management.QueueCallHistory (
            QueueID, CallNumber, CalledBy, ResponseStatus
        )
        SELECT @QueueID, 
               ISNULL(MAX(CallNumber), 0) + 1,
               @CalledByStaffID,
               'NoResponse'  -- Default until patient responds
        FROM Outpatient_Management.QueueCallHistory
        WHERE QueueID = @QueueID;
        
        COMMIT TRANSACTION;
        
        -- Return patient details
        SELECT 
            pq.QueueID,
            pq.QueueNumber,
            pq.PatientID,
            p.FirstName + ' ' + p.LastName AS PatientName,
            p.DateOfBirth,
            DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
            p.Gender,
            pq.ChiefComplaint,
            pq.Priority,
            pq.VisitType
        FROM Outpatient_Management.PatientQueue pq
        JOIN Patient_Management.Patient p ON pq.PatientID = p.PatientID
        WHERE pq.QueueID = @QueueID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- 3. Start Consultation (Patient Responded)
GO
CREATE PROCEDURE usp_StartConsultation
    @QueueID INT,
    @StaffID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Outpatient_Management.PatientQueue
    SET QueueStatus = 'InProgress',
        ConsultationStartTime = GETDATE(),
        UpdatedAt = GETDATE(),
        UpdatedBy = @StaffID
    WHERE QueueID = @QueueID;
    
    -- Update call history
    UPDATE qch
    SET ResponseStatus = 'Responded'
    FROM Outpatient_Management.QueueCallHistory qch
    WHERE qch.QueueID = @QueueID
      AND qch.CallID = (
          SELECT MAX(CallID) 
          FROM Outpatient_Management.QueueCallHistory 
          WHERE QueueID = @QueueID
      );
    
    SELECT 'Consultation started' AS Status;
END;
GO

-- 4. Complete Consultation
GO
CREATE PROCEDURE usp_CompleteConsultation
    @QueueID INT,
    @EncounterID INT,  -- Link to encounter created during consultation
    @StaffID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Outpatient_Management.PatientQueue
    SET QueueStatus = 'Completed',
        ConsultationEndTime = GETDATE(),
        UpdatedAt = GETDATE(),
        UpdatedBy = @StaffID
    WHERE QueueID = @QueueID;
    
    -- Update positions for remaining patients
    UPDATE pq
    SET CurrentPosition = CurrentPosition - 1
    FROM Outpatient_Management.PatientQueue pq
    WHERE pq.PhysicianID = (SELECT PhysicianID FROM Outpatient_Management.PatientQueue WHERE QueueID = @QueueID)
      AND pq.QueueDate = CAST(GETDATE() AS DATE)
      AND pq.QueueStatus = 'Waiting';
    
    SELECT 'Consultation completed' AS Status;
END;
GO

-- 5. Get Current Queue Status for Physician
GO
CREATE PROCEDURE usp_GetPhysicianQueueStatus
    @PhysicianID INT,
    @QueueDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @QueueDate IS NULL
        SET @QueueDate = CAST(GETDATE() AS DATE);
    
    SELECT 
        pq.QueueID,
        pq.QueueNumber,
        pq.PatientID,
        p.FirstName + ' ' + p.LastName AS PatientName,
        DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
        p.Gender,
        pq.Priority,
        pq.VisitType,
        pq.QueueStatus,
        pq.CheckInTime,
        pq.EstimatedWaitTime,
        pq.CurrentPosition,
        pq.ChiefComplaint,
        DATEDIFF(MINUTE, pq.CheckInTime, GETDATE()) AS WaitingMinutes
    FROM Outpatient_Management.PatientQueue pq
    JOIN Patient_Management.Patient p ON pq.PatientID = p.PatientID
    WHERE pq.PhysicianID = @PhysicianID
      AND pq.QueueDate = @QueueDate
      AND pq.QueueStatus IN ('Waiting', 'Called', 'InProgress')
    ORDER BY 
        CASE pq.Priority
            WHEN 'Emergency' THEN 1
            WHEN 'Urgent' THEN 2
            WHEN 'Senior' THEN 3
            WHEN 'Appointment' THEN 4
            WHEN 'Follow-up' THEN 5
            WHEN 'Normal' THEN 6
        END,
        pq.CheckInTime;
END;
GO

-- 6. Get Queue Statistics
GO
CREATE PROCEDURE usp_GetQueueStatistics
    @PhysicianID INT = NULL,
    @DepartmentID INT = NULL,
    @QueueDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @QueueDate IS NULL
        SET @QueueDate = CAST(GETDATE() AS DATE);
    
    SELECT 
        ISNULL(s.FullName, d.DepartmentName) AS EntityName,
        COUNT(*) AS TotalPatients,
        SUM(CASE WHEN QueueStatus = 'Waiting' THEN 1 ELSE 0 END) AS Waiting,
        SUM(CASE WHEN QueueStatus = 'Called' THEN 1 ELSE 0 END) AS Called,
        SUM(CASE WHEN QueueStatus = 'InProgress' THEN 1 ELSE 0 END) AS InProgress,
        SUM(CASE WHEN QueueStatus = 'Completed' THEN 1 ELSE 0 END) AS Completed,
        SUM(CASE WHEN QueueStatus = 'NoShow' THEN 1 ELSE 0 END) AS NoShow,
        AVG(CASE 
            WHEN ConsultationStartTime IS NOT NULL AND ConsultationEndTime IS NOT NULL 
            THEN DATEDIFF(MINUTE, ConsultationStartTime, ConsultationEndTime)
        END) AS AvgConsultationTime,
        AVG(CASE 
            WHEN ConsultationStartTime IS NOT NULL 
            THEN DATEDIFF(MINUTE, CheckInTime, ConsultationStartTime)
        END) AS AvgWaitTime
    FROM Outpatient_Management.PatientQueue pq
    LEFT JOIN Core_system.Staff s ON pq.PhysicianID = s.StaffID
    LEFT JOIN Core_system.Departments d ON pq.DepartmentID = d.DepartmentID
    WHERE pq.QueueDate = @QueueDate
      AND (@PhysicianID IS NULL OR pq.PhysicianID = @PhysicianID)
      AND (@DepartmentID IS NULL OR pq.DepartmentID = @DepartmentID)
    GROUP BY s.FullName, d.DepartmentName;
END;
GO

-- =============================================
-- VIEWS FOR DISPLAY BOARDS
-- =============================================

-- View for waiting room display
GO
CREATE VIEW vw_WaitingRoomDisplay AS
SELECT 
    pq.QueueNumber,
    CASE 
        WHEN LEN(p.FirstName + ' ' + p.LastName) > 20 
        THEN LEFT(p.FirstName + ' ' + p.LastName, 17) + '...'
        ELSE p.FirstName + ' ' + p.LastName
    END AS PatientName,
    s.FullName AS PhysicianName,
    d.DepartmentName,
    pq.QueueStatus,
    pq.Priority,
    pq.CurrentPosition,
    pq.EstimatedWaitTime,
    DATEDIFF(MINUTE, pq.CheckInTime, GETDATE()) AS WaitingMinutes
FROM Outpatient_Management.PatientQueue pq
JOIN Patient_Management.Patient p ON pq.PatientID = p.PatientID
JOIN Core_system.Staff s ON pq.PhysicianID = s.StaffID
JOIN Core_system.Departments d ON pq.DepartmentID = d.DepartmentID
WHERE pq.QueueDate = CAST(GETDATE() AS DATE)
  AND pq.QueueStatus IN ('Waiting', 'Called', 'InProgress');
GO

-- =============================================
-- SAMPLE DATA FOR TESTING
-- =============================================

-- Insert queue configuration
INSERT INTO Outpatient_Management.QueueConfiguration (DepartmentID, QueuePrefix, AverageConsultationTime, MaxPatientsPerDay)
VALUES 
    (1, 'A', 15, 50),  -- Cardiology
    (2, 'B', 20, 40),  -- Neurology
    (3, 'C', 10, 60);  -- General Medicine












    -- =============================================
-- IMPROVED CreateEncounter Procedure
-- =============================================

CREATE OR ALTER PROCEDURE usp_CreateEncounter
    @EncounterNumber NVARCHAR(20) = NULL,  -- Allow auto-generation
    @PatientId INT,
    @PhysicianID INT,
    @AppointmentId INT = NULL,
    @EncounterDate DATETIME2 = NULL,  -- Default to current date
    @EncounterType NVARCHAR(50),
    @VisitType NVARCHAR(20) = NULL,  -- Can be pulled from appointment
    @ReviewOfSystems NVARCHAR(MAX) = NULL,
    @StartDateTime DATETIME = NULL,  -- Default to now
    @EndDateTime DATETIME = NULL,  -- Can be calculated
    @Status NVARCHAR(20) = 'Active',
    @FollowUpInstructions NVARCHAR(MAX) = NULL,
    @CreatedBy INT,
    @EncounterId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        -- =============================================
        -- 1. REQUIRED FIELDS VALIDATION
        -- =============================================
        IF @PatientId IS NULL
            THROW 50001, 'PatientID is required', 1;
            
        IF @PhysicianID IS NULL
            THROW 50001, 'PhysicianID is required', 1;
            
        IF @EncounterType IS NULL
            THROW 50001, 'EncounterType is required', 1;
            
        IF @CreatedBy IS NULL
            THROW 50001, 'CreatedBy is required', 1;
        
        -- =============================================
        -- 2. PATIENT VALIDATION
        -- =============================================
        IF NOT EXISTS (
            SELECT 1 
            FROM Patient_Management.Patient 
            WHERE PatientID = @PatientId 
            AND IsActive = 1
        )
            THROW 50002, 'Patient not found or inactive', 1;
        

        

        
        -- =============================================
        -- 5. VISIT TYPE VALIDATION & AUTO-POPULATION
        -- =============================================
        -- If appointment exists, get visit type from it
        IF @AppointmentId IS NOT NULL
        BEGIN
            IF NOT EXISTS (
                SELECT 1 
                FROM Scheduling.Appointments 
                WHERE AppointmentId = @AppointmentId 
                AND PatientID = @PatientId
            )
                THROW 50005, 'Appointment not found or does not belong to this patient', 1;
            
            -- Auto-populate VisitType from appointment if not provided
            IF @VisitType IS NULL
            BEGIN
                SELECT @VisitType = VisitType
                FROM Scheduling.Appointments
                WHERE AppointmentId = @AppointmentId;
            END
            
            -- Validate appointment status
            DECLARE @AppointmentStatus NVARCHAR(20);
            SELECT @AppointmentStatus = Status
            FROM Scheduling.Appointments
            WHERE AppointmentId = @AppointmentId;
            
            IF @AppointmentStatus NOT IN ('Scheduled', 'Confirmed', 'In Progress')
                THROW 50006, 'Appointment status must be Scheduled, Confirmed, or In Progress', 1;
        END
        ELSE
        BEGIN
            -- For walk-ins, require VisitType or set default
            IF @VisitType IS NULL
                SET @VisitType = 'Consultation';  -- Default for walk-ins
        END
        
        -- Validate VisitType values
        IF @VisitType NOT IN ('New Patient', 'Follow-up', 'Consultation', 'Procedure', 'Screening', 'Annual Checkup', 'Emergency')
            THROW 50007, 'Invalid VisitType', 1;
        
        -- =============================================
        -- 6. DATE/TIME VALIDATIONS & DEFAULTS
        -- =============================================
        -- Set defaults
        IF @EncounterDate IS NULL
            SET @EncounterDate = GETDATE();
        
        IF @StartDateTime IS NULL
            SET @StartDateTime = GETDATE();
        
        -- Validate encounter date is not too far in future (max 1 day)
        IF @EncounterDate > DATEADD(DAY, 1, GETDATE())
            THROW 50008, 'Encounter date cannot be more than 1 day in the future', 1;
        
        -- Validate encounter date is not too old (max 7 days in past)
        IF @EncounterDate < DATEADD(DAY, -7, GETDATE())
            THROW 50009, 'Encounter date cannot be more than 7 days in the past. Contact supervisor for backdated entries.', 1;
        
        -- Validate StartDateTime vs EndDateTime
        IF @EndDateTime IS NOT NULL
        BEGIN
            IF @StartDateTime >= @EndDateTime
                THROW 50010, 'StartDateTime must be before EndDateTime', 1;
            
            -- Validate encounter duration (max 8 hours)
            IF DATEDIFF(HOUR, @StartDateTime, @EndDateTime) > 8
                THROW 50011, 'Encounter duration cannot exceed 8 hours', 1;
        END
        ELSE
        BEGIN
            -- Set default end time (1 hour from start)
            SET @EndDateTime = DATEADD(HOUR, 1, @StartDateTime);
        END
        
        -- =============================================
        -- 7. STATUS VALIDATION
        -- =============================================
        IF @Status NOT IN ('Active', 'Completed', 'Cancelled')
            THROW 50012, 'Invalid Status. Must be: Active, Completed, or Cancelled', 1;
        
        -- =============================================
        -- 8. BUSINESS RULE VALIDATIONS
        -- =============================================
        
        -- Check for duplicate active encounters for same patient today
        IF EXISTS (
            SELECT 1 
            FROM Clinical_Management.Encounters 
            WHERE PatientId = @PatientId 
            AND CAST(EncounterDate AS DATE) = CAST(@EncounterDate AS DATE)
            AND Status = 'Active'
            AND PhysicianID = @PhysicianID
        )
            THROW 50013, 'Patient already has an active encounter with this physician today', 1;
        
        -- Check physician schedule/availability (if you have scheduling)
        -- Check if physician is working in correct department for encounter type
        
        -- For Inpatient encounters, verify patient has an active admission
        IF @EncounterType = 'Inpatient'
        BEGIN
            IF NOT EXISTS (
                SELECT 1 
                FROM Inpatient_Management.Admissions 
                WHERE PatientId = @PatientId 
                AND Status = 'Active'
            )
                THROW 50014, 'Patient must have an active admission for Inpatient encounters', 1;
        END
        
        -- For Emergency encounters, verify ER visit exists
        IF @EncounterType = 'Emergency'
        BEGIN
            -- Could add validation that ER_Visit exists or will be created
            -- This depends on your workflow
        END
        
        -- =============================================
        -- 9. AUTO-GENERATE ENCOUNTER NUMBER IF NULL
        -- =============================================
        IF @EncounterNumber IS NULL OR @EncounterNumber = ''
        BEGIN
            -- Generate unique encounter number
            DECLARE @DatePart NVARCHAR(8) = FORMAT(@EncounterDate, 'yyyyMMdd');
            DECLARE @SequencePart INT;
            
            -- Get next sequence for today
            SELECT @SequencePart = ISNULL(MAX(
                CAST(RIGHT(EncounterNumber, 5) AS INT)
            ), 0) + 1
            FROM Clinical_Management.Encounters
            WHERE EncounterNumber LIKE 'ENC' + @DatePart + '%';
            
            SET @EncounterNumber = 'ENC' + @DatePart + RIGHT('00000' + CAST(@SequencePart AS VARCHAR), 5);
        END
        ELSE
        BEGIN
            -- If provided, check uniqueness
            IF EXISTS (
                SELECT 1 
                FROM Clinical_Management.Encounters 
                WHERE EncounterNumber = @EncounterNumber
            )
                THROW 50015, 'Encounter number already exists', 1;
        END
        
        -- =============================================
        -- 10. INSERT ENCOUNTER
        -- =============================================
        INSERT INTO Clinical_Management.Encounters (
            EncounterNumber,
            PatientId,
            PhysicianID,
            AppointmentId,
            EncounterDate,
            EncounterType,
            VisitType,
            ReviewOfSystems,
            StartDateTime,
            EndDateTime,
            Status,
            FollowUpInstructions,
            CreatedBy,
            CreatedAt
        )
        VALUES (
            @EncounterNumber,
            @PatientId,
            @PhysicianID,
            @AppointmentId,
            @EncounterDate,
            @EncounterType,
            @VisitType,
            @ReviewOfSystems,
            @StartDateTime,
            @EndDateTime,
            @Status,
            @FollowUpInstructions,
            @CreatedBy,
            GETDATE()
        );
        
        SET @EncounterId = SCOPE_IDENTITY();
        
        -- =============================================
        -- 11. UPDATE RELATED RECORDS
        -- =============================================
        
        -- Update appointment status if linked
        IF @AppointmentId IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'In Progress'
            WHERE AppointmentId = @AppointmentId;
        END
        
        -- Create OPD Visit record if Outpatient
        IF @EncounterType = 'Outpatient'
        BEGIN
            IF NOT EXISTS (
                SELECT 1 
                FROM Outpatient_Management.OPD_Visit 
                WHERE EncounterID = @EncounterId
            )
            BEGIN
                INSERT INTO Outpatient_Management.OPD_Visit (
                    EncounterID,
                    AppointmentID,
                    VisitReason,
                    VisitStatus
                )
                VALUES (
                    @EncounterId,
                    @AppointmentId,
                    @ReviewOfSystems,
                    'Seen'
                );
            END
        END
        
        -- Link to ER_Visit if Emergency
        IF @EncounterType = 'Emergency'
        BEGIN
            -- Check if ER_Visit exists and link it
            DECLARE @ERVisitID INT;
            SELECT TOP 1 @ERVisitID = ERVisitID
            FROM Emergency_Management.ER_Visit
            WHERE EncounterID IS NULL  -- Not yet linked
            ORDER BY ArrivalDateTime DESC;
            
            IF @ERVisitID IS NOT NULL
            BEGIN
                UPDATE Emergency_Management.ER_Visit
                SET EncounterID = @EncounterId
                WHERE ERVisitID = @ERVisitID;
            END
        END
        
        COMMIT TRANSACTION;
        
        -- =============================================
        -- 12. RETURN SUCCESS
        -- =============================================
        SELECT 
            @EncounterId AS EncounterId,
            @EncounterNumber AS EncounterNumber,
            @VisitType AS VisitType,
            'Encounter created successfully' AS Message;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        
        -- Return detailed error information
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        
        -- Log error (optional - insert into error log table)
        -- INSERT INTO SystemErrorLog...
        
        PRINT 'Error Creating Encounter: ' + @ErrorMessage;
        
        -- Re-throw with context
        THROW;
    END CATCH
END;
GO

-- =============================================
-- USAGE EXAMPLES
-- =============================================

-- Example 1: Create encounter from appointment
/*
DECLARE @NewEncounterId INT;
EXEC usp_CreateEncounter
    @PatientId = 123,
    @PhysicianID = 45,
    @AppointmentId = 789,  -- VisitType will be pulled from appointment
    @EncounterType = 'Outpatient',
    @CreatedBy = 10,
    @EncounterId = @NewEncounterId OUTPUT;

SELECT @NewEncounterId AS NewEncounterId;
*/

-- Example 2: Create walk-in encounter
/*
DECLARE @NewEncounterId INT;
EXEC usp_CreateEncounter
    @PatientId = 123,
    @PhysicianID = 45,
    @EncounterType = 'Outpatient',
    @VisitType = 'Consultation',
    @ReviewOfSystems = 'Patient complains of headache',
    @CreatedBy = 10,
    @EncounterId = @NewEncounterId OUTPUT;
*/

-- Example 3: Create emergency encounter
/*
DECLARE @NewEncounterId INT;
EXEC usp_CreateEncounter
    @PatientId = 123,
    @PhysicianID = 45,
    @EncounterType = 'Emergency',
    @VisitType = 'Emergency',
    @CreatedBy = 10,
    @EncounterId = @NewEncounterId OUTPUT;
*/



