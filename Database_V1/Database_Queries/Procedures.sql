/*

50000-50999: Validation Errors
51000-51999: Business Logic Errors  
52000-52999: Data Access/CRUD Errors
53000-53999: Security/Auth Errors
54000-54999: System/Integration Errors

*/

USE HIS_V1




GO
----------------------------
-- Specilization Procedure
---------------------------

create procedure Add_Specialization @SpeciName varchar(100) , @speciCode Nvarchar(20) , @SpeciDesc Nvarchar(255)
as
Begin
 SET NOCOUNT ON;
 Begin TRY 
		
		SET @speciCode = UPPER(TRIM(@speciCode));
		SET @SpeciName = TRIM(@SpeciName);

		IF @SpeciName IS NUll OR LEN(@SpeciName) < 2 or @speciCode IS NUll OR LEN(@speciCode) < 2
			Throw 50001 , 'Length Error Please eneter a valid Name',1;

		IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationName = @SpeciName)
            THROW 50002, 'DUPLICATE_ERROR: Specialization name already exists', 1;

		IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationCode = @speciCode)
            THROW 50002, 'Specialization code already exists', 1;



		Insert Into Core_system.Specializations(SpecializationName,SpecializationCode,Description) 
		Values(@SpeciName,@speciCode,@SpeciDesc);
		
		Print 'Specliztion Added Successfully';
		
	End Try
	Begin Catch 
		Print 'Error in Spciliztion' + ERROR_Message();
		Throw;	
	End Catch

End
GO

GO
Create Procedure Update_Specialization @SpeciID INT, @SpeciName varchar(100) = null , @speciCode Nvarchar(20) = null  , @SpeciDesc Nvarchar(255) =null

As Begin 
	SET NOCOUNT ON;
	BEGIN TRY
		SET @speciCode = UPPER(TRIM(@speciCode));
		SET @SpeciName = TRIM(@SpeciName);
		
		IF @SpeciID IS Null 
			THrow 50001 , 'Specialization ID Cannot be Null',1;
			
		IF   LEN(@SpeciName)< 2 OR LEN(@speciCode) < 2
			Throw 50001 , 'Length Error Please eneter a valid Name',1;
		IF NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpeciID)
            THROW 50003, 'Specialization ID not found', 1;
		IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationName = @SpeciName AND SpecializationID != @SpeciID)
            THROW 50002, 'DUPLICATE_ERROR: Specialization name already exists', 1;

		IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationCode = @speciCode AND SpecializationID != @SpeciID)
            THROW 50002, 'DUPLICATE_ERROR: Specialization code already exists', 1;

		UPDATE Core_system.Specializations  
		SET SpecializationName = COALESCE(@SpeciName, SpecializationName),
		SpecializationCode = COALESCE(@SpeciCode, SpecializationCode),
		Description = COALESCE(@SpeciDesc, Description)
		Where SpecializationID = @SpeciID

		PRINT 'Specialization updated successfully';

	END TRY
	Begin CATCH
		Print 'Error in Specilization ' + Error_Message();
		Throw;
	END CATCH

END
GO  


GO
Create Procedure Delete_Specialization @SpeciID INT
As Begin 
	SET NOCOUNT ON;
	BEGIN TRANSACTION
BEGIN TRY

	
	IF @SpeciID IS NULL 
		THROW 50001 , 'Specialization ID Can not be Null ',1;

	IF NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpeciID)
		THROW 50001 , 'Specialization ID Does not Exist , Enter a valid ID' , 1;

	IF EXISTS (SELECT 1 FROM Core_system.Staff WHERE SpecializationID = @SpeciID)
		THROW 50003 , 'This Specialization is linked to staff and cannot be deleted',1;

	DELETE FROM Core_system.Specializations WHERE SpecializationID = @SpeciID

COMMIT TRANSACTION;
END TRY



BEGIN CATCH
	IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION;
	Print 'Specilization Error' + Error_Message();
	Throw;
END CATCH


END
GO

CREATE PROCEDURE GetAll_SPECILIZATIONS 
AS BEGIN 
	SELECT * FROM Core_system.Specializations
END 

GO

CREATE PROCEDURE GetByID_SPECILIZATIONS @SPECIID INT  

AS BEGIN 
	BEGIN TRY 
		IF @SPECIID IS NULL 
		 THROW 50001,'Specialization ID Cannot be Null ',1;

		 IF NOT EXISTS(SELECT 1 FROM Core_system.Specializations WHERE @SPECIID = SpecializationID)
			THROW 50002,'THIS  Specialization  ID IS NOT FOUND',1;
		SELECT * FROM Core_system.Specializations WHERE SpecializationID =  @SPECIID  
	END TRY
	BEGIN CATCH 
		PRINT 'SPECILIZATION ERRROR ' + ERROR_MESSAGE();
		THROW;
	END CATCH
END 

GO
CREATE PROCEDURE Search_Specilizations @SearchTerm NVARCHAR(100)
	
	AS BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	IF @SearchTerm IS NOT NULL AND LEN(@SearchTerm) > 100
    THROW 50004, 'Search term too long', 1
	SELECT SpecializationName,SpecializationCode,SpecializationID FROM Core_system.Specializations WHERE  
	(		
			@SearchTerm IS NULL 
             OR SpecializationName LIKE '%' + @SearchTerm + '%'
             OR SpecializationCode LIKE '%' + @SearchTerm + '%'
             OR Description LIKE '%' + @SearchTerm + '%')
			 order by SpecializationName

	END  TRY
	BEGIN CATCH
		PRINT 'SPECILIZATION ERROR ' + ERROR_MESSAGE();
		THROW;
	END CATCH 
	END


GO





----------------------------
-- Users Procedure
---------------------------
GO
Create Procedure Add_User @UserName Varchar(50) , @BrithDate DATETIME,@PasswordHash Nvarchar(250) ,@Email Nvarchar(150),@RoleID INT
As Begin 
	SET NOCOUNT ON;
	Begin Try 

	IF @UserName IS NUll OR @BrithDate IS NULL OR @PasswordHash IS NULL OR @Email IS NULL 
		THROW 50001 , 'ONE OF THE FIELDS HAS A NULL VALUE , PLEASE CHECK AGAIN',1;

    IF DATEDIFF(YEAR, @BrithDate, GETDATE()) < 18 
            THROW 50003, 'USER MUST BE AT LEAST 18 YEARS OLD', 1;

	IF @RoleID IS NULL 
		THROW 50001,'A  User must have a role ',1;

	IF  NOT EXISTS(SELECT 1 FROM  Core_system.Roles WHERE RoleID = @RoleID ) 
		THROW 50003,' RoleId is not found ',1;

	IF @BrithDate > GETDATE()
            THROW 50003, 'Birth date cannot be in the future', 1;
        
	IF EXISTS(SELECT 1 FROM Core_system.Users WHERE @UserName = UserName ) 
		THROW 50002,'THIS USER NAME ALREADY EXISTS',1;

	IF EXISTS(SELECT 1 FROM Core_system.Users WHERE @Email = Email ) 
		THROW 50002,'THIS Email NAME ALREADY EXISTS',1;
	
	 IF @Email NOT LIKE '%_@_%_.__%'
            THROW 50006, 'Invalid email format', 1;

	 IF @UserName LIKE '%[^a-zA-Z0-9_]%'
            THROW 50005, 'Username can only contain letters, numbers, and underscores', 1;

	 Insert INTO Core_system.Users (UserName, BrithDate, PasswordHash, Email, RoleID)
        VALUES(@UserName, @BrithDate, @PasswordHash, @Email, @RoleID);

	End Try
	BEGIN CATCH
	PRINT 'USER ERROR ' + ERROR_MESSAGE();
	THROW;
	END CATCH
END


GO

Go 
Create Procedure Delete_User @User_ID INT
	As Begin 
	Set NOCOUNT ON ;
	BEGIN TRANSACTION
	BEGIN TRY 

	IF @USER_ID IS NULL 
		THROW 50001 , 'UserID is not be Null ',1;

	IF NOT EXISTS(SELECT 1 FROM Core_system.Users WHERE UserID = @User_ID)
		THROW 50002 , 'USER ID IS NOT FOUND ',1;
	
	IF EXISTS(SELECT 1 FROM Core_system.Staff WHERE UserID = @User_ID)
    THROW 50002 , 'CAN NOT DELETE THIS USER , LINKED TO STAFF TABLE',1;
	
	DELETE  FROM Core_system.Users WHERE UserID = @User_ID

	COMMIT TRANSACTION
	END TRY 
	
	BEGIN CATCH
	IF @@TRANCOUNT > 0 
	ROLLBACK TRANSACTION
	PRINT 'USER ERRROR' + ERROR_MESSAGE();
	THROW;
	END CATCH

	END
	GO 

GO
CREATE PROCEDURE  UPDATE_USER @USERID INT ,@UserName Varchar(50) = NULL , @BrithDate DATETIME = NULL ,@Email Nvarchar(150) =NULL,@RoleID int = Null
	AS BEGIN 
	SET NOCOUNT ON; 
	BEGIN TRY
		
		IF @USERID IS NULL 
		THROW 50001 , 'UserID can not be Null ',1;

		
		IF @RoleID IS NULL 
			THROW 50001,'A  User must have a role ',1;

		IF NOT EXISTS(SELECT 1 FROM Core_system.Users WHERE UserID = @USERID)
			THROW 50001 , 'UserID is not found ',1;
		
		UPDATE Core_system.Users 
		SET UserName =  COALESCE(@UserName,UserName),
		BrithDate = COALESCE (@BrithDate,BrithDate),
		Email = COALESCE(Email,@Email),
		RoleID = COALESCE(@RoleID,RoleID)
		where UserID = @USERID;


	END TRY 
	BEGIN CATCH 
	PRINT 'USER ERROR ' + ERROR_MESSAGE();
	THROW;
	END CATCH 
	END

GO


GO


GO

CREATE PROCEDURE Update_LastLoginAt_user @USERID INT
	AS BEGIN
	BEGIN TRY 
		IF @USERID IS NULL 
			THROW 50001,'PLEASE ENTER USER ID ',1;

		UPDATE Core_system.Users SET LastLoginAt = GETDATE() WHERE UserID = @USERID;

	END TRY 
	BEGIN CATCH
	PRINT 'USER ERROR' + ERROR_MESSAGE();
	END CATCH
END

GO

CREATE PROCEDURE Get_USER_ID @USERID INT 

	AS BEGIN
	BEGIN TRY 
		IF @USERID IS NULL 
			THROW 50001,'PLEASE ENTER USER ID ',1;

		SELECT UserName,Email, BrithDate,R.RoleID,R.RoleName,R.Description  FROM Core_system.Users U left join Core_system.Roles R on U.RoleID = R.RoleID  where UserID = @USERID;
	END TRY 
	BEGIN CATCH
	PRINT 'USER ERROR' + ERROR_MESSAGE();
	END CATCH
	END

GO

----------------------------
-- ROLES Procedure
---------------------------

GO

CREATE PROCEDURE Add_Role
@RoleName NVARCHAR(70),
@Description NVARCHAR(255) = NULL,
@Permissions NVARCHAR(MAX) = NULL,
@CreatedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        
        IF @RoleName IS NULL OR LEN(TRIM(@RoleName)) < 2
            THROW 50001, 'Role name must be at least 2 characters', 1;
            
        
        IF EXISTS (SELECT 1 FROM Core_system.Roles WHERE RoleName = @RoleName)
            THROW 50002, 'Role name already exists', 1;
        
        
        INSERT INTO Core_system.Roles (RoleName, Description, Permissions)
        VALUES (@RoleName, @Description, @Permissions);
        
        
        SELECT SCOPE_IDENTITY() AS RoleID, 'Role created successfully' AS Message;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


Create Procedure Update_Role 
@RoleName NVARCHAR(70),
@Description NVARCHAR(255) = NULL,
@Permissions NVARCHAR(MAX) = NULL,
@Role_ID INT
	AS BEGIN 
	SET NOCOUNT ON;
	BEGIN TRY 
	IF @Role_ID IS NULL 
		THROW 50001,'PLEASE PROVIDE A ROLEID',1;
	
	IF NOT EXISTS (SELECT 1 FROM Core_system.Roles WHERE RoleID = @Role_ID)
		THROW 50001 , 'THIS ROLE ID IS NOT FOUND',1;

	IF EXISTS(SELECT 1 FROM Core_system.Roles WHERE RoleID!=@Role_ID AND @RoleName = RoleName)
		THROW 50002,'DUPLICATE ERROR : PLEASE CHANGE THE ROLE NAME',1;

	

	UPDATE Core_system.Roles 
	SET RoleName =  COALESCE(@RoleName,RoleName),
	    Description = COALESCE(@Description,Description),
		Permissions  =  COALESCE(@Permissions,Permissions)
		where RoleID = @Role_ID;

	END TRY
	BEGIN CATCH
		PRINT 'ROLES ERROR' + ERROR_MESSAGE();
		THROW;
	END CATCH 
	END


GO
CREATE PROCEDURE Get_all_ROLES
	AS BEGIN 
	SET NOCOUNT ON 
	BEGIN TRY 

	SELECT RoleID,RoleName,Description,Permissions FROM Core_system.Roles

	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE();
		THROW;
	END CATCH
	END
GO



CREATE PROCEDURE Delete_Role
    @RoleID INT
AS BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @ROLEID IS NULL 
		THROW 50001,'ROLE ID CAN NOT BE NULL ',1;
        
		IF NOT EXISTS (SELECT 1 FROM Core_system.Roles WHERE RoleID = @RoleID)
            THROW 50003, 'Role not found', 1;
            
        
        IF EXISTS (SELECT 1 FROM Core_system.Users WHERE RoleID = @RoleID)
            THROW 50002, 'Cannot delete role - it is assigned to users', 1;
        
        DELETE FROM Core_system.Roles 
        WHERE RoleID = @RoleID;
        
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO



----------------------------
-- UsersRoles Procedure
---------------------------

CREATE PROCEDURE ASSIGN_USER_TO_ROLE @USERID INT , @ROLEID INT
	
AS BEGIN
SET NOCOUNT ON 
	BEGIN TRY
	
	IF @USERID IS NULL OR @ROLEID IS NULL 
		THROW 50001,'USER OR ROLE ID CAN NOT BE NULL ',1;
	IF NOT EXISTS (SELECT 1 FROM Core_system.Users WHERE UserID = @USERID )
		THROW 50003,'USER DOES NOT EXIST ',1;

	IF NOT EXISTS (SELECT 1 FROM Core_system.Roles WHERE RoleID = @ROLEID)
		THROW 50003,'ROLE DOES NOT EXIST',1;

	IF EXISTS (SELECT 1 FROM Core_system.Users WHERE UserID = @USERID AND RoleID = @ROLEID)
            THROW 50004, 'User already has this role assigned', 1;
	
	INSERT INTO Core_system.Users (UserID, RoleID) VALUES (@USERID, @ROLEID)

END TRY
BEGIN CATCH 
	PRINT ERROR_MESSAGE();
    THROW;
END CATCH
END 

GO

CREATE PROCEDURE GetAll_User_Roles
AS BEGIN
	 SET NOCOUNT ON;
	SELECT u.UserID ,u.UserName,u.Email,Age = DATEDIFF(YEAR,BrithDate,GETDATE()),R.RoleName,r.Description FROM Core_system.Users u
	INNER JOIN Core_system.Roles r on u.RoleID = r.RoleID 
	ORDER BY u.UserName, r.RoleName;
END

GO



