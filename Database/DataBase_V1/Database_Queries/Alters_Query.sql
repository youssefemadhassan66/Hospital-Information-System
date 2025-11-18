--// Modifications
use HIS_V1


Drop table Core_system.UserRoles;

GO

ALTER TABLE Core_system.Users
ADD RoleID INT NULL;

GO
ALTER TABLE Core_system.Users
ADD CONSTRAINT FK_Users_Role FOREIGN KEY (RoleID) REFERENCES Core_system.Roles(RoleID);


go

use HIS_V1

alter table Patient_Management.Patient 
add Age as ( 
	Datediff(YEAR,DateOfBirth,GETDATE()) - 
	CASE 
		WHEN(MONTH(DateOfBirth) > MONTH(GETDATE()) OR (MONTH(DateOfBirth) = MONTH(GETDATE()) AND DAY(DateOfBirth) >  Day(GETDATE())))
		then 1 
		else 0 
	END
)

go

CREATE TABLE Scheduling.DoctorsSchedules(
	ScheduleID int primary key identity(1,1),
	DoctorID int not null , 
	DayOfTheWeek TinyInt Null,
	SpecificDate Date null,
	StartTime time null ,
	EndTime time  null ,
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
	GO
	ALTER TABLE Scheduling.PhysicianSchedules DROP CONSTRAINT FK_PhysicianSchedules_Staff
	DROP TABLE Scheduling.PhysicianSchedules
	GO

ALTER TABLE Scheduling.Appointments
add canelation_Reason nvarchar(100) null;

go

use HIS_V1
-- First: Add VisitType to Appointments table
ALTER TABLE Scheduling.Appointments
ADD VisitType NVARCHAR(20) CHECK (VisitType IN (
    'New Patient',
    'Follow-up',
    'Consultation',
    'Procedure',
    'Screening',
    'Annual Checkup',
    'Emergency'
));

-- Add VisitType to Encounters table
ALTER TABLE Clinical_Management.Encounters
ADD VisitType NVARCHAR(20) CHECK (VisitType IN (
    'New Patient',
    'Follow-up',
    'Consultation',
    'Procedure',
    'Screening',
    'Annual Checkup',
    'Emergency'
));


GO 
-- Remove Appointemnt for encounter and add queue to link with encounter and 

use HIS_V1

ALTER TABLE Clinical_Management.Encounters
DROP CONSTRAINT FK_Encounters_Appointment

ALTER TABLE Clinical_Management.Encounters
DROP Column AppointmentId



use HIS_V1


ALTER TABLE Clinical_Management.Encounters
ADD QueueId int

go
use HIS_V1
ALTER TABLE Clinical_Management.EncountersADD CONSTRAINT FK_Queue_Encounters FOREIGN KEY (QueueId)REFERENCES Clinical_Management.PatientQueue(QueueID);

use HIS_V1 
ALTER TABLE Clinical_Management.Encounters
ADD ChiefComplaint NVARCHAR(500)  NULL 
use HIS_V1 
ALTER TABLE Clinical_Management.Prescriptions

ADD CONSTRAINT FK_Prescriptions_Encounter FOREIGN KEY (EncounterId) REFERENCES Clinical_Management.Encounters(EncounterId)

use HIS_V1 
ALTER TABLE Clinical_Management.Prescriptions
ALTER COLUMN MedicationId  INT NULL;


USE HIS_V1
ALTER TABLE Clinical_Management.Prescriptions
ADD MedicationName NVARCHAR(200);


use HIS_V1
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ER_Visit_EncounterID')
    ALTER TABLE Emergency_Management.ER_Visit DROP CONSTRAINT FK_ER_Visit_EncounterID;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TriageAssessment_ERVisit')
    ALTER TABLE Emergency_Management.TriageAssessment DROP CONSTRAINT FK_TriageAssessment_ERVisit;

-- Add new columns to ER_Visit
ALTER TABLE Emergency_Management.ER_Visit 
ADD PatientID INT NOT NULL,
    PhysicianID INT NOT NULL,
    VisitDateTime DATETIME NOT NULL DEFAULT GETDATE(),
    DepartmentID INT NULL;

-- Remove EncounterID column
ALTER TABLE Emergency_Management.ER_Visit DROP COLUMN EncounterID;

-- Add new foreign key constraints for ER_Visit
ALTER TABLE Emergency_Management.ER_Visit 
ADD CONSTRAINT FK_ER_Visit_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_ER_Visit_Physician FOREIGN KEY (PhysicianID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_ER_Visit_Department FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID);

USe HIS_V1
-- Recreate TriageAssessment foreign key
ALTER TABLE Emergency_Management.TriageAssessment 
ADD CONSTRAINT FK_TriageAssessment_ERVisit FOREIGN KEY (ERVisitID) REFERENCES Emergency_Management.ER_Visit(ERVisitID);

USe HIS_V1

-- Drop existing foreign key constraints first
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_EncounterID_OPD_visit')
    ALTER TABLE Outpatient_Management.OPD_Visit DROP CONSTRAINT FK_EncounterID_OPD_visit;

-- Add new columns to OPD_Visit
ALTER TABLE Outpatient_Management.OPD_Visit 
ADD PatientID INT NOT NULL,
    PhysicianID INT NOT NULL,
    VisitDateTime DATETIME NOT NULL DEFAULT GETDATE(),
    DepartmentID INT NULL;

-- Remove EncounterID column
ALTER TABLE Outpatient_Management.OPD_Visit DROP COLUMN EncounterID;

-- Add new foreign key constraints for OPD_Visit
ALTER TABLE Outpatient_Management.OPD_Visit 
ADD CONSTRAINT FK_OPD_Visit_Patient FOREIGN KEY (PatientID) REFERENCES Patient_Management.Patient(PatientID),
    CONSTRAINT FK_OPD_Visit_Physician FOREIGN KEY (PhysicianID) REFERENCES Core_system.Staff(StaffID),
    CONSTRAINT FK_OPD_Visit_Department FOREIGN KEY (DepartmentID) REFERENCES Core_system.Departments(DepartmentID);


 USE HIS_V1
 -- Add default values and constraints for ER_Visit
ALTER TABLE Emergency_Management.ER_Visit 
ADD CONSTRAINT DF_ER_Visit_DateTime DEFAULT GETDATE() FOR VisitDateTime;

ALTER TABLE Emergency_Management.ER_Visit 
ADD CONSTRAINT CK_ER_Visit_DateTime CHECK (VisitDateTime <= GETDATE());

-- Add default values and constraints for OPD_Visit
ALTER TABLE Outpatient_Management.OPD_Visit 
ADD CONSTRAINT DF_OPD_Visit_DateTime DEFAULT GETDATE() FOR VisitDateTime;

ALTER TABLE Outpatient_Management.OPD_Visit 
ADD CONSTRAINT CK_OPD_Visit_DateTime CHECK (VisitDateTime <= GETDATE());