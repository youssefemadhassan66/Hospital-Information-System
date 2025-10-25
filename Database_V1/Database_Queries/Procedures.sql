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
		IF NOT EXISTS (SELECT 1 FROM  Core_system.Specializations WHERE SpecializationID = @SpeciID)

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

	 Insert INTO Core_system.Users (UserName,BrithDate,PasswordHash,Email,RoleID)
	 VALUES(@UserName,@BrithDate,@PasswordHash,@Email);

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
	
	INSERT INTO Core_system.Users (UserID, RoleID) VALUES (123, 2)

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
        SET DepartmentName = COALESCE(@DepartmentName,DepartmentName),
            DepartmentCode =COALESCE( @DepartmentCode,DepartmentCode),
            ManagerID = COALESCE(@ManagerID,DepartmentCode),
            IsActive = COALESCE(ISNULL(@IsActive, IsActive))
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


GO 
CREATE PROCEDURE GetByID_ScheduleDoctor @DoctorId INT=NULL ,@ScheduleID INT=NULL
AS BEGIN
    
        IF (@DoctorId IS NULL AND @ScheduleID IS NULL) or (@DoctorId IS NOT NULL AND @ScheduleID IS NOT NULL)   
            THROW 50001, 'Doctor ID and schedule Id  one of them is requrired required', 1;
          
        IF @ScheduleID IS NOT NULL AND  NOT EXISTS (SELECT 1 FROM Scheduling.DoctorsSchedules WHERE ScheduleID = @ScheduleID)
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
        SELECT DS.ScheduleID,DS.DoctorID,DS.DayOfTheWeek,DS.StartTime,
        DS.EndTime,DS.EffectiveStart,DS.EffectiveEnd,DS.IsAvalibale,DS.IsRecurring,DS.MaxAppointments 
        FROM Scheduling.DoctorsSchedules DS WHERE DoctorID = @DoctorId OR ScheduleID = @ScheduleID 
        
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
CREATE OR ALTER PROCEDURE Add_Appointment 
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


CREATE PROCEDURE Update_Appointment @AppintmentID int,
@PatientID INT =NULL, @PhysicianID INT =NULL , @AppointmentDateTime DATETIME , @DepartmentID INT=NULL,
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

GO
















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