CREATE PROCEDURE User_GetRolesByUser
    @UserID INT = NULL,
    @UserName NVARCHAR(150) = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    
    IF @UserID IS NULL AND @UserName IS NOT NULL
        SELECT @UserID = UserID FROM Core_system.Users WHERE UserName = @UserName;
    
    SELECT 
        u.UserID,
        u.UserName,
        u.Email,
        s.FullName AS StaffName,
        s.Position,
        u.RoleID, 
        r.RoleName,
        r.Description AS RoleDescription
    FROM Core_system.Users u 
    INNER JOIN Core_system.Roles r ON u.RoleID = r.RoleID 
    LEFT JOIN Core_system.Staff s ON u.UserID = s.UserID
    WHERE (@UserID IS NULL OR u.UserID = @UserID)
    ORDER BY r.RoleName;
END
GO
----------------------------
-- Department Procedure
---------------------------
GO
CREATE PROCEDURE ADD_Department @DepartmentName VARCHAR(50) , @DepartmentCode VARCHAR(20) ,@ManagerID INT,@IsActicve bit
	AS BEGIN 
	SET NOCOUNT ON 
	BEGIN TRY 

	IF @DepartmentCode IS NULL OR @DepartmentName IS NULL OR LEN(TRIM(@DepartmentName)) < 4 
		THROW 50001, 'DEPARTMENT CODE OR NAME CAN NOT BE NULL' , 1;
	IF EXISTS(SELECT 1 FROM Core_system.Departments WHERE DepartmentCode = @DepartmentCode)
		THROW 50002,'DUPLICATE ERROR THIS CODE ALREADY EXISTS ',1;
		
	IF EXISTS(SELECT 1 FROM Core_system.Departments WHERE DepartmentName = @DepartmentName)
		THROW 50002,'DUPLICATE ERROR THIS NAME ALREADY EXISTS ',1;
	
	IF @ManagerID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @ManagerID)
            THROW 50004, 'Manager not found', 1;
	

	
	SET @IsActicve = 1;
	INSERT INTO Core_system.Departments (DepartmentName, DepartmentCode, ManagerID,IsActive)
        VALUES (@DepartmentName, @DepartmentCode, @ManagerID,@IsActicve);

	END TRY
	BEGIN CATCH 
		 PRINT ERROR_MESSAGE();
		THROW;
	END CATCH
END
	
GO

CREATE PROCEDURE Update_Department
    @DepartmentID INT,
    @DepartmentName VARCHAR(50)=NULL,
    @DepartmentCode VARCHAR(20) = NULL,
    @ManagerID INT = NULL,
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
            THROW 50001, 'Department not found', 1;
            
        IF EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentName = @DepartmentName AND DepartmentID != @DepartmentID)
            THROW 50003, 'Department name already exists', 1;
            
        
        IF @DepartmentCode IS NOT NULL AND EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentCode = @DepartmentCode AND DepartmentID != @DepartmentID)
            THROW 50004, 'Department code already exists', 1;
            
        
        IF @ManagerID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @ManagerID)
            THROW 50005, 'Manager not found', 1;
        
        -- Update department
        UPDATE Core_system.Departments 
        SET DepartmentName = COALESCE(@DepartmentName, DepartmentName),
            DepartmentCode = COALESCE(@DepartmentCode, DepartmentCode),
             ManagerID = COALESCE(@ManagerID, ManagerID),
             IsActive = COALESCE(@IsActive, IsActive)
        WHERE DepartmentID = @DepartmentID;
        
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


CREATE PROCEDURE Delete_Department
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
            THROW 50001, 'Department not found', 1;
            
        
        IF EXISTS (SELECT 1 FROM Core_system.Staff WHERE DepartmentID = @DepartmentID)
            THROW 50002, 'Cannot delete department - staff members are assigned to it', 1;
            
        
        IF EXISTS (SELECT 1 FROM Inpatient_Management.Wards WHERE DepartmentID = @DepartmentID)
            THROW 50003, 'Cannot delete department - wards are assigned to it', 1;
        
       
       DELETE FROM Core_system.Departments 
	   WHERE DepartmentID = @DepartmentID
        
       
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

GO 

Create procedure Get_All_Departments 
AS BEGIN 
    SET NOCOUNT ON;
    
    SELECT 
        d.DepartmentID,
        d.DepartmentName,
        d.DepartmentCode,
        d.ManagerID,
        m.FullName AS ManagerName,
        d.CreatedAt,
        d.IsActive,
        StaffCount = (SELECT COUNT(*) FROM Core_system.Staff s WHERE s.DepartmentID = d.DepartmentID AND s.IsActive = 1)
    FROM Core_system.Departments d
    LEFT JOIN Core_system.Staff m ON d.ManagerID = m.StaffID
    ORDER BY d.DepartmentName;
END

GO

CREATE PROCEDURE Get_Department_ByID @DepID INT

AS BEGIN
	BEGIN TRY 
	
	IF @DepID IS NULL 
		THROW 50001 ,'PLEASE ENTER A DEPARTMENT ID ',1;

		SELECT DEP.DepartmentID,DepartmentName,DepartmentCode,ST.FullName,ST.HireDate FROM Core_system.Departments DEP join Core_system.Staff ST ON DEP.ManagerID = ST.StaffID WHERE DEP.DepartmentID = @DepID
	END TRY
	BEGIN CATCH 
		PRINT 'DEPARTMENT ERROR ' + ERROR_MESSAGE();
		THROW;
	END CATCH

END
GO

----------------------------
-- Staff Procedure
---------------------------

Create PROCEDURE Add_Staff 
    @FullName NVARCHAR(120),@Gender VARCHAR(10),@MobileNumber VARCHAR(20) = NULL,@UserID INT,
	@PhoneNumber VARCHAR(20),@Address NVARCHAR(500) = NULL,@DepartmentID INT,@Position NVARCHAR(100),
    @SpecializationID INT = NULL,@LicenseNumber NVARCHAR(50) = NULL,@HireDate DATE,@Salary DECIMAL(10,2),  @IsActive BIT = 1

AS BEGIN 
	SET NOCOUNT  ON ;
	BEGIN TRY 

		IF @FullName IS NULL OR LEN(TRIM(@FullName)) < 6
            THROW 50001, 'Valid full name (min 3 chars) is required', 1;
        
        IF @Position IS NULL OR LEN(TRIM(@Position)) < 2
            THROW 50002, 'Valid position is required', 1;
            
        IF @HireDate IS NULL OR @HireDate > CAST(GETDATE() AS DATE)
            THROW 50003, 'Valid hire date (not future) is required', 1;
        
        IF @Gender NOT IN ('Male', 'Female')
            THROW 50004, 'Gender must be Male or Female', 1;
            
        IF @PhoneNumber IS NULL OR LEN(TRIM(@PhoneNumber)) < 5
            THROW 50005, 'Valid phone number is required', 1;
            
        IF @Salary IS NULL OR @Salary < 0
            THROW 50006, 'Valid salary is required', 1;
        
        IF EXISTS (SELECT 1 FROM Core_system.Staff WHERE UserID = @UserID)
            THROW 50007, 'User already has a staff profile', 1;
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Users WHERE UserID = @UserID)
            THROW 50008, 'User does not exist', 1;
            
        IF @SpecializationID IS NOT NULL 
            AND NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpecializationID)
            THROW 50009, 'Specialization does not exist', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID AND IsActive = 1)
            THROW 50010, 'Department does not exist or is inactive', 1;
        
        IF @PhoneNumber LIKE '%[^0-9+]%' AND @PhoneNumber IS NOT NULL
            THROW 50011, 'Phone number can only contain numbers and +', 1;
            
        IF @MobileNumber LIKE '%[^0-9+]%' AND @MobileNumber IS NOT NULL
            THROW 50012, 'Mobile number can only contain numbers and +', 1;
				
	   INSERT INTO Core_system.Staff (
            FullName, Gender, MobileNumber, Phone, Address, Position, 
            LicenseNumber, HireDate, Salary, IsActive, UserID, SpecializationID, DepartmentID
        )
        VALUES (
            TRIM(@FullName), @Gender, NULLIF(TRIM(@MobileNumber), ''), TRIM(@PhoneNumber), 
            NULLIF(TRIM(@Address), ''), TRIM(@Position), NULLIF(TRIM(@LicenseNumber), ''), 
            @HireDate, @Salary, @IsActive, @UserID, @SpecializationID, @DepartmentID
        );
        
		
	
	
	END TRY 
	BEGIN CATCH
	PRINT 'Staff Error' + Error_Message();
	Throw;
	END CATCH
END

GO

Create procedure Upate_Staff 
    @FullName NVARCHAR(120)=null,@Gender VARCHAR(10)=null,@MobileNumber VARCHAR(20) = NULL,@UserID INT=NULL,@StaffID int,
	@PhoneNumber VARCHAR(20)=NULL,@Address NVARCHAR(500) = NULL,@DepartmentID INT=NULL,@Position NVARCHAR(100)=NULL,
    @SpecializationID INT = NULL,@LicenseNumber NVARCHAR(50) = NULL,@HireDate DATE=NULL,@Salary DECIMAL(10,2)=NULL,  @IsActive BIT = null

	
AS BEGIN 
	SET NOCOUNT  ON ;
	BEGIN TRY 
		
		IF @StaffID IS NULL 
			THROW 50001, 'Valid Staff id can not be null', 1;

		IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @StaffID)
			THROW 50003, 'Valid Staff id can not be null', 1;

		IF LEN(TRIM(@FullName)) < 6 AND LEN(TRIM(@FullName)) > 0
            THROW 50001, 'Valid full name (min 6 chars) is required', 1;
        
        IF  LEN(TRIM(@Position)) < 5 AND LEN(TRIM(@Position)) > 0
            THROW 50002, 'Valid position is required', 1;
            
        IF @HireDate > CAST(GETDATE() AS DATE)
            THROW 50003, 'Valid hire date (not future) is required', 1;
        
        IF @Gender NOT IN ('Male', 'Female')
            THROW 50004, 'Gender must be Male or Female', 1;
            
        IF	LEN(TRIM(@PhoneNumber)) < 5
            THROW 50005, 'Valid phone number is required', 1;
            
        IF	@Salary < 0
            THROW 50006, 'Valid salary is required', 1;
        
        IF EXISTS (SELECT 1 FROM Core_system.Staff WHERE UserID = @UserID AND StaffID != @StaffID)
            THROW 50007, 'User already has a staff profile', 1;
        
        IF @UserID IS NOT NULl AND NOT EXISTS (SELECT 1 FROM Core_system.Users WHERE UserID = @UserID)
            THROW 50008, 'User does not exist', 1;
            
        IF @SpecializationID IS NOT NULL 
            AND NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpecializationID)
            THROW 50009, 'Specialization does not exist', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID AND IsActive = 1)
            THROW 50010, 'Department does not exist or is inactive', 1;
        
        IF @PhoneNumber LIKE '%[^0-9]%' AND @PhoneNumber IS NOT NULL
            THROW 50011, 'Phone number can only contain numbers and +', 1;
            
        IF @MobileNumber LIKE '%[^0-9+]%' AND @MobileNumber IS NOT NULL
            THROW 50012, 'Mobile number can only contain numbers and +', 1;
				
	     UPDATE Core_system.Staff 
        SET FullName = COALESCE(TRIM(@FullName), FullName), 
            Gender = COALESCE(@Gender, Gender),
            MobileNumber = COALESCE(NULLIF(TRIM(@MobileNumber), ''), MobileNumber),
            Phone = COALESCE(TRIM(@PhoneNumber), Phone),
            Address = COALESCE(NULLIF(TRIM(@Address), ''), Address),
            Position = COALESCE(TRIM(@Position), Position),
            LicenseNumber = COALESCE(NULLIF(TRIM(@LicenseNumber), ''), LicenseNumber),
            HireDate = COALESCE(@HireDate, HireDate),
            Salary = COALESCE(@Salary, Salary),
            IsActive = COALESCE(@IsActive, IsActive),
            UserID = COALESCE(@UserID, UserID),
            SpecializationID = COALESCE(@SpecializationID, SpecializationID),
            DepartmentID = COALESCE(@DepartmentID, DepartmentID)
        WHERE StaffID = @StaffID;
		
	
	BEGIN TRANSACTION
	END TRY 
	BEGIN CATCH
	PRINT 'Staff Error' + Error_Message();
	Throw;
	END CATCH
END

GO
CREATE PROCEDURE Delete_Staff @StaffID INT
AS BEGIN
	SET NOCOUNT ON ;
	BEGIN TRY 
	BEGIN TRANSACTION 
		IF @StaffID IS NULL 
			THROW 50001, 'Valid Staff id can not be null', 1;

		IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @StaffID)
			THROW 50003, 'Valid Staff id can not be null', 1;

		DELETE Core_system.Staff 
		WHERE StaffID = @StaffID;

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
	IF @@TRANCOUNT > 0	ROLLBACK TRANSACTION
	THROW;
	END CATCH
END 
GO

CREATE PROCEDURE GetById_Staff @StaffID INT
AS BEGIN
	SET NOCOUNT ON ;
	
	IF @StaffID IS NULL 
			THROW 50001, 'Valid Staff id can not be null', 1;

	IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @StaffID)
			THROW 50003, 'Valid Staff id can not be null', 1;
	



	SELECT 
	s.StaffID,s.FullName , s.Position ,s.Address, s.Phone, s.MobileNumber ,s.Gender,s.Salary , d.DepartmentID,
	d.DepartmentName , us.Email , Age = DATEDIFF(YEAR,us.BrithDate,GETDATE()),Years_of_service = DATEDIFF(YEAR,s.HireDate,GETDATE()),r.RoleName , r.Description,
	Specialization_Name = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN spec.SpecializationName ELSE NULL END,
	LicenseNumber = Case  WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN s.LicenseNumber ELSE NULL END

	from Core_system.Staff s
	LEFT JOIN Core_system.Departments d on s.DepartmentID  = d.DepartmentID
	LEFT  JOIN Core_system.Users us on us.UserID = s.UserID
	LEFT JOIN Core_system.Specializations spec on spec.SpecializationID = s.StaffID
	Left Join Core_system.Roles  r on r.RoleID = us.RoleID

END
GO
CREATE PROCEDURE GetByDepartment_Staff 
    @DepartmentID INT
AS 
BEGIN
    SET NOCOUNT ON;
    
    IF @DepartmentID IS NULL 
        THROW 50001, 'Department ID cannot be null', 1;

    IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
        THROW 50002, 'Department not found', 1;

    SELECT 
        s.StaffID,
        s.FullName, 
        s.Position,
        s.Address, 
        s.Phone, 
        s.MobileNumber,
        s.Gender,
        s.Salary, 
        d.DepartmentID,
        d.DepartmentName, 
        us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, 
        r.Description,
        Specialization_Name = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN spec.SpecializationName ELSE NULL END,
        LicenseNumber = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN s.LicenseNumber ELSE NULL END
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.DepartmentID = @DepartmentID
    AND s.IsActive = 1
    ORDER BY s.FullName;
END
GO

CREATE PROCEDURE GetBySpecialization_Staff 
    @SpecializationID INT
AS 
BEGIN
    SET NOCOUNT ON;
    
    IF @SpecializationID IS NULL 
        THROW 50001, 'Specialization ID cannot be null', 1;

    IF NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpecializationID)
        THROW 50002, 'Specialization not found', 1;

    SELECT 
        s.StaffID,
        s.FullName, 
        s.Position,
        s.Address, 
        s.Phone, 
        s.MobileNumber,
        s.Gender,
        s.Salary, 
        d.DepartmentID,
        d.DepartmentName, 
        us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, 
        r.Description,
        spec.SpecializationName,
        LicenseNumber = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN s.LicenseNumber ELSE NULL END
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.SpecializationID = @SpecializationID
    AND s.IsActive = 1
    ORDER BY s.FullName;
