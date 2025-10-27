USE HIS_V1
-- =============================================
-- CORE SYSTEM TABLES
-- =============================================

CREATE TABLE Core_system.Specializations(
    SpecializationID INT IDENTITY(1,1) PRIMARY KEY,
    SpecializationName NVARCHAR(100) NOT NULL UNIQUE,
    SpecializationCode NVARCHAR(10) UNIQUE,
    Description NVARCHAR(255)
);

-- Users and Roles
CREATE TABLE Core_system.Users(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    UserName NVARCHAR(150) UNIQUE NOT NULL,
    BrithDate DATETIME NOT NULL,  
    Email NVARCHAR(200) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    LastLoginAt DATETIME2,
    CreatedBy INT,
    CONSTRAINT FK_Users_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID)
);

CREATE TABLE Core_system.Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY, 
    RoleName NVARCHAR(70) NOT NULL,
    Description NVARCHAR(255),
    Permissions NVARCHAR(MAX)
);


CREATE TABLE Core_system.Departments(
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName VARCHAR(50) NOT NULL UNIQUE,
    DepartmentCode VARCHAR(20) UNIQUE,
    ManagerID INT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    CreatedBy INT,
    IsActive BIT DEFAULT 1
);

ALTER TABLE Core_system.Departments 
ADD CONSTRAINT FK_Departments_ManagerID FOREIGN KEY (ManagerID) REFERENCES Core_system.Staff(StaffID);

CREATE TABLE Core_system.Staff(
    StaffID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    FullName NVARCHAR(120) NOT NULL,
    Gender CHAR(10) CHECK (Gender IN ('Male','Female')),
    Phone NVARCHAR(20),
    DepartmentID INT,
    SpecializationID INT,
    Position NVARCHAR(100),     
    MobileNumber NVARCHAR(20),
    Address NVARCHAR(500),
    HireDate DATE NOT NULL,
    Salary DECIMAL(10,2),
    LicenseNumber NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_Staff_UserID FOREIGN KEY (UserID) REFERENCES Core_system.Users(UserID),
    CONSTRAINT FK_Staff_Department FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID),
    CONSTRAINT FK_Staff_Specialization FOREIGN KEY (SpecializationID) REFERENCES Core_system.Specializations(SpecializationID)
);



-- 

-- =============================================
-- SCHEDULING Tables
-- =============================================

CREATE TABLE Scheduling.DoctorsSchedules(
	ScheduleID int primary key identity(1,1),
	DoctorID int not null , 
	DayOfTheWeek TinyInt Null,
	SpecificDate Date null,
	StartTime time not null ,
	EndTime time not null ,
	SlotDuration  int Default 30, 
	MaxAppointments INT DEFAULT 1,
	IsRecurring Bit null,
	EffectiveStart Date not null,
	EffectiveEnd Date,
	IsAvalibale BIT Not NULL,
	CreatedAt datetime default GetDate(),
	CreatedBy int ,
	CONSTRAINT FK_Staff_Doctorid FOREIGN KEY (DoctorID) REFERENCES Core_system.Staff(StaffID),
	CONSTRAINT Check_Time CHECK(EndTime>StartTime),
	CONSTRAINT Check_Day_week CHECK(DayOfTheWeek >0 and DayOfTheWeek < 8 or DayOfTheWeek IS NULL),
	CONSTRAINT CHK_DateOrDay CHECK (DayOfTheWeek IS NOT NULL OR SpecificDate IS NOT NULL),
	CONSTRAINT FK_DoctorsSchedules_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID),

	)

-- =============================================
-- PATIENT MANAGEMENT
-- =============================================

-- Patient Management
CREATE TABLE Patient_Management.Patient (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    MRN NVARCHAR(50) UNIQUE NOT NULL,
    NationalID NVARCHAR(20) UNIQUE, 
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50),
    LastName NVARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender NVARCHAR(20) CHECK(Gender IN ('Male', 'Female', 'Baby', 'Unknown')),
    BloodType NVARCHAR(15) CHECK(BloodType IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown')),
    PhoneNumber NVARCHAR(20),
    MobileNumber NVARCHAR(20),
    Email NVARCHAR(100),
    Address NVARCHAR(500),
    City NVARCHAR(50),                  
    Country NVARCHAR(50),
    EmergencyContactName NVARCHAR(100),
    EmergencyContactPhone NVARCHAR(20),
    Allergies NVARCHAR(500),
    MaritalStatus NVARCHAR(20) CHECK (MaritalStatus IN ('Single', 'Married', 'Divorced', 'Widowed', 'Other')),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    CONSTRAINT FK_Patient_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID)
);

