--// Modifications
use HIS_V1


--Drop table Core_system.UserRoles;

--GO

--ALTER TABLE Core_system.Users
--ADD RoleID INT NULL;

--GO
--ALTER TABLE Core_system.Users
--ADD CONSTRAINT FK_Users_Role FOREIGN KEY (RoleID) REFERENCES Core_system.Roles(RoleID);


--go

--use HIS_V1

--alter table Patient_Management.Patient 
--add Age as ( 
--	Datediff(YEAR,DateOfBirth,GETDATE()) - 
--	CASE 
--		WHEN(MONTH(DateOfBirth) > MONTH(GETDATE()) OR (MONTH(DateOfBirth) = MONTH(GETDATE()) AND DAY(DateOfBirth) >  Day(GETDATE())))
--		then 1 
--		else 0 
--	END
--)

--go

--CREATE TABLE Scheduling.DoctorsSchedules(
--	ScheduleID int primary key identity(1,1),
--	DoctorID int not null , 
--	DayOfTheWeek TinyInt Null,
--	SpecificDate Date null,
--	StartTime time null ,
--	EndTime time  null ,
--	SlotDuration  int Default 30, 
--	MaxAppointments INT DEFAULT 1,
--	IsRecurring Bit null,
--	EffectiveStart Date not null,
--	EffectiveEnd Date,
--	IsAvalibale BIT Not NULL,
--	CreatedAt datetime default GetDate(),
--	CreatedBy int ,
--	CONSTRAINT FK_Staff_Doctorid FOREIGN KEY (DoctorID) REFERENCES Core_system.Staff(StaffID),

--	CONSTRAINT Check_Time CHECK(EndTime>StartTime),
--	CONSTRAINT Check_Day_week CHECK(DayOfTheWeek >0 and DayOfTheWeek < 8 or DayOfTheWeek IS NULL),
--	CONSTRAINT CHK_DateOrDay CHECK (DayOfTheWeek IS NOT NULL OR SpecificDate IS NOT NULL),
--	CONSTRAINT FK_DoctorsSchedules_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Core_system.Staff(StaffID),

--	)
--	GO
--	ALTER TABLE Scheduling.PhysicianSchedules DROP CONSTRAINT FK_PhysicianSchedules_Staff
--	DROP TABLE Scheduling.PhysicianSchedules
--	GO

ALTER TABLE Scheduling.Appointments
add canelation_Reason nvarchar(100) null;