END
GO


CREATE PROCEDURE Search_Staff 
    @SearchTerm NVARCHAR(100) = NULL,
    @DepartmentID INT = NULL,
    @SpecializationID INT = NULL,
    @RoleID INT = NULL,
    @IsActive BIT = 1
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.StaffID,
        s.FullName, 
        s.Position,
        s.Address, 
        s.Phone, 
        s.MobileNumber,
        s.Gender,
        s.Salary, 
        d.DepartmentID,
        d.DepartmentName, 
        us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, 
        r.Description,
        spec.SpecializationName,
        Specialization_Name = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN spec.SpecializationName ELSE NULL END,
        LicenseNumber = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN s.LicenseNumber ELSE NULL END
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.IsActive = @IsActive
    AND (@SearchTerm IS NULL 
         OR s.FullName LIKE '%' + @SearchTerm + '%' 
         OR s.Position LIKE '%' + @SearchTerm + '%'
         OR us.Email LIKE '%' + @SearchTerm + '%'
         OR s.MobileNumber LIKE '%' + @SearchTerm  +'%' )
    AND (@DepartmentID IS NULL OR s.DepartmentID = @DepartmentID)
    AND (@SpecializationID IS NULL OR s.SpecializationID = @SpecializationID)
    AND (@RoleID IS NULL OR us.RoleID = @RoleID)
    ORDER BY s.FullName;
END
GO

CREATE PROCEDURE GetAll_Staff
    @IsActive BIT = 1
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.StaffID,
        s.FullName, 
        s.Position,
        s.Phone, 
        s.MobileNumber,
        s.Gender,
        s.Salary, 
        d.DepartmentID,
        d.DepartmentName, 
        us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName,
        spec.SpecializationName,
        s.IsActive
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.IsActive = @IsActive
    ORDER BY s.FullName;
END
GO

CREATE PROCEDURE GetDoctors_staff
    @DepartmentID INT = NULL,
    @SpecializationID INT = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.StaffID,
        s.FullName, 
        s.Position,
        s.Phone, 
        s.MobileNumber,
        d.DepartmentName, 
        spec.SpecializationName,
        s.LicenseNumber,
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        us.Email
    FROM Core_system.Staff s
    INNER JOIN Core_system.Users us ON us.UserID = s.UserID
    INNER JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    WHERE r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
    AND s.IsActive = 1
    AND (@DepartmentID IS NULL OR s.DepartmentID = @DepartmentID)
    AND (@SpecializationID IS NULL OR s.SpecializationID = @SpecializationID)
    ORDER BY s.FullName;
END
GO  



----------------------------
-- Paitent Procedures
---------------------------
GO
Create procedure Create_Paitent
    @NationalID INT,
    @fristName NVARCHAR(10),
    @secondName NVARCHAR(10),
    @lastName NVARCHAR(10),
    @Gender NVARCHAR(10),
    @phone NVARCHAR(10),
    @Email NVARCHAR(100),
    @DateOfBirth Date,
    @BloodType NVARCHAR(10),
    @MobileNumber NVARCHAR(15),
    @Address NVARCHAR(500),
    @City NVARCHAR(50),                  
    @Country NVARCHAR(50),
    @EmergencyContactName NVARCHAR(100),
    @EmergencyContactPhone NVARCHAR(20),
    @Allergies NVARCHAR(500),
    @MaritalStatus NVARCHAR(20),
    @IsActive BIT
AS BEGIN
    SET NOCOUNT ON
    BEGIN TRY
    BEGIN TRANSACTION

       IF @NationalID IS NULL OR LEN(TRIM(@NationalID)) < 14
            THROW 50001, 'National ID cannot be null or less than 14 characters', 1;
            
        IF @fristName IS NULL OR LEN(TRIM(@fristName)) < 2 
            THROW 50002, 'First name cannot be null or less than 2 characters', 1;
            
        IF @LastName IS NULL OR LEN(TRIM(@LastName)) < 2
            THROW 50003, 'Last name cannot be null or less than 2 characters', 1;
            
        IF @Gender IS NULL
            THROW 50004, 'Gender must be Male, Female, Baby, or Unknown', 1;
            
        IF @phone IS NULL OR LEN(TRIM(@phone)) < 8 
            THROW 50005, 'Phone number cannot be null or less than 8 characters', 1;
            
        IF @Email IS NULL OR LEN(TRIM(@Email)) < 5
            THROW 50006, 'Email cannot be null or less than 5 characters', 1;
            
        IF @DateOfBirth IS NULL  
            THROW 50007, 'Date of birth cannot be null', 1;
 
       IF @BloodType IS NULL 
            THROW 50001, 'Length validtion : Blood Type can not be null',1;

       IF @MobileNumber IS NULL OR LEN(TRIM(@MobileNumber)) < 10
            THROW 50009, 'Mobile number cannot be null or less than 10 characters', 1;
            
        IF @Address IS NULL OR LEN(TRIM(@Address)) < 8 
            THROW 50010, 'Address cannot be null or less than 8 characters', 1;
            
        IF @City IS NULL OR LEN(TRIM(@City)) < 2
            THROW 50011, 'City cannot be null or less than 2 characters', 1;
            
        IF @Country IS NULL OR LEN(TRIM(@Country)) < 2
            THROW 50012, 'Country cannot be null or less than 2 characters', 1;

       IF LEN(@EmergencyContactPhone) < 8
             THROW 50001, 'Length validtion  : EmergencyContactPhone Can not be less than 8  ',1;
       IF LEN(@MaritalStatus) < 5
             THROW 50001, 'Length validtion  : Matrial staus Can not be less than 5  ',1;
       
       IF EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE NationalID = @NationalID)
            THROW 50001, 'National ID already exists',1;
       IF EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE Email = @Email)
            THROW 50001, 'Email already exists',1;
       IF EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE @address = @Address and @city = @City and @country = @Country)
            THROW 50001, 'Address already exists',1;
       -- DATE VALIDATION 
        IF @DateOfBirth > CAST(GETDATE() AS DATE)
           THROW 50015, 'Date of birth cannot be in future', 1;
       
       --Email validation
       IF @Email NOT LIKE '%_@_%_.%'
            THROW 50006, 'Invalid email format', 1;
       --Phone validation 
       IF @phone LIKE '%[^0-9+]%' AND @phone IS NOT NULL
            THROW 50011, 'Phone number can only contain numbers and +', 1;
            
       IF @MobileNumber LIKE '%[^0-9+]%' AND @MobileNumber IS NOT NULL
            THROW 50012, 'Mobile number can only contain numbers and +', 1;

       DECLARE @MRN VARCHAR(20);

        SELECT @MRN = 'MRN' + RIGHT(
            CAST(
                ABS(CHECKSUM(
                    NEWID() * CHECKSUM(CONVERT(VARCHAR(20), GETDATE(), 121)) * CHECKSUM(@@SERVERNAME)
                )) AS BIGINT
            ), 8
        );

          INSERT INTO Patient_Management.Patient (
            MRN, NationalID, FirstName, MiddleName, LastName, DateOfBirth, Gender, 
            BloodType, PhoneNumber, MobileNumber, Email, Address, City, Country,
            EmergencyContactName, EmergencyContactPhone, Allergies, MaritalStatus, 
            IsActive
        )
        VALUES (
            @MRN, @NationalID, TRIM(@fristName), NULLIF(TRIM(@MiddleName), ''), TRIM(@LastName), 
            @DateOfBirth, @Gender, @BloodType, TRIM(@phone), TRIM(@MobileNumber), 
            TRIM(@Email), TRIM(@Address), TRIM(@City), TRIM(@Country),
            NULLIF(TRIM(@EmergencyContactName), ''), TRIM(@EmergencyContactPhone), 
            NULLIF(TRIM(@Allergies), ''), @MaritalStatus, @IsActive
        );
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
            
       PRINT 'Pitent Error' +  ERROR_MESSAGE();
       throw
    END CATCH 
END
GO


GO 
CREATE PROCEDURE Update_Patient 
    @PatientID int,
    @NationalID NVARCHAR(20) = NULL,
    @FirstName NVARCHAR(50) = NULL,
    @MiddleName NVARCHAR(50) = NULL,
    @LastName NVARCHAR(50) = NULL,
    @Gender NVARCHAR(20) = NULL,
    @PhoneNumber NVARCHAR(20) = NULL,
    @Email NVARCHAR(100) = NULL,
    @DateOfBirth DATE = NULL,
    @BloodType NVARCHAR(15) = NULL,
    @MobileNumber NVARCHAR(20) = NULL,
    @Address NVARCHAR(500) = NULL,
    @City NVARCHAR(50) = NULL,                  
    @Country NVARCHAR(50) = NULL,
    @EmergencyContactName NVARCHAR(100) = NULL,
    @EmergencyContactPhone NVARCHAR(20) = NULL,
    @Allergies NVARCHAR(500) = NULL,
    @MaritalStatus NVARCHAR(20) = NULL,
    @IsActive BIT = NULL
    
AS BEGIN
    SET NOCOUNT ON
    BEGIN TRY
    BEGIN TRANSACTION


    IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID)
        THROW 50000, 'Patient not found', 1;

  
    IF @NationalID IS NOT NULL AND LEN(TRIM(@NationalID)) < 14
        THROW 50001, 'National ID must be at least 14 characters', 1;
    
    IF @FirstName IS NOT NULL AND LEN(TRIM(@FirstName)) < 2 
        THROW 50002, 'First name must be at least 2 characters', 1;
    
    IF @LastName IS NOT NULL AND LEN(TRIM(@LastName)) < 2
        THROW 50003, 'Last name must be at least 2 characters', 1;
    
    IF @PhoneNumber IS NOT NULL AND LEN(TRIM(@PhoneNumber)) < 8 
        THROW 50004, 'Phone number must be at least 8 characters', 1;
    
    IF @Email IS NOT NULL AND LEN(TRIM(@Email)) < 5
        THROW 50005, 'Email must be at least 5 characters', 1;

    IF @MobileNumber IS NOT NULL AND LEN(TRIM(@MobileNumber)) < 10
        THROW 50006, 'Mobile number must be at least 10 characters', 1;
    
    IF @Address IS NOT NULL AND LEN(TRIM(@Address)) < 8 
        THROW 50007, 'Address must be at least 8 characters', 1;
    
    IF @City IS NOT NULL AND LEN(TRIM(@City)) < 2
        THROW 50008, 'City must be at least 2 characters', 1;
    
    IF @Country IS NOT NULL AND LEN(TRIM(@Country)) < 2
        THROW 50009, 'Country must be at least 2 characters', 1;

    IF @EmergencyContactPhone IS NOT NULL AND LEN(TRIM(@EmergencyContactPhone)) < 8
        THROW 50010, 'Emergency contact phone must be at least 8 characters', 1;
    
    IF @Email IS NOT NULL AND @Email NOT LIKE '%_@_%_.%'
        THROW 50011, 'Invalid email format', 1;
       
    IF @PhoneNumber IS NOT NULL AND @PhoneNumber LIKE '%[^0-9+]%'
        THROW 50012, 'Phone number can only contain numbers and +', 1;
            
    IF @MobileNumber IS NOT NULL AND @MobileNumber LIKE '%[^0-9+]%'
        THROW 50013, 'Mobile number can only contain numbers and +', 1;
    
    
    IF @NationalID IS NOT NULL AND EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE NationalID = @NationalID AND PatientID != @PatientID)
        THROW 50014, 'National ID already exists', 1;
       
    IF @Email IS NOT NULL AND EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE Email = @Email AND PatientID != @PatientID)
        THROW 50015, 'Email already exists', 1;

    
    UPDATE Patient_Management.Patient 
    SET NationalID = COALESCE(@NationalID, NationalID),
        FirstName = COALESCE(@FirstName, FirstName),
        MiddleName = COALESCE(@MiddleName, MiddleName),
        LastName = COALESCE(@LastName, LastName),
        Gender = COALESCE(@Gender, Gender),
        PhoneNumber = COALESCE(@PhoneNumber, PhoneNumber),
        Email = COALESCE(@Email, Email),
        DateOfBirth = COALESCE(@DateOfBirth, DateOfBirth),
        BloodType = COALESCE(@BloodType, BloodType),
        MobileNumber = COALESCE(@MobileNumber, MobileNumber),
        Address = COALESCE(@Address, Address),
        City = COALESCE(@City, City),
        Country = COALESCE(@Country, Country),
        EmergencyContactName = COALESCE(@EmergencyContactName, EmergencyContactName),
        EmergencyContactPhone = COALESCE(@EmergencyContactPhone, EmergencyContactPhone),
        Allergies = COALESCE(@Allergies, Allergies),
        MaritalStatus = COALESCE(@MaritalStatus, MaritalStatus),
        IsActive = COALESCE(@IsActive, IsActive)
    WHERE PatientID = @PatientID;

    print  'Patient updated successfully';

    COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END
GO



 GO
  CREATE PROCEDURE GetAll_Paitent @ISACTIVE BIT = 1 , @startDate DATETIME = NULL, @EndDate DATETIME =NULL
    AS BEGIN
    SET NOCOUNT ON ;
    BEGIN TRY
        SELECT PatientID, MRN, NationalID, FirstName, MiddleName, LastName, DateOfBirth, Gender,          
            BloodType, PhoneNumber, MobileNumber, Email, Address, City, Country,
            EmergencyContactName, EmergencyContactPhone, Allergies, MaritalStatus,      
            IsActive FROM Patient_Management.Patient 

            WHERE IsActive =  @ISACTIVE AND (@startDate IS NULL OR CreatedAt >= @startDate) AND(@EndDate IS NULL OR CreatedAt <= @EndDate) order by PatientID
    END TRY
    BEGIN CATCH
        PRINT 'ERROR retrieving patients' + ERROR_MESSAGE();
        THROW;
    END CATCH
    END
 GO
  GO

  CREATE PROCEDURE GetbyId_Paitent @PatientID int , @MRN NVARCHAR(50) = null
    AS BEGIN
    SET NOCOUNT ON ;
    BEGIN TRY
        IF @PatientID IS NULL AND @MRN IS NULL 
            THROW 50001,'Please provide MRN or paitentID',1;
        SELECT PatientID, MRN, NationalID, FirstName, MiddleName, LastName, DateOfBirth, Gender, 
            BloodType, PhoneNumber, MobileNumber, Email, Address, City, Country,
            EmergencyContactName, EmergencyContactPhone, Allergies, MaritalStatus,      
            IsActive FROM Patient_Management.Patient 
            WHERE PatientID = @PatientID or MRN = @MRN order by PatientID
    END TRY
    BEGIN CATCH
        PRINT 'ERROR retrieving patients' + ERROR_MESSAGE();
        THROW;
    END CATCH
    END
GO
CREATE PROCEDURE DeleteByID_Patient 
    @PatientID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID)
            THROW 50001, 'Patient not found', 1;

        
        IF EXISTS (SELECT 1 FROM Scheduling.Appointments WHERE PatientID = @PatientID)
            THROW 50002, 'Cannot delete patient with existing appointments', 1;

        IF EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE PatientId = @PatientID)
            THROW 50003, 'Cannot delete patient with clinical encounters', 1;

        IF EXISTS (SELECT 1 FROM Clinical_Management.Prescriptions WHERE PatientId = @PatientID)
            THROW 50004, 'Cannot delete patient with active prescriptions', 1;

        IF EXISTS (SELECT 1 FROM Inpatient_Management.Admissions WHERE PatientId = @PatientID AND Status = 'Active')
            THROW 50005, 'Cannot delete patient who is currently admitted', 1;

        UPDATE Patient_Management.Patient 
        SET IsActive = 0
        WHERE PatientID = @PatientID;

      

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        Print  'Error deleting patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO


CREATE PROCEDURE Search_Patient @searchTerm  nvarchar(60)
    AS BEGIN 
    SET NOCOUNT ON 
    BEGIN TRY


       SELECT * FROM Patient_Management.Patient pat 
       WHERE @searchTerm IS NULL OR 
           (NationalID LIKE '%' + @searchTerm +'%') OR 
           (Email LIKE '%' + @searchTerm +'%') OR 
           (LastName LIKE '%' + @searchTerm +'%') OR
           (FirstName LIKE '%' + @searchTerm +'%') OR
           (MRN LIKE '%' + @searchTerm +'%') OR
           (BloodType LIKE '%' + @searchTerm +'%') OR
           (PhoneNumber LIKE '%' + @searchTerm +'%') OR
           (MobileNumber LIKE '%' + @searchTerm +'%') OR
           (MaritalStatus LIKE '%' + @searchTerm +'%') OR
           (Address LIKE '%' + @searchTerm +'%') OR
           (City LIKE '%' + @searchTerm +'%') OR
           (Country LIKE '%' + @searchTerm +'%') OR
           (Age LIKE '%' + @searchTerm +'%')
       ORDER BY LastName, FirstName;
    

    END TRY
    BEGIN CATCH 
   
            ROLLBACK TRANSACTION
        PRINT 'Serach paitent Error' + ERROR_MESSAGE();
    END CATCH
END


----------------------------
-- Paitent Reports  Procedures
---------------------------
GO
CREATE PROCEDURE Add_PaitentReport @PatientID INT ,@FileSize BIGINT ,@DocumentType NVARCHAR(80),@FilePath NVARCHAR(500),@FileName NVARCHAR(50)
    AS BEGIN
	SET NOCOUNT  ON ;
	BEGIN TRY 

		IF @PatientID IS NULL 
            THROW 50001, 'Valid Patient ID is required', 1;
        
        IF @DocumentType IS NULL OR LEN(TRIM(@DocumentType)) < 2
            THROW 50002, 'Valid position is required', 1;
            
        IF @FilePath IS NULL 
            THROW 50003, 'Valid File Path is required', 1;
        
        IF @FileName IS NULL 
            THROW 50004, 'Valid file name is required', 1;
           
            
        IF @FileSize  <= 0
            THROW 50006, 'Valid Filesize is required', 1;
        
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50007, 'Patient Not found OR NOT ACTIVE ', 1;
  				
	    INSERT INTO Patient_Management.Patient_Reports (
          PatientID, DocumentType, FileName, FileSize, FilePath
        )
        VALUES (
            @PatientID, @DocumentType, @FileName, @FileSize, @FilePath
        );
       	
	
	END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT'Error adding patient report: ' + ERROR_MESSAGE();
        THROW ;
    END CATCH  
    END

GO
GO
CREATE PROCEDURE GetRepByPID_PatientReport
    @PatientID INT,
    @DocumentType NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        pr.ReportID,
        pr.PatientID,
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.MRN,
        pr.DocumentType,
        pr.FileName,
        pr.FileSize,
        -- Format file size for display
        CASE 
            WHEN pr.FileSize < 1024 THEN CAST(pr.FileSize AS NVARCHAR(20)) + ' B'
            WHEN pr.FileSize < 1048576 THEN CAST(ROUND(pr.FileSize/1024.0, 2) AS NVARCHAR(20)) + ' KB'
            ELSE CAST(ROUND(pr.FileSize/1048576.0, 2) AS NVARCHAR(20)) + ' MB'
        END AS FileSizeDisplay,
        pr.FilePath,
        pr.CreatedDate,
        pr.CreatedBy,
        s.FullName AS CreatedByName,
        s.Position AS CreatedByPosition
    FROM Patient_Management.Patient_Reports pr
    INNER JOIN Patient_Management.Patient p ON pr.PatientID = p.PatientID
    INNER JOIN Core_system.Staff s ON pr.CreatedBy = s.StaffID
    WHERE pr.PatientID = @PatientID
    AND (@DocumentType IS NULL OR pr.DocumentType = @DocumentType)
    ORDER BY pr.CreatedDate DESC;
END
GO

GO
CREATE PROCEDURE GetByID_PatientReport
    @ReportID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        pr.ReportID,
        pr.PatientID,
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.MRN,
        pr.DocumentType,
        pr.FileName,
        pr.FileSize,
        pr.FilePath,
        pr.CreatedDate,
        pr.CreatedBy,
        s.FullName AS CreatedByName
    FROM Patient_Management.Patient_Reports pr
    INNER JOIN Patient_Management.Patient p ON pr.PatientID = p.PatientID
    INNER JOIN Core_system.Staff s ON pr.CreatedBy = s.StaffID
    WHERE pr.ReportID = @ReportID;
END
GO

GO

CREATE PROCEDURE Delete_PatientReport
    @ReportID INT,
    @DeletedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient_Reports WHERE ReportID = @ReportID)
            THROW 50001, 'Report not found', 1;

        
        DELETE FROM Patient_Management.Patient_Reports 
        WHERE ReportID = @ReportID;

        SELECT 'Patient report deleted successfully' AS Message;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Error deleting patient report: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END
GO



----------------------------
-- Doctor Schedules Procedures
---------------------------
CREATE PROCEDURE Add_DoctorSchedule 
    @Doc_ID INT,
    @DayofWeek INT = NULL,
    @SpecificDate DATE = NULL, 
    @StartTime TIME,
    @EndTime TIME,
    @SlotDuration INT,
    @MaxAppointments INT,
    @IsRecurring BIT,
    @EffectiveStart DATE,
    @EffectiveEnd DATE = NULL,
    @IsAvailable BIT
AS BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
       
        IF @Doc_ID IS NULL 
            THROW 50001, 'Doctor ID is required', 1;
            
        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            JOIN Core_system.Users us ON s.UserID = us.UserID 
            JOIN Core_system.Roles r ON r.RoleID = us.RoleID  
            WHERE s.StaffID = @Doc_ID  
            AND r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') 
            AND s.IsActive = 1
        )
            THROW 50002, 'Staff member is not an active doctor', 1;
            
        IF @DayofWeek IS NULL AND @SpecificDate IS NULL
            THROW 50003, 'Day of Week or Specific Date is required', 1;
            
        IF @StartTime IS NULL OR @EndTime IS NULL 
            THROW 50004, 'Start time and End time are required', 1;
            
            
        IF @SlotDuration < 15
            THROW 50006, 'Slot cannot be less than 15 minutes', 1;
            
        IF @MaxAppointments < 1
            THROW 50007, 'Max appointments cannot be less than 1', 1;
            
        IF @EffectiveStart IS NULL
            THROW 50008, 'Effective start date is required', 1;
            
        IF @IsAvailable IS NULL
            THROW 50009, 'Is Available is required', 1;

      
        IF EXISTS (
            SELECT 1 FROM Scheduling.DoctorsSchedules 
            WHERE DoctorID = @Doc_ID
            AND (
               
                (@DayofWeek IS NOT NULL AND 
                 @DayofWeek = DayOfTheWeek AND
                 IsRecurring = 1 AND
                 @IsRecurring = 1)
                OR
                
                (@SpecificDate IS NOT NULL AND
                 @SpecificDate = SpecificDate AND
                 IsRecurring = 0 AND
                 @IsRecurring = 0)
            )
            AND (
                (@StartTime < EndTime AND @EndTime > StartTime)
            )
            AND IsAvalibale = 1
            AND @IsAvailable = 1
        )
        THROW 50011, 'Schedule conflict detected - doctor already has schedule at this time', 1;
        
      
        INSERT INTO Scheduling.DoctorsSchedules (
            DoctorID, DayOfTheWeek, SpecificDate, StartTime, EndTime, 
            SlotDuration, MaxAppointments, IsRecurring, EffectiveStart, 
            EffectiveEnd, IsAvalibale
        )
        VALUES (
            @Doc_ID, @DayofWeek, @SpecificDate, @StartTime, @EndTime, 
            @SlotDuration, @MaxAppointments, @IsRecurring, @EffectiveStart, 
            @EffectiveEnd, @IsAvailable
        );
        
        
        SELECT SCOPE_IDENTITY() AS ScheduleID, 'Doctor schedule added successfully' AS Message;
        
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error adding doctor schedule: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END
GO


GO
CREATE PROCEDURE Update_DoctorSchedule 
    @ScheduleID INT,
    @DoctorID INT = NULL,
    @DayOfWeek INT = NULL,
    @SpecificDate DATE = NULL, 
    @StartTime TIME = NULL, 
    @EndTime TIME = NULL, 
    @SlotDuration INT = NULL, 
    @MaxAppointments INT = NULL,
    @IsRecurring BIT = NULL,
    @EffectiveStart DATE = NULL,
    @EffectiveEnd DATE = NULL, 
    @IsAvailable BIT = NULL
AS BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @ScheduleID IS NULL 
            THROW 50001, 'Schedule ID is required', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Scheduling.DoctorsSchedules WHERE ScheduleID = @ScheduleID)
            THROW 50002, 'Schedule not found', 1;
        
        
        IF @DoctorID IS NOT NULL AND NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            JOIN Core_system.Users us ON s.UserID = us.UserID 
            JOIN Core_system.Roles r ON r.RoleID = us.RoleID  
            WHERE s.StaffID = @DoctorID  
            AND r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') 
            AND s.IsActive = 1
        )
            THROW 50003, 'Staff member is not an active doctor', 1;
            
        
        IF @SlotDuration IS NOT NULL AND @SlotDuration < 15
            THROW 50004, 'Slot cannot be less than 15 minutes', 1;
            
        
        IF @MaxAppointments IS NOT NULL AND @MaxAppointments < 1
            THROW 50005, 'Max appointments cannot be less than 1', 1;
            
        
        IF @StartTime IS NOT NULL AND @EndTime IS NOT NULL AND @EndTime <= @StartTime
            THROW 50006, 'End time must be after start time', 1;
            
       
        IF (@DoctorID IS NOT NULL OR @StartTime IS NOT NULL OR @EndTime IS NOT NULL OR 
            @DayOfWeek IS NOT NULL OR @SpecificDate IS NOT NULL)
        BEGIN
            IF EXISTS (
                SELECT 1 FROM Scheduling.DoctorsSchedules 
                WHERE ScheduleID != @ScheduleID
                AND DoctorID = COALESCE(@DoctorID, DoctorID)
                AND (
                    
                    (COALESCE(@DayOfWeek, DayOfTheWeek) IS NOT NULL AND 
                     COALESCE(@DayOfWeek, DayOfTheWeek) = DayOfTheWeek AND
                     IsRecurring = 1)
                    OR
                    
                    (COALESCE(@SpecificDate, SpecificDate) IS NOT NULL AND
                     COALESCE(@SpecificDate, SpecificDate) = SpecificDate AND
                     IsRecurring = 0)
                )
                AND (
                    
                    (COALESCE(@StartTime, StartTime) < COALESCE(@EndTime, EndTime) AND
                     COALESCE(@EndTime, EndTime) > COALESCE(@StartTime, StartTime))
                )
                AND IsAvailable = 1
            )
            THROW 50007, 'Schedule conflict detected', 1;
        END

       
        UPDATE Scheduling.DoctorsSchedules
        SET DoctorID = COALESCE(@DoctorID, DoctorID),
            DayOfTheWeek = COALESCE(@DayOfWeek, DayOfTheWeek),
            SpecificDate = COALESCE(@SpecificDate, SpecificDate),
            StartTime = COALESCE(@StartTime, StartTime),       
            EndTime = COALESCE(@EndTime, EndTime),
            SlotDuration = COALESCE(@SlotDuration, SlotDuration),
            MaxAppointments = COALESCE(@MaxAppointments, MaxAppointments),
            IsRecurring = COALESCE(@IsRecurring, IsRecurring),
            EffectiveStart = COALESCE(@EffectiveStart, EffectiveStart),
            EffectiveEnd = COALESCE(@EffectiveEnd, EffectiveEnd),
            IsAvailable = COALESCE(@IsAvailable, IsAvailable)
        WHERE ScheduleID = @ScheduleID;
        
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error updating doctor schedule: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END
GO


Go 
Create PROCEDURE Delete_DoctorSchedule @SheduleID int , @DoctorId int = NULL
    AS BEGIN
    SET NOCOUNT ON;
        BEGIN TRY 
        BEGIN TRANSACTION
        IF @sheduleID IS NULL 
            THROW 50001,'Validation error please provide shedule id',1;

        IF NOT EXISTS (SELECT 1 FROM  Scheduling.DoctorsSchedules WHERE ScheduleID = @SheduleID)
             THROW 50001,'Validation error please provide shedule id',1;
        
        IF EXISTS (
            SELECT 1 FROM Scheduling.Appointments ap where 
            ap.PhysicianID = (SELECT DoctorID FROM Scheduling.DoctorsSchedules where ScheduleID = @SheduleID)
            AND ap.Status in ('Scheduled', 'Confirmed', 'In Progress') AND AP.AppointmentDateTime >= GETDATE()
        )
            THROW 50004,'Cannot delete schedule with future appointment',1;

        DELETE FROM Scheduling.DoctorsSchedules WHERE ScheduleID = @SheduleID

        COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'ERROR deleting doctor schedule ' + Error_message();
        throw;
        END CATCH
    END
GO



CREATE OR ALTER PROCEDURE GetByID_ScheduleDoctor @DoctorId INT=NULL ,@ScheduleID INT=NULL
AS BEGIN
    IF (@DoctorId IS NULL AND @ScheduleID IS NULL) OR (@DoctorId IS NOT NULL AND @ScheduleID IS NOT NULL)   
        THROW 50001, 'Provide either Doctor ID OR Schedule ID (not both)', 1;
    

    IF @DoctorID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Core_system.Staff WHERE StaffID = @DoctorID AND IsActive = 1
    )
        THROW 50002, 'Doctor not found', 1;
    
    SELECT DS.ScheduleID, DS.DoctorID, DS.DayOfTheWeek, DS.StartTime,
           DS.EndTime, DS.EffectiveStart, DS.EffectiveEnd, DS.IsAvalibale, 
           DS.IsRecurring, DS.MaxAppointments 
    FROM Scheduling.DoctorsSchedules DS 
    WHERE (@DoctorID IS NOT NULL AND DS.DoctorID = @DoctorID)
       OR (@ScheduleID IS NOT NULL AND DS.ScheduleID = @ScheduleID);
END
GO

CREATE PROCEDURE GetAll_ScheduleDoctor @Stratdate datetime = NULL, @EndDate datetime =NULL
AS BEGIN
    
     SELECT DS.ScheduleID,DS.DoctorID,S.FullName,DS.DayOfTheWeek,DS.StartTime,
        DS.EndTime,DS.EffectiveStart,DS.EffectiveEnd,DS.IsAvalibale,DS.IsRecurring,DS.MaxAppointments 
        FROM Scheduling.DoctorsSchedules DS INNER JOIN Core_system.Staff S ON DS.DoctorID = S.StaffID
        WHERE (@Stratdate IS NULL OR DS.EffectiveStart >=@Stratdate) AND (@EndDate IS NULL OR DS.EffectiveEnd < @EndDate) 
        AND IsAvalibale = 1
        ORDER BY 
        S.FullName,
        DS.EffectiveStart,
        DS.DayOfTheWeek,
        DS.StartTime;
END
GO