CREATE TABLE Patient_Management.Patient_Reports(
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    DocumentType NVARCHAR(50) NOT NULL CHECK (DocumentType IN (
        'LabReport', 'RadiologyReport', 'DischargeSummary', 'ClinicalNote', 
        'OperativeReport', 'ProgressNote', 'Prescription', 'ReferralLetter',
         'PatientPhoto', 'MedicalImage'
    )),
    FileName NVARCHAR(255) NOT NULL,
    FileSize BIGINT NOT NULL, 
    FilePath NVARCHAR(500) NOT NULL,
    CreatedBy INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_PatientReports_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_PatientReports_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID)
);


-- =============================================
-- APPOINTMENT SCHEDULING
-- =============================================


-- Appointment Management
CREATE TABLE Scheduling.Appointments (
    AppointmentId INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    PhysicianID INT NOT NULL,
    DepartmentID INT NULL,
    AppointmentDateTime DATETIME NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Scheduled' CHECK (Status IN ('Scheduled', 'Confirmed', 'In Progress', 'Completed', 'Cancelled', 'No Show', 'Rescheduled')),
    Duration INT NOT NULL,
    Priority NVARCHAR(20) DEFAULT 'Normal' CHECK (Priority IN ('Low', 'Normal', 'High', 'Urgent')),
    VisitType NVARCHAR(20) CHECK (VisitType IN ('New Patient',  'Follow-up', 'Consultation','Procedure','Screening','Annual Checkup','Emergency')),
    ReminderSent BIT DEFAULT 0,
    Complaint NVARCHAR(500) NULL,   
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    CONSTRAINT FK_Patient_ID_Appointments FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Staff_ID_Appointments FOREIGN KEY (PhysicianID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Appointments_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID)
);


-- =============================================
-- CLINICAL DATA MANAGEMENT
-- =============================================


USE HIS_V1

CREATE TABLE Clinical_Management.PatientQueue(

    QueueID INT IDENTITY(1,1) PRIMARY KEY,
    PatientId INT NOT NULL ,
    DoctorId INT NOT NULL , 
    AppointmentId INT NULL ,
    DepartmentID INT NOT NULL,
    QueueNumber NVARCHAR(20) NOT NULL UNIQUE,
    QueueDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status NVARCHAR(30) DEFAULT 'Waiting' CHECK (Status in ( 'Waiting' , 'Called','Inprogress','Canceled','NoShow')),
    ArrivalMethod NVARCHAR(20) NOT NULL CHECK (ArrivalMethod IN ('Walk-in','Appointment','Emergency')),
    Priority NVARCHAR(20) DEFAULT 'Normal' CHECK (Priority IN ('Low', 'Normal', 'High', 'Urgent')),
    SequenceNumber INT NOT NULL,
    CurrentPosition INT,
    CheckInTime DateTime DEFAULT GETDATE(),
    WatingTime INT,
    CalledTime DATETIME,
    ConsultationStartTime DateTime,
    ConsultationEndTime DateTime,
    CheckInBy INT,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,

       CONSTRAINT CK_Queue_Times CHECK (
        (CalledTime IS NULL OR CalledTime >= CheckInTime) AND
        (ConsultationStartTime IS NULL OR ConsultationStartTime >= CheckInTime) AND
        (ConsultationEndTime IS NULL OR ConsultationEndTime >= ConsultationStartTime)
    ),
    CONSTRAINT UQ_Queue_Patient_Doctor_Date UNIQUE (PatientID, DoctorID, QueueDate),
    CONSTRAINT FK_Queue_CheckInBy FOREIGN KEY (CheckInBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_QueueCreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID),
    CONSTRAINT FK_Queue_Patient FOREIGN KEY (PatientId) REFERENCES Patient_Management.Patient(PatientId),
    CONSTRAINT FK_Queue_Provider FOREIGN KEY (DoctorId) REFERENCES Core_system.Staff(StaffId),
    CONSTRAINT FK_Queue_Appointment FOREIGN KEY (AppointmentId) REFERENCES Scheduling.Appointments(AppointmentId),
)









CREATE TABLE Clinical_Management.Encounters (
    EncounterId INT IDENTITY(1,1) PRIMARY KEY,
    EncounterNumber NVARCHAR(20) UNIQUE NOT NULL,
    PatientId INT NOT NULL,
    PhysicianID INT NOT NULL, 
    QueueId INT,
    EncounterDate DATETIME2 NOT NULL,
    EncounterType NVARCHAR(50) NOT NULL CHECK (EncounterType IN ('Outpatient', 'Inpatient', 'Emergency', 'Day Surgery', 'Telemedicine')),
    VisitType NVARCHAR(20) CHECK (VisitType IN ('New Patient',  'Follow-up', 'Consultation','Procedure','Screening','Annual Checkup','Emergency'));
    ReviewOfSystems NVARCHAR(MAX),
    StartDateTime DATETIME NOT NULL,
    EndDateTime DATETIME NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Completed', 'Cancelled')),
    FollowUpInstructions NVARCHAR(MAX),
    CreatedAt DATETIME2 DEFAULT GETDATE(),

    CreatedBy INT,
    CONSTRAINT FK_Encounters_Patient FOREIGN KEY (PatientId) REFERENCES Patient_Management.Patient(PatientId),
    CONSTRAINT FK_Encounters_Provider FOREIGN KEY (PhysicianID) REFERENCES Core_system.Staff(StaffId),
    CONSTRAINT FK_Encounters_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserId),
    ALTER TABLE Clinical_Management.EncountersADD CONSTRAINT FK_Queue_Encounters FOREIGN KEY (QueueId)REFERENCES Clinical_Management.PatientQueue(QueueID),

    CONSTRAINT CK_Check_Start_End_date CHECK (EndDateTime > StartDateTime)

);




