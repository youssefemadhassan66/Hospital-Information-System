
-- =============================================
-- 1. CORE SYSTEM TABLES
-- =============================================

CREATE TABLE Core_system.Specializations(
    SpecializationID INT IDENTITY(1,1) PRIMARY KEY,
    SpecializationName NVARCHAR(100) NOT NULL UNIQUE,
    SpecializationCode NVARCHAR(20) UNIQUE,
    Degree NVARCHAR(100) NULL,
    Description NVARCHAR(255),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
GO

CREATE TABLE Core_system.Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY, 
    RoleName NVARCHAR(70) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    Permissions NVARCHAR(MAX),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
GO

CREATE TABLE Core_system.Users(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    UserName NVARCHAR(150) UNIQUE NOT NULL,
    BirthDate DATETIME2 NOT NULL,
    Email NVARCHAR(200) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    RoleID INT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    LastLoginAt DATETIME2 NULL,
    CreatedBy INT NULL,
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_Users_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID),
    CONSTRAINT FK_Users_Role FOREIGN KEY (RoleID) REFERENCES Core_system.Roles(RoleID)
);
GO

CREATE TABLE Core_system.Departments(
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(50) NOT NULL UNIQUE,
    DepartmentCode VARCHAR(20) UNIQUE,
    ManagerID INT NULL, -- FK will be added later
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    IsActive BIT DEFAULT 1
);
GO

CREATE TABLE Core_system.Staff(
    StaffID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL UNIQUE,
    FirstName NVARCHAR(30) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    FullName AS (
        CASE 
            WHEN MiddleName IS NOT NULL AND MiddleName != '' 
            THEN FirstName + ' ' + MiddleName + ' ' + LastName
            ELSE FirstName + ' ' + LastName
        END
    ),
    Gender NVARCHAR(10) CHECK (Gender IN ('Male','Female')),
    Phone NVARCHAR(20),
    MobileNumber NVARCHAR(20),
    Email NVARCHAR(200) UNIQUE NOT NULL,
    Address NVARCHAR(500),
    DepartmentID INT NULL,
    SpecializationID INT NULL,
    Position NVARCHAR(100),     
    LicenseNumber NVARCHAR(50),
    HireDate DATE NOT NULL,
    Salary DECIMAL(10,2) CHECK (Salary >= 0),
    YearsOfExperience INT NULL CHECK (YearsOfExperience >= 0),
    Certification NVARCHAR(200) NULL,
    Bio NVARCHAR(MAX) NULL,
    Rating DECIMAL(3,2) NULL CHECK (Rating >= 0.0 AND Rating <= 5.0),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Staff_UserID FOREIGN KEY (UserID) REFERENCES Core_system.Users(UserID),
    CONSTRAINT FK_Staff_Department FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_Staff_Specialization FOREIGN KEY (SpecializationID) REFERENCES Core_system.Specializations(SpecializationID)
);
GO

-- Add circular FK after Staff table is created
ALTER TABLE Core_system.Departments 
ADD CONSTRAINT FK_Departments_ManagerID FOREIGN KEY (ManagerID) REFERENCES Core_system.Staff(StaffID);
GO

-- =============================================
-- 2. PATIENT MANAGEMENT TABLES
-- =============================================

CREATE TABLE Patient_Management.Patient (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    MRN NVARCHAR(50) UNIQUE NOT NULL,
    NationalID NVARCHAR(20) UNIQUE, 
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Age AS ( 
        DATEDIFF(YEAR, DateOfBirth, GETDATE()) - 
        CASE 
            WHEN (MONTH(DateOfBirth) > MONTH(GETDATE()) OR 
                 (MONTH(DateOfBirth) = MONTH(GETDATE()) AND DAY(DateOfBirth) > DAY(GETDATE())))
            THEN 1 
            ELSE 0 
        END
    ),
    Gender NVARCHAR(20) CHECK(Gender IN ('Male', 'Female', 'Other', 'Unknown')),
    BloodType NVARCHAR(15) CHECK(BloodType IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown')),
    PhoneNumber NVARCHAR(20) NULL,
    MobileNumber NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    Address NVARCHAR(500) NULL,
    City NVARCHAR(50) NULL,                  
    Country NVARCHAR(50) NULL,
    EmergencyContactName NVARCHAR(100) NULL,
    EmergencyContactPhone NVARCHAR(20) NULL,
    Allergies NVARCHAR(500) NULL,
    MaritalStatus NVARCHAR(20) CHECK (MaritalStatus IN ('Single', 'Married', 'Divorced', 'Widowed', 'Other', 'Unknown')),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_Patient_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID)
);
GO