GO
CREATE OR ALTER PROCEDURE GetAvailableSlots_DoctorSchedule
    @DoctorID INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DayOfWeek TINYINT = DATEPART(WEEKDAY, @Date);
    
    SELECT 
        DS.ScheduleID,
        DS.DoctorID,
        S.FullName AS DoctorName,
        DS.StartTime,
        DS.EndTime,
        DS.SlotDuration,
        DS.MaxAppointments,
        COUNT(A.AppointmentId) AS BookedAppointments,
        DS.MaxAppointments - COUNT(A.AppointmentId) AS AvailableSlots
    FROM Scheduling.DoctorsSchedules DS
    INNER JOIN Core_system.Staff S ON DS.DoctorID = S.StaffID
    LEFT JOIN Scheduling.Appointments A ON A.PhysicianID = DS.DoctorID
        AND CAST(A.AppointmentDateTime AS DATE) = @Date
        AND A.Status IN ('Scheduled', 'Confirmed')
    WHERE DS.DoctorID = @DoctorID
        AND DS.IsAvalibale = 1
        AND @Date BETWEEN DS.EffectiveStart AND ISNULL(DS.EffectiveEnd, '9999-12-31')
        AND (
            (DS.IsRecurring = 1 AND DS.DayOfTheWeek = @DayOfWeek)
            OR (DS.IsRecurring = 0 AND DS.SpecificDate = @Date)
        )
    GROUP BY 
        DS.ScheduleID, DS.DoctorID, S.FullName, 
        DS.StartTime, DS.EndTime, DS.SlotDuration, DS.MaxAppointments
    HAVING COUNT(A.AppointmentId) < DS.MaxAppointments
    ORDER BY DS.StartTime;
END
GO

GO
-- =============================================
-- APPOINTMENT SCHEDULING PROCEDURES
-- =============================================


-- Create Appintment
CREATE OR ALTER PROCEDURE Create_Appointment 
@PatientID INT, @PhysicianID INT , @AppointmentDateTime DATETIME , @DepartmentID INT,
@Status NVARCHAR(20),@Duration INT,@Priority NVARCHAR(30),@Complaint NVARCHAR(30)

    AS BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
    BEGIN TRANSACTION 
        IF @PatientID IS NULL OR @PhysicianID IS NULL OR @AppointmentDateTime IS NULL
            THROW 50001, 'PatientID, PhysicianID, and AppointmentDateTime are required', 1;
            
       
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50002, 'Patient not found or inactive', 1;
            
        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            JOIN Core_system.Users us ON s.UserID = us.UserID 
            JOIN Core_system.Roles r ON r.RoleID = us.RoleID  
            WHERE s.StaffID = @PhysicianID  
            AND r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') 
            AND s.IsActive = 1
        )
            THROW 50003, 'Physician not found or not an active doctor', 1;
       
         IF @AppointmentDateTime <= GETDATE()
            THROW 50004, 'Appointment date must be in the future', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Scheduling.DoctorsSchedules ds
            WHERE ds.DoctorID = @PhysicianID
            AND ds.IsAvalibale = 1
            AND (
                
                (ds.SpecificDate = CAST(@AppointmentDateTime AS DATE) AND ds.IsRecurring = 0)
                OR
             
                (ds.DayOfTheWeek = DATEPART(WEEKDAY, @AppointmentDateTime) AND ds.IsRecurring = 1
                 AND CAST(@AppointmentDateTime AS DATE) BETWEEN ds.EffectiveStart AND ISNULL(ds.EffectiveEnd, '9999-12-31'))
            )
            AND CAST(@AppointmentDateTime AS TIME) >= ds.StartTime
            AND CAST(@AppointmentDateTime AS TIME) < ds.EndTime
        )
            THROW 50005, 'Physician is not available at the requested time', 1;

            IF EXISTS (
                SELECT 1 FROM Scheduling.Appointments 
                where PhysicianID = @PhysicianID AND 
                AppointmentDateTime = @AppointmentDateTime    
                AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
            )
            THROW 50005,'Doctor has appointment at this time',1;
            
            IF EXISTS (
                SELECT 1 FROM Scheduling.Appointments 
                where PatientID = @PatientID AND 
                AppointmentDateTime = @AppointmentDateTime    
                AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
            )
            THROW 50005,'patient has appointment at this time',1;

            INSERT INTO Scheduling.Appointments (
            PatientID, PhysicianID, DepartmentID, AppointmentDateTime,Status,
            Duration, Priority, Complaint
        )
        VALUES (
            @PatientID, @PhysicianID, @DepartmentID, @AppointmentDateTime,@Status,
            @Duration, @Priority, @Complaint
        );

    COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        PRINT 'CREATE APPOINTMENT  ERROR' +ERROR_MESSAGE();
    END CATCH
    END

GO

--Update_Appointment
CREATE PROCEDURE Update_Appointment 
@AppintmentID int,@PatientID INT =NULL, @PhysicianID INT =NULL , @AppointmentDateTime DATETIME , @DepartmentID INT=NULL,
@Status NVARCHAR(20)=NULL,@Duration INT=NULL,@Priority NVARCHAR(30) = NULL,@Complaint NVARCHAR(30) = NULL
   
    AS BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
    BEGIN TRANSACTION 
  
            
       
        IF NOT EXISTS (SELECT 1 FROM Scheduling.Appointments WHERE AppointmentId =@AppintmentID )
            THROW 50002, 'Appoinment is not found or inactive', 1;
            
        IF @PhysicianID IS NOT NULL AND  NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            JOIN Core_system.Users us ON s.UserID = us.UserID 
            JOIN Core_system.Roles r ON r.RoleID = us.RoleID  
            WHERE s.StaffID = @PhysicianID  
            AND r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') 
            AND s.IsActive = 1
        )
            THROW 50003, 'Physician not found or not an active doctor', 1;
       
         IF @AppointmentDateTime IS NOT NULL AND @AppointmentDateTime <= GETDATE()
            THROW 50004, 'Appointment date must be in the future', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Scheduling.DoctorsSchedules ds
            WHERE ds.DoctorID = @PhysicianID
            AND ds.IsAvalibale = 1
            AND (
                
                (ds.SpecificDate = CAST(@AppointmentDateTime AS DATE) AND ds.IsRecurring = 0)
                OR
             
                (ds.DayOfTheWeek = DATEPART(WEEKDAY, @AppointmentDateTime) AND ds.IsRecurring = 1
                 AND CAST(@AppointmentDateTime AS DATE) BETWEEN ds.EffectiveStart AND ISNULL(ds.EffectiveEnd, '9999-12-31'))
            )
            AND CAST(@AppointmentDateTime AS TIME) >= ds.StartTime
            AND CAST(@AppointmentDateTime AS TIME) < ds.EndTime
        )
            THROW 50005, 'Physician is not available at the requested time', 1;

            IF EXISTS (
                SELECT 1 FROM Scheduling.Appointments 
                where PhysicianID = @PhysicianID AND 
                AppointmentDateTime = @AppointmentDateTime    
                AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
            )
            THROW 50005,'Doctor has appointment at this time',1;
            
            IF EXISTS (
                SELECT 1 FROM Scheduling.Appointments 
                where PatientID = @PatientID AND 
                AppointmentDateTime = @AppointmentDateTime    
                AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
            )
            THROW 50005,'patient has appointment at this time',1;
         UPDATE Scheduling.Appointments
            SET 
                AppointmentDateTime = COALESCE(@AppointmentDateTime, AppointmentDateTime),
                Duration = COALESCE(@Duration, Duration),
                Status = COALESCE(@Status, Status),
                Priority = COALESCE(@Priority, Priority),
                Complaint = COALESCE(@Complaint, Complaint),
                PhysicianID = COALESCE(@PhysicianID, PhysicianID)
            WHERE AppointmentID = @AppintmentID;

    COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        PRINT 'CREATE APPOINTMENT  ERROR' +ERROR_MESSAGE();
    END CATCH
    END
GO


--Delete_Appointment
CREATE OR ALTER PROCEDURE Delete_Appointment 
    @AppointmentID INT,
    @CancelledBy INT,
    @CancellationReason NVARCHAR(500) = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        DECLARE @CurrentStatus NVARCHAR(20);
        DECLARE @AppointmentDateTime DATETIME;
        DECLARE @PatientID INT;

       
        SELECT 
            @CurrentStatus = Status,
            @AppointmentDateTime = AppointmentDateTime,
            @PatientID = PatientID
        FROM Scheduling.Appointments 
        WHERE AppointmentID = @AppointmentID;

       
        IF @CurrentStatus IS NULL
            THROW 50001, 'Appointment not found', 1;

    
        IF @CurrentStatus IN ('In Progress', 'Completed')
            THROW 50002, 'Cannot delete appointment that is in progress or completed', 1;

    
        IF DATEDIFF(HOUR, GETDATE(), @AppointmentDateTime) < 2
            THROW 50003, 'Cannot delete appointment within 2 hours of scheduled time', 1;

       
        IF EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue 
            WHERE AppointmentID = @AppointmentID 
            AND Status IN ('Waiting', 'Called', 'InProgress')
        )
            THROW 50004, 'Cannot delete appointment with active queue entry', 1;

    
        UPDATE Scheduling.Appointments
        SET 
            Status = 'Cancelled',
            Complaint = ISNULL(@CancellationReason, 'Appointment cancelled by user')
        WHERE AppointmentID = @AppointmentID;

       
        UPDATE Clinical_Management.PatientQueue
        SET Status = 'Cancelled'
        WHERE AppointmentID = @AppointmentID 
          AND Status IN ('Waiting', 'Called');

        COMMIT TRANSACTION;

        SELECT 
            @AppointmentID AS AppointmentID,
            'Appointment cancelled successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Delete appointment error: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



--Reschedule_Appointment
GO
CREATE OR ALTER PROCEDURE Reschedule_Appointment 
    @AppointmentID INT,
    @NewAppointmentDateTime DATETIME,
    @RescheduledBy INT,
    @Reason NVARCHAR(500) = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        DECLARE @CurrentStatus NVARCHAR(20);
        DECLARE @CurrentDateTime DATETIME;
        DECLARE @PatientID INT;
        DECLARE @PhysicianID INT;
        DECLARE @DepartmentID INT;
        DECLARE @Duration INT;
        DECLARE @Priority NVARCHAR(30);
        DECLARE @Complaint NVARCHAR(500);

    
        SELECT 
            @CurrentStatus = Status,
            @CurrentDateTime = AppointmentDateTime,
            @PatientID = PatientID,
            @PhysicianID = PhysicianID,
            @DepartmentID = DepartmentID,
            @Duration = Duration,
            @Priority = Priority,
            @Complaint = Complaint
        FROM Scheduling.Appointments 
        WHERE AppointmentID = @AppointmentID;

       
        IF @CurrentStatus IS NULL
            THROW 50001, 'Appointment not found', 1;

        
        IF @CurrentStatus IN ('In Progress', 'Completed', 'No Show')
            THROW 50002, 'Cannot reschedule appointment that is in progress, completed, or no show', 1;

                IF @NewAppointmentDateTime <= GETDATE()
            THROW 50003, 'New appointment date must be in the future', 1;

       
        IF NOT EXISTS (
            SELECT 1 
            FROM Scheduling.DoctorsSchedules ds
            WHERE ds.DoctorID = @PhysicianID
            AND ds.IsAvalibale = 1
            AND (
                (ds.SpecificDate = CAST(@NewAppointmentDateTime AS DATE) AND ds.IsRecurring = 0)
                OR
                (ds.DayOfTheWeek = DATEPART(WEEKDAY, @NewAppointmentDateTime) AND ds.IsRecurring = 1
                 AND CAST(@NewAppointmentDateTime AS DATE) BETWEEN ds.EffectiveStart AND ISNULL(ds.EffectiveEnd, '9999-12-31'))
            )
            AND CAST(@NewAppointmentDateTime AS TIME) >= ds.StartTime
            AND CAST(@NewAppointmentDateTime AS TIME) < ds.EndTime
        )
            THROW 50004, 'Physician is not available at the requested time', 1;

       
        IF EXISTS (
            SELECT 1 
            FROM Scheduling.Appointments 
            WHERE PhysicianID = @PhysicianID 
            AND AppointmentDateTime = @NewAppointmentDateTime    
            AND Status IN ('Scheduled', 'Confirmed')
            AND AppointmentID != @AppointmentID  
        )
            THROW 50005, 'Doctor has another appointment at this time', 1;

      
        IF EXISTS (
            SELECT 1 
            FROM Scheduling.Appointments 
            WHERE PatientID = @PatientID 
            AND AppointmentDateTime = @NewAppointmentDateTime    
            AND Status IN ('Scheduled', 'Confirmed')
            AND AppointmentID != @AppointmentID 
        )
            THROW 50006, 'Patient has another appointment at this time', 1;

        
        UPDATE Scheduling.Appointments
        SET 
            AppointmentDateTime = @NewAppointmentDateTime,
            Status = 'Rescheduled',
            Complaint = ISNULL(@Reason, Complaint) + ' (Rescheduled from ' + CONVERT(VARCHAR, @CurrentDateTime, 120) + ')'
        WHERE AppointmentID = @AppointmentID;

     
        UPDATE Clinical_Management.PatientQueue
        SET 
            QueueDate = CAST(@NewAppointmentDateTime AS DATE),
            Status = 'Waiting' 
        WHERE AppointmentID = @AppointmentID 
          AND Status IN ('Waiting', 'Called');

        COMMIT TRANSACTION;

        SELECT 
            @AppointmentID AS AppointmentID,
            @NewAppointmentDateTime AS NewAppointmentDateTime,
            'Appointment rescheduled successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Reschedule appointment error: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

use HIS_V1
go

-- Get Doctor appointement
Create PROCEDURE Get_Appointments_Doctors @DoctorID int ,@Appointment_Date Date 
    AS BEGIN
    SET NOCOUNT ON 
        Select 
           ap.AppointmentId,
            ap.AppointmentDateTime,
            ap.Status,
            ap.Priority,
            ap.Duration,
            ap.Complaint,
            p.PatientID,
            p.FirstName + ' ' + p.LastName AS PatientName,
            p.Gender,
            p.Age,
            p.PhoneNumber,
            p.EMail AS Email,
            st.StaffID AS DoctorID,
            st.FullName AS DoctorName,
            st.Position 
        from Scheduling.Appointments ap 
        join Core_system.staff st 
        on ap.PhysicianID = st.StaffID join Patient_Management.patient p on ap.PatientID = p.PatientID 
        where CAST(ap.AppointmentDateTime AS DATE) = @Appointment_Date  AND (@DoctorID IS NULL OR ap.PhysicianID = @DoctorID)
        order by ap.AppointmentDateTime ASC
    END
GO
--Get_Appointment_Details
CREATE OR ALTER PROCEDURE Get_Appointment_Details
    @AppointmentID INT = NULL,
    @PatientID INT = NULL,
    @PhysicianID INT = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS 