CREATE TABLE Clinical_Management.VitalSigns (
    VitalSignId INT IDENTITY(1,1) PRIMARY KEY,
    EncounterId INT NOT NULL,
    Temperature DECIMAL(4,2),
    BloodPressure NVARCHAR(20),  
    HeartRate INT,
    RespiratoryRate INT, 
    OxygenSaturation DECIMAL(5,2),
    Height DECIMAL(5,2), 
    Weight DECIMAL(5,2), 
    BMI AS (CASE WHEN Height > 0 THEN Weight / POWER(Height/100, 2) ELSE NULL END),
    BloodGlucose DECIMAL(5,2),
    Notes NVARCHAR(500),
    PainScore INT CHECK (PainScore BETWEEN 0 AND 10),
    RecordedAt DATETIME2 DEFAULT GETDATE(),
    RecordedBy INT NOT NULL,
    CONSTRAINT FK_VitalSigns_Encounter FOREIGN KEY (EncounterId) REFERENCES Clinical_Management.Encounters(EncounterId),
    CONSTRAINT FK_VitalSigns_RecordedBy FOREIGN KEY (RecordedBy) REFERENCES Core_system.Staff(StaffId),
    CONSTRAINT CK_Temp_Range CHECK (Temperature BETWEEN 32 AND 45 OR Temperature IS NULL),
    CONSTRAINT CK_VitalSigns_HeartRate CHECK (HeartRate BETWEEN 20 AND 250 OR HeartRate IS NULL)
);

CREATE TABLE Clinical_Management.Diagnoses (
    DiagnosisId INT IDENTITY(1,1) PRIMARY KEY,
    EncounterId INT NOT NULL,
    PatientId INT NOT NULL, 
    DiagnosisCode NVARCHAR(20) NOT NULL,
    DiagnosisDescription NVARCHAR(500) NOT NULL,
    DiagnosisType NVARCHAR(20) DEFAULT 'Primary' CHECK (DiagnosisType IN ('Primary', 'Secondary')),
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Resolved', 'Chronic')),
    DiagnosisDate DATE DEFAULT GETDATE(),
    DiagnosedBy INT NOT NULL,
    Notes NVARCHAR(1000),
    CONSTRAINT FK_Diagnoses_Encounter FOREIGN KEY (EncounterId) REFERENCES Clinical_Management.Encounters(EncounterId),
    CONSTRAINT FK_Diagnoses_Patient FOREIGN KEY (PatientId) REFERENCES Patient_Management.Patient(PatientId),
    CONSTRAINT FK_Diagnoses_Staff FOREIGN KEY (DiagnosedBy) REFERENCES Core_system.Staff(StaffId)
);

-- Medication Management
CREATE TABLE Medication_Management.Medications (
    MedicationId INT IDENTITY(1,1) PRIMARY KEY,
    MedicationName NVARCHAR(200) NOT NULL,
    GenericName NVARCHAR(200),
    Strength NVARCHAR(50), 
    Form NVARCHAR(50),
    Route NVARCHAR(50) DEFAULT 'Oral', 
    DrugClass NVARCHAR(100),
    IsActive BIT DEFAULT 1
);


CREATE TABLE Clinical_Management.Prescriptions (
    PrescriptionId INT IDENTITY(1,1) PRIMARY KEY,
    PatientId INT NOT NULL,
    MedicationId INT NOT NULL,
    PrescribedBy INT NOT NULL,
    Dosage NVARCHAR(100) NOT NULL, 
    Frequency NVARCHAR(50) NOT NULL,
    Duration INT NOT NULL,
    Quantity INT NOT NULL,
    Instructions NVARCHAR(200),
    StartDate DATE DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Completed', 'Cancelled')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Prescriptions_Patient FOREIGN KEY (PatientId) REFERENCES Patient_Management.Patient(PatientId),
    CONSTRAINT FK_Prescriptions_Medication FOREIGN KEY (MedicationId) REFERENCES Medication_Management.Medications(MedicationId),
    CONSTRAINT FK_Prescriptions_PrescribedBy FOREIGN KEY (PrescribedBy) REFERENCES Core_system.Staff(StaffId)
);