CREATE TABLE Patient_Management.Patient_Reports(
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    DocumentType NVARCHAR(50) NOT NULL CHECK (DocumentType IN (
        'LabReport', 'RadiologyReport', 'DischargeSummary', 'ClinicalNote', 
        'OperativeReport', 'ProgressNote', 'Prescription', 'ReferralLetter',
        'PatientPhoto', 'MedicalImage', 'InsuranceCard', 'ConsentForm'
    )),
    FileName NVARCHAR(255) NOT NULL,
    FileSize BIGINT NOT NULL, 
    FilePath NVARCHAR(500) NOT NULL,
    CreatedBy INT NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    Description NVARCHAR(500) NULL,
    CONSTRAINT FK_PatientReports_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_PatientReports_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID)
);
GO

-- =============================================
-- 3. SCHEDULING TABLES
-- =============================================

CREATE TABLE Scheduling.DoctorsSchedules(
    ScheduleID INT PRIMARY KEY IDENTITY(1,1),
    DoctorID INT NOT NULL, 
    DayOfTheWeek TINYINT NULL CHECK (DayOfTheWeek BETWEEN 1 AND 7 OR DayOfTheWeek IS NULL),
    SpecificDate DATE NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    SlotDuration INT DEFAULT 30 CHECK (SlotDuration >= 15), 
    MaxAppointments INT DEFAULT 1 CHECK (MaxAppointments >= 1),
    IsRecurring BIT NOT NULL,
    EffectiveStart DATE NOT NULL,
    EffectiveEnd DATE NULL,
    IsAvailable BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_DoctorsSchedules_DoctorID FOREIGN KEY (DoctorID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_DoctorsSchedules_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT Check_Time CHECK(EndTime > StartTime),
    CONSTRAINT CHK_DateOrDay CHECK (DayOfTheWeek IS NOT NULL OR SpecificDate IS NOT NULL),
    CONSTRAINT CHK_RecurringLogic CHECK (
        (IsRecurring = 1 AND DayOfTheWeek IS NOT NULL AND SpecificDate IS NULL) OR
        (IsRecurring = 0 AND SpecificDate IS NOT NULL AND DayOfTheWeek IS NULL)
    )
);
GO

CREATE TABLE Scheduling.Appointments (
    AppointmentID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    PhysicianID INT NOT NULL,
    DepartmentID INT NULL,
    AppointmentDateTime DATETIME2 NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Scheduled' CHECK (Status IN ('Scheduled', 'Confirmed', 'In Progress', 'Completed', 'Cancelled', 'No Show', 'Rescheduled')),
    Duration INT NOT NULL CHECK (Duration > 0),
    Priority NVARCHAR(20) DEFAULT 'Normal' CHECK (Priority IN ('Low', 'Normal', 'High', 'Urgent')),
    VisitType NVARCHAR(20) CHECK (VisitType IN ('New Patient', 'Follow-up', 'Consultation', 'Procedure', 'Screening', 'Annual Checkup', 'Emergency', 'Walk-in')),
    ReminderSent BIT DEFAULT 0,
    Complaint NVARCHAR(500) NULL,
    CancellationReason NVARCHAR(500) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_Appointments_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Appointments_Physician FOREIGN KEY (PhysicianID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Appointments_Department FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_Appointments_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID)
);
GO

-- =============================================
-- 4. CLINICAL MANAGEMENT - QUEUE SYSTEM
-- =============================================

CREATE TABLE Clinical_Management.PatientQueue (
    QueueID INT IDENTITY(1,1) PRIMARY KEY,
    QueueNumber NVARCHAR(20) NOT NULL UNIQUE,
    QueueDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    
    -- Patient & Appointment Info
    PatientID INT NOT NULL,
    AppointmentID INT NULL,
    PhysicianID INT NOT NULL,
    DepartmentID INT NOT NULL,
    
    -- Queue Status
    Status NVARCHAR(20) DEFAULT 'Waiting' CHECK (Status IN (
        'Waiting', 'Called', 'InProgress', 'Completed', 'NoShow', 'Cancelled', 'Transferred'
    )),
    
    -- Priority Management
    Priority NVARCHAR(20) DEFAULT 'Normal' CHECK (Priority IN (
        'Emergency', 'Urgent', 'Senior', 'Appointment', 'Normal', 'Follow-up'
    )),
    
    -- Visit Type
    VisitType NVARCHAR(20) DEFAULT 'Walk-in' CHECK (VisitType IN (
        'Walk-in', 'Appointment', 'Emergency', 'Follow-up'
    )),
    
    -- Timing Information
    CheckInTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    EstimatedWaitTime INT NULL,
    CalledTime DATETIME2 NULL,
    ConsultationStartTime DATETIME2 NULL,
    ConsultationEndTime DATETIME2 NULL,
    
    -- Queue Position
    SequenceNumber INT NOT NULL,
    CurrentPosition INT NULL,
    
    -- Additional Information
    ChiefComplaint NVARCHAR(500) NULL,
    Notes NVARCHAR(1000) NULL,
    ArrivalMethod NVARCHAR(20) NULL,
    WaitingTime INT NULL,
    
    -- Station/Counter Info
    CheckInCounter NVARCHAR(20) NULL,
    CheckInBy INT NOT NULL,
    
    -- Transfer Information
    TransferredFromQueueID INT NULL,
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
    CONSTRAINT FK_Queue_TransferredFrom FOREIGN KEY (TransferredFromQueueID) 
        REFERENCES Clinical_Management.PatientQueue(QueueID),

    CONSTRAINT CK_Queue_Times CHECK (
        (CalledTime IS NULL OR CalledTime >= CheckInTime) AND
        (ConsultationStartTime IS NULL OR ConsultationStartTime >= CheckInTime) AND
        (ConsultationEndTime IS NULL OR ConsultationEndTime >= ConsultationStartTime)
    )
);
GO

CREATE TABLE Clinical_Management.QueueConfiguration (
    ConfigID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentID INT NULL,
    PhysicianID INT NULL,
    QueuePrefix NVARCHAR(5) NOT NULL,
    AverageConsultationTime INT DEFAULT 15 CHECK (AverageConsultationTime > 0),
    MaxPatientsPerDay INT NULL CHECK (MaxPatientsPerDay > 0),
    DisplayOnScreen BIT DEFAULT 1,
    DisplayOrder INT NULL,
    StartingNumber INT DEFAULT 1 CHECK (StartingNumber > 0),
    ResetDaily BIT DEFAULT 1,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_QueueConfig_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_QueueConfig_Physician FOREIGN KEY (PhysicianID) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_QueueConfig_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT CK_QueueConfig_DeptOrPhysician CHECK (
        DepartmentID IS NOT NULL OR PhysicianID IS NOT NULL
    )
);
GO

CREATE TABLE Clinical_Management.QueueCallHistory (
    CallID INT IDENTITY(1,1) PRIMARY KEY,
    QueueID INT NOT NULL,
    CallNumber INT NOT NULL CHECK (CallNumber > 0),
    CalledTime DATETIME2 DEFAULT GETDATE(),
    CalledBy INT NOT NULL,
    ResponseStatus NVARCHAR(20) CHECK (ResponseStatus IN ('Responded', 'NoResponse', 'Delayed')),
    Notes NVARCHAR(200) NULL,
    CONSTRAINT FK_CallHistory_Queue FOREIGN KEY (QueueID) 
        REFERENCES Clinical_Management.PatientQueue(QueueID),
    CONSTRAINT FK_CallHistory_CalledBy FOREIGN KEY (CalledBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Clinical_Management.DisplayBoards (
    BoardID INT IDENTITY(1,1) PRIMARY KEY,
    BoardName NVARCHAR(100) NOT NULL,
    Location NVARCHAR(100) NOT NULL,
    DisplayType NVARCHAR(20) CHECK (DisplayType IN ('General', 'Department', 'Physician')),
    DepartmentID INT NULL,
    PhysicianID INT NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_DisplayBoard_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_DisplayBoard_Physician FOREIGN KEY (PhysicianID) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_DisplayBoard_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

-- =============================================
-- 5. CLINICAL DATA MANAGEMENT
-- =============================================

CREATE TABLE Clinical_Management.Encounters (
    EncounterID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterNumber NVARCHAR(20) UNIQUE NOT NULL,
    PatientID INT NOT NULL,
    PhysicianID INT NOT NULL, 
    QueueID INT NULL,
    EncounterDate DATETIME2 NOT NULL,
    EncounterType NVARCHAR(50) NOT NULL CHECK (EncounterType IN ('Outpatient', 'Inpatient', 'Emergency', 'Day Surgery', 'Telemedicine')),
    VisitType NVARCHAR(20) CHECK (VisitType IN ('New Patient', 'Follow-up', 'Consultation', 'Procedure', 'Screening', 'Annual Checkup', 'Emergency')),
    ChiefComplaint NVARCHAR(500) NULL,
    ReviewOfSystems NVARCHAR(MAX) NULL,
    StartDateTime DATETIME2 NOT NULL,
    EndDateTime DATETIME2 NULL,
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Completed', 'Cancelled')),
    FollowUpInstructions NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_Encounters_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Encounters_Physician FOREIGN KEY (PhysicianID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Encounters_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID),
    CONSTRAINT FK_Encounters_Queue FOREIGN KEY (QueueID) REFERENCES Clinical_Management.PatientQueue(QueueID),
    CONSTRAINT CK_Encounters_StartEnd CHECK (EndDateTime IS NULL OR EndDateTime > StartDateTime)
);
GO

CREATE TABLE Clinical_Management.VitalSigns (
    VitalSignID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,
    Temperature DECIMAL(4,2) NULL CHECK (Temperature BETWEEN 32 AND 45 OR Temperature IS NULL),
    BloodPressure NVARCHAR(20) NULL,  
    HeartRate INT NULL CHECK (HeartRate BETWEEN 20 AND 250 OR HeartRate IS NULL),
    RespiratoryRate INT NULL CHECK (RespiratoryRate BETWEEN 6 AND 60 OR RespiratoryRate IS NULL), 
    OxygenSaturation DECIMAL(5,2) NULL CHECK (OxygenSaturation BETWEEN 70 AND 100 OR OxygenSaturation IS NULL),
    Height DECIMAL(5,2) NULL CHECK (Height > 0 OR Height IS NULL), 
    Weight DECIMAL(5,2) NULL CHECK (Weight > 0 OR Weight IS NULL), 
    BMI AS (CASE WHEN Height > 0 THEN Weight / POWER(Height/100, 2) ELSE NULL END),
    BloodGlucose DECIMAL(5,2) NULL CHECK (BloodGlucose >= 0 OR BloodGlucose IS NULL),
    PainScore INT CHECK (PainScore BETWEEN 0 AND 10 OR PainScore IS NULL),
    Notes NVARCHAR(500) NULL,
    RecordedAt DATETIME2 DEFAULT GETDATE(),
    RecordedBy INT NOT NULL,
    CONSTRAINT FK_VitalSigns_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_VitalSigns_RecordedBy FOREIGN KEY (RecordedBy) REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Clinical_Management.Diagnoses (
    DiagnosisID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,
    PatientID INT NOT NULL,
    DiagnosisCode NVARCHAR(20) NOT NULL,
    DiagnosisDescription NVARCHAR(500) NOT NULL,
    DiagnosisType NVARCHAR(20) DEFAULT 'Primary' CHECK (DiagnosisType IN ('Primary', 'Secondary', 'Differential')),
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Resolved', 'Chronic', 'RuledOut')),
    DiagnosisDate DATETIME2 DEFAULT GETDATE(),
    DiagnosedBy INT NOT NULL,
    Notes NVARCHAR(1000) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Diagnoses_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_Diagnoses_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Diagnoses_Staff FOREIGN KEY (DiagnosedBy) REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Clinical_Management.NursingTasks (
    TaskID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,
    TaskDescription NVARCHAR(500) NOT NULL,
    TaskType NVARCHAR(50) NOT NULL,
    Priority NVARCHAR(20) DEFAULT 'Normal' CHECK (Priority IN ('Low', 'Normal', 'High', 'Urgent')),
    ScheduledTime DATETIME2 NULL,
    PerformedTime DATETIME2 NULL,
    OrderedBy INT NOT NULL,
    PerformedBy INT NULL,
    Status NVARCHAR(20) DEFAULT 'Planned' CHECK (Status IN ('Planned','Done','Skipped','Cancelled')),
    Notes NVARCHAR(1000) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    CONSTRAINT FK_NursingTasks_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_NursingTasks_OrderedBy FOREIGN KEY (OrderedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_NursingTasks_PerformedBy FOREIGN KEY (PerformedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_NursingTasks_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT CK_NursingTasks_Times CHECK (
        (PerformedTime IS NULL OR PerformedTime >= ScheduledTime)
    )
);
GO

-- =============================================
-- 6. MEDICATION MANAGEMENT
-- =============================================

CREATE TABLE Medication_Management.Medications (
    MedicationID INT IDENTITY(1,1) PRIMARY KEY,
    MedicationName NVARCHAR(200) NOT NULL,
    GenericName NVARCHAR(200) NULL,
    Strength NVARCHAR(50) NULL, 
    Form NVARCHAR(50) NULL,
    Route NVARCHAR(50) DEFAULT 'Oral', 
    DrugClass NVARCHAR(100) NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_Medications_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Clinical_Management.Prescriptions (
    PrescriptionID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    EncounterID INT NOT NULL,
    MedicationID INT NULL,
    MedicationName NVARCHAR(200) NULL,
    PrescribedBy INT NOT NULL,
    Dosage NVARCHAR(100) NOT NULL, 
    Frequency NVARCHAR(50) NOT NULL,
    Duration INT NOT NULL CHECK (Duration > 0),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Instructions NVARCHAR(200) NULL,
    StartDate DATE DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Completed', 'Cancelled', 'Expired')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Prescriptions_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Prescriptions_Medication FOREIGN KEY (MedicationID) REFERENCES Medication_Management.Medications(MedicationID),
    CONSTRAINT FK_Prescriptions_PrescribedBy FOREIGN KEY (PrescribedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Prescriptions_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID)
);
GO

-- =============================================
-- 7. ORDER MANAGEMENT
-- =============================================

CREATE TABLE Order_Management.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,          
    OrderingPhysicianID INT NOT NULL,
    OrderDescription NVARCHAR(500) NULL, 
    OrderType NVARCHAR(50) NOT NULL,  
    OrderDate DATETIME2 DEFAULT GETDATE(),
    Priority NVARCHAR(10) CHECK (Priority IN ('Routine','Urgent','Stat')),
    Status NVARCHAR(20) CHECK (Status IN ('New','InProgress','Completed','Cancelled')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_Orders_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_Orders_Doctor FOREIGN KEY (OrderingPhysicianID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Orders_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID)
);
GO

-- =============================================
-- 8. OUTPATIENT MANAGEMENT
-- =============================================

CREATE TABLE Outpatient_Management.OPD_Visit (
    OPDVisitID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,
    AppointmentID INT NULL,
    VisitReason NVARCHAR(500),
    VisitStatus NVARCHAR(20) DEFAULT 'In Progress' CHECK (VisitStatus IN ('Scheduled', 'In Progress', 'Completed', 'Cancelled', 'NoShow')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_OPD_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_OPD_Appointment FOREIGN KEY (AppointmentID) REFERENCES Scheduling.Appointments(AppointmentID)
);
GO

-- =============================================
-- 9. INPATIENT MANAGEMENT
-- =============================================

CREATE TABLE Inpatient_Management.Wards (
    WardID INT IDENTITY(1,1) PRIMARY KEY,
    WardName NVARCHAR(100) NOT NULL,
    DepartmentID INT NULL,
    WardType NVARCHAR(50) DEFAULT 'General' 
        CHECK (WardType IN ('General', 'ICU', 'Pediatric', 'Maternity', 'Surgical', 'Psychiatric', 'Isolation')),
    Description NVARCHAR(500) NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_Wards_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_Wards_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Wards_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Inpatient_Management.Beds (
    BedID INT IDENTITY(1,1) PRIMARY KEY,
    WardID INT NOT NULL,
    BedNumber NVARCHAR(10) NOT NULL,
    BedStatus NVARCHAR(20) DEFAULT 'Available' 
        CHECK (BedStatus IN ('Available','Occupied','Cleaning','Blocked','Maintenance')),
    Description NVARCHAR(200) NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_Beds_Ward FOREIGN KEY (WardID) 
        REFERENCES Inpatient_Management.Wards(WardID),
    CONSTRAINT FK_Beds_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Beds_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT UQ_Bed_Ward_Number UNIQUE (WardID, BedNumber)
);
GO

CREATE TABLE Inpatient_Management.Admissions (
    AdmissionID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    EncounterID INT NULL,
    AdmittingPhysicianID INT NOT NULL,
    AdmissionDate DATETIME2 NOT NULL,
    DischargeDate DATETIME2 NULL,
    AdmittedFrom NVARCHAR(50) 
        CHECK (AdmittedFrom IN ('Emergency Room', 'Outpatient Clinic', 'Transfer', 'Direct Admission', 'Referral')),
    BedID INT NOT NULL, 
    AdmissionReason NVARCHAR(500) NULL,
    Status NVARCHAR(20) DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Discharged', 'Transferred', 'Expired', 'Cancelled')),
    TotalCharges DECIMAL(12,2) DEFAULT 0 CHECK (TotalCharges >= 0),
    EstimatedDischargeDate DATE NULL,
    DischargeSummary NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_Admissions_Patient FOREIGN KEY (PatientID) 
        REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Admissions_Encounter FOREIGN KEY (EncounterID) 
        REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_Admissions_Bed FOREIGN KEY (BedID) 
        REFERENCES Inpatient_Management.Beds(BedID),
    CONSTRAINT FK_Admissions_AdmittingPhysician FOREIGN KEY (AdmittingPhysicianID) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Admissions_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Users(UserID),
    CONSTRAINT FK_Admissions_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Users(UserID),
    CONSTRAINT CK_Admission_Discharge_Date CHECK (
        DischargeDate IS NULL OR DischargeDate >= AdmissionDate
    )
);
GO

CREATE TABLE Inpatient_Management.BedTransfers (
    TransferID INT IDENTITY(1,1) PRIMARY KEY,
    AdmissionID INT NOT NULL,
    FromBedID INT NOT NULL,
    ToBedID INT NOT NULL,
    TransferDate DATETIME2 DEFAULT GETDATE(),
    Reason NVARCHAR(500) NULL,
    OrderedBy INT NOT NULL,
    Notes NVARCHAR(1000) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_Transfers_Admission FOREIGN KEY (AdmissionID) 
        REFERENCES Inpatient_Management.Admissions(AdmissionID),
    CONSTRAINT FK_Transfers_FromBed FOREIGN KEY (FromBedID) 
        REFERENCES Inpatient_Management.Beds(BedID),
    CONSTRAINT FK_Transfers_ToBed FOREIGN KEY (ToBedID) 
        REFERENCES Inpatient_Management.Beds(BedID),
    CONSTRAINT FK_Transfers_OrderedBy FOREIGN KEY (OrderedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Transfers_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT CK_Transfer_Different_Beds CHECK (FromBedID != ToBedID)
);
GO

-- =============================================
-- 10. EMERGENCY MANAGEMENT
-- =============================================

CREATE TABLE Emergency_Management.ER_Visit (
    ERVisitID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    PhysicianID INT NOT NULL,
    DepartmentID INT NULL,
    VisitDateTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    TriageLevel INT CHECK (TriageLevel BETWEEN 1 AND 5),
    ChiefComplaint NVARCHAR(500) NULL,
    ArrivalMode NVARCHAR(20) CHECK (ArrivalMode IN ('Walk-in','Ambulance')),
    ArrivalDateTime DATETIME2 NOT NULL,
    Disposition NVARCHAR(20) CHECK (Disposition IN ('Discharge','Admit','Transfer','Deceased')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_ER_Visit_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_ER_Visit_Physician FOREIGN KEY (PhysicianID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_ER_Visit_Department FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_ER_Visit_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT CK_ER_Visit_DateTime CHECK (VisitDateTime <= GETDATE())
);
GO

-- =============================================
-- 11. FINANCE MANAGEMENT
-- =============================================

CREATE TABLE Finance_Management.InsuranceCompanies (
    CompanyID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName NVARCHAR(200) NOT NULL UNIQUE,
    ContactPerson NVARCHAR(100) NULL,
    Phone NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    Address NVARCHAR(500) NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    UpdatedDate DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_InsuranceCompanies_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_InsuranceCompanies_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Finance_Management.InsurancePlans (
    PlanID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NOT NULL,
    PlanName NVARCHAR(100) NOT NULL,
    PlanCode NVARCHAR(50) NULL,
    CoveragePercentage DECIMAL(5,2) DEFAULT 80.00 
        CHECK (CoveragePercentage >= 0 AND CoveragePercentage <= 100),
    DeductibleAmount DECIMAL(10,2) DEFAULT 100.00 
        CHECK (DeductibleAmount >= 0),
    MaxAnnualCoverage DECIMAL(10,2) NULL 
        CHECK (MaxAnnualCoverage IS NULL OR MaxAnnualCoverage >= 0),
    CoPayAmount DECIMAL(10,2) DEFAULT 20.00 
        CHECK (CoPayAmount >= 0),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    UpdatedDate DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_InsurancePlans_Company FOREIGN KEY (CompanyID) 
        REFERENCES Finance_Management.InsuranceCompanies(CompanyID),
    CONSTRAINT FK_InsurancePlans_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_InsurancePlans_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Finance_Management.Services (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceCode NVARCHAR(20) UNIQUE NOT NULL,
    ServiceName NVARCHAR(200) NOT NULL,
    ServiceCategory NVARCHAR(50) NULL,
    Description NVARCHAR(500) NULL,
    DepartmentID INT NULL,
    StandardPrice DECIMAL(10,2) NOT NULL 
        CHECK (StandardPrice >= 0),
    Cost DECIMAL(10,2) NULL 
        CHECK (Cost IS NULL OR Cost >= 0),
    IsInsuranceCovered BIT DEFAULT 1,
    RequiresPreAuthorization BIT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    UpdatedDate DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_Services_Department FOREIGN KEY (DepartmentID) 
        REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_Services_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Services_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Patient_Management.PatientInsurance (
    PatientInsuranceID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    PlanID INT NOT NULL,
    PolicyNumber NVARCHAR(100) NOT NULL,
    GroupNumber NVARCHAR(100) NULL,
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    IsPrimary BIT DEFAULT 1,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    UpdatedDate DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_PatientInsurance_Patient FOREIGN KEY (PatientID) 
        REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_PatientInsurance_Plan FOREIGN KEY (PlanID) 
        REFERENCES Finance_Management.InsurancePlans(PlanID),
    CONSTRAINT FK_PatientInsurance_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_PatientInsurance_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT CK_EffectiveExpiryDate CHECK (ExpiryDate > EffectiveDate)
);
GO

CREATE TABLE Finance_Management.InsuranceVerificationLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    InsurancePlanID INT NOT NULL,
    VerificationMethod NVARCHAR(50) CHECK (VerificationMethod IN (
        'Card Check', 'Portal Login', 'Phone Call', 'Email', 'Auto-Renew'
    )),
    VerificationDate DATETIME2 DEFAULT GETDATE(),
    VerifiedBy INT NULL,
    IsSuccessful BIT DEFAULT 1,
    Notes NVARCHAR(500) NULL,
    NextVerificationDate DATE NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_VerificationLog_Patient FOREIGN KEY (PatientID) 
        REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_VerificationLog_Plan FOREIGN KEY (InsurancePlanID) 
        REFERENCES Finance_Management.InsurancePlans(PlanID),
    CONSTRAINT FK_VerificationLog_VerifiedBy FOREIGN KEY (VerifiedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_VerificationLog_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Finance_Management.Invoices (
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNumber NVARCHAR(50) UNIQUE NOT NULL,
    
    -- Patient and Context
    PatientID INT NOT NULL,
    AdmissionID INT NULL,
    EncounterID INT NULL,
    PhysicianID INT NULL,
    InsurancePlanID INT NULL,
    
    -- Financial Breakdown
    SubTotal DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (SubTotal >= 0),
    TaxRate DECIMAL(5,2) DEFAULT 0 CHECK (TaxRate >= 0),
    TaxAmount DECIMAL(10,2) DEFAULT 0 CHECK (TaxAmount >= 0),
    DiscountRate DECIMAL(5,2) DEFAULT 0 CHECK (DiscountRate >= 0),
    DiscountAmount DECIMAL(10,2) DEFAULT 0 CHECK (DiscountAmount >= 0),
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0),
    
    -- Insurance Processing
    InsuranceCoverageAmount DECIMAL(10,2) DEFAULT 0 CHECK (InsuranceCoverageAmount >= 0),
    PatientResponsibilityAmount DECIMAL(10,2) DEFAULT 0 CHECK (PatientResponsibilityAmount >= 0),
    InsuranceClaimNumber NVARCHAR(100) NULL,
    InsuranceStatus NVARCHAR(20) DEFAULT 'Not Submitted' 
        CHECK (InsuranceStatus IN ('Not Submitted', 'Submitted', 'Approved', 'Rejected', 'Paid', 'Pending')),
    CoPayAmount DECIMAL(10,2) DEFAULT 0 CHECK (CoPayAmount >= 0),
    DeductibleAmount DECIMAL(10,2) DEFAULT 0 CHECK (DeductibleAmount >= 0),
    
    -- Payment Tracking
    PaidAmount DECIMAL(10,2) DEFAULT 0 CHECK (PaidAmount >= 0),
    BalanceAmount AS (TotalAmount - PaidAmount),
    
    -- Status and Dates
    PaymentStatus NVARCHAR(20) DEFAULT 'Unpaid' 
        CHECK (PaymentStatus IN ('Paid', 'Unpaid', 'Partial', 'Cancelled', 'Refunded')),
    Status NVARCHAR(20) DEFAULT 'Draft' 
        CHECK (Status IN ('Draft', 'Posted', 'Cancelled')),
    InvoiceDate DATETIME2 DEFAULT GETDATE(),
    DueDate DATE NULL,
    
    -- Additional Fields
    Notes NVARCHAR(1000) NULL,
    PaymentMethod NVARCHAR(50) NULL,
    
    -- System Fields
    CreatedBy INT NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    UpdatedBy INT NULL,
    UpdatedDate DATETIME2 NULL,
    
    -- Foreign Keys
    CONSTRAINT FK_Invoices_Patient FOREIGN KEY (PatientID) 
        REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Invoices_Admission FOREIGN KEY (AdmissionID) 
        REFERENCES Inpatient_Management.Admissions(AdmissionID),
    CONSTRAINT FK_Invoices_Encounter FOREIGN KEY (EncounterID) 
        REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_Invoices_Physician FOREIGN KEY (PhysicianID) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Invoices_InsurancePlan FOREIGN KEY (InsurancePlanID) 
        REFERENCES Finance_Management.InsurancePlans(PlanID),
    CONSTRAINT FK_Invoices_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Invoices_UpdatedBy FOREIGN KEY (UpdatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Finance_Management.InvoiceLines (
    LineID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID INT NOT NULL,
    ServiceID INT NULL,
    OrderID INT NULL,
    Description NVARCHAR(500) NOT NULL,
    Quantity INT DEFAULT 1 CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    
    -- Line-level calculations
    LineDiscountRate DECIMAL(5,2) DEFAULT 0 CHECK (LineDiscountRate >= 0),
    LineDiscountAmount DECIMAL(10,2) DEFAULT 0 CHECK (LineDiscountAmount >= 0),
    
    -- Computed columns for automatic calculations
    LineCharges AS (Quantity * UnitPrice),
    LineTotal AS (Quantity * UnitPrice - LineDiscountAmount),
    
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT FK_InvoiceLines_Invoice FOREIGN KEY (InvoiceID) 
        REFERENCES Finance_Management.Invoices(InvoiceID),
    CONSTRAINT FK_InvoiceLines_Service FOREIGN KEY (ServiceID) 
        REFERENCES Finance_Management.Services(ServiceID),
    CONSTRAINT FK_InvoiceLines_Order FOREIGN KEY (OrderID) 
        REFERENCES Order_Management.Orders(OrderID)
);
GO

CREATE TABLE Finance_Management.InsuranceClaims (
    ClaimID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID INT NOT NULL,
    InsurancePlanID INT NOT NULL,
    ClaimNumber NVARCHAR(100) UNIQUE NOT NULL,
    SubmittedDate DATETIME2 DEFAULT GETDATE(),
    ApprovedDate DATETIME2 NULL,
    ClaimAmount DECIMAL(10,2) NOT NULL CHECK (ClaimAmount >= 0),
    ApprovedAmount DECIMAL(10,2) NULL CHECK (ApprovedAmount >= 0),
    RejectedAmount DECIMAL(10,2) NULL CHECK (RejectedAmount >= 0),
    Status NVARCHAR(20) DEFAULT 'Submitted' 
        CHECK (Status IN ('Submitted', 'Processing', 'Approved', 'Partially Approved', 'Rejected', 'Paid')),
    RejectionReason NVARCHAR(500) NULL,
    PaymentDate DATETIME2 NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    
    CONSTRAINT FK_InsuranceClaims_Invoice FOREIGN KEY (InvoiceID) 
        REFERENCES Finance_Management.Invoices(InvoiceID),
    CONSTRAINT FK_InsuranceClaims_Plan FOREIGN KEY (InsurancePlanID) 
        REFERENCES Finance_Management.InsurancePlans(PlanID),
    CONSTRAINT FK_InsuranceClaims_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Finance_Management.Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID INT NOT NULL,
    PaymentDate DATETIME2 DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(20) 
        CHECK (PaymentMethod IN ('Cash','Card','Transfer','Insurance','Cheque')),
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    ReferenceNumber NVARCHAR(50) NULL,
    Status NVARCHAR(20) DEFAULT 'Completed' 
        CHECK (Status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    PaymentType NVARCHAR(20) DEFAULT 'Patient' 
        CHECK (PaymentType IN ('Patient', 'Insurance', 'Corporate')),
    Notes NVARCHAR(500) NULL,
    ProcessedBy INT NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT FK_Payments_Invoice FOREIGN KEY (InvoiceID) 
        REFERENCES Finance_Management.Invoices(InvoiceID),
    CONSTRAINT FK_Payments_ProcessedBy FOREIGN KEY (ProcessedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

CREATE TABLE Finance_Management.InsurancePayments (
    InsurancePaymentID INT IDENTITY(1,1) PRIMARY KEY,
    ClaimID INT NOT NULL,
    PaymentAmount DECIMAL(10,2) NOT NULL CHECK (PaymentAmount > 0),
    PaymentDate DATETIME2 DEFAULT GETDATE(),
    ReferenceNumber NVARCHAR(100),
    Notes NVARCHAR(500),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL,
    
    CONSTRAINT FK_InsurancePayments_Claim FOREIGN KEY (ClaimID) 
        REFERENCES Finance_Management.InsuranceClaims(ClaimID),
    CONSTRAINT FK_InsurancePayments_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Core_system.Staff(StaffID)
);
GO

-- =============================================
-- 12. SECURITY & AUDITING
-- =============================================

CREATE TABLE Security.AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(50) NOT NULL,
    Operation NVARCHAR(10) NOT NULL,
    RecordID INT NOT NULL,
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    ChangedBy INT NULL,
    ChangedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_AuditLog_ChangedBy FOREIGN KEY (ChangedBy) REFERENCES Core_system.Users(UserID)
);
GO

-- =============================================
-- 13. PERFORMANCE INDEXES
-- =============================================

CREATE INDEX IX_Encounters_PatientID ON Clinical_Management.Encounters(PatientID);
CREATE INDEX IX_Encounters_PhysicianID ON Clinical_Management.Encounters(PhysicianID);
CREATE INDEX IX_Orders_EncounterID ON Order_Management.Orders(EncounterID);
CREATE INDEX IX_Appointments_DateTime ON Scheduling.Appointments(AppointmentDateTime);
CREATE INDEX IX_Appointments_PatientID ON Scheduling.Appointments(PatientID);
CREATE INDEX IX_Appointments_PhysicianID ON Scheduling.Appointments(PhysicianID);
CREATE INDEX IX_Patient_MRN ON Patient_Management.Patient(MRN);
CREATE INDEX IX_Patient_NationalID ON Patient_Management.Patient(NationalID);
CREATE INDEX IX_Queue_PatientDate ON Clinical_Management.PatientQueue(PatientID, QueueDate);
CREATE INDEX IX_Queue_Status ON Clinical_Management.PatientQueue(Status);
CREATE INDEX IX_Queue_PhysicianDate ON Clinical_Management.PatientQueue(PhysicianID, QueueDate);
CREATE INDEX IX_Admissions_PatientID ON Inpatient_Management.Admissions(PatientID);
CREATE INDEX IX_Admissions_BedID ON Inpatient_Management.Admissions(BedID);
CREATE INDEX IX_Admissions_Status ON Inpatient_Management.Admissions(Status);
CREATE INDEX IX_Beds_WardID ON Inpatient_Management.Beds(WardID);
CREATE INDEX IX_Beds_Status ON Inpatient_Management.Beds(BedStatus);
CREATE INDEX IX_Invoices_PatientID ON Finance_Management.Invoices(PatientID);
CREATE INDEX IX_Invoices_Status ON Finance_Management.Invoices(Status);
CREATE INDEX IX_InsuranceClaims_Status ON Finance_Management.InsuranceClaims(Status);
GO