BEGIN 
    SET NOCOUNT ON;


    IF @StartDate IS NULL
        SET @StartDate = CAST(GETDATE() AS DATE);
    IF @EndDate IS NULL
        SET @EndDate = DATEADD(DAY, 30, @StartDate);

    SELECT 
        a.AppointmentID,
        a.PatientID,
        p.FirstName + ' ' + p.LastName AS PatientName,
        a.PhysicianID,
        s.FirstName + ' ' + s.LastName AS PhysicianName,
        d.DepartmentName,
        a.AppointmentDateTime,
        a.Status,
        a.Duration,
        a.Complaint,
        a.Priority,
        a.CreatedAt,
        CASE 
            WHEN a.AppointmentDateTime < GETDATE() AND a.Status IN ('Scheduled', 'Confirmed') THEN 'Missed'
            WHEN a.AppointmentDateTime > GETDATE() THEN 'Upcoming'
            ELSE 'Today'
        END AS AppointmentTiming,
      
        EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue pq 
            WHERE pq.AppointmentID = a.AppointmentID 
            AND pq.QueueDate = CAST(a.AppointmentDateTime AS DATE)
        ) AS HasCheckedIn
    FROM Scheduling.Appointments a
    INNER JOIN Patient_Management.Patient p ON a.PatientID = p.PatientID
    INNER JOIN Core_system.Staff s ON a.PhysicianID = s.StaffID
    INNER JOIN Clinical_Management.Departments d ON a.DepartmentID = d.DepartmentID
    WHERE (@AppointmentID IS NULL OR a.AppointmentID = @AppointmentID)
      AND (@PatientID IS NULL OR a.PatientID = @PatientID)
      AND (@PhysicianID IS NULL OR a.PhysicianID = @PhysicianID)
      AND CAST(a.AppointmentDateTime AS DATE) BETWEEN @StartDate AND @EndDate
    ORDER BY a.AppointmentDateTime ASC;
END;
GO

-- =============================================
-- Patient Queue PROCEDURES
-- =============================================
CREATE PROCEDURE CheckInPatientToQueue
    @PatientID INT,
    @DoctorID INT,
    @DepartmentID INT,
    @AppointmentID INT = NULL,
    @Priority NVARCHAR(20) = 'Normal',
    @ArrivalMethod NVARCHAR(20) = 'Walk-in',
    @ChiefComplaint NVARCHAR(500) = NULL,
    @CheckInCounter NVARCHAR(20) = NULL,
    @CheckInByStaffID INT, 
    @QueueID INT OUTPUT,
    @QueueNumber NVARCHAR(20) OUTPUT,
    @CurrentPosition INT OUTPUT
AS 
BEGIN
    DECLARE @QueueDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @QueuePrefix NVARCHAR(5);
    DECLARE @NextSequence INT;
    DECLARE @EstimatedWait INT;
    DECLARE @MaxPatients INT;
    DECLARE @CurrentCount INT;
    DECLARE @AvgConsultTime INT;
    DECLARE @PatientsAhead INT;

    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        
        IF @PatientID IS NULL OR @DoctorID IS NULL OR @DepartmentID IS NULL
            THROW 50001, 'PatientID, DoctorID, and DepartmentID are required', 1;
        
        IF @CheckInByStaffID IS NULL
            THROW 50001, 'CheckInByStaffID and CreatedByUserID are required', 1;
    
       
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientId = @PatientID)
            THROW 50002, 'Patient not found or inactive', 1;
            
        
        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffID = @DoctorID  
            AND s.IsActive = 1
            AND u.RoleID IN (SELECT RoleID FROM Core_system.Roles WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident'))
        )
            THROW 50003, 'Doctor not found or not an active medical staff', 1;
     
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
            THROW 50004, 'Department not found', 1;

        -- Check if patient is already in queue
        IF EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue
            WHERE PatientID = @PatientID
              AND QueueDate = @QueueDate
              AND Status IN ('Waiting', 'Called', 'InProgress')
        )
            THROW 50007, 'Patient is already in queue today', 1;

     
        --SELECT 
        --    @QueuePrefix = QueuePrefix,
        --    @MaxPatients = MaxPatientsPerDay,
        --    @AvgConsultTime = AverageConsultationTime
        --FROM Clinical_Management.QueueConfiguration
        --WHERE DepartmentID = @DepartmentID 
        --  AND IsActive = 1;
        
        -- Set default queue prefix if not configured
        IF @QueuePrefix IS NULL
        BEGIN
            SELECT @QueuePrefix = UPPER(LEFT(st.FullName, 1))
            FROM Core_system.Staff st
            WHERE StaffID = @DoctorID;
            
            SET @AvgConsultTime = 15; 
        END
        
        
        IF @MaxPatients IS NOT NULL
        BEGIN
            SELECT @CurrentCount = COUNT(*)
            FROM Clinical_Management.PatientQueue
            WHERE DoctorID = @DoctorID
              AND QueueDate = @QueueDate
              AND Status NOT IN ('Cancelled', 'NoShow', 'Completed');
            
            IF @CurrentCount >= @MaxPatients
                THROW 50008, 'Doctor has reached maximum patient capacity for today', 1;
        END

        
        SELECT @NextSequence = ISNULL(MAX(SequenceNumber), 0) + 1
        FROM Clinical_Management.PatientQueue
        WHERE DoctorID = @DoctorID
          AND QueueDate = @QueueDate;

      
        SELECT @PatientsAhead = COUNT(*)
        FROM Clinical_Management.PatientQueue
        WHERE DoctorID = @DoctorID
          AND QueueDate = @QueueDate
          AND Status = 'Waiting'
          AND SequenceNumber < @NextSequence;

        SET @CurrentPosition = @PatientsAhead + 1;

       
        SET @QueueNumber = @QueuePrefix + FORMAT(@NextSequence, '000') + '-' + FORMAT(CAST(RIGHT(CAST(NEWID() AS NVARCHAR(36)), 3) AS INT), '000');


        SET @EstimatedWait = @PatientsAhead * ISNULL(@AvgConsultTime, 20);
        
       
        INSERT INTO Clinical_Management.PatientQueue (
            PatientID, 
            DoctorID,
            AppointmentID, 
            DepartmentID,
            QueueNumber, 
            QueueDate, 
            Status, 
            ArrivalMethod,
            Priority,
            SequenceNumber,
            CurrentPosition, 
            WatingTime,
            CheckInBy,
            CheckInTime
        )
        VALUES (
            @PatientID, 
            @DoctorID,
            @AppointmentID, 
            @DepartmentID,
            @QueueNumber, 
            @QueueDate, 
            'Waiting', 
            @ArrivalMethod,
            @Priority,
            @NextSequence,
            @CurrentPosition, 
            @EstimatedWait,
            @CheckInCounter,
            GETDATE()
        );

        -- Set output parameters
        SET @QueueID = SCOPE_IDENTITY();
        SET @CurrentPosition = @PatientsAhead + 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Patient Checkin error: ' + ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;

GO



CREATE OR ALTER PROCEDURE UpdateQueuePositions
    @DoctorID INT,
    @QueueDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @QueueDate IS NULL
        SET @QueueDate = CAST(GETDATE() AS DATE);
    
    -- Reset positions for non-waiting patients
    UPDATE Clinical_Management.PatientQueue
    SET CurrentPosition = NULL
    WHERE DoctorID = @DoctorID
      AND QueueDate = @QueueDate
      AND Status IN ('Called', 'InProgress', 'Completed', 'Cancelled', 'NoShow', 'Transferred');
    
    -- Recalculate positions for waiting patients (ONLY by check-in time - FCFS)
    WITH RankedQueue AS (
        SELECT 
            QueueID,
            ROW_NUMBER() OVER (
                ORDER BY CheckInTime ASC  
            ) AS NewPosition
        FROM Clinical_Management.PatientQueue
        WHERE DoctorID = @DoctorID
          AND QueueDate = @QueueDate
          AND Status = 'Waiting'
    )
    UPDATE pq
    SET CurrentPosition = rq.NewPosition
    FROM Clinical_Management.PatientQueue pq
    INNER JOIN RankedQueue rq ON pq.QueueID = rq.QueueID;
    
   
    SELECT 
        QueueID,
        QueueNumber,
        CurrentPosition,
        Priority,
        Status,
        CheckInTime,
        DATEDIFF(MINUTE, CheckInTime, GETDATE()) AS WaitingMinutes
    FROM Clinical_Management.PatientQueue
    WHERE DoctorID = @DoctorID
      AND QueueDate = @QueueDate
    ORDER BY 
        CASE Status
            WHEN 'InProgress' THEN 1
            WHEN 'Called' THEN 2
            WHEN 'Waiting' THEN 3
            ELSE 4
        END,
        CheckInTime ASC;  
END;
GO
GO


-- PROCEDURE 3: Call Next Patient

CREATE OR ALTER PROCEDURE CallNextPatientQueue
    @DoctorID INT,
    @CalledByStaffID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
         DECLARE @QueueDate DATE = CAST(GETDATE() AS DATE);
        DECLARE @QueueID INT;
        DECLARE @QueueNumber NVARCHAR(20);
        DECLARE @PatientName NVARCHAR(100);
        DECLARE @PatientID INT;


        IF @DoctorID IS NULL OR @CalledByStaffID IS NULL
            THROW 50001, 'DoctorID and CalledByStaffID are required', 1;
        

        SELECT TOP 1 
            @QueueID = QueueID,
            @QueueNumber = QueueNumber,
            @PatientID = PatientId
        FROM Clinical_Management.PatientQueue
        WHERE DoctorID = @DoctorID
          AND QueueDate = @QueueDate
          AND Status = 'Waiting'
        ORDER BY 
            CheckInTime ASC;
        

        IF @QueueID IS NULL
        BEGIN
            SELECT 
                0 AS QueueID, 
                NULL AS QueueNumber, 
                'No patients in queue' AS Message,
                0 AS PatientsWaiting;
            
            COMMIT TRANSACTION;
            RETURN;
        END

        SELECT @PatientName = FirstName + ' ' + LastName
        FROM Patient_Management.Patient
        WHERE PatientId = @PatientID;

        UPDATE Clinical_Management.PatientQueue
        SET Status = 'Called',
            CalledTime = GETDATE()
        WHERE QueueID = @QueueID;
        

        
     
        EXEC UpdateQueuePositions @DoctorID, @QueueDate;
        
        COMMIT TRANSACTION;


          SELECT 
            @QueueID AS QueueID,
            @QueueNumber AS QueueNumber,
            @PatientID AS PatientID,
            @PatientName AS PatientName,
            'Patient called successfully' AS Message,
            (SELECT COUNT(*) 
             FROM Clinical_Management.PatientQueue 
             WHERE DoctorID = @DoctorID 
               AND QueueDate = @QueueDate 
               AND Status = 'Waiting') AS PatientsRemaining;

        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO


-- Get DoctorQueue 

CREATE OR ALTER PROCEDURE GetDoctorQueue 
    @DoctorId INT,
    @GetDate DATE = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @GetDate IS NULL
            SET @GetDate = CAST(GETDATE() AS DATE);
        

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @DoctorId AND IsActive = 1)
        BEGIN
            SELECT 'Doctor not found or inactive' AS Message;
            RETURN;
        END

        SELECT   
            pq.QueueID,
            pq.QueueNumber,
            pq.PatientID,
            p.FirstName + ' ' + p.LastName AS PatientName,
            pq.CurrentPosition,
            pq.Priority,
            pq.Status,
            pq.CheckInTime,
            pq.CalledTime,
            pq.ConsultationStartTime,
            DATEDIFF(MINUTE, pq.CheckInTime, GETDATE()) AS WaitingMinutes,
            pq.WatingTime,
            pq.ArrivalMethod
        FROM Clinical_Management.PatientQueue pq
        INNER JOIN Patient_Management.Patient p ON pq.PatientID = p.PatientId
        WHERE pq.DoctorId = @DoctorId 
          AND pq.QueueDate = @GetDate 
        ORDER BY 
            CASE pq.Status
                WHEN 'InProgress' THEN 1
                WHEN 'Called' THEN 2
                WHEN 'Waiting' THEN 3
                ELSE 4
            END,
            pq.CheckInTime ASC;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Error retrieving doctor queue: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE CancelQueueEntry
    @QueueID INT,
    @StaffID INT,
    @Reason NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DoctorID INT, @QueueDate DATE, @AppointmentID INT;

        -- Get queue details
        SELECT 
            @DoctorID = DoctorID,
            @QueueDate = QueueDate,
            @AppointmentID = AppointmentID
        FROM Clinical_Management.PatientQueue
        WHERE QueueID = @QueueID;

        IF @DoctorID IS NULL
            THROW 50001, 'Queue entry not found', 1;

        -- Update queue status
        UPDATE Clinical_Management.PatientQueue
        SET Status = 'Cancelled'
        WHERE QueueID = @QueueID;

        -- Update appointment if exists
        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'Cancelled'
            WHERE AppointmentId = @AppointmentID;
        END

        -- Update positions
        EXEC UpdateQueuePositions @DoctorID, @QueueDate;

        COMMIT TRANSACTION;

        SELECT 'Queue entry cancelled successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE MarkPatientNoShow
    @QueueID INT,
    @StaffID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DoctorID INT, @QueueDate DATE, @AppointmentID INT;

        SELECT 
            @DoctorID = DoctorID,
            @QueueDate = QueueDate,
            @AppointmentID = AppointmentID
        FROM Clinical_Management.PatientQueue
        WHERE QueueID = @QueueID;

        IF @DoctorID IS NULL
            THROW 50001, 'Queue entry not found', 1;

        -- Update queue status
        UPDATE Clinical_Management.PatientQueue
        SET Status = 'NoShow'
        WHERE QueueID = @QueueID;

        -- Update appointment if exists
        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'No Show'
            WHERE AppointmentId = @AppointmentID;
        END

        -- Update positions
        EXEC UpdateQueuePositions @DoctorID, @QueueDate;

        COMMIT TRANSACTION;

        SELECT 'Patient marked as No Show' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO



-- =============================================
-- Encounter PROCEDURES
-- =============================================



--Start Consulation