-- =============================================
-- ORDER MANAGEMENT
-- =============================================

-- Order Management
CREATE TABLE Order_Management.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,          
    OrderingPhysicianID INT NOT NULL,
    OrderDescription NVARCHAR(500) NULL, 
    OrderType NVARCHAR(50) NOT NULL,  
    OrderDate DATETIME DEFAULT GETDATE(),
    Priority NVARCHAR(10) CHECK (Priority IN ('Routine','Urgent','Stat')),
    Status NVARCHAR(20) CHECK (Status IN ('New','InProgress','Completed','Cancelled')),
    CONSTRAINT FK_Orders_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_Orders_Doctor FOREIGN KEY (OrderingPhysicianID) REFERENCES Core_system.Staff(StaffID)
);
-- =============================================
-- INPATIENT MANAGEMENT
-- =============================================


-- Inpatient Management
CREATE TABLE Inpatient_Management.Wards (
    WardID INT IDENTITY(1,1) PRIMARY KEY,
    WardName NVARCHAR(100) NOT NULL,
    DepartmentID INT NULL,
    WardType NVARCHAR(50) DEFAULT 'General',
    IsActive BIT DEFAULT 1
);

CREATE TABLE Inpatient_Management.Beds (
    BedID INT IDENTITY(1,1) PRIMARY KEY,
    WardID INT NOT NULL,
    BedNumber NVARCHAR(10) NOT NULL,
    BedStatus NVARCHAR(20) CHECK (BedStatus IN ('Available','Occupied','Cleaning','Blocked','Maintenance')),
    CONSTRAINT FK_Beds_Ward FOREIGN KEY (WardID) REFERENCES Inpatient_Management.Wards(WardID)
);

CREATE TABLE Inpatient_Management.Admissions (
    AdmissionId INT IDENTITY(1,1) PRIMARY KEY,
    PatientId INT NOT NULL,
    EncounterId INT, 
    AdmittingPhysicianID INT NOT NULL,
    AdmissionDate DATETIME2 NOT NULL,
    DischargeDate DATETIME2,
    AdmittedFrom NVARCHAR(50) CHECK (AdmittedFrom IN ('Emergency Room', 'Outpatient Clinic', 'Transfer', 'Direct Admission', 'Referral')),
    BedID INT NOT NULL, 
    AdmissionReason NVARCHAR(500) NULL,
    Status NVARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Discharged', 'Transferred', 'Expired')),
    TotalCharges DECIMAL(12,2) DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    CONSTRAINT FK_Admissions_Patient FOREIGN KEY (PatientId) REFERENCES Patient_Management.Patient(PatientId),
    CONSTRAINT FK_Admissions_Encounter FOREIGN KEY (EncounterId) REFERENCES Clinical_Management.Encounters(EncounterId),
    CONSTRAINT FK_Admissions_Bed FOREIGN KEY (BedID) REFERENCES Inpatient_Management.Beds(BedID),
    CONSTRAINT FK_Admissions_AdmittingPhysician FOREIGN KEY (AdmittingPhysicianID) REFERENCES Core_system.Staff(StaffId),
    CONSTRAINT FK_Admissions_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserId)
);

CREATE TABLE Inpatient_Management.BedTransfers (
    TransferId INT IDENTITY(1,1) PRIMARY KEY,
    AdmissionId INT NOT NULL,
    FromBedId INT NOT NULL,
    ToBedId INT NOT NULL,
    TransferDate DATETIME2 DEFAULT GETDATE(),
    Reason NVARCHAR(200),
    OrderedBy INT NOT NULL,
    CONSTRAINT FK_Transfers_Admission FOREIGN KEY (AdmissionId) REFERENCES Inpatient_Management.Admissions(AdmissionId),
    CONSTRAINT FK_Transfers_FromBed FOREIGN KEY (FromBedId) REFERENCES Inpatient_Management.Beds(BedId),
    CONSTRAINT FK_Transfers_ToBed FOREIGN KEY (ToBedId) REFERENCES Inpatient_Management.Beds(BedId),
    CONSTRAINT FK_Transfers_OrderedBy FOREIGN KEY (OrderedBy) REFERENCES Core_system.Staff(StaffID)
);

