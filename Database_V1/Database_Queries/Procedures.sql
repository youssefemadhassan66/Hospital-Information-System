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
-- Specilization Prcedure
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

CREATE PROCEDURE GetAllL_SPECILIZATIONS 
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
         OR us.Email LIKE '%' + @SearchTerm + '%')
    AND (@DepartmentID IS NULL OR s.DepartmentID = @DepartmentID)
    AND (@SpecializationID IS NULL OR s.SpecializationID = @SpecializationID)
    AND (@RoleID IS NULL OR us.RoleID = @RoleID)
    ORDER BY s.FullName;
END
GO

CREATE PROCEDURE usp_Staff_GetAll
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

CREATE PROCEDURE usp_Staff_GetDoctors
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