CREATE OR ALTER PROCEDURE StartConsultation
    @QueueID INT,
    @StaffID INT,
    @ChiefComplaint NVARCHAR(500) = NULL,
    @EstimatedDuration INT = 30,
    @EncounterID INT OUTPUT,
    @VisitType NVARCHAR(20) = NULL 
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Variables
        DECLARE @PatientID INT;
        DECLARE @DoctorID INT;
        DECLARE @AppointmentID INT;
        DECLARE @DepartmentID INT;
        DECLARE @EncounterNumber NVARCHAR(20);
        DECLARE @QueueDate DATE;
        DECLARE @StartTime DATETIME2 = GETDATE();
        DECLARE @EndTime DATETIME2;
        
        
        -- VALIDATION
        IF @QueueID IS NULL OR @StaffID IS NULL
            THROW 50001, 'QueueID and StaffID are required', 1;
        
        -- Check if queue entry exists and is in valid status
        IF NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue 
            WHERE QueueID = @QueueID 
            AND Status IN ('Waiting', 'Called')
        )
            THROW 50002, 'Queue entry not found or not in valid status for consultation', 1;
        
        -- Check if doctor already has a patient in consultation
        IF EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue 
            WHERE DoctorID = (SELECT DoctorID FROM Clinical_Management.PatientQueue WHERE QueueID = @QueueID)
            AND Status = 'InProgress'
            AND QueueID != @QueueID
        )
            THROW 50003, 'Doctor already has a patient in consultation', 1;
        
        -- GET QUEUE DETAILS
        SELECT 
            @PatientID = PatientID,
            @DoctorID = DoctorID,
            @AppointmentID = AppointmentID,
            @DepartmentID = DepartmentID,
            @QueueDate = QueueDate
        FROM Clinical_Management.PatientQueue
        WHERE QueueID = @QueueID;
        
        -- GET VISIT TYPE (from appointment or default)
        IF @AppointmentID IS NOT NULL
        BEGIN
            SELECT @VisitType = VisitType
            FROM Scheduling.Appointments
            WHERE AppointmentId = @AppointmentID;
        END
        
        IF @VisitType IS NULL
            SET @VisitType = 'Follow-up';
        
  
        IF @ChiefComplaint IS NULL AND @AppointmentID IS NOT NULL
        BEGIN
            SELECT @ChiefComplaint = Complaint
            FROM Scheduling.Appointments
            WHERE AppointmentId = @AppointmentID;
        END
        
      
        -- CALCULATE END TIME
      
        SET @EndTime = DATEADD(MINUTE, @EstimatedDuration, @StartTime);
        
      
        -- GENERATE ENCOUNTER NUMBER
      
        DECLARE @DatePart NVARCHAR(8) = FORMAT(GETDATE(), 'yyyyMMdd');
        DECLARE @SequencePart INT;
        
        SELECT @SequencePart = ISNULL(MAX(
            CAST(RIGHT(EncounterNumber, 5) AS INT)
        ), 0) + 1
        FROM Clinical_Management.Encounters
        WHERE EncounterNumber LIKE 'ENC' + @DatePart + '%';
        
        SET @EncounterNumber = 'ENC' + @DatePart + RIGHT('00000' + CAST(@SequencePart AS VARCHAR), 5);
     
        -- CREATE ENCOUNTER
 
        INSERT INTO Clinical_Management.Encounters (
            EncounterNumber, 
            PatientId, 
            PhysicianID, 
            QueueID,
            EncounterDate, 
            EncounterType, 
            VisitType,
            ReviewOfSystems,
            StartDateTime, 
            EndDateTime, 
            Status, 
            CreatedBy,
            CreatedAt
        )
        VALUES (
            @EncounterNumber, 
            @PatientID, 
            @DoctorID, 
            @QueueID,
            @StartTime,
            'Outpatient',
            @VisitType,
            @ChiefComplaint,
            @StartTime,
            @EndTime,
            'Active', 
            @StaffID,
            @StartTime
        );
        
        SET @EncounterID = SCOPE_IDENTITY();
        
       
        -- UPDATE QUEUE STATUS
      
        UPDATE Clinical_Management.PatientQueue
        SET Status = 'InProgress',
            ConsultationStartTime = @StartTime
        WHERE QueueID = @QueueID;
        
    
        -- UPDATE APPOINTMENT STATUS
      
        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'In Progress'
            WHERE AppointmentId = @AppointmentID;
        END
        
     
        -- CREATE OPD VISIT RECORD 
     
        IF OBJECT_ID('Outpatient_Management.OPD_Visit') IS NOT NULL
        BEGIN
            INSERT INTO Outpatient_Management.OPD_Visit (
                EncounterID, 
                AppointmentID,
                VisitReason, 
                VisitStatus
            )
            VALUES (
                @EncounterID, 
                @AppointmentID,
                @ChiefComplaint, 
                'In Progress'
            );
        END
        
         -- UPDATE POSITIONS FOR REMAINING PATIENTS
   
        EXEC UpdateQueuePositions @DoctorID, @QueueDate;
        
        COMMIT TRANSACTION;
        
      
        -- RETURN SUCCESS WITH DETAILS
     
        SELECT 
            @EncounterID AS EncounterID,
            @EncounterNumber AS EncounterNumber,
            'Consultation started successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO



CREATE OR ALTER PROCEDURE CompleteConsultation
    @QueueID INT,
    @EncounterID INT,
    @StaffID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @DoctorID INT;
        DECLARE @QueueDate DATE;
        DECLARE @AppointmentID INT;
        DECLARE @CurrentQueueStatus NVARCHAR(30);
        DECLARE @CurrentEncounterStatus NVARCHAR(20);
        

        IF @QueueID IS NULL OR @EncounterID IS NULL OR @StaffID IS NULL
            THROW 50001, 'QueueID, EncounterID, and StaffID are required', 1;
        
       
        SELECT 
            @DoctorID = DoctorID,
            @QueueDate = QueueDate,
            @AppointmentID = AppointmentID,
            @CurrentQueueStatus = Status
        FROM Clinical_Management.PatientQueue
        WHERE QueueID = @QueueID;
        
        IF @DoctorID IS NULL
            THROW 50002, 'Queue entry not found', 1;
            
  
        IF @CurrentQueueStatus != 'InProgress'
            THROW 50003, 'Cannot complete consultation that is not in progress', 1;
        

        SELECT @CurrentEncounterStatus = Status
        FROM Clinical_Management.Encounters
        WHERE EncounterId = @EncounterID;
        
        IF @CurrentEncounterStatus IS NULL
            THROW 50004, 'Encounter not found', 1;
            
        IF @CurrentEncounterStatus != 'Active'
            THROW 50005, 'Cannot complete encounter that is not active', 1;
        
  
  
        UPDATE Clinical_Management.PatientQueue
        SET Status = 'Completed',
            ConsultationEndTime = GETDATE()
        WHERE QueueID = @QueueID;
        

     
    
        UPDATE Clinical_Management.Encounters
        SET Status = 'Completed',
            EndDateTime = GETDATE()
        WHERE EncounterId = @EncounterID;
        



    
        BEGIN
            UPDATE Outpatient_Management.OPD_Visit
            SET VisitStatus = 'Completed'
            WHERE EncounterID = @EncounterID;
        END
        
  
 
   
        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'Completed'
            WHERE AppointmentId = @AppointmentID;
        END
        

     

        EXEC UpdateQueuePositions @DoctorID, @QueueDate;
        
        COMMIT TRANSACTION;
        

        

        SELECT 
            @QueueID AS QueueID,
            @EncounterID AS EncounterID,
            'Consultation completed successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- =============================================
-- Clinical_Management.VitalSigns PROCEDURES
-- =============================================

CREATE OR ALTER PROCEDURE Clinical_Management.CreateVitalSigns
    @EncounterId INT,
    @Temperature DECIMAL(4,2) = NULL,
    @BloodPressure NVARCHAR(20) = NULL,
    @HeartRate INT = NULL,
    @RespiratoryRate INT = NULL,
    @OxygenSaturation DECIMAL(5,2) = NULL,
    @Height DECIMAL(5,2) = NULL,
    @Weight DECIMAL(5,2) = NULL,
    @BloodGlucose DECIMAL(5,2) = NULL,
    @PainScore INT = NULL,
    @Notes NVARCHAR(500) = NULL,
    @RecordedBy INT,
    @VitalSignId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;


        IF @EncounterId IS NULL OR @RecordedBy IS NULL
            THROW 50001, 'EncounterId and RecordedBy are required', 1;

    
        IF NOT EXISTS (
            SELECT 1 FROM Clinical_Management.Encounters 
            WHERE EncounterId = @EncounterId AND Status = 'Active'
        )
            THROW 50002, 'Active encounter not found', 1;

        -- Validate staff exists
        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffId = @RecordedBy AND IsActive = 1)
            THROW 50003, 'Recording staff not found or inactive', 1;


        IF @RespiratoryRate IS NOT NULL AND (@RespiratoryRate < 6 OR @RespiratoryRate > 60)
            THROW 50006, 'Respiratory rate must be between 6 and 60 breaths/min', 1;

        IF @OxygenSaturation IS NOT NULL AND (@OxygenSaturation < 70 OR @OxygenSaturation > 100)
            THROW 50007, 'Oxygen saturation must be between 70% and 100%', 1;

        IF @PainScore IS NOT NULL AND (@PainScore < 0 OR @PainScore > 10)
            THROW 50008, 'Pain score must be between 0 and 10', 1;

        -- Insert vital signs
        INSERT INTO Clinical_Management.VitalSigns (
            EncounterId,
            Temperature,
            BloodPressure,
            HeartRate,
            RespiratoryRate,
            OxygenSaturation,
            Height,
            Weight,
            BloodGlucose,
            PainScore,
            Notes,
            RecordedBy
        )
        VALUES (
            @EncounterId,
            @Temperature,
            @BloodPressure,
            @HeartRate,
            @RespiratoryRate,
            @OxygenSaturation,
            @Height,
            @Weight,
            @BloodGlucose,
            @PainScore,
            @Notes,
            @RecordedBy
        );

        SET @VitalSignId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT 
            @VitalSignId AS VitalSignId,
            'Vital signs recorded successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Error creating vital signs: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE GetVitalSignsByEncounter
    @EncounterId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate encounter exists
    IF NOT EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE EncounterId = @EncounterId)
    BEGIN
        SELECT 'Encounter not found' AS Message;
        RETURN;
    END

    SELECT 
        vs.VitalSignId,
        vs.EncounterId,
        vs.Temperature,
        vs.BloodPressure,
        vs.HeartRate,
        vs.RespiratoryRate,
        vs.OxygenSaturation,
        vs.Height,
        vs.Weight,
        vs.BMI,
        vs.BloodGlucose,
        vs.PainScore,
        vs.Notes,
        vs.RecordedAt,
        vs.RecordedBy,
        s.FullName AS RecordedByName,
        -- Categorize vital signs
        CASE 
            WHEN vs.Temperature < 36 THEN 'Low'
            WHEN vs.Temperature > 37.5 THEN 'High'
            ELSE 'Normal'
        END AS TemperatureStatus,
        CASE 
            WHEN vs.HeartRate < 60 THEN 'Low'
            WHEN vs.HeartRate > 100 THEN 'High' 
            ELSE 'Normal'
        END AS HeartRateStatus,
        CASE 
            WHEN vs.OxygenSaturation < 95 THEN 'Low'
            ELSE 'Normal'
        END AS OxygenStatus
    FROM Clinical_Management.VitalSigns vs
    INNER JOIN Core_system.Staff s ON vs.RecordedBy = s.StaffId
    WHERE vs.EncounterId = @EncounterId
    ORDER BY vs.RecordedAt DESC;
END;
GO


CREATE OR ALTER PROCEDURE UpdateVitalSigns
    @VitalSignId INT,
    @Temperature DECIMAL(4,2) = NULL,
    @BloodPressure NVARCHAR(20) = NULL,
    @HeartRate INT = NULL,
    @RespiratoryRate INT = NULL,
    @OxygenSaturation DECIMAL(5,2) = NULL,
    @Height DECIMAL(5,2) = NULL,
    @Weight DECIMAL(5,2) = NULL,
    @BloodGlucose DECIMAL(5,2) = NULL,
    @PainScore INT = NULL,
    @Notes NVARCHAR(500) = NULL,
    @UpdatedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        
        IF @VitalSignId IS NULL OR @UpdatedBy IS NULL
            THROW 50001, 'VitalSignId and UpdatedBy are required', 1;

       
        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.VitalSigns WHERE VitalSignId = @VitalSignId)
            THROW 50002, 'Vital signs record not found', 1;

 
        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffId = @UpdatedBy AND IsActive = 1)
            THROW 50003, 'Updating staff not found or inactive', 1;

        IF @PainScore IS NOT NULL AND (@PainScore < 0 OR @PainScore > 10)
            THROW 50006, 'Pain score must be between 0 and 10', 1;

        -- Update vital signs
        UPDATE Clinical_Management.VitalSigns
        SET 
            Temperature = COALESCE(@Temperature, Temperature),
            BloodPressure = COALESCE(@BloodPressure, BloodPressure),
            HeartRate = COALESCE(@HeartRate, HeartRate),
            RespiratoryRate = COALESCE(@RespiratoryRate, RespiratoryRate),
            OxygenSaturation = COALESCE(@OxygenSaturation, OxygenSaturation),
            Height = COALESCE(@Height, Height),
            Weight = COALESCE(@Weight, Weight),
            BloodGlucose = COALESCE(@BloodGlucose, BloodGlucose),
            PainScore = COALESCE(@PainScore, PainScore),
            Notes = COALESCE(@Notes, Notes),
            RecordedBy = @UpdatedBy,  -- Track who made the update
            RecordedAt = GETDATE()    -- Update timestamp
        WHERE VitalSignId = @VitalSignId;

        COMMIT TRANSACTION;

        SELECT 
            @VitalSignId AS VitalSignId,
            'Vital signs updated successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Error updating vital signs: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;
GO



CREATE OR ALTER PROCEDURE GetPatientVitalSignsHistory
    @PatientId INT,
    @DaysBack INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate patient exists
    IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientId = @PatientId AND IsActive = 1)
    BEGIN
        SELECT 'Patient not found' AS Message;
        RETURN;
    END

    SELECT 
        vs.VitalSignId,
        vs.EncounterId,
        e.EncounterNumber,
        e.EncounterDate,
        vs.Temperature,
        vs.BloodPressure,
        vs.HeartRate,
        vs.RespiratoryRate,
        vs.OxygenSaturation,
        vs.Height,
        vs.Weight,
        vs.BMI,
        vs.BloodGlucose,
        vs.PainScore,
        vs.Notes,
        vs.RecordedAt,
        s.FullName AS RecordedByName,
        doc.FullName AS DoctorName,
        
        LAG(vs.HeartRate) OVER (PARTITION BY e.PatientId ORDER BY vs.RecordedAt) AS PreviousHeartRate,
        LAG(vs.BloodPressure) OVER (PARTITION BY e.PatientId ORDER BY vs.RecordedAt) AS PreviousBloodPressure,
        LAG(vs.Temperature) OVER (PARTITION BY e.PatientId ORDER BY vs.RecordedAt) AS PreviousTemperature
    FROM Clinical_Management.VitalSigns vs
    INNER JOIN Clinical_Management.Encounters e ON vs.EncounterId = e.EncounterId
    INNER JOIN Core_system.Staff s ON vs.RecordedBy = s.StaffId
    INNER JOIN Core_system.Staff doc ON e.PhysicianID = doc.StaffId
    WHERE e.PatientId = @PatientId
      AND vs.RecordedAt >= DATEADD(DAY, -@DaysBack, GETDATE())
    ORDER BY vs.RecordedAt DESC;
END;
GO


 GO 
CREATE OR ALTER PROCEDURE DeleteVitalSigns
    @VitalSignId INT,
    @DeletedBy INT,
    @PatientID INT , 
    @EnconterID INT 

AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validation
        IF @VitalSignId IS NULL OR @DeletedBy IS NULL
            THROW 50001, 'VitalSignId and DeletedBy are required', 1;

       
        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.VitalSigns WHERE VitalSignId = @VitalSignId)
            THROW 50002, 'Vital signs record not found', 1;

        
        IF NOT EXISTS (
            SELECT 1 FROM Core_system.Staff 
            WHERE StaffId = @DeletedBy AND IsActive = 1
        )
            THROW 50003, 'Staff not authorized to delete vital signs', 1;

          IF EXISTS (
            SELECT 1 FROM Clinical_Management.VitalSigns vs
            INNER JOIN Clinical_Management.Encounters e ON vs.EncounterId = e.EncounterId
            WHERE vs.VitalSignId = @VitalSignId AND e.Status = 'Active'
        )
            THROW 50004, 'Cannot delete vital signs for active encounter', 1;

        
        DELETE FROM Clinical_Management.VitalSigns 
        WHERE VitalSignId = @VitalSignId;

        COMMIT TRANSACTION;

        SELECT 'Vital signs record deleted successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Error deleting vital signs: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END;



-- =============================================
-- Clinical_Management.Dignosis PROCEDURES
-- =============================================