CREATE TABLE Clinical_Management.NursingTasks (
    TaskID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,
    OrderedBy INT NULL,
    TaskType NVARCHAR(50) NULL,
    ScheduledTime DATETIME NULL,  
    PerformedTime DATETIME NULL,
    PerformedBy INT NULL,
    Status NVARCHAR(20) CHECK (Status IN ('Planned','Done','Skipped')),
    CONSTRAINT FK_NursingTasks_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_NursingTasks_OrderedBy FOREIGN KEY (OrderedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_NursingTasks_PerformedBy FOREIGN KEY (PerformedBy) REFERENCES Core_system.Staff(StaffID)
);

-- =============================================
-- EMERGENCY MANAGEMENT
-- =============================================
-- Emergency Module
CREATE TABLE Emergency_Management.ER_Visit (
    ERVisitID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,
    TriageLevel INT CHECK (TriageLevel BETWEEN 1 AND 5),
    ChiefComplaint NVARCHAR(500) NULL,
    ArrivalMode NVARCHAR(20) CHECK (ArrivalMode IN ('Walk-in','Ambulance')),
    ArrivalDateTime DATETIME NOT NULL,
    Disposition NVARCHAR(20) CHECK (Disposition IN ('Discharge','Admit','Transfer','Deceased')),
    CONSTRAINT FK_ER_Visit_EncounterID FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterId)
);

CREATE TABLE Emergency_Management.TriageAssessment (
    TriageID INT IDENTITY(1,1) PRIMARY KEY,
    ERVisitID INT NOT NULL,
    BP NVARCHAR(20) NULL,  
    HR INT NULL,            
    Temp DECIMAL(4,1) NULL, 
    RR INT NULL,            
    SpO2 INT NULL,          
    PainScore INT CHECK (PainScore BETWEEN 0 AND 10),
    AssessedBy INT NULL,    
    AssessmentTime DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_TriageAssessment_AssessedBy FOREIGN KEY (AssessedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_TriageAssessment_ERVisit FOREIGN KEY (ERVisitID) REFERENCES Emergency_Management.ER_Visit(ERVisitID)
);

-- =============================================
-- OUTPATIENT MANAGEMENT
-- =============================================

CREATE TABLE Outpatient_Management.OPD_Visit (
    OPDVisitID INT IDENTITY(1,1) PRIMARY KEY,
    EncounterID INT NOT NULL,
    AppointmentID INT NULL,
    VisitReason NVARCHAR(500) NULL,
    VisitStatus NVARCHAR(20) CHECK (VisitStatus IN ('CheckedIn','Seen','Completed')),
    CONSTRAINT FK_EncounterID_OPD_visit FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterId),
    CONSTRAINT FK_Appointment_OPD_Visit FOREIGN KEY (AppointmentID) REFERENCES Scheduling.Appointments(AppointmentId)
);

-- =============================================
-- LABORATORY MANAGEMENT
-- =============================================

CREATE TABLE Lab_Management.LabOrders (
    LabOrderID INT PRIMARY KEY,
    PatientID INT NOT NULL,
    SpecimenType NVARCHAR(50) NULL,
    FastingRequired BIT NULL,
    OrderDateTime DATETIME NOT NULL DEFAULT GETDATE(),
    CollectedBy INT NULL,
    OrderStatus NVARCHAR(20) DEFAULT 'Pending' CHECK (OrderStatus IN ('Pending','Collected','InProgress','Completed','Cancelled')),
    CONSTRAINT FK_LabOrders_OrderID FOREIGN KEY (LabOrderID) REFERENCES Order_Management.Orders(OrderID),
    CONSTRAINT FK_LabOrders_CollectedBy FOREIGN KEY (CollectedBy) REFERENCES Core_system.Staff(StaffId),
    CONSTRAINT FK_LabOrders_PatientID FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID)
);

CREATE TABLE Lab_Management.LabTests (
    TestID INT IDENTITY(1,1) PRIMARY KEY,
    TestCode NVARCHAR(20) NOT NULL UNIQUE,
    TestName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NULL,
    SubCategory NVARCHAR(50) NULL,
    Unit NVARCHAR(20) NULL,
    ReferenceRange NVARCHAR(50) NULL,
    Price DECIMAL(10,2) NULL,
    TurnaroundTime INT NULL,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    CONSTRAINT FK_LabTests_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID)
);

CREATE TABLE Lab_Management.LabOrderTests (
    LabOrderID INT NOT NULL,
    TestID INT NOT NULL,
    DisplayOrder INT NULL,
    IsUrgent BIT DEFAULT 0,
    CONSTRAINT PK_LabOrderTests PRIMARY KEY (LabOrderID, TestID),
    CONSTRAINT FK_LabOrderTests_LabOrder FOREIGN KEY (LabOrderID) REFERENCES Lab_Management.LabOrders(LabOrderID),
    CONSTRAINT FK_LabOrderTests_Test FOREIGN KEY (TestID) REFERENCES Lab_Management.LabTests(TestID)
);