GO
CREATE PROCEDURE Create_Dignosis 
@EncounterId INT, @PatientId INT , @DiagnosisCode NVARCHAR(20) ,  
@DiagnosisDescription Nvarchar(500) ,@DiagnosisType Nvarchar(50),
@Status Nvarchar(40) , @DiagnosedBy INT,
@Notes NVARCHAR(1000)
 AS BEGIN
    
 BEGIN TRY
 
   BEGIN TRANSACTION

   IF @EncounterId IS NULL OR @DiagnosedBy IS NULL OR @PatientId IS NULL 
        THROW 50001,'Encounter ID And Doctor id and patient id are required ',1;
   
   IF @DiagnosisDescription IS NULL OR @DiagnosisType IS NULL 
         THROW 50001,'Dignose Type and Description are required ',1;


      IF NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.Encounters 
            WHERE EncounterId = @EncounterId 
            AND PatientId = @PatientId
        )
            THROW 50004, 'Encounter not found or does not belong to the specified patient', 1;

        
        IF NOT EXISTS (
            SELECT 1 
            FROM Patient_Management.Patient 
            WHERE PatientId = @PatientId 
            AND IsActive = 1
        )
            THROW 50005, 'Patient not found or inactive', 1;

        
        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffId = @DiagnosedBy 
            AND s.IsActive = 1
            AND u.RoleID IN (
                SELECT RoleID 
                FROM Core_system.Roles 
                WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
            )
        )
        THROW 50006, 'Diagnosing staff must be an active medical doctor', 1;

     INSERT INTO Clinical_Management.Diagnoses(
            EncounterId,
            PatientId,
            DiagnosisCode,
            DiagnosisDescription,
            DiagnosisType,
            Status,
            DiagnosedBy,
            Notes
        )
        VALUES(
            @EncounterId,
            @PatientId,
            @DiagnosisCode,
            @DiagnosisDescription,
            @DiagnosisType,
            @Status,
            @DiagnosedBy,
            @Notes
        );
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
     IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = 'Error inserting Dignoses: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH

    END
GO


GO 
--Upate_Dignoses

CREATE PROCEDURE Update_Digonoses
    @DignosisId INT, @EncounterId INT = NULL, @PatientId INT = NULL , @DiagnosisCode NVARCHAR(20)= NULL ,  
    @DiagnosisDescription Nvarchar(500)= NULL ,@DiagnosisType Nvarchar(50)= NULL,
    @Status Nvarchar(40)= NULL , @DiagnosedBy INT = NULL,
    @Notes NVARCHAR(1000)= NULL 
    AS BEGIN 
    BEGIN TRY
        BEGIN TRANSACTION
        IF @DignosisId IS NULL
            THROW 50001, 'Diagnoses ID is required', 1;

      IF NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.Encounters 
            WHERE EncounterId = @EncounterId 
            AND PatientId = @PatientId
        )
            THROW 50004, 'Encounter not found or does not belong to the specified patient', 1;

        
        IF NOT EXISTS (
            SELECT 1 
            FROM Patient_Management.Patient 
            WHERE PatientId = @PatientId 
            AND IsActive = 1
        )
            THROW 50005, 'Patient not found or inactive', 1;

        
        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffId = @DiagnosedBy 
            AND s.IsActive = 1
            AND u.RoleID IN (
                SELECT RoleID 
                FROM Core_system.Roles 
                WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
            )
        )
        THROW 50006, 'Diagnosing staff must be an active medical doctor', 1;

        update Clinical_Management.Diagnoses 
        SET  EncounterId = COALESCE(@EncounterId, EncounterId),
        PatientId = COALESCE(@PatientId, PatientId),
        DiagnosisCode = COALESCE(@DiagnosisCode, DiagnosisCode),
        DiagnosisDescription = COALESCE(@DiagnosisDescription, DiagnosisDescription),
        DiagnosisType = COALESCE(@DiagnosisType, DiagnosisType),
        Status = COALESCE(@status, Status),
        DiagnosedBy = COALESCE(@DiagnosedBy, DiagnosedBy),
        Notes = COALESCE(@Notes, Notes)   
        WHERE DiagnosisId = @DignosisId;

         COMMIT TRANSACTION 
     END TRY 
     BEGIN CATCH 
         DECLARE @ErrorMessage NVARCHAR(4000) = 'Error upadating Dignoses: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
     END CATCH
     END
 GO


 Go
 --usp_Diagnosis_GetByPatient

CREATE PROCEDURE GetByPatient_Dignosis @patientID INT 
   AS BEGIN 
   SET NOCOUNT ON 
   BEGIN TRY

   IF @patientID IS NULL 
    THROW 50001,'Patient id is required',1;

    IF NOT EXISTS( 
                    SELECT 1 FROM Patient_Management.Patient 
                    WHERE PatientID = @patientID AND IsActive != 0
                 )
                 THROW 50002,'Patient id Does not exist or is not active',1;


   SELECT  
           Di.EncounterId,
           Di.PatientId,
           Di.DiagnosisCode,
           Di.DiagnosisDescription,
           Di.DiagnosisType,
           Di.Status,
           Di.DiagnosedBy,
           Di.Notes,
           pa.FirstName + ' '+ pa.LastName as Patient_name,
           Pa.MRN,
           Pa.Age,
           Pa.Gender
     FROM Clinical_Management.Diagnoses Di 
     join Patient_Management.Patient Pa on Di.PatientId = Pa.PatientID
     WHERE Di.PatientId = @patientID 
    ORDER BY Di.DiagnosisDate
    END TRY
       BEGIN CATCH 
         DECLARE @ErrorMessage NVARCHAR(4000) = 'Error Fetching Dignoses: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
     END CATCH


   END
GO
-- Get Dignoses by encounter 
CREATE PROCEDURE GetByEncounter_Dignosis @EncounterId INT 
 AS BEGIN 
   SET NOCOUNT ON 
   BEGIN TRY

   IF @EncounterId IS NULL 
    THROW 50001,'EncounterId is required',1;

    IF NOT EXISTS( 
                    SELECT 1 FROM Clinical_Management.Encounters 
                    WHERE EncounterId = @EncounterId 
                 )
                 THROW 50002,'Encounter id Does not exist ',1;


   SELECT  
           Di.EncounterId,
           Di.PatientId,
           Di.DiagnosisCode,
           Di.DiagnosisDescription,
           Di.DiagnosisType,
           Di.Status,
           Di.DiagnosedBy,
           Di.Notes,
           En.EncounterDate,
           En.FollowUpInstructions,
           En.VisitType,
           En.EncounterNumber,
           pa.FirstName + ' '+ pa.LastName as Patient_name,
           Pa.MRN,
           Pa.Age,
           Pa.Gender
     FROM Clinical_Management.Diagnoses Di 
     join Patient_Management.Patient Pa on Di.PatientId = Pa.PatientID
     join Clinical_Management.Encounters En on En.EncounterId = Di.EncounterId 
     WHERE En.EncounterId = @EncounterId 
    ORDER BY En.EncounterDate, Di.DiagnosisDate
 END TRY   
 BEGIN CATCH 
         DECLARE @ErrorMessage NVARCHAR(4000) = 'Error Fetching Dignoses: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
 END CATCH

 END
GO

-- Get Dignoses by ID 
CREATE PROCEDURE GetByID_Dignosis @DignosId INT 
 AS BEGIN 
   SET NOCOUNT ON 
   BEGIN TRY

   IF @DignosId IS NULL 
    THROW 50001,'DignosId  id is required',1;

    IF NOT EXISTS( 
                    SELECT 1 FROM Clinical_Management.Diagnoses 
                    WHERE DiagnosisId = @DignosId 
                 )
                 THROW 50002,'@DignosId Does not exist ',1;


   SELECT  
           Di.EncounterId,
           Di.PatientId,
           Di.DiagnosisCode,
           Di.DiagnosisDescription,
           Di.DiagnosisType,
           Di.Status,
           Di.DiagnosedBy,
           Di.Notes
     FROM Clinical_Management.Diagnoses Di 
     WHERE Di.DiagnosisId= @DignosId
     ORDER BY Di.DiagnosisDate
 END TRY   
 BEGIN CATCH 
         DECLARE @ErrorMessage NVARCHAR(4000) = 'Error Fetching Dignoses: ' + ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
 END CATCH

 END
GO



-- Delete Dignoses by ID 
CREATE PROCEDURE Delete_Dignosis @DignosId INT 
 AS BEGIN 
   SET NOCOUNT ON 
   BEGIN TRY

   BEGIN TRANSACTION

   IF @DignosId IS NULL 
    THROW 50001,'DignosId  id is required',1;

    IF NOT EXISTS( 
                    SELECT 1 FROM Clinical_Management.Diagnoses 
                    WHERE DiagnosisId = @DignosId 
                 )
                 THROW 50002,'@DignosId Does not exist ',1;


   DELETE  FROM Clinical_Management.Diagnoses  
   WHERE DiagnosisId= @DignosId
 

     COMMIT TRANSACTION

 END TRY   
 BEGIN CATCH 
    IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = 'Error Deleting Dignoses: ' + ERROR_MESSAGE();
    THROW 50000, @ErrorMessage, 1;
 END CATCH

 END
GO

-- =============================================
-- Clinical_Management.Prescription PROCEDURES
-- =============================================






















































--CREATE PROCEDURE Emergency_ToggleAvailability
--    @DoctorID INT,
--    @UnavailableFrom DATETIME,
--    @UnavailableTo DATETIME,
--    @IsUnavailable BIT,  -- 1 = emergency, 0 = restore
--    @Reason NVARCHAR(200)
--AS
--BEGIN
--    SET NOCOUNT ON;
--    BEGIN TRY
--        BEGIN TRANSACTION;
        
--        IF @IsUnavailable = 1  -- Emergency mode
--        BEGIN
--            -- Simply update the recurring schedule to unavailable
--            UPDATE Scheduling.DoctorsSchedules 
--            SET IsAvailable = 0
--            WHERE DoctorID = @DoctorID
--              AND IsRecurring = 1
--              AND DayOfTheWeek = DATEPART(WEEKDAY, @UnavailableFrom)
--              AND IsAvailable = 1;
            
--            -- Cancel appointments
--            UPDATE Scheduling.Appointments 
--            SET Status = 'Cancelled',
--                CancellationReason = 'Doctor emergency: ' + @Reason
--            WHERE PhysicianID = @DoctorID
--              AND AppointmentDateTime >= @UnavailableFrom
--              AND AppointmentDateTime <= @UnavailableTo
--              AND Status IN ('Scheduled', 'Confirmed');
--        END
--        ELSE  -- Restore mode
--        BEGIN
--            -- Restore availability
--            UPDATE Scheduling.DoctorsSchedules 
--            SET IsAvailable = 1
--            WHERE DoctorID = @DoctorID
--              AND IsRecurring = 1
--              AND DayOfTheWeek = DATEPART(WEEKDAY, @UnavailableFrom)
--              AND IsAvailable = 0;
--        END
        
--        SELECT 
--            CASE WHEN @IsUnavailable = 1 
--                 THEN 'Doctor marked as unavailable' 
--                 ELSE 'Doctor availability restored' 
--            END AS Message;
        
--        COMMIT TRANSACTION;
--    END TRY
--    BEGIN CATCH
--        IF @@TRANCOUNT > 0
--            ROLLBACK TRANSACTION;
--        THROW;
--    END CATCH;
--END
--GO
--CREATE OR ALTER PROCEDURE Get_DoctorAppointments_Detailed
--    @DoctorID INT = NULL,
--    @AppointmentDate DATE = NULL,
--    @IncludePastAppointments BIT = 0
--AS 
--BEGIN
--    SET NOCOUNT ON;
    
--    BEGIN TRY
--        -- Set defaults
--        IF @AppointmentDate IS NULL
--            SET @AppointmentDate = CAST(GETDATE() AS DATE);
        
--        -- If no doctor specified, return all doctors' appointments (for admin view)
--        IF @DoctorID IS NOT NULL
--        BEGIN
--            -- Validate doctor exists
--            IF NOT EXISTS (
--                SELECT 1 
--                FROM Core_system.Staff 
--                WHERE StaffID = @DoctorID 
--                AND IsActive = 1
--            )
--                THROW 50001, 'Doctor not found or inactive', 1;
--        END
        
--        SELECT 
--            -- Appointment Details
--            ap.AppointmentId,
--            ap.AppointmentDateTime,
--            ap.Status,
--            ap.Priority,
--            ap.Duration,
--            ap.Complaint,
            
--            -- Patient Details
--            p.PatientID,
--            p.FirstName + ' ' + p.LastName AS PatientName,
--            p.Gender,
--            DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
--            p.PhoneNumber,
--            p.EMail AS Email,
            
--            -- Doctor Details
--            st.StaffID AS DoctorID,
--            st.FullName AS DoctorName,
--            st.Position,
            
--            -- Department
--            d.DepartmentName,
            
--            -- Calculated Fields
--            CASE 
--                WHEN ap.AppointmentDateTime > GETDATE() THEN 'Upcoming'
--                WHEN ap.AppointmentDateTime <= GETDATE() AND ap.Status IN ('Scheduled', 'Confirmed') THEN 'Missed'
--                ELSE 'Completed'
--            END AS AppointmentStatus,
            
--            DATEDIFF(MINUTE, GETDATE(), ap.AppointmentDateTime) AS MinutesUntilAppointment,
            
--            -- Queue Information
--            pq.QueueNumber,
--            pq.Status AS QueueStatus,
--            pq.CurrentPosition,
            
--            -- Emergency contact (if exists)
--            ec.FullName AS EmergencyContact,
--            ec.PhoneNumber AS EmergencyPhone
            
--        FROM Scheduling.Appointments ap 
--        INNER JOIN Patient_Management.Patient p ON ap.PatientID = p.PatientID 
--        INNER JOIN Core_system.Staff st ON ap.PhysicianID = st.StaffID 
--        INNER JOIN Clinical_Management.Departments d ON ap.DepartmentID = d.DepartmentID
--        LEFT JOIN Clinical_Management.PatientQueue pq ON ap.AppointmentID = pq.AppointmentID 
--            AND pq.QueueDate = @AppointmentDate
--        LEFT JOIN Patient_Management.EmergencyContacts ec ON p.PatientID = ec.PatientID 
--            AND ec.IsPrimary = 1
        
--        WHERE 
--            -- Doctor filter (if provided)
--            (@DoctorID IS NULL OR ap.PhysicianID = @DoctorID)
--            -- Date filter
--            AND CAST(ap.AppointmentDateTime AS DATE) = @AppointmentDate
--            -- Status filter (include past appointments if requested)
--            AND (
--                @IncludePastAppointments = 1 
--                OR ap.Status IN ('Scheduled', 'Confirmed', 'In Progress')
--                OR (ap.AppointmentDateTime >= GETDATE())
--            )
        
--        ORDER BY 
--            ap.AppointmentDateTime ASC,
--            CASE ap.Priority
--                WHEN 'Urgent' THEN 1
--                WHEN 'High' THEN 2
--                WHEN 'Normal' THEN 3
--                WHEN 'Low' THEN 4
--                ELSE 5
--            END;
        
--        -- Return summary statistics
--        SELECT 
--            COUNT(*) AS TotalAppointments,
--            SUM(CASE WHEN ap.Status = 'Scheduled' THEN 1 ELSE 0 END) AS ScheduledCount,
--            SUM(CASE WHEN ap.Status = 'Confirmed' THEN 1 ELSE 0 END) AS ConfirmedCount,
--            SUM(CASE WHEN ap.Status = 'In Progress' THEN 1 ELSE 0 END) AS InProgressCount,
--            SUM(CASE WHEN pq.QueueID IS NOT NULL THEN 1 ELSE 0 END) AS CheckedInCount
--        FROM Scheduling.Appointments ap
--        LEFT JOIN Clinical_Management.PatientQueue pq ON ap.AppointmentID = pq.AppointmentID 
--            AND pq.QueueDate = @AppointmentDate
--        WHERE 
--            (@DoctorID IS NULL OR ap.PhysicianID = @DoctorID)
--            AND CAST(ap.AppointmentDateTime AS DATE) = @AppointmentDate
--            AND (@IncludePastAppointments = 1 OR ap.Status IN ('Scheduled', 'Confirmed', 'In Progress'));
            
--    END TRY
--    BEGIN CATCH
--        DECLARE @ErrorMessage NVARCHAR(4000) = 'Error retrieving doctor appointments: ' + ERROR_MESSAGE();
--        THROW 50000, @ErrorMessage, 1;
--    END CATCH
--END;
--GO