CREATE TABLE Lab_Management.Specimen (
    SpecimenID INT IDENTITY(1,1) PRIMARY KEY,
    LabOrderID INT NOT NULL,
    SpecimenBarcode NVARCHAR(50) UNIQUE NOT NULL,
    CollectionDateTime DATETIME NULL,
    CollectedBy INT NULL,
    ReceivedDateTime DATETIME NULL,
    ReceivedBy INT NULL,
    Status NVARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending','Collected','Received','InProgress','Completed','Rejected')),
    RejectionReason NVARCHAR(200) NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    CONSTRAINT FK_Specimen_LabOrder FOREIGN KEY (LabOrderID) REFERENCES Lab_Management.LabOrders(LabOrderID),
    CONSTRAINT FK_Specimen_CollectedBy FOREIGN KEY (CollectedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Specimen_ReceivedBy FOREIGN KEY (ReceivedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_Specimen_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID)
);

CREATE TABLE Lab_Management.LabResults (
    ResultID INT IDENTITY(1,1) PRIMARY KEY,
    SpecimenID INT NOT NULL,
    TestID INT NOT NULL,
    ResultValue NVARCHAR(100) NULL,
    AbnormalFlag CHAR(1) CHECK (AbnormalFlag IN ('H','L','N','A')),
    ResultDateTime DATETIME NOT NULL,
    PerformedBy INT NULL,
    VerifiedBy INT NULL,
    VerifiedDateTime DATETIME NULL,
    Notes NVARCHAR(500) NULL,
    CONSTRAINT FK_LabResults_Specimen FOREIGN KEY (SpecimenID) REFERENCES Lab_Management.Specimen(SpecimenID),
    CONSTRAINT FK_LabResults_Test FOREIGN KEY (TestID) REFERENCES Lab_Management.LabTests(TestID),
    CONSTRAINT FK_LabResults_PerformedBy FOREIGN KEY (PerformedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_LabResults_VerifiedBy FOREIGN KEY (VerifiedBy) REFERENCES Core_system.Staff(StaffID)
);

-- =============================================
-- RADIOLOGY MANAGEMENT
-- =============================================

CREATE TABLE Radiology_Management.RadiologyOrders (
    RadiologyOrderID INT PRIMARY KEY,
    Modality NVARCHAR(10) CHECK (Modality IN ('XR','CT','MRI','US','NM')),
    BodyPart NVARCHAR(50) NULL,
    Contrast BIT NULL DEFAULT 0,
    CONSTRAINT FK_RadiologyOrders_Orders FOREIGN KEY (RadiologyOrderID) REFERENCES Order_Management.Orders(OrderID)
);

CREATE TABLE Radiology_Management.ImagingStudy (
    StudyID INT IDENTITY(1,1) PRIMARY KEY,
    RadiologyOrderID INT NOT NULL,
    AccessionNumber NVARCHAR(50) UNIQUE NOT NULL,
    StudyDateTime DATETIME NOT NULL,
    Modality NVARCHAR(10) NULL,
    PerformedBy INT NULL,
    Status NVARCHAR(20) DEFAULT 'Scheduled' CHECK (Status IN ('Scheduled','InProgress','Performed','Reported')),
    CONSTRAINT FK_ImagingStudy_RadiologyOrder FOREIGN KEY (RadiologyOrderID) REFERENCES Radiology_Management.RadiologyOrders(RadiologyOrderID),
    CONSTRAINT FK_ImagingStudy_PerformedBy FOREIGN KEY (PerformedBy) REFERENCES Core_system.Staff(StaffID)
);

CREATE TABLE Radiology_Management.ImagingSeries (
    SeriesID INT IDENTITY(1,1) PRIMARY KEY,
    StudyID INT NOT NULL,
    SeriesNumber INT NOT NULL,
    SeriesDescription NVARCHAR(100) NULL,
    CONSTRAINT FK_ImagingSeries_Study FOREIGN KEY (StudyID) REFERENCES Radiology_Management.ImagingStudy(StudyID)
);

CREATE TABLE Radiology_Management.PACSImage (
    ImageID INT IDENTITY(1,1) PRIMARY KEY,
    SeriesID INT NOT NULL,
    SOPInstanceUID NVARCHAR(100) UNIQUE NOT NULL,
    StorageURI NVARCHAR(200) NULL,
    ImageNumber INT NULL,
    CONSTRAINT FK_PACSImage_Series FOREIGN KEY (SeriesID) REFERENCES Radiology_Management.ImagingSeries(SeriesID)
);

CREATE TABLE Radiology_Management.RadiologyReport (
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    StudyID INT NOT NULL UNIQUE, 
    ReportText NVARCHAR(MAX) NULL,
    Findings NVARCHAR(MAX) NULL,
    Impression NVARCHAR(MAX) NULL,
    ReportedBy INT NULL, 
    ReportDateTime DATETIME NOT NULL,
    Status NVARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft','Final','Amended')),
    CONSTRAINT FK_RadiologyReport_Study FOREIGN KEY (StudyID) REFERENCES Radiology_Management.ImagingStudy(StudyID),
    CONSTRAINT FK_RadiologyReport_ReportedBy FOREIGN KEY (ReportedBy) REFERENCES Core_system.Staff(StaffID)
);
-- =============================================
-- SURGERY MANAGEMENT
-- =============================================

CREATE TABLE Surgery_Management.OR_Rooms (
    ORRoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomName NVARCHAR(50) NOT NULL,
    DepartmentID INT NULL,
    Status NVARCHAR(20) CHECK (Status IN ('Available','InUse','Maintenance')),
    CONSTRAINT FK_ORRooms_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID)
);

CREATE TABLE Surgery_Management.Procedures (
    ProcedureID INT IDENTITY(1,1) PRIMARY KEY,
    ProcedureCode NVARCHAR(20) NOT NULL,
    ProcedureName NVARCHAR(100) NOT NULL,
    DefaultDurationMin INT NULL,
    CreatedBy INT,
    CONSTRAINT FK_Procedures_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Users(UserID)
);

CREATE TABLE Surgery_Management.SurgerySchedule (
    SurgeryID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,             
    AdmissionID INT NULL,             
    OPDVisitID INT NULL,              
    ORRoomID INT NOT NULL,
    ScheduledStart DATETIME NOT NULL,
    ScheduledEnd DATETIME NULL,
    AnesthesiaType NVARCHAR(50) NULL,
    PrimarySurgeonID INT NULL,
    CreatedBy INT,
    Status NVARCHAR(20) CHECK (Status IN ('Scheduled','InProgress','Completed','Cancelled')),
    CONSTRAINT FK_OrderID_SurgerySchedule FOREIGN KEY (OrderID) REFERENCES Order_Management.Orders(OrderID),
    CONSTRAINT FK_AdmissionID_SurgerySchedule FOREIGN KEY (AdmissionID) REFERENCES Inpatient_Management.Admissions(AdmissionID),
    CONSTRAINT FK_OPDVisitID_SurgerySchedule FOREIGN KEY (OPDVisitID) REFERENCES Outpatient_Management.OPD_Visit(OPDVisitID),
    CONSTRAINT FK_ORRooms_SurgerySchedule FOREIGN KEY (ORRoomID) REFERENCES Surgery_Management.OR_Rooms(ORRoomID),
    CONSTRAINT FK_SurgerySchedule_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT CK_SurgerySchedule_Times CHECK (ScheduledEnd > ScheduledStart),
    CONSTRAINT CK_SurgerySchedule_Context CHECK (AdmissionID IS NOT NULL OR OPDVisitID IS NOT NULL)
);

CREATE TABLE Surgery_Management.SurgeryTeam (
    SurgeryTeamID INT IDENTITY(1,1) PRIMARY KEY,
    SurgeryID INT NOT NULL,
    StaffID INT NOT NULL,
    RoleInSurgery NVARCHAR(50) CHECK (RoleInSurgery IN ('Surgeon','Assistant','Nurse','Anesthetist','Tech')),
    CONSTRAINT FK_StaffID_SurgeryTeam FOREIGN KEY (StaffID) REFERENCES Core_system.Staff(StaffID), 
    CONSTRAINT FK_SurgeryID_SurgeryTeam FOREIGN KEY (SurgeryID) REFERENCES Surgery_Management.SurgerySchedule(SurgeryID)
);

CREATE TABLE Surgery_Management.SurgeryNotes (
    SurgeryNoteID INT IDENTITY(1,1) PRIMARY KEY,
    SurgeryID INT NOT NULL,
    IntraOpNotes NVARCHAR(MAX) NULL,
    Complications NVARCHAR(MAX) NULL,
    BloodLoss DECIMAL(6,2) NULL,
    ImplantsUsed NVARCHAR(MAX) NULL,
    CONSTRAINT FK_SurgeryID_SurgeryNotes FOREIGN KEY (SurgeryID) REFERENCES Surgery_Management.SurgerySchedule(SurgeryID)
);
-- =============================================
-- Finance Management
-- =============================================

CREATE TABLE Finance_Management.Services (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceCode NVARCHAR(20) UNIQUE NOT NULL,
    ServiceName NVARCHAR(200) NOT NULL,
    ServiceCategory NVARCHAR(50), 
    DepartmentID INT,
    StandardPrice DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2) NULL, 
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Services_Department FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID)
);

CREATE TABLE Finance_Management.Payers (
    PayerID INT IDENTITY(1,1) PRIMARY KEY,
    PayerName NVARCHAR(100) NOT NULL,
    Type NVARCHAR(20) CHECK (Type IN ('Insurance','Cash','Corporate'))
);

CREATE TABLE Finance_Management.InsurancePlans (
    PlanID INT IDENTITY(1,1) PRIMARY KEY,
    PayerID INT NOT NULL,
    PlanName NVARCHAR(100) NOT NULL,
    PlanCode NVARCHAR(50) NULL,
    IsActive BIT DEFAULT 1,
    CONSTRAINT FK_InsurancePlans_Payer FOREIGN KEY (PayerID) REFERENCES Finance_Management.Payers(PayerID)
);

CREATE TABLE Patient_Management.PatientInsurance (
    PatientInsuranceID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT NOT NULL,
    PlanID INT NOT NULL,
    InsuranceNumber NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_PatientInsurance_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_PatientInsurance_Plan FOREIGN KEY (PlanID) REFERENCES Finance_Management.InsurancePlans(PlanID)
);

CREATE TABLE Finance_Management.Invoices (
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNumber NVARCHAR(50) UNIQUE NOT NULL,      
    PatientID INT NOT NULL,
    EncounterID INT NULL,                            
    PayerID INT NULL,                                
    InvoiceDate DATETIME DEFAULT GETDATE(),
    DueDate DATE NULL,                              
    Status NVARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft', 'Posted', 'Partial', 'Paid', 'Cancelled')),
    TotalAmount DECIMAL(10,2) NOT NULL,      
    InsuranceAmount DECIMAL(10,2) NOT NULL,
    DiscountAmount DECIMAL(10,2) DEFAULT 0,         
    PaidAmount DECIMAL(10,2) DEFAULT 0,             
    BalanceAmount DECIMAL(10,2) NOT NULL,            
    CreatedBy INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Invoices_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_Invoices_Encounter FOREIGN KEY (EncounterID) REFERENCES Clinical_Management.Encounters(EncounterID),
    CONSTRAINT FK_Invoices_Payer FOREIGN KEY (PayerID) REFERENCES Finance_Management.Payers(PayerID),
    CONSTRAINT FK_Invoices_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID)
);

CREATE TABLE Finance_Management.InvoiceLines (
    LineID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID INT NOT NULL,
    ServiceID INT NOT NULL,
    OrderID INT NULL,
    Quantity INT DEFAULT 1,
    UnitPrice DECIMAL(10,2) NOT NULL,
    LineAmount DECIMAL(10,2) NOT NULL,
    Description NVARCHAR(200) NULL,
    CONSTRAINT FK_InvoiceLines_Invoice FOREIGN KEY (InvoiceID) REFERENCES Finance_Management.Invoices(InvoiceID),
    CONSTRAINT FK_InvoiceLines_Service FOREIGN KEY (ServiceID) REFERENCES Finance_Management.Services(ServiceID),
    CONSTRAINT FK_InvoiceLines_Order FOREIGN KEY (OrderID) REFERENCES Order_Management.Orders(OrderID)
);

CREATE TABLE Finance_Management.Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceID INT NOT NULL,
    PaymentDate DATETIME DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(20) CHECK (PaymentMethod IN ('Cash','Card','Transfer','Insurance')),
    Amount DECIMAL(10,2) NOT NULL,
    ReferenceNumber NVARCHAR(50) NULL,
    PayerID INT NULL, 
    ReceivedBy INT NOT NULL,
    CONSTRAINT FK_Payments_Invoice FOREIGN KEY (InvoiceID) REFERENCES Finance_Management.Invoices(InvoiceID),
    CONSTRAINT FK_Payments_Payer FOREIGN KEY (PayerID) REFERENCES Finance_Management.Payers(PayerID),
    CONSTRAINT FK_Payments_ReceivedBy FOREIGN KEY (ReceivedBy) REFERENCES Core_system.Staff(StaffID)
);

-- Security
CREATE TABLE Security.Authorizations (
    AuthID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    PlanID INT NOT NULL,
    Approved CHAR(1) CHECK (Approved IN ('Y','N')),
    ApprovedAmount DECIMAL(10,2) NULL,
    CONSTRAINT FK_Authorizations_Order FOREIGN KEY (OrderID) REFERENCES Order_Management.Orders(OrderID),
    CONSTRAINT FK_Authorizations_Plan FOREIGN KEY (PlanID) REFERENCES Finance_Management.InsurancePlans(PlanID)
);

CREATE TABLE Security.AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(50) NOT NULL,
    Operation NVARCHAR(10) NOT NULL,
    RecordID INT NOT NULL,
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    ChangedBy INT,
    ChangedAt DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_AuditLog_ChangedBy FOREIGN KEY (ChangedBy) REFERENCES Core_system.Users(UserID)
);

Create Table SystemErrorCodes(
ErrorCode INT Primary key , 
ErrorMessage Varchar(500) Not Null ,
ErrorCategory varchar(100) , 
Severity int default 16 
);

-- Performance indexes
CREATE INDEX IX_Encounters_PatientID ON Clinical_Management.Encounters(PatientID);
CREATE INDEX IX_Orders_EncounterID ON Order_Management.Orders(EncounterID);
CREATE INDEX IX_Appointments_DateTime ON Scheduling.Appointments(AppointmentDateTime);
CREATE INDEX IX_Patient_MRN ON Patient_Management.Patient(MRN);