-- =============================================
-- Specialization Procedures 
-- =============================================
USE HIS_V2
GO

--usp-AddSpecialization
CREATE OR ALTER PROCEDURE Add_Specialization 
    @SpeciName VARCHAR(100), 
    @speciCode NVARCHAR(20), 
    @SpeciDesc NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        SET @speciCode = UPPER(TRIM(@speciCode));
        SET @SpeciName = TRIM(@SpeciName);

        IF @SpeciName IS NULL OR LEN(@SpeciName) < 2 OR @speciCode IS NULL OR LEN(@speciCode) < 2
            THROW 50001, 'Specialization name and code must be at least 2 characters', 1;

        IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationName = @SpeciName)
            THROW 50002, 'Specialization name already exists', 1;

        IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationCode = @speciCode)
            THROW 50002, 'Specialization code already exists', 1;

        INSERT INTO Core_system.Specializations(SpecializationName, SpecializationCode, Description) 
        VALUES(@SpeciName, @speciCode, @SpeciDesc);
        
        PRINT 'Specialization added successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Add_Specialization: ' + ERROR_MESSAGE();
        THROW;	
    END CATCH
END
GO

--usp-UpdateSpecialization
CREATE OR ALTER PROCEDURE Update_Specialization 
    @SpeciID INT, 
    @SpeciName VARCHAR(100) = NULL, 
    @speciCode NVARCHAR(20) = NULL, 
    @SpeciDesc NVARCHAR(255) = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SET @speciCode = UPPER(TRIM(@speciCode));
        SET @SpeciName = TRIM(@SpeciName);
        
        IF @SpeciID IS NULL 
            THROW 50001, 'Specialization ID cannot be null', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpeciID)
            THROW 50003, 'Specialization ID not found', 1;

        IF @SpeciName IS NOT NULL AND LEN(@SpeciName) < 2
            THROW 50001, 'Specialization name must be at least 2 characters', 1;

        IF @speciCode IS NOT NULL AND LEN(@speciCode) < 2
            THROW 50001, 'Specialization code must be at least 2 characters', 1;

        IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationName = @SpeciName AND SpecializationID != @SpeciID)
            THROW 50002, 'Specialization name already exists', 1;

        IF EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationCode = @speciCode AND SpecializationID != @SpeciID)
            THROW 50002, 'Specialization code already exists', 1;

        UPDATE Core_system.Specializations  
        SET SpecializationName = COALESCE(@SpeciName, SpecializationName),
            SpecializationCode = COALESCE(@speciCode, SpecializationCode),
            Description = COALESCE(@SpeciDesc, Description)
        WHERE SpecializationID = @SpeciID;

        PRINT 'Specialization updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Specialization: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteSpecialization
CREATE OR ALTER PROCEDURE Delete_Specialization 
    @SpeciID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @SpeciID IS NULL 
            THROW 50001, 'Specialization ID cannot be null', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpeciID)
            THROW 50003, 'Specialization ID does not exist', 1;

        IF EXISTS (SELECT 1 FROM Core_system.Staff WHERE SpecializationID = @SpeciID)
            THROW 50003, 'This specialization is linked to staff and cannot be deleted', 1;

        DELETE FROM Core_system.Specializations WHERE SpecializationID = @SpeciID;
        
        PRINT 'Specialization deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Specialization: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetAllSpecializations
CREATE OR ALTER PROCEDURE GetAll_Specializations 
AS 
BEGIN 
    SELECT * FROM Core_system.Specializations
END 
GO

--usp-GetByIDSpecializations
CREATE OR ALTER PROCEDURE GetByID_Specializations 
    @SpeciID INT  
AS 
BEGIN 
    BEGIN TRY 
        IF @SpeciID IS NULL 
            THROW 50001, 'Specialization ID cannot be null', 1;

        IF NOT EXISTS(SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpeciID)
            THROW 50003, 'Specialization ID not found', 1;

        SELECT * FROM Core_system.Specializations WHERE SpecializationID = @SpeciID;
    END TRY
    BEGIN CATCH 
        PRINT 'Error in GetByID_Specializations: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END 
GO

--usp-SearchSpecializations
CREATE OR ALTER PROCEDURE Search_Specializations 
    @SearchTerm NVARCHAR(100)
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @SearchTerm IS NOT NULL AND LEN(@SearchTerm) > 100
            THROW 50004, 'Search term too long', 1;

        SELECT SpecializationName, SpecializationCode, SpecializationID 
        FROM Core_system.Specializations 
        WHERE @SearchTerm IS NULL 
            OR SpecializationName LIKE '%' + @SearchTerm + '%'
            OR SpecializationCode LIKE '%' + @SearchTerm + '%'
            OR Description LIKE '%' + @SearchTerm + '%'
        ORDER BY SpecializationName;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Search_Specializations: ' + ERROR_MESSAGE();
        THROW;
    END CATCH 
END
GO

-- =============================================
-- Users Procedures
-- =============================================

--usp-AddUser
CREATE OR ALTER PROCEDURE Add_User 
    @UserName VARCHAR(50), 
    @BirthDate DATETIME,
    @PasswordHash NVARCHAR(250), 
    @Email NVARCHAR(150),
    @RoleID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;

        IF @UserName IS NULL OR @BirthDate IS NULL OR @PasswordHash IS NULL OR @Email IS NULL 
            THROW 50001, 'All fields are required', 1;

        IF DATEDIFF(YEAR, @BirthDate, GETDATE()) < 18 
            THROW 50003, 'User must be at least 18 years old', 1;

        IF @RoleID IS NULL 
            THROW 50001, 'User must have a role', 1;

        IF NOT EXISTS(SELECT 1 FROM Core_system.Roles WHERE RoleID = @RoleID) 
            THROW 50003, 'Role ID not found', 1;

        IF @BirthDate > GETDATE()
            THROW 50003, 'Birth date cannot be in the future', 1;
        
        IF EXISTS(SELECT 1 FROM Core_system.Users WHERE UserName = @UserName) 
            THROW 50002, 'Username already exists', 1;

        IF EXISTS(SELECT 1 FROM Core_system.Users WHERE Email = @Email) 
            THROW 50002, 'Email already exists', 1;
        
        IF @Email NOT LIKE '%_@_%_.__%'
            THROW 50006, 'Invalid email format', 1;

        IF @UserName LIKE '%[^a-zA-Z0-9_]%'
            THROW 50005, 'Username can only contain letters, numbers, and underscores', 1;

        INSERT INTO Core_system.Users (UserName, BrithDate, PasswordHash, Email, RoleID)
        VALUES(@UserName, @BirthDate, @PasswordHash, @Email, @RoleID);

        PRINT 'User added successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Add_User: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateUser
CREATE OR ALTER PROCEDURE Update_User 
    @UserID INT,
    @UserName VARCHAR(50) = NULL, 
    @BirthDate DATETIME = NULL,
    @Email NVARCHAR(150) = NULL,
    @RoleID INT = NULL
AS 
BEGIN 
    SET NOCOUNT ON; 
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @UserID IS NULL 
            THROW 50001, 'User ID cannot be null', 1;

        IF NOT EXISTS(SELECT 1 FROM Core_system.Users WHERE UserID = @UserID)
            THROW 50003, 'User ID not found', 1;
        
        IF @RoleID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM Core_system.Roles WHERE RoleID = @RoleID)
            THROW 50003, 'Role ID not found', 1;

        IF @UserName IS NOT NULL AND EXISTS(SELECT 1 FROM Core_system.Users WHERE UserName = @UserName AND UserID != @UserID)
            THROW 50002, 'Username already exists', 1;

        IF @Email IS NOT NULL AND EXISTS(SELECT 1 FROM Core_system.Users WHERE Email = @Email AND UserID != @UserID)
            THROW 50002, 'Email already exists', 1;

        UPDATE Core_system.Users 
        SET UserName = COALESCE(@UserName, UserName),
            BirthDate = COALESCE(@BirthDate, BirthDate),
            Email = COALESCE(@Email, Email),
            RoleID = COALESCE(@RoleID, RoleID)
        WHERE UserID = @UserID;

        PRINT 'User updated successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_User: ' + ERROR_MESSAGE();
        THROW;
    END CATCH 
END
GO

--usp-DeleteUser
CREATE OR ALTER PROCEDURE Delete_User 
    @UserID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY 
        IF @UserID IS NULL 
            THROW 50001, 'User ID cannot be null', 1;

        IF NOT EXISTS(SELECT 1 FROM Core_system.Users WHERE UserID = @UserID)
            THROW 50003, 'User ID not found', 1;
        
        IF EXISTS(SELECT 1 FROM Core_system.Staff WHERE UserID = @UserID)
            THROW 50002, 'Cannot delete user linked to staff table', 1;
        
        DELETE FROM Core_system.Users WHERE UserID = @UserID;

        PRINT 'User deleted successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_User: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateLastLoginAtUser
CREATE OR ALTER PROCEDURE Update_LastLoginAt_User 
    @UserID INT
AS 
BEGIN
    BEGIN TRY 
        IF @UserID IS NULL 
            THROW 50001, 'User ID is required', 1;

        UPDATE Core_system.Users SET LastLoginAt = GETDATE() WHERE UserID = @UserID;
        PRINT 'Last login updated successfully';
    END TRY 
    BEGIN CATCH
        PRINT 'Error in Update_LastLoginAt_User: ' + ERROR_MESSAGE();
        THROW;       
    END CATCH
END
GO

--usp-GetUserByID
CREATE OR ALTER PROCEDURE Get_User_ByID 
    @UserID INT 
AS 
BEGIN
    BEGIN TRY 
        IF @UserID IS NULL 
            THROW 50001, 'User ID is required', 1;

        SELECT UserName, Email, BrithDate, R.RoleID, R.RoleName, R.Description  
        FROM Core_system.Users U 
        LEFT JOIN Core_system.Roles R ON U.RoleID = R.RoleID  
        WHERE UserID = @UserID;
    END TRY 
    BEGIN CATCH
        PRINT 'Error in Get_User_ByID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Roles Procedures
-- =============================================

--usp-AddRole
CREATE OR ALTER PROCEDURE Add_Role
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
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Add_Role: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateRole
CREATE OR ALTER PROCEDURE Update_Role 
    @RoleID INT,
    @RoleName NVARCHAR(70) = NULL,
    @Description NVARCHAR(255) = NULL,
    @Permissions NVARCHAR(MAX) = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @RoleID IS NULL 
            THROW 50001, 'Role ID is required', 1;
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Roles WHERE RoleID = @RoleID)
            THROW 50003, 'Role ID not found', 1;

        IF @RoleName IS NOT NULL AND EXISTS(SELECT 1 FROM Core_system.Roles WHERE RoleID != @RoleID AND RoleName = @RoleName)
            THROW 50002, 'Role name already exists', 1;

        UPDATE Core_system.Roles 
        SET RoleName = COALESCE(@RoleName, RoleName),
            Description = COALESCE(@Description, Description),
            Permissions = COALESCE(@Permissions, Permissions)
        WHERE RoleID = @RoleID;

        PRINT 'Role updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Role: ' + ERROR_MESSAGE();
        THROW;
    END CATCH 
END
GO

--usp-GetAllRoles
CREATE OR ALTER PROCEDURE Get_All_Roles
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        SELECT RoleID, RoleName, Description, Permissions FROM Core_system.Roles;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_All_Roles: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteRole
CREATE OR ALTER PROCEDURE Delete_Role
    @RoleID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @RoleID IS NULL 
            THROW 50001, 'Role ID cannot be null', 1;
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Roles WHERE RoleID = @RoleID)
            THROW 50003, 'Role not found', 1;
            
        IF EXISTS (SELECT 1 FROM Core_system.Users WHERE RoleID = @RoleID)
            THROW 50002, 'Cannot delete role - it is assigned to users', 1;
        
        DELETE FROM Core_system.Roles WHERE RoleID = @RoleID;
        
        PRINT 'Role deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Role: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- UserRoles Procedures
-- =============================================

--usp-AssignUserToRole
CREATE OR ALTER PROCEDURE Assign_User_To_Role 
    @UserID INT, 
    @RoleID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @UserID IS NULL OR @RoleID IS NULL 
            THROW 50001, 'User ID and Role ID cannot be null', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Core_system.Users WHERE UserID = @UserID)
            THROW 50003, 'User does not exist', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Roles WHERE RoleID = @RoleID)
            THROW 50003, 'Role does not exist', 1;

        IF EXISTS (SELECT 1 FROM Core_system.Users WHERE UserID = @UserID AND RoleID = @RoleID)
            THROW 50004, 'User already has this role assigned', 1;
        
        UPDATE Core_system.Users SET RoleID = @RoleID WHERE UserID = @UserID;
        
        PRINT 'Role assigned successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Assign_User_To_Role: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END 
GO

--usp-GetAllUserRoles
CREATE OR ALTER PROCEDURE Get_All_User_Roles
AS 
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserID, u.UserName, u.Email, 
           Age = DATEDIFF(YEAR, BrithDate, GETDATE()),
           R.RoleName, r.Description 
    FROM Core_system.Users u
    INNER JOIN Core_system.Roles r ON u.RoleID = r.RoleID 
    ORDER BY u.UserName, r.RoleName;
END
GO

--usp-GetRolesByUser
CREATE OR ALTER PROCEDURE Get_Roles_By_User
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

-- =============================================
-- Department Procedures
-- =============================================

--usp-AddDepartment
CREATE OR ALTER PROCEDURE Add_Department 
    @DepartmentName VARCHAR(50), 
    @DepartmentCode VARCHAR(20), 
    @ManagerID INT,
    @IsActive BIT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;

        IF @DepartmentCode IS NULL OR @DepartmentName IS NULL OR LEN(TRIM(@DepartmentName)) < 4 
            THROW 50001, 'Department code and name (min 4 chars) are required', 1;
            
        IF EXISTS(SELECT 1 FROM Core_system.Departments WHERE DepartmentCode = @DepartmentCode)
            THROW 50002, 'Department code already exists', 1;
            
        IF EXISTS(SELECT 1 FROM Core_system.Departments WHERE DepartmentName = @DepartmentName)
            THROW 50002, 'Department name already exists', 1;
        
        IF @ManagerID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @ManagerID)
            THROW 50004, 'Manager not found', 1;
        
        SET @IsActive = COALESCE(@IsActive, 1);
        
        INSERT INTO Core_system.Departments (DepartmentName, DepartmentCode, ManagerID, IsActive)
        VALUES (@DepartmentName, @DepartmentCode, @ManagerID, @IsActive);

        PRINT 'Department created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Add_Department: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateDepartment
CREATE OR ALTER PROCEDURE Update_Department
    @DepartmentID INT,
    @DepartmentName VARCHAR(50) = NULL,
    @DepartmentCode VARCHAR(20) = NULL,
    @ManagerID INT = NULL,
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
            THROW 50003, 'Department not found', 1;
            
        IF @DepartmentName IS NOT NULL AND EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentName = @DepartmentName AND DepartmentID != @DepartmentID)
            THROW 50002, 'Department name already exists', 1;
            
        IF @DepartmentCode IS NOT NULL AND EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentCode = @DepartmentCode AND DepartmentID != @DepartmentID)
            THROW 50002, 'Department code already exists', 1;
            
        IF @ManagerID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @ManagerID)
            THROW 50004, 'Manager not found', 1;
        
        UPDATE Core_system.Departments 
        SET DepartmentName = COALESCE(@DepartmentName, DepartmentName),
            DepartmentCode = COALESCE(@DepartmentCode, DepartmentCode),
            ManagerID = COALESCE(@ManagerID, ManagerID),
            IsActive = COALESCE(@IsActive, IsActive)
        WHERE DepartmentID = @DepartmentID;
        
        PRINT 'Department updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Department: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteDepartment
CREATE OR ALTER PROCEDURE Delete_Department
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
            THROW 50003, 'Department not found', 1;
            
        IF EXISTS (SELECT 1 FROM Core_system.Staff WHERE DepartmentID = @DepartmentID)
            THROW 50002, 'Cannot delete department - staff members are assigned to it', 1;
            
        IF EXISTS (SELECT 1 FROM Inpatient_Management.Wards WHERE DepartmentID = @DepartmentID)
            THROW 50002, 'Cannot delete department - wards are assigned to it', 1;
        
        DELETE FROM Core_system.Departments WHERE DepartmentID = @DepartmentID;
        
        PRINT 'Department deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Department: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetAllDepartment
CREATE OR ALTER PROCEDURE Get_All_Departments 
AS 
BEGIN 
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

--usp-GetDepartmentByID
CREATE OR ALTER PROCEDURE Get_Department_ByID 
    @DepID INT
AS 
BEGIN
    BEGIN TRY 
        IF @DepID IS NULL 
            THROW 50001, 'Department ID is required', 1;

        SELECT DEP.DepartmentID, DepartmentName, DepartmentCode, ST.FullName, ST.HireDate 
        FROM Core_system.Departments DEP 
        JOIN Core_system.Staff ST ON DEP.ManagerID = ST.StaffID 
        WHERE DEP.DepartmentID = @DepID;
    END TRY
    BEGIN CATCH 
        PRINT 'Error in Get_Department_ByID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Staff Procedures
-- =============================================

--usp-AddStaff
CREATE OR ALTER PROCEDURE Add_Staff 
    @FullName NVARCHAR(120),
    @Gender VARCHAR(10),
    @MobileNumber VARCHAR(20) = NULL,
    @UserID INT,
    @PhoneNumber VARCHAR(20),
    @Address NVARCHAR(500) = NULL,
    @DepartmentID INT,
    @Position NVARCHAR(100),
    @SpecializationID INT = NULL,
    @LicenseNumber NVARCHAR(50) = NULL,
    @HireDate DATE,
    @Salary DECIMAL(10,2),
    @IsActive BIT = 1
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;

        IF @FullName IS NULL OR LEN(TRIM(@FullName)) < 6
            THROW 50001, 'Valid full name (min 6 chars) is required', 1;
        
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
            
        IF @SpecializationID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpecializationID)
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
        
        PRINT 'Staff added successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Add_Staff: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateStaff
CREATE OR ALTER PROCEDURE Update_Staff 
    @StaffID INT,
    @FullName NVARCHAR(120) = NULL,
    @Gender VARCHAR(10) = NULL,
    @MobileNumber VARCHAR(20) = NULL,
    @UserID INT = NULL,
    @PhoneNumber VARCHAR(20) = NULL,
    @Address NVARCHAR(500) = NULL,
    @DepartmentID INT = NULL,
    @Position NVARCHAR(100) = NULL,
    @SpecializationID INT = NULL,
    @LicenseNumber NVARCHAR(50) = NULL,
    @HireDate DATE = NULL,
    @Salary DECIMAL(10,2) = NULL,
    @IsActive BIT = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @StaffID IS NULL 
            THROW 50001, 'Staff ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @StaffID)
            THROW 50003, 'Staff ID not found', 1;

        IF @FullName IS NOT NULL AND LEN(TRIM(@FullName)) < 6
            THROW 50001, 'Valid full name (min 6 chars) is required', 1;
        
        IF @Position IS NOT NULL AND LEN(TRIM(@Position)) < 2
            THROW 50002, 'Valid position is required', 1;
            
        IF @HireDate IS NOT NULL AND @HireDate > CAST(GETDATE() AS DATE)
            THROW 50003, 'Valid hire date (not future) is required', 1;
        
        IF @Gender IS NOT NULL AND @Gender NOT IN ('Male', 'Female')
            THROW 50004, 'Gender must be Male or Female', 1;
            
        IF @PhoneNumber IS NOT NULL AND LEN(TRIM(@PhoneNumber)) < 5
            THROW 50005, 'Valid phone number is required', 1;
            
        IF @Salary IS NOT NULL AND @Salary < 0
            THROW 50006, 'Valid salary is required', 1;
        
        IF @UserID IS NOT NULL AND EXISTS (SELECT 1 FROM Core_system.Staff WHERE UserID = @UserID AND StaffID != @StaffID)
            THROW 50007, 'User already has a staff profile', 1;
        
        IF @UserID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Users WHERE UserID = @UserID)
            THROW 50008, 'User does not exist', 1;
            
        IF @SpecializationID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpecializationID)
            THROW 50009, 'Specialization does not exist', 1;
            
        IF @DepartmentID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID AND IsActive = 1)
            THROW 50010, 'Department does not exist or is inactive', 1;
        
        IF @PhoneNumber IS NOT NULL AND @PhoneNumber LIKE '%[^0-9+]%'
            THROW 50011, 'Phone number can only contain numbers and +', 1;
            
        IF @MobileNumber IS NOT NULL AND @MobileNumber LIKE '%[^0-9+]%'
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
        
        PRINT 'Staff updated successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Staff: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteStaff
CREATE OR ALTER PROCEDURE Delete_Staff 
    @StaffID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @StaffID IS NULL 
            THROW 50001, 'Staff ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @StaffID)
            THROW 50003, 'Staff ID not found', 1;

        DELETE FROM Core_system.Staff WHERE StaffID = @StaffID;

        PRINT 'Staff deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Staff: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END 
GO

--usp-GetStaffByID
CREATE OR ALTER PROCEDURE Get_Staff_ByID 
    @StaffID INT
AS 
BEGIN
    SET NOCOUNT ON;
    
    IF @StaffID IS NULL 
        THROW 50001, 'Staff ID is required', 1;

    IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @StaffID)
        THROW 50003, 'Staff ID not found', 1;

    SELECT 
        s.StaffID, s.FullName, s.Position, s.Address, s.Phone, s.MobileNumber, s.Gender, s.Salary, d.DepartmentID,
        d.DepartmentName, us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, r.Description,
        Specialization_Name = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN spec.SpecializationName ELSE NULL END,
        LicenseNumber = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN s.LicenseNumber ELSE NULL END
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.StaffID = @StaffID;
END
GO

--usp-GetStaffByDepartment
CREATE OR ALTER PROCEDURE Get_Staff_ByDepartment 
    @DepartmentID INT
AS 
BEGIN
    SET NOCOUNT ON;
    
    IF @DepartmentID IS NULL 
        THROW 50001, 'Department ID cannot be null', 1;

    IF NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
        THROW 50003, 'Department not found', 1;

    SELECT 
        s.StaffID, s.FullName, s.Position, s.Address, s.Phone, s.MobileNumber, s.Gender, s.Salary, d.DepartmentID,
        d.DepartmentName, us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, r.Description,
        Specialization_Name = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN spec.SpecializationName ELSE NULL END,
        LicenseNumber = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN s.LicenseNumber ELSE NULL END
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.DepartmentID = @DepartmentID AND s.IsActive = 1
    ORDER BY s.FullName;
END
GO

--usp-GetStaffBySpecialization
CREATE OR ALTER PROCEDURE Get_Staff_BySpecialization 
    @SpecializationID INT
AS 
BEGIN
    SET NOCOUNT ON;
    
    IF @SpecializationID IS NULL 
        THROW 50001, 'Specialization ID cannot be null', 1;

    IF NOT EXISTS (SELECT 1 FROM Core_system.Specializations WHERE SpecializationID = @SpecializationID)
        THROW 50003, 'Specialization not found', 1;

    SELECT 
        s.StaffID, s.FullName, s.Position, s.Address, s.Phone, s.MobileNumber, s.Gender, s.Salary, d.DepartmentID,
        d.DepartmentName, us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, r.Description,
        spec.SpecializationName,
        LicenseNumber = CASE WHEN r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') THEN s.LicenseNumber ELSE NULL END
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.SpecializationID = @SpecializationID AND s.IsActive = 1
    ORDER BY s.FullName;
END
GO

--usp-SearchStaff
CREATE OR ALTER PROCEDURE Search_Staff 
    @SearchTerm NVARCHAR(100) = NULL,
    @DepartmentID INT = NULL,
    @SpecializationID INT = NULL,
    @RoleID INT = NULL,
    @IsActive BIT = 1
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.StaffID, s.FullName, s.Position, s.Address, s.Phone, s.MobileNumber, s.Gender, s.Salary, d.DepartmentID,
        d.DepartmentName, us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, r.Description,
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
             OR s.MobileNumber LIKE '%' + @SearchTerm + '%')
        AND (@DepartmentID IS NULL OR s.DepartmentID = @DepartmentID)
        AND (@SpecializationID IS NULL OR s.SpecializationID = @SpecializationID)
        AND (@RoleID IS NULL OR us.RoleID = @RoleID)
    ORDER BY s.FullName;
END
GO

--usp-GetAllStaff
CREATE OR ALTER PROCEDURE Get_All_Staff
    @IsActive BIT = 1
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.StaffID, s.FullName, s.Position, s.Phone, s.MobileNumber, s.Gender, s.Salary, d.DepartmentID,
        d.DepartmentName, us.Email, 
        Age = DATEDIFF(YEAR, us.BrithDate, GETDATE()),
        Years_of_service = DATEDIFF(YEAR, s.HireDate, GETDATE()),
        r.RoleName, spec.SpecializationName, s.IsActive
    FROM Core_system.Staff s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    LEFT JOIN Core_system.Users us ON us.UserID = s.UserID
    LEFT JOIN Core_system.Specializations spec ON spec.SpecializationID = s.SpecializationID
    LEFT JOIN Core_system.Roles r ON r.RoleID = us.RoleID
    WHERE s.IsActive = @IsActive
    ORDER BY s.FullName;
END
GO

--usp-GetDoctorsStaff
CREATE OR ALTER PROCEDURE Get_Doctors_Staff
    @DepartmentID INT = NULL,
    @SpecializationID INT = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.StaffID, s.FullName, s.Position, s.Phone, s.MobileNumber, d.DepartmentName, 
        spec.SpecializationName, s.LicenseNumber,
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

-- =============================================
-- Patient Procedures
-- =============================================

--usp-CreatePatient
CREATE OR ALTER PROCEDURE Create_Patient
    @NationalID INT,
    @FirstName NVARCHAR(10),
    @SecondName NVARCHAR(10),
    @LastName NVARCHAR(10),
    @Gender NVARCHAR(10),
    @Phone NVARCHAR(10),
    @Email NVARCHAR(100),
    @DateOfBirth DATE,
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
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @NationalID IS NULL OR LEN(TRIM(CAST(@NationalID AS NVARCHAR(20)))) < 14
            THROW 50001, 'National ID cannot be null or less than 14 characters', 1;
            
        IF @FirstName IS NULL OR LEN(TRIM(@FirstName)) < 2 
            THROW 50002, 'First name cannot be null or less than 2 characters', 1;
            
        IF @LastName IS NULL OR LEN(TRIM(@LastName)) < 2
            THROW 50003, 'Last name cannot be null or less than 2 characters', 1;
            
        IF @Gender IS NULL
            THROW 50004, 'Gender is required', 1;
            
        IF @Phone IS NULL OR LEN(TRIM(@Phone)) < 8 
            THROW 50005, 'Phone number cannot be null or less than 8 characters', 1;
            
        IF @Email IS NULL OR LEN(TRIM(@Email)) < 5
            THROW 50006, 'Email cannot be null or less than 5 characters', 1;
            
        IF @DateOfBirth IS NULL  
            THROW 50007, 'Date of birth cannot be null', 1;
 
        IF @BloodType IS NULL 
            THROW 50001, 'Blood Type cannot be null', 1;

        IF @MobileNumber IS NULL OR LEN(TRIM(@MobileNumber)) < 10
            THROW 50009, 'Mobile number cannot be null or less than 10 characters', 1;
            
        IF @Address IS NULL OR LEN(TRIM(@Address)) < 8 
            THROW 50010, 'Address cannot be null or less than 8 characters', 1;
            
        IF @City IS NULL OR LEN(TRIM(@City)) < 2
            THROW 50011, 'City cannot be null or less than 2 characters', 1;
            
        IF @Country IS NULL OR LEN(TRIM(@Country)) < 2
            THROW 50012, 'Country cannot be null or less than 2 characters', 1;

        IF LEN(@EmergencyContactPhone) < 8
            THROW 50001, 'Emergency contact phone cannot be less than 8 characters', 1;
            
        IF LEN(@MaritalStatus) < 5
            THROW 50001, 'Marital status cannot be less than 5 characters', 1;
       
        IF EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE NationalID = @NationalID)
            THROW 50002, 'National ID already exists', 1;
            
        IF EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE Email = @Email)
            THROW 50002, 'Email already exists', 1;
            
        IF EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE Address = @Address AND City = @City AND Country = @Country)
            THROW 50002, 'Address already exists', 1;
            
        IF @DateOfBirth > CAST(GETDATE() AS DATE)
            THROW 50015, 'Date of birth cannot be in future', 1;
       
        IF @Email NOT LIKE '%_@_%_.%'
            THROW 50006, 'Invalid email format', 1;
            
        IF @Phone LIKE '%[^0-9+]%' AND @Phone IS NOT NULL
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
            @MRN, @NationalID, TRIM(@FirstName), NULLIF(TRIM(@SecondName), ''), TRIM(@LastName), 
            @DateOfBirth, @Gender, @BloodType, TRIM(@Phone), TRIM(@MobileNumber), 
            TRIM(@Email), TRIM(@Address), TRIM(@City), TRIM(@Country),
            NULLIF(TRIM(@EmergencyContactName), ''), TRIM(@EmergencyContactPhone), 
            NULLIF(TRIM(@Allergies), ''), @MaritalStatus, @IsActive
        );
        
        PRINT 'Patient created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH 
END
GO

--usp-UpdatePatient
CREATE OR ALTER PROCEDURE Update_Patient 
    @PatientID INT,
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
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID)
            THROW 50003, 'Patient not found', 1;

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
            THROW 50002, 'National ID already exists', 1;
       
        IF @Email IS NOT NULL AND EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE Email = @Email AND PatientID != @PatientID)
            THROW 50002, 'Email already exists', 1;

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

        PRINT 'Patient updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetAllPatients
CREATE OR ALTER PROCEDURE Get_All_Patients 
    @IsActive BIT = 1, 
    @StartDate DATETIME = NULL, 
    @EndDate DATETIME = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT PatientID, MRN, NationalID, FirstName, MiddleName, LastName, DateOfBirth, Gender,          
            BloodType, PhoneNumber, MobileNumber, Email, Address, City, Country,
            EmergencyContactName, EmergencyContactPhone, Allergies, MaritalStatus,      
            IsActive 
        FROM Patient_Management.Patient 
        WHERE IsActive = @IsActive 
            AND (@StartDate IS NULL OR CreatedAt >= @StartDate) 
            AND (@EndDate IS NULL OR CreatedAt <= @EndDate) 
        ORDER BY PatientID;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_All_Patients: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetPatientByID
CREATE OR ALTER PROCEDURE Get_Patient_ByID 
    @PatientID INT, 
    @MRN NVARCHAR(50) = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @PatientID IS NULL AND @MRN IS NULL 
            THROW 50001, 'Please provide PatientID or MRN', 1;
            
        SELECT PatientID, MRN, NationalID, FirstName, MiddleName, LastName, DateOfBirth, Gender, 
            BloodType, PhoneNumber, MobileNumber, Email, Address, City, Country,
            EmergencyContactName, EmergencyContactPhone, Allergies, MaritalStatus,      
            IsActive 
        FROM Patient_Management.Patient 
        WHERE PatientID = @PatientID OR MRN = @MRN 
        ORDER BY PatientID;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Patient_ByID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeletePatientByID
CREATE OR ALTER PROCEDURE Delete_Patient_ByID 
    @PatientID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID)
            THROW 50003, 'Patient not found', 1;

        IF EXISTS (SELECT 1 FROM Scheduling.Appointments WHERE PatientID = @PatientID)
            THROW 50002, 'Cannot delete patient with existing appointments', 1;

        IF EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE PatientID = @PatientID)
            THROW 50003, 'Cannot delete patient with clinical encounters', 1;

        IF EXISTS (SELECT 1 FROM Clinical_Management.Prescriptions WHERE PatientID = @PatientID)
            THROW 50004, 'Cannot delete patient with active prescriptions', 1;

        IF EXISTS (SELECT 1 FROM Inpatient_Management.Admissions WHERE PatientID = @PatientID AND Status = 'Active')
            THROW 50005, 'Cannot delete patient who is currently admitted', 1;

        UPDATE Patient_Management.Patient 
        SET IsActive = 0
        WHERE PatientID = @PatientID;

        PRINT 'Patient deactivated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Patient_ByID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-SearchPatient
CREATE OR ALTER PROCEDURE Search_Patient 
    @SearchTerm NVARCHAR(60)
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT * FROM Patient_Management.Patient pat 
        WHERE @SearchTerm IS NULL 
            OR NationalID LIKE '%' + @SearchTerm + '%'
            OR Email LIKE '%' + @SearchTerm + '%'
            OR LastName LIKE '%' + @SearchTerm + '%'
            OR FirstName LIKE '%' + @SearchTerm + '%'
            OR MRN LIKE '%' + @SearchTerm + '%'
            OR BloodType LIKE '%' + @SearchTerm + '%'
            OR PhoneNumber LIKE '%' + @SearchTerm + '%'
            OR MobileNumber LIKE '%' + @SearchTerm + '%'
            OR MaritalStatus LIKE '%' + @SearchTerm + '%'
            OR Address LIKE '%' + @SearchTerm + '%'
            OR City LIKE '%' + @SearchTerm + '%'
            OR Country LIKE '%' + @SearchTerm + '%'
        ORDER BY LastName, FirstName;
    END TRY
    BEGIN CATCH 
        PRINT 'Error in Search_Patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Patient Reports Procedures
-- =============================================

--usp-AddPatientReport
CREATE OR ALTER PROCEDURE Add_Patient_Report 
    @PatientID INT,
    @FileSize BIGINT,
    @DocumentType NVARCHAR(80),
    @FilePath NVARCHAR(500),
    @FileName NVARCHAR(50)
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;

        IF @PatientID IS NULL 
            THROW 50001, 'Patient ID is required', 1;
        
        IF @DocumentType IS NULL OR LEN(TRIM(@DocumentType)) < 2
            THROW 50002, 'Valid document type is required', 1;
            
        IF @FilePath IS NULL 
            THROW 50003, 'File path is required', 1;
        
        IF @FileName IS NULL 
            THROW 50004, 'File name is required', 1;
            
        IF @FileSize <= 0
            THROW 50006, 'Valid file size is required', 1;
        
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50003, 'Patient not found or inactive', 1;
  				
        INSERT INTO Patient_Management.Patient_Reports (
            PatientID, DocumentType, FileName, FileSize, FilePath
        )
        VALUES (
            @PatientID, @DocumentType, @FileName, @FileSize, @FilePath
        );
        
        PRINT 'Patient report added successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Add_Patient_Report: ' + ERROR_MESSAGE();
        THROW;
    END CATCH  
END
GO

--usp-GetReportsByPatientID
CREATE OR ALTER PROCEDURE Get_Reports_By_PatientID
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

--usp-GetReportByID
CREATE OR ALTER PROCEDURE Get_Report_ByID
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

--usp-DeletePatientReport
CREATE OR ALTER PROCEDURE Delete_Patient_Report
    @ReportID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient_Reports WHERE ReportID = @ReportID)
            THROW 50003, 'Report not found', 1;
        
        DELETE FROM Patient_Management.Patient_Reports 
        WHERE ReportID = @ReportID;

        PRINT 'Patient report deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Patient_Report: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Doctor Schedules Procedures
-- =============================================

--usp-AddDoctorSchedule
CREATE OR ALTER PROCEDURE Add_Doctor_Schedule 
    @DoctorID INT,
    @DayOfWeek INT = NULL,
    @SpecificDate DATE = NULL, 
    @StartTime TIME,
    @EndTime TIME,
    @SlotDuration INT,
    @MaxAppointments INT,
    @IsRecurring BIT,
    @EffectiveStart DATE,
    @EffectiveEnd DATE = NULL,
    @IsAvailable BIT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @DoctorID IS NULL 
            THROW 50001, 'Doctor ID is required', 1;
            
        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            JOIN Core_system.Users us ON s.UserID = us.UserID 
            JOIN Core_system.Roles r ON r.RoleID = us.RoleID  
            WHERE s.StaffID = @DoctorID  
            AND r.RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident') 
            AND s.IsActive = 1
        )
            THROW 50003, 'Staff member is not an active doctor', 1;
            
        IF @DayOfWeek IS NULL AND @SpecificDate IS NULL
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
            WHERE DoctorID = @DoctorID
            AND (
                (@DayOfWeek IS NOT NULL AND 
                 @DayOfWeek = DayOfTheWeek AND
                 IsRecurring = 1 AND
                 @IsRecurring = 1)
                OR
                (@SpecificDate IS NOT NULL AND
                 @SpecificDate = SpecificDate AND
                 IsRecurring = 0 AND
                 @IsRecurring = 0)
            )
            AND ((@StartTime < EndTime AND @EndTime > StartTime))
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
            @DoctorID, @DayOfWeek, @SpecificDate, @StartTime, @EndTime, 
            @SlotDuration, @MaxAppointments, @IsRecurring, @EffectiveStart, 
            @EffectiveEnd, @IsAvailable
        );
        
        PRINT 'Doctor schedule added successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Add_Doctor_Schedule: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END
GO

--usp-UpdateDoctorSchedule
CREATE OR ALTER PROCEDURE Update_Doctor_Schedule
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
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @ScheduleID IS NULL 
            THROW 50001, 'Schedule ID is required', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Scheduling.DoctorsSchedules WHERE ScheduleID = @ScheduleID)
            THROW 50003, 'Schedule not found', 1;
        
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
                AND ((COALESCE(@StartTime, StartTime) < COALESCE(@EndTime, EndTime) AND
                     COALESCE(@EndTime, EndTime) > COALESCE(@StartTime, StartTime)))
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
        
        PRINT 'Doctor schedule updated successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Doctor_Schedule: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END
GO

--usp-DeleteDoctorSchedule
CREATE OR ALTER PROCEDURE Delete_Doctor_Schedule 
    @ScheduleID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @ScheduleID IS NULL 
            THROW 50001, 'Schedule ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Scheduling.DoctorsSchedules WHERE ScheduleID = @ScheduleID)
            THROW 50003, 'Schedule ID not found', 1;
        
        IF EXISTS (
            SELECT 1 FROM Scheduling.Appointments ap 
            WHERE ap.PhysicianID = (SELECT DoctorID FROM Scheduling.DoctorsSchedules WHERE ScheduleID = @ScheduleID)
            AND ap.Status IN ('Scheduled', 'Confirmed', 'In Progress') 
            AND ap.AppointmentDateTime >= GETDATE()
        )
            THROW 50004, 'Cannot delete schedule with future appointments', 1;

        DELETE FROM Scheduling.DoctorsSchedules WHERE ScheduleID = @ScheduleID;

        PRINT 'Doctor schedule deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Doctor_Schedule: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetScheduleByDoctor
CREATE OR ALTER PROCEDURE Get_Schedule_By_Doctor 
    @DoctorID INT = NULL,
    @ScheduleID INT = NULL
AS 
BEGIN
    IF (@DoctorID IS NULL AND @ScheduleID IS NULL) OR (@DoctorID IS NOT NULL AND @ScheduleID IS NOT NULL)   
        THROW 50001, 'Provide either Doctor ID OR Schedule ID (not both)', 1;
    
    IF @DoctorID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Core_system.Staff WHERE StaffID = @DoctorID AND IsActive = 1
    )
        THROW 50003, 'Doctor not found', 1;
    
    SELECT DS.ScheduleID, DS.DoctorID, DS.DayOfTheWeek, DS.StartTime,
           DS.EndTime, DS.EffectiveStart, DS.EffectiveEnd, DS.IsAvalibale, 
           DS.IsRecurring, DS.MaxAppointments 
    FROM Scheduling.DoctorsSchedules DS 
    WHERE (@DoctorID IS NOT NULL AND DS.DoctorID = @DoctorID)
       OR (@ScheduleID IS NOT NULL AND DS.ScheduleID = @ScheduleID);
END
GO

--usp-GetAllDoctorSchedules
CREATE OR ALTER PROCEDURE Get_All_Doctor_Schedules 
    @StartDate DATETIME = NULL, 
    @EndDate DATETIME = NULL
AS 
BEGIN
    SELECT DS.ScheduleID, DS.DoctorID, S.FullName, DS.DayOfTheWeek, DS.StartTime,
        DS.EndTime, DS.EffectiveStart, DS.EffectiveEnd, DS.IsAvalibale, DS.IsRecurring, DS.MaxAppointments 
    FROM Scheduling.DoctorsSchedules DS 
    INNER JOIN Core_system.Staff S ON DS.DoctorID = S.StaffID
    WHERE (@StartDate IS NULL OR DS.EffectiveStart >= @StartDate) 
        AND (@EndDate IS NULL OR DS.EffectiveEnd < @EndDate) 
        AND IsAvalibale = 1
    ORDER BY S.FullName, DS.EffectiveStart, DS.DayOfTheWeek, DS.StartTime;
END
GO

--usp-GetAvailableSlotsDoctorSchedule
CREATE OR ALTER PROCEDURE Get_Available_Slots_Doctor_Schedule
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
        COUNT(A.AppointmentID) AS BookedAppointments,
        DS.MaxAppointments - COUNT(A.AppointmentID) AS AvailableSlots
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
    HAVING COUNT(A.AppointmentID) < DS.MaxAppointments
    ORDER BY DS.StartTime;
END
GO

-- =============================================
-- Appointment Procedures 
-- =============================================

--usp-CreateAppointment
CREATE OR ALTER PROCEDURE Create_Appointment 
    @PatientID INT, 
    @PhysicianID INT, 
    @AppointmentDateTime DATETIME, 
    @DepartmentID INT,
    @Status NVARCHAR(20),
    @Duration INT,
    @Priority NVARCHAR(30),
    @Complaint NVARCHAR(30)
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @PatientID IS NULL OR @PhysicianID IS NULL OR @AppointmentDateTime IS NULL
            THROW 50001, 'PatientID, PhysicianID, and AppointmentDateTime are required', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50003, 'Patient not found or inactive', 1;
            
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
            WHERE PhysicianID = @PhysicianID 
            AND AppointmentDateTime = @AppointmentDateTime    
            AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
        )
            THROW 50005, 'Doctor has appointment at this time', 1;
            
        IF EXISTS (
            SELECT 1 FROM Scheduling.Appointments 
            WHERE PatientID = @PatientID 
            AND AppointmentDateTime = @AppointmentDateTime    
            AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
        )
            THROW 50005, 'Patient has appointment at this time', 1;

        INSERT INTO Scheduling.Appointments (
            PatientID, PhysicianID, DepartmentID, AppointmentDateTime, Status,
            Duration, Priority, Complaint
        )
        VALUES (
            @PatientID, @PhysicianID, @DepartmentID, @AppointmentDateTime, @Status,
            @Duration, @Priority, @Complaint
        );

        PRINT 'Appointment created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Appointment: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateAppointment
CREATE OR ALTER PROCEDURE Update_Appointment 
    @AppointmentID INT,
    @PatientID INT = NULL, 
    @PhysicianID INT = NULL, 
    @AppointmentDateTime DATETIME = NULL, 
    @DepartmentID INT = NULL,
    @Status NVARCHAR(20) = NULL,
    @Duration INT = NULL,
    @Priority NVARCHAR(30) = NULL,
    @Complaint NVARCHAR(30) = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
  
        IF NOT EXISTS (SELECT 1 FROM Scheduling.Appointments WHERE AppointmentID = @AppointmentID)
            THROW 50003, 'Appointment not found', 1;
            
        IF @PhysicianID IS NOT NULL AND NOT EXISTS (
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

        IF @PhysicianID IS NOT NULL AND @AppointmentDateTime IS NOT NULL AND NOT EXISTS (
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

        IF @PhysicianID IS NOT NULL AND @AppointmentDateTime IS NOT NULL AND EXISTS (
            SELECT 1 FROM Scheduling.Appointments 
            WHERE PhysicianID = @PhysicianID 
            AND AppointmentDateTime = @AppointmentDateTime    
            AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
            AND AppointmentID != @AppointmentID
        )
            THROW 50005, 'Doctor has appointment at this time', 1;
            
        IF @PatientID IS NOT NULL AND @AppointmentDateTime IS NOT NULL AND EXISTS (
            SELECT 1 FROM Scheduling.Appointments 
            WHERE PatientID = @PatientID 
            AND AppointmentDateTime = @AppointmentDateTime    
            AND Status IN ('Scheduled', 'Confirmed', 'In Progress')
            AND AppointmentID != @AppointmentID
        )
            THROW 50005, 'Patient has appointment at this time', 1;
            
        UPDATE Scheduling.Appointments
        SET 
            AppointmentDateTime = COALESCE(@AppointmentDateTime, AppointmentDateTime),
            Duration = COALESCE(@Duration, Duration),
            Status = COALESCE(@Status, Status),
            Priority = COALESCE(@Priority, Priority),
            Complaint = COALESCE(@Complaint, Complaint),
            PhysicianID = COALESCE(@PhysicianID, PhysicianID),
            PatientID = COALESCE(@PatientID, PatientID),
            DepartmentID = COALESCE(@DepartmentID, DepartmentID)
        WHERE AppointmentID = @AppointmentID;

        PRINT 'Appointment updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Appointment: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteAppointment
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
            THROW 50003, 'Appointment not found', 1;

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

        PRINT 'Appointment cancelled successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Appointment: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-RescheduleAppointment
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
            THROW 50003, 'Appointment not found', 1;

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

        PRINT 'Appointment rescheduled successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Reschedule_Appointment: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-GetAppointmentsByDoctor
CREATE OR ALTER PROCEDURE Get_Appointments_By_Doctor 
    @DoctorID INT, 
    @AppointmentDate DATE 
AS 
BEGIN
    SET NOCOUNT ON;
    SELECT 
        ap.AppointmentID,
        ap.AppointmentDateTime,
        ap.Status,
        ap.Priority,
        ap.Duration,
        ap.Complaint,
        p.PatientID,
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.Gender,
        DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
        p.PhoneNumber,
        p.Email,
        st.StaffID AS DoctorID,
        st.FullName AS DoctorName,
        st.Position 
    FROM Scheduling.Appointments ap 
    JOIN Core_system.Staff st ON ap.PhysicianID = st.StaffID 
    JOIN Patient_Management.Patient p ON ap.PatientID = p.PatientID 
    WHERE CAST(ap.AppointmentDateTime AS DATE) = @AppointmentDate  
        AND (@DoctorID IS NULL OR ap.PhysicianID = @DoctorID)
    ORDER BY ap.AppointmentDateTime ASC;
END
GO

--usp-GetAppointmentDetails
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
        s.FullName AS PhysicianName,
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
    INNER JOIN Core_system.Departments d ON a.DepartmentID = d.DepartmentID
    WHERE (@AppointmentID IS NULL OR a.AppointmentID = @AppointmentID)
      AND (@PatientID IS NULL OR a.PatientID = @PatientID)
      AND (@PhysicianID IS NULL OR a.PhysicianID = @PhysicianID)
      AND CAST(a.AppointmentDateTime AS DATE) BETWEEN @StartDate AND @EndDate
    ORDER BY a.AppointmentDateTime ASC;
END;
GO

-- =============================================
-- Patient Queue Procedures
-- =============================================

--usp-CheckInPatientToQueue
CREATE OR ALTER PROCEDURE CheckIn_Patient_To_Queue
    @PatientID INT,
    @DoctorID INT,
    @DepartmentID INT,
    @AppointmentID INT = NULL,
    @Priority NVARCHAR(20) = 'Normal',
    @ArrivalMethod NVARCHAR(20) = 'Walk-in',
    @ChiefComplaint NVARCHAR(500) = NULL,
    @CheckInCounter NVARCHAR(20) = NULL,
    @CheckInByStaffID INT
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
            THROW 50001, 'CheckInByStaffID is required', 1;
    
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID)
            THROW 50003, 'Patient not found', 1;
            
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
            THROW 50003, 'Department not found', 1;

        IF EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue
            WHERE PatientID = @PatientID
              AND QueueDate = @QueueDate
              AND Status IN ('Waiting', 'Called', 'InProgress')
        )
            THROW 50007, 'Patient is already in queue today', 1;

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

        SET @EstimatedWait = @PatientsAhead * ISNULL(@AvgConsultTime, 20);
        
        DECLARE @QueueNumber NVARCHAR(20);
        SET @QueueNumber = @QueuePrefix + FORMAT(@NextSequence, '000') + '-' + FORMAT(CAST(RIGHT(CAST(NEWID() AS NVARCHAR(36)), 3) AS INT), '000');

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
            @PatientsAhead + 1, 
            @EstimatedWait,
            @CheckInByStaffID,
            GETDATE()
        );

        PRINT 'Patient checked in to queue successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in CheckIn_Patient_To_Queue: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-UpdateQueuePositions
CREATE OR ALTER PROCEDURE Update_Queue_Positions
    @DoctorID INT,
    @QueueDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @QueueDate IS NULL
        SET @QueueDate = CAST(GETDATE() AS DATE);
    
    UPDATE Clinical_Management.PatientQueue
    SET CurrentPosition = NULL
    WHERE DoctorID = @DoctorID
      AND QueueDate = @QueueDate
      AND Status IN ('Called', 'InProgress', 'Completed', 'Cancelled', 'NoShow', 'Transferred');
    
    WITH RankedQueue AS (
        SELECT 
            QueueID,
            ROW_NUMBER() OVER (ORDER BY CheckInTime ASC) AS NewPosition
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

--usp-CallNextPatientQueue
CREATE OR ALTER PROCEDURE Call_Next_Patient_Queue
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
            @PatientID = PatientID
        FROM Clinical_Management.PatientQueue
        WHERE DoctorID = @DoctorID
          AND QueueDate = @QueueDate
          AND Status = 'Waiting'
        ORDER BY CheckInTime ASC;

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
        WHERE PatientID = @PatientID;

        UPDATE Clinical_Management.PatientQueue
        SET Status = 'Called',
            CalledTime = GETDATE()
        WHERE QueueID = @QueueID;

        EXEC Update_Queue_Positions @DoctorID, @QueueDate;
        
        PRINT 'Patient called successfully';
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
        PRINT 'Error in Call_Next_Patient_Queue: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-GetDoctorQueue
CREATE OR ALTER PROCEDURE Get_Doctor_Queue 
    @DoctorID INT,
    @QueueDate DATE = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @QueueDate IS NULL
            SET @QueueDate = CAST(GETDATE() AS DATE);

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @DoctorID AND IsActive = 1)
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
        INNER JOIN Patient_Management.Patient p ON pq.PatientID = p.PatientID
        WHERE pq.DoctorID = @DoctorID 
          AND pq.QueueDate = @QueueDate 
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
        PRINT 'Error in Get_Doctor_Queue: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-CancelQueueEntry
CREATE OR ALTER PROCEDURE Cancel_Queue_Entry
    @QueueID INT,
    @StaffID INT,
    @Reason NVARCHAR(200) = NULL
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
            THROW 50003, 'Queue entry not found', 1;

        UPDATE Clinical_Management.PatientQueue
        SET Status = 'Cancelled'
        WHERE QueueID = @QueueID;

        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'Cancelled'
            WHERE AppointmentID = @AppointmentID;
        END

        EXEC Update_Queue_Positions @DoctorID, @QueueDate;

        PRINT 'Queue entry cancelled successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Cancel_Queue_Entry: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-MarkPatientNoShow
CREATE OR ALTER PROCEDURE Mark_Patient_No_Show
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
            THROW 50003, 'Queue entry not found', 1;

        UPDATE Clinical_Management.PatientQueue
        SET Status = 'NoShow'
        WHERE QueueID = @QueueID;

        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'No Show'
            WHERE AppointmentID = @AppointmentID;
        END

        EXEC Update_Queue_Positions @DoctorID, @QueueDate;

        PRINT 'Patient marked as No Show';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Mark_Patient_No_Show: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- =============================================
-- Encounter Procedures
-- =============================================

--usp-StartConsultation
CREATE OR ALTER PROCEDURE Start_Consultation
    @QueueID INT,
    @StaffID INT,
    @ChiefComplaint NVARCHAR(500) = NULL,
    @EstimatedDuration INT = 30,
    @VisitType NVARCHAR(20) = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @PatientID INT;
        DECLARE @DoctorID INT;
        DECLARE @AppointmentID INT;
        DECLARE @DepartmentID INT;
        DECLARE @EncounterNumber NVARCHAR(20);
        DECLARE @QueueDate DATE;
        DECLARE @StartTime DATETIME2 = GETDATE();
        DECLARE @EndTime DATETIME2;
        
        IF @QueueID IS NULL OR @StaffID IS NULL
            THROW 50001, 'QueueID and StaffID are required', 1;
        
        IF NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue 
            WHERE QueueID = @QueueID 
            AND Status IN ('Waiting', 'Called')
        )
            THROW 50003, 'Queue entry not found or not in valid status for consultation', 1;
        
        IF EXISTS (
            SELECT 1 
            FROM Clinical_Management.PatientQueue 
            WHERE DoctorID = (SELECT DoctorID FROM Clinical_Management.PatientQueue WHERE QueueID = @QueueID)
            AND Status = 'InProgress'
            AND QueueID != @QueueID
        )
            THROW 50003, 'Doctor already has a patient in consultation', 1;
        
        SELECT 
            @PatientID = PatientID,
            @DoctorID = DoctorID,
            @AppointmentID = AppointmentID,
            @DepartmentID = DepartmentID,
            @QueueDate = QueueDate
        FROM Clinical_Management.PatientQueue
        WHERE QueueID = @QueueID;
        
        IF @AppointmentID IS NOT NULL
        BEGIN
            SELECT @VisitType = VisitType
            FROM Scheduling.Appointments
            WHERE AppointmentID = @AppointmentID;
        END
        
        IF @VisitType IS NULL
            SET @VisitType = 'Follow-up';
  
        IF @ChiefComplaint IS NULL AND @AppointmentID IS NOT NULL
        BEGIN
            SELECT @ChiefComplaint = Complaint
            FROM Scheduling.Appointments
            WHERE AppointmentID = @AppointmentID;
        END
        
        SET @EndTime = DATEADD(MINUTE, @EstimatedDuration, @StartTime);
        
        DECLARE @DatePart NVARCHAR(8) = FORMAT(GETDATE(), 'yyyyMMdd');
        DECLARE @SequencePart INT;
        
        SELECT @SequencePart = ISNULL(MAX(CAST(RIGHT(EncounterNumber, 5) AS INT)), 0) + 1
        FROM Clinical_Management.Encounters
        WHERE EncounterNumber LIKE 'ENC' + @DatePart + '%';
        
        SET @EncounterNumber = 'ENC' + @DatePart + RIGHT('00000' + CAST(@SequencePart AS VARCHAR), 5);
     
        DECLARE @EncounterID INT;
        INSERT INTO Clinical_Management.Encounters (
            EncounterNumber, 
            PatientID, 
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
       
        UPDATE Clinical_Management.PatientQueue
        SET Status = 'InProgress',
            ConsultationStartTime = @StartTime
        WHERE QueueID = @QueueID;
    
        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'In Progress'
            WHERE AppointmentID = @AppointmentID;
        END
     
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
        
        EXEC Update_Queue_Positions @DoctorID, @QueueDate;
        
        PRINT 'Consultation started successfully';
        COMMIT TRANSACTION;
        
        SELECT 
            @EncounterID AS EncounterID,
            @EncounterNumber AS EncounterNumber,
            'Consultation started successfully' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Start_Consultation: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-CompleteConsultation
CREATE OR ALTER PROCEDURE Complete_Consultation
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
            THROW 50003, 'Queue entry not found', 1;
            
        IF @CurrentQueueStatus != 'InProgress'
            THROW 50003, 'Cannot complete consultation that is not in progress', 1;

        SELECT @CurrentEncounterStatus = Status
        FROM Clinical_Management.Encounters
        WHERE EncounterID = @EncounterID;
        
        IF @CurrentEncounterStatus IS NULL
            THROW 50003, 'Encounter not found', 1;
            
        IF @CurrentEncounterStatus != 'Active'
            THROW 50003, 'Cannot complete encounter that is not active', 1;
        
        UPDATE Clinical_Management.PatientQueue
        SET Status = 'Completed',
            ConsultationEndTime = GETDATE()
        WHERE QueueID = @QueueID;

        UPDATE Clinical_Management.Encounters
        SET Status = 'Completed',
            EndDateTime = GETDATE()
        WHERE EncounterID = @EncounterID;

        IF OBJECT_ID('Outpatient_Management.OPD_Visit') IS NOT NULL
        BEGIN
            UPDATE Outpatient_Management.OPD_Visit
            SET VisitStatus = 'Completed'
            WHERE EncounterID = @EncounterID;
        END
  
        IF @AppointmentID IS NOT NULL
        BEGIN
            UPDATE Scheduling.Appointments
            SET Status = 'Completed'
            WHERE AppointmentID = @AppointmentID;
        END

        EXEC Update_Queue_Positions @DoctorID, @QueueDate;
        
        PRINT 'Consultation completed successfully';
        COMMIT TRANSACTION;

        SELECT 
            @QueueID AS QueueID,
            @EncounterID AS EncounterID,
            'Consultation completed successfully' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Complete_Consultation: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- =============================================
-- Vital Signs Procedures
-- =============================================

--usp-CreateVitalSigns
CREATE OR ALTER PROCEDURE Create_Vital_Signs
    @EncounterID INT,
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
    @RecordedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @EncounterID IS NULL OR @RecordedBy IS NULL
            THROW 50001, 'EncounterID and RecordedBy are required', 1;

        IF NOT EXISTS (
            SELECT 1 FROM Clinical_Management.Encounters 
            WHERE EncounterID = @EncounterID AND Status = 'Active'
        )
            THROW 50003, 'Active encounter not found', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @RecordedBy AND IsActive = 1)
            THROW 50003, 'Recording staff not found or inactive', 1;

        IF @RespiratoryRate IS NOT NULL AND (@RespiratoryRate < 6 OR @RespiratoryRate > 60)
            THROW 50006, 'Respiratory rate must be between 6 and 60 breaths/min', 1;

        IF @OxygenSaturation IS NOT NULL AND (@OxygenSaturation < 70 OR @OxygenSaturation > 100)
            THROW 50007, 'Oxygen saturation must be between 70% and 100%', 1;

        IF @PainScore IS NOT NULL AND (@PainScore < 0 OR @PainScore > 10)
            THROW 50008, 'Pain score must be between 0 and 10', 1;

        INSERT INTO Clinical_Management.VitalSigns (
            EncounterID,
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
            @EncounterID,
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

        PRINT 'Vital signs recorded successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Vital_Signs: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-GetVitalSignsByEncounter
CREATE OR ALTER PROCEDURE Get_Vital_Signs_By_Encounter
    @EncounterID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE EncounterID = @EncounterID)
    BEGIN
        SELECT 'Encounter not found' AS Message;
        RETURN;
    END

    SELECT 
        vs.VitalSignID,
        vs.EncounterID,
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
    INNER JOIN Core_system.Staff s ON vs.RecordedBy = s.StaffID
    WHERE vs.EncounterID = @EncounterID
    ORDER BY vs.RecordedAt DESC;
END;
GO

--usp-UpdateVitalSigns
CREATE OR ALTER PROCEDURE Update_Vital_Signs
    @VitalSignID INT,
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

        IF @VitalSignID IS NULL OR @UpdatedBy IS NULL
            THROW 50001, 'VitalSignID and UpdatedBy are required', 1;

        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.VitalSigns WHERE VitalSignID = @VitalSignID)
            THROW 50003, 'Vital signs record not found', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @UpdatedBy AND IsActive = 1)
            THROW 50003, 'Updating staff not found or inactive', 1;

        IF @PainScore IS NOT NULL AND (@PainScore < 0 OR @PainScore > 10)
            THROW 50006, 'Pain score must be between 0 and 10', 1;

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
            RecordedBy = @UpdatedBy,
            RecordedAt = GETDATE()
        WHERE VitalSignID = @VitalSignID;

        PRINT 'Vital signs updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Vital_Signs: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

--usp-GetPatientVitalSignsHistory
CREATE OR ALTER PROCEDURE Get_Patient_Vital_Signs_History
    @PatientID INT,
    @DaysBack INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
    BEGIN
        SELECT 'Patient not found' AS Message;
        RETURN;
    END

    SELECT 
        vs.VitalSignID,
        vs.EncounterID,
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
        LAG(vs.HeartRate) OVER (PARTITION BY e.PatientID ORDER BY vs.RecordedAt) AS PreviousHeartRate,
        LAG(vs.BloodPressure) OVER (PARTITION BY e.PatientID ORDER BY vs.RecordedAt) AS PreviousBloodPressure,
        LAG(vs.Temperature) OVER (PARTITION BY e.PatientID ORDER BY vs.RecordedAt) AS PreviousTemperature
    FROM Clinical_Management.VitalSigns vs
    INNER JOIN Clinical_Management.Encounters e ON vs.EncounterID = e.EncounterID
    INNER JOIN Core_system.Staff s ON vs.RecordedBy = s.StaffID
    INNER JOIN Core_system.Staff doc ON e.PhysicianID = doc.StaffID
    WHERE e.PatientID = @PatientID
      AND vs.RecordedAt >= DATEADD(DAY, -@DaysBack, GETDATE())
    ORDER BY vs.RecordedAt DESC;
END;
GO

--usp-DeleteVitalSigns
CREATE OR ALTER PROCEDURE Delete_Vital_Signs
    @VitalSignID INT,
    @DeletedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @VitalSignID IS NULL OR @DeletedBy IS NULL
            THROW 50001, 'VitalSignID and DeletedBy are required', 1;

        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.VitalSigns WHERE VitalSignID = @VitalSignID)
            THROW 50003, 'Vital signs record not found', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @DeletedBy AND IsActive = 1)
            THROW 50003, 'Staff not authorized to delete vital signs', 1;

        IF EXISTS (
            SELECT 1 FROM Clinical_Management.VitalSigns vs
            INNER JOIN Clinical_Management.Encounters e ON vs.EncounterID = e.EncounterID
            WHERE vs.VitalSignID = @VitalSignID AND e.Status = 'Active'
        )
            THROW 50004, 'Cannot delete vital signs for active encounter', 1;

        DELETE FROM Clinical_Management.VitalSigns 
        WHERE VitalSignID = @VitalSignID;

        PRINT 'Vital signs record deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Vital_Signs: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- =============================================
-- Diagnosis Procedures
-- =============================================

--usp-CreateDiagnosis
CREATE OR ALTER PROCEDURE Create_Diagnosis 
    @EncounterID INT, 
    @PatientID INT, 
    @DiagnosisCode NVARCHAR(20),  
    @DiagnosisDescription NVARCHAR(500),
    @DiagnosisType NVARCHAR(50),
    @Status NVARCHAR(40), 
    @DiagnosedBy INT,
    @Notes NVARCHAR(1000)
AS 
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @EncounterID IS NULL OR @DiagnosedBy IS NULL OR @PatientID IS NULL 
            THROW 50001, 'Encounter ID, Doctor ID and Patient ID are required', 1;
   
        IF @DiagnosisDescription IS NULL OR @DiagnosisType IS NULL 
            THROW 50001, 'Diagnosis Type and Description are required', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.Encounters 
            WHERE EncounterID = @EncounterID 
            AND PatientID = @PatientID
        )
            THROW 50003, 'Encounter not found or does not belong to the specified patient', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Patient_Management.Patient 
            WHERE PatientID = @PatientID 
            AND IsActive = 1
        )
            THROW 50003, 'Patient not found or inactive', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffID = @DiagnosedBy 
            AND s.IsActive = 1
            AND u.RoleID IN (
                SELECT RoleID 
                FROM Core_system.Roles 
                WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
            )
        )
        THROW 50003, 'Diagnosing staff must be an active medical doctor', 1;

        INSERT INTO Clinical_Management.Diagnoses(
            EncounterID,
            PatientID,
            DiagnosisCode,
            DiagnosisDescription,
            DiagnosisType,
            Status,
            DiagnosedBy,
            Notes
        )
        VALUES(
            @EncounterID,
            @PatientID,
            @DiagnosisCode,
            @DiagnosisDescription,
            @DiagnosisType,
            @Status,
            @DiagnosedBy,
            @Notes
        );
        
        PRINT 'Diagnosis created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Diagnosis: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateDiagnosis
CREATE OR ALTER PROCEDURE Update_Diagnosis
    @DiagnosisID INT, 
    @EncounterID INT = NULL, 
    @PatientID INT = NULL, 
    @DiagnosisCode NVARCHAR(20)= NULL,  
    @DiagnosisDescription NVARCHAR(500)= NULL,
    @DiagnosisType NVARCHAR(50)= NULL,
    @Status NVARCHAR(40)= NULL, 
    @DiagnosedBy INT = NULL,
    @Notes NVARCHAR(1000)= NULL 
AS 
BEGIN 
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @DiagnosisID IS NULL
            THROW 50001, 'Diagnosis ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.Diagnoses WHERE DiagnosisID = @DiagnosisID)
            THROW 50003, 'Diagnosis not found', 1;

        IF @EncounterID IS NOT NULL AND NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.Encounters 
            WHERE EncounterID = @EncounterID 
            AND PatientID = @PatientID
        )
            THROW 50003, 'Encounter not found or does not belong to the specified patient', 1;

        IF @PatientID IS NOT NULL AND NOT EXISTS (
            SELECT 1 
            FROM Patient_Management.Patient 
            WHERE PatientID = @PatientID 
            AND IsActive = 1
        )
            THROW 50003, 'Patient not found or inactive', 1;

        IF @DiagnosedBy IS NOT NULL AND NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffID = @DiagnosedBy 
            AND s.IsActive = 1
            AND u.RoleID IN (
                SELECT RoleID 
                FROM Core_system.Roles 
                WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
            )
        )
        THROW 50003, 'Diagnosing staff must be an active medical doctor', 1;

        UPDATE Clinical_Management.Diagnoses 
        SET EncounterID = COALESCE(@EncounterID, EncounterID),
            PatientID = COALESCE(@PatientID, PatientID),
            DiagnosisCode = COALESCE(@DiagnosisCode, DiagnosisCode),
            DiagnosisDescription = COALESCE(@DiagnosisDescription, DiagnosisDescription),
            DiagnosisType = COALESCE(@DiagnosisType, DiagnosisType),
            Status = COALESCE(@Status, Status),
            DiagnosedBy = COALESCE(@DiagnosedBy, DiagnosedBy),
            Notes = COALESCE(@Notes, Notes)   
        WHERE DiagnosisID = @DiagnosisID;

        PRINT 'Diagnosis updated successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Diagnosis: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetDiagnosisByPatient
CREATE OR ALTER PROCEDURE Get_Diagnosis_By_Patient 
    @PatientID INT 
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        IF @PatientID IS NULL 
            THROW 50001, 'Patient ID is required', 1;

        IF NOT EXISTS( 
            SELECT 1 FROM Patient_Management.Patient 
            WHERE PatientID = @PatientID AND IsActive = 1
        )
            THROW 50003, 'Patient ID does not exist or is not active', 1;

        SELECT  
            Di.DiagnosisID,
            Di.EncounterID,
            Di.PatientID,
            Di.DiagnosisCode,
            Di.DiagnosisDescription,
            Di.DiagnosisType,
            Di.Status,
            Di.DiagnosedBy,
            Di.Notes,
            pa.FirstName + ' '+ pa.LastName AS PatientName,
            Pa.MRN,
            DATEDIFF(YEAR, Pa.DateOfBirth, GETDATE()) AS Age,
            Pa.Gender
        FROM Clinical_Management.Diagnoses Di 
        JOIN Patient_Management.Patient Pa ON Di.PatientID = Pa.PatientID
        WHERE Di.PatientID = @PatientID 
        ORDER BY Di.DiagnosisDate;
    END TRY
    BEGIN CATCH 
        PRINT 'Error in Get_Diagnosis_By_Patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetDiagnosisByEncounter
CREATE OR ALTER PROCEDURE Get_Diagnosis_By_Encounter 
    @EncounterID INT 
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        IF @EncounterID IS NULL 
            THROW 50001, 'EncounterID is required', 1;

        IF NOT EXISTS( 
            SELECT 1 FROM Clinical_Management.Encounters 
            WHERE EncounterID = @EncounterID 
        )
            THROW 50003, 'Encounter ID does not exist', 1;

        SELECT  
            Di.DiagnosisID,
            Di.EncounterID,
            Di.PatientID,
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
            pa.FirstName + ' '+ pa.LastName AS PatientName,
            Pa.MRN,
            DATEDIFF(YEAR, Pa.DateOfBirth, GETDATE()) AS Age,
            Pa.Gender
        FROM Clinical_Management.Diagnoses Di 
        JOIN Patient_Management.Patient Pa ON Di.PatientID = Pa.PatientID
        JOIN Clinical_Management.Encounters En ON En.EncounterID = Di.EncounterID 
        WHERE En.EncounterID = @EncounterID 
        ORDER BY En.EncounterDate, Di.DiagnosisDate;
    END TRY   
    BEGIN CATCH 
        PRINT 'Error in Get_Diagnosis_By_Encounter: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetDiagnosisByID
CREATE OR ALTER PROCEDURE Get_Diagnosis_By_ID 
    @DiagnosisID INT 
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        IF @DiagnosisID IS NULL 
            THROW 50001, 'Diagnosis ID is required', 1;

        IF NOT EXISTS( 
            SELECT 1 FROM Clinical_Management.Diagnoses 
            WHERE DiagnosisID = @DiagnosisID 
        )
            THROW 50003, 'Diagnosis ID does not exist', 1;

        SELECT  
            Di.DiagnosisID,
            Di.EncounterID,
            Di.PatientID,
            Di.DiagnosisCode,
            Di.DiagnosisDescription,
            Di.DiagnosisType,
            Di.Status,
            Di.DiagnosedBy,
            Di.Notes
        FROM Clinical_Management.Diagnoses Di 
        WHERE Di.DiagnosisID = @DiagnosisID
        ORDER BY Di.DiagnosisDate;
    END TRY   
    BEGIN CATCH 
        PRINT 'Error in Get_Diagnosis_By_ID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteDiagnosis
CREATE OR ALTER PROCEDURE Delete_Diagnosis 
    @DiagnosisID INT 
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @DiagnosisID IS NULL 
            THROW 50001, 'Diagnosis ID is required', 1;

        IF NOT EXISTS( 
            SELECT 1 FROM Clinical_Management.Diagnoses 
            WHERE DiagnosisID = @DiagnosisID 
        )
            THROW 50003, 'Diagnosis ID does not exist', 1;

        DELETE FROM Clinical_Management.Diagnoses  
        WHERE DiagnosisID = @DiagnosisID;

        PRINT 'Diagnosis deleted successfully';
        COMMIT TRANSACTION;
    END TRY   
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Diagnosis: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Prescription Procedures
-- =============================================

--usp-CreatePrescription
CREATE OR ALTER PROCEDURE Create_Prescription 
    @PatientID INT NOT NULL,
    @MedicationID INT NULL,
    @EncounterID INT NOT NULL,
    @MedicationName NVARCHAR(200) NULL,
    @PrescribedBy INT NOT NULL,
    @Dosage NVARCHAR(100) NOT NULL, 
    @Frequency NVARCHAR(50) NOT NULL,
    @Duration INT NOT NULL,
    @Quantity INT NOT NULL,
    @Instructions NVARCHAR(200),
    @StartDate DATE,
    @Status NVARCHAR(20)
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY 
        BEGIN TRANSACTION;
        
        IF @EncounterID IS NULL OR @PrescribedBy IS NULL OR @PatientID IS NULL 
            THROW 50001, 'Encounter ID, Doctor ID and Patient ID are required', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.Encounters 
            WHERE EncounterID = @EncounterID 
            AND PatientID = @PatientID
        )
            THROW 50003, 'Encounter not found or does not belong to the specified patient', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Patient_Management.Patient 
            WHERE PatientID = @PatientID 
            AND IsActive = 1
        )
            THROW 50003, 'Patient not found or inactive', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffID = @PrescribedBy 
            AND s.IsActive = 1
            AND u.RoleID IN (
                SELECT RoleID 
                FROM Core_system.Roles 
                WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
            )
        )
        THROW 50003, 'Prescribing staff must be an active medical doctor', 1;

        IF @MedicationID IS NULL AND @MedicationName IS NULL 
            THROW 50001, 'Provide either Medication ID or Name', 1;
            
        IF @Dosage IS NULL OR @Frequency IS NULL OR @Duration IS NULL OR @Quantity IS NULL
            THROW 50001, 'Dosage, Frequency, Duration and Quantity are required', 1;

        IF @StartDate IS NULL
            SET @StartDate = GETDATE();

        IF @Status IS NULL
            SET @Status = 'Active';

        INSERT INTO Clinical_Management.Prescriptions(
            PatientID,
            MedicationID,
            EncounterID,
            MedicationName,
            PrescribedBy,
            Dosage,
            Frequency,
            Duration,
            Quantity,
            Instructions,
            StartDate,
            Status
        )
        VALUES(
            @PatientID,
            @MedicationID,
            @EncounterID,
            @MedicationName,
            @PrescribedBy,
            @Dosage,
            @Frequency,
            @Duration,
            @Quantity,
            @Instructions,
            @StartDate,
            @Status
        );

        PRINT 'Prescription created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Prescription: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdatePrescription
CREATE OR ALTER PROCEDURE Update_Prescription
    @PrescriptionID INT,
    @PatientID INT = NULL,
    @MedicationID INT = NULL,
    @EncounterID INT = NULL,
    @MedicationName NVARCHAR(200) = NULL,
    @PrescribedBy INT = NULL,
    @Dosage NVARCHAR(100) = NULL,
    @Frequency NVARCHAR(50) = NULL,
    @Duration INT = NULL,
    @Quantity INT = NULL,
    @Instructions NVARCHAR(200) = NULL,
    @StartDate DATE = NULL,
    @Status NVARCHAR(20) = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @PrescriptionID IS NULL
            THROW 50001, 'Prescription ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.Prescriptions WHERE PrescriptionID = @PrescriptionID)
            THROW 50003, 'Prescription not found', 1;

        IF @EncounterID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE EncounterID = @EncounterID)
            THROW 50003, 'Encounter not found', 1;

        IF @PatientID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50003, 'Patient not found or inactive', 1;

        IF @PrescribedBy IS NOT NULL AND NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffID = @PrescribedBy 
            AND s.IsActive = 1
            AND u.RoleID IN (
                SELECT RoleID 
                FROM Core_system.Roles 
                WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
            )
        )
            THROW 50003, 'Prescribing staff must be an active medical doctor', 1;

        UPDATE Clinical_Management.Prescriptions
        SET PatientID = COALESCE(@PatientID, PatientID),
            MedicationID = COALESCE(@MedicationID, MedicationID),
            EncounterID = COALESCE(@EncounterID, EncounterID),
            MedicationName = COALESCE(@MedicationName, MedicationName),
            PrescribedBy = COALESCE(@PrescribedBy, PrescribedBy),
            Dosage = COALESCE(@Dosage, Dosage),
            Frequency = COALESCE(@Frequency, Frequency),
            Duration = COALESCE(@Duration, Duration),
            Quantity = COALESCE(@Quantity, Quantity),
            Instructions = COALESCE(@Instructions, Instructions),
            StartDate = COALESCE(@StartDate, StartDate),
            Status = COALESCE(@Status, Status)
        WHERE PrescriptionID = @PrescriptionID;

        PRINT 'Prescription updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Prescription: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeletePrescription
CREATE OR ALTER PROCEDURE Delete_Prescription
    @PrescriptionID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @PrescriptionID IS NULL
            THROW 50001, 'Prescription ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.Prescriptions WHERE PrescriptionID = @PrescriptionID)
            THROW 50003, 'Prescription not found', 1;

        DELETE FROM Clinical_Management.Prescriptions
        WHERE PrescriptionID = @PrescriptionID;

        PRINT 'Prescription deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Prescription: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetPrescriptionsByPatient
CREATE OR ALTER PROCEDURE Get_Prescriptions_By_Patient
    @PatientID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @PatientID IS NULL
            THROW 50001, 'Patient ID is required', 1;
            
        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50003, 'Patient not found or inactive', 1;

        SELECT 
            p.PrescriptionID,
            p.PatientID,
            p.MedicationID,
            p.EncounterID,
            p.MedicationName,
            p.PrescribedBy,
            p.Dosage,
            p.Frequency,
            p.Duration,
            p.Quantity,
            p.Instructions,
            p.StartDate,
            p.Status,
            pa.FirstName + ' ' + pa.LastName AS PatientName,
            pa.MRN,
            s.FullName AS DoctorName,
            e.EncounterDate
        FROM Clinical_Management.Prescriptions p
        INNER JOIN Patient_Management.Patient pa ON p.PatientID = pa.PatientID
        INNER JOIN Core_system.Staff s ON p.PrescribedBy = s.StaffID
        INNER JOIN Clinical_Management.Encounters e ON p.EncounterID = e.EncounterID
        WHERE p.PatientID = @PatientID
        ORDER BY p.StartDate DESC;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Prescriptions_By_Patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetPrescriptionByID
CREATE OR ALTER PROCEDURE Get_Prescription_By_ID
    @PrescriptionID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @PrescriptionID IS NULL
            THROW 50001, 'Prescription ID is required', 1;

        SELECT 
            p.PrescriptionID,
            p.PatientID,
            p.MedicationID,
            p.EncounterID,
            p.MedicationName,
            p.PrescribedBy,
            p.Dosage,
            p.Frequency,
            p.Duration,
            p.Quantity,
            p.Instructions,
            p.StartDate,
            p.Status,
            pa.FirstName + ' ' + pa.LastName AS PatientName,
            pa.MRN,
            s.FullName AS DoctorName,
            e.EncounterDate
        FROM Clinical_Management.Prescriptions p
        INNER JOIN Patient_Management.Patient pa ON p.PatientID = pa.PatientID
        INNER JOIN Core_system.Staff s ON p.PrescribedBy = s.StaffID
        INNER JOIN Clinical_Management.Encounters e ON p.EncounterID = e.EncounterID
        WHERE p.PrescriptionID = @PrescriptionID;

        IF @@ROWCOUNT = 0
            THROW 50003, 'Prescription not found', 1;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Prescription_By_ID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetActivePrescriptions
CREATE OR ALTER PROCEDURE Get_Active_Prescriptions
    @PatientID INT = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @PatientID IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
                THROW 50003, 'Patient not found or inactive', 1;
                
            SELECT 
                p.PrescriptionID,
                p.PatientID,
                p.MedicationID,
                p.EncounterID,
                p.MedicationName,
                p.PrescribedBy,
                p.Dosage,
                p.Frequency,
                p.Duration,
                p.Quantity,
                p.Instructions,
                p.StartDate,
                p.Status,
                pa.FirstName + ' ' + pa.LastName AS PatientName,
                pa.MRN,
                s.FullName AS DoctorName,
                e.EncounterDate
            FROM Clinical_Management.Prescriptions p
            INNER JOIN Patient_Management.Patient pa ON p.PatientID = pa.PatientID
            INNER JOIN Core_system.Staff s ON p.PrescribedBy = s.StaffID
            INNER JOIN Clinical_Management.Encounters e ON p.EncounterID = e.EncounterID
            WHERE p.PatientID = @PatientID AND p.Status = 'Active'
            ORDER BY p.StartDate DESC;
        END
        ELSE
        BEGIN
            SELECT 
                p.PrescriptionID,
                p.PatientID,
                p.MedicationID,
                p.EncounterID,
                p.MedicationName,
                p.PrescribedBy,
                p.Dosage,
                p.Frequency,
                p.Duration,
                p.Quantity,
                p.Instructions,
                p.StartDate,
                p.Status,
                pa.FirstName + ' ' + pa.LastName AS PatientName,
                pa.MRN,
                s.FullName AS DoctorName,
                e.EncounterDate
            FROM Clinical_Management.Prescriptions p
            INNER JOIN Patient_Management.Patient pa ON p.PatientID = pa.PatientID
            INNER JOIN Core_system.Staff s ON p.PrescribedBy = s.StaffID
            INNER JOIN Clinical_Management.Encounters e ON p.EncounterID = e.EncounterID
            WHERE p.Status = 'Active'
            ORDER BY p.StartDate DESC;
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Active_Prescriptions: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Order Procedures
-- =============================================

--usp-CreateOrder
CREATE OR ALTER PROCEDURE Create_Order 
    @EncounterID INT NOT NULL,          
    @OrderingPhysicianID INT NOT NULL,
    @OrderDescription NVARCHAR(500) NULL, 
    @OrderType NVARCHAR(50) NOT NULL,  
    @OrderDate DATETIME,
    @Priority NVARCHAR(10),
    @Status NVARCHAR(20)
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @EncounterID IS NULL OR @OrderingPhysicianID IS NULL
            THROW 50001, 'Encounter ID and Doctor ID are required', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Clinical_Management.Encounters 
            WHERE EncounterID = @EncounterID 
        )
            THROW 50003, 'Encounter not found', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM Core_system.Staff s 
            INNER JOIN Core_system.Users u ON s.UserID = u.UserID
            WHERE s.StaffID = @OrderingPhysicianID 
            AND s.IsActive = 1
            AND u.RoleID IN (
                SELECT RoleID 
                FROM Core_system.Roles 
                WHERE RoleName IN ('Doctor', 'Physician', 'Surgeon', 'Resident')
            )
        )
        THROW 50003, 'Doctor must be an active medical doctor', 1;

        IF @OrderType IS NULL 
            THROW 50003, 'Order type is required', 1;
        
        IF @Priority IS NULL
            SET @Priority = 'Normal';
        
        IF @Status IS NULL
            SET @Status = 'Pending';

        INSERT INTO Order_Management.Orders (EncounterID, OrderingPhysicianID, OrderDescription, OrderType, OrderDate, Priority, Status)
        VALUES(
            @EncounterID,          
            @OrderingPhysicianID,
            @OrderDescription, 
            @OrderType,  
            @OrderDate,
            @Priority,
            @Status  
        );

        PRINT 'Order created successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Order: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateOrder
CREATE OR ALTER PROCEDURE Update_Order
    @OrderID INT,
    @OrderDescription NVARCHAR(500) = NULL,
    @OrderType NVARCHAR(50) = NULL,
    @Priority NVARCHAR(10) = NULL,
    @Status NVARCHAR(20) = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @OrderID IS NULL
            THROW 50001, 'Order ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Order_Management.Orders WHERE OrderID = @OrderID)
            THROW 50003, 'Order not found', 1;

        UPDATE Order_Management.Orders 
        SET OrderDescription = COALESCE(@OrderDescription, OrderDescription),
            OrderType = COALESCE(@OrderType, OrderType),
            Priority = COALESCE(@Priority, Priority),
            Status = COALESCE(@Status, Status)
        WHERE OrderID = @OrderID;

        PRINT 'Order updated successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Order: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetOrdersByEncounter
CREATE OR ALTER PROCEDURE Get_Orders_By_Encounter
    @EncounterID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @EncounterID IS NULL
            THROW 50001, 'Encounter ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE EncounterID = @EncounterID)
            THROW 50003, 'Encounter not found', 1;

        SELECT 
            o.OrderID,
            o.EncounterID,
            o.OrderingPhysicianID,
            o.OrderDescription,
            o.OrderType,
            o.OrderDate,
            o.Priority,
            o.Status,
            pa.PatientID,
            pa.FirstName + ' ' + pa.LastName AS PatientName,
            pa.MRN,
            s.FullName AS PhysicianName,
            e.EncounterDate
        FROM Order_Management.Orders o
        INNER JOIN Clinical_Management.Encounters e ON o.EncounterID = e.EncounterID
        INNER JOIN Patient_Management.Patient pa ON e.PatientID = pa.PatientID
        INNER JOIN Core_system.Staff s ON o.OrderingPhysicianID = s.StaffID
        WHERE o.EncounterID = @EncounterID
        ORDER BY o.OrderDate DESC;
    END TRY 
    BEGIN CATCH 
        PRINT 'Error in Get_Orders_By_Encounter: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetOrdersByPatient
CREATE OR ALTER PROCEDURE Get_Orders_By_Patient
    @PatientID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @PatientID IS NULL
            THROW 50001, 'Patient ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50003, 'Patient not found or inactive', 1;

        SELECT 
            o.OrderID,
            o.EncounterID,
            o.OrderingPhysicianID,
            o.OrderDescription,
            o.OrderType,
            o.OrderDate,
            o.Priority,
            o.Status,
            pa.PatientID,
            pa.FirstName + ' ' + pa.LastName AS PatientName,
            pa.MRN,
            s.FullName AS PhysicianName,
            e.EncounterDate
        FROM Order_Management.Orders o
        INNER JOIN Clinical_Management.Encounters e ON o.EncounterID = e.EncounterID
        INNER JOIN Patient_Management.Patient pa ON e.PatientID = pa.PatientID
        INNER JOIN Core_system.Staff s ON o.OrderingPhysicianID = s.StaffID
        WHERE pa.PatientID = @PatientID
        ORDER BY o.OrderDate DESC;
    END TRY 
    BEGIN CATCH 
        PRINT 'Error in Get_Orders_By_Patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteOrder
CREATE OR ALTER PROCEDURE Delete_Order
    @OrderID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @OrderID IS NULL
            THROW 50001, 'Order ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Order_Management.Orders WHERE OrderID = @OrderID)
            THROW 50003, 'Order not found', 1;

        DELETE FROM Order_Management.Orders 
        WHERE OrderID = @OrderID;

        PRINT 'Order deleted successfully';
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Order: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Inpatient Management Procedures
-- =============================================

--usp-CreateAdmission
CREATE OR ALTER PROCEDURE Create_Admission
    @PatientID INT,
    @EncounterID INT,
    @AdmittingPhysicianID INT,
    @AdmissionDate DATETIME2,
    @AdmittedFrom NVARCHAR(50),
    @BedID INT,
    @AdmissionReason NVARCHAR(500)
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @PatientID IS NULL OR @AdmittingPhysicianID IS NULL OR @BedID IS NULL 
            THROW 50001, 'Patient, Physician, and Bed are required', 1;

        IF NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50003, 'Patient not found or inactive', 1;

        IF @EncounterID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE EncounterID = @EncounterID)
            THROW 50003, 'Encounter not found', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @AdmittingPhysicianID AND IsActive = 1)
            THROW 50003, 'Admitting physician not found or inactive', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE BedID = @BedID AND BedStatus = 'Available')
            THROW 50005, 'Bed not available', 1;

        INSERT INTO Inpatient_Management.Admissions (
            PatientID, EncounterID, AdmittingPhysicianID, AdmissionDate, 
            AdmittedFrom, BedID, AdmissionReason
        )
        VALUES (
            @PatientID, @EncounterID, @AdmittingPhysicianID, @AdmissionDate,
            @AdmittedFrom, @BedID, @AdmissionReason  
        );

        UPDATE Inpatient_Management.Beds SET BedStatus = 'Occupied' WHERE BedID = @BedID;

        PRINT 'Admission created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Admission: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DischargePatient
CREATE OR ALTER PROCEDURE Discharge_Patient
    @AdmissionID INT,
    @DischargeDate DATETIME2
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @AdmissionID IS NULL OR @DischargeDate IS NULL
            THROW 50001, 'Admission ID and Discharge Date are required', 1;

        DECLARE @BedID INT, @CurrentStatus NVARCHAR(20);
        
        SELECT @BedID = BedID, @CurrentStatus = Status 
        FROM Inpatient_Management.Admissions 
        WHERE AdmissionID = @AdmissionID;

        IF @BedID IS NULL
            THROW 50003, 'Admission not found', 1;

        IF @CurrentStatus != 'Active'
            THROW 50003, 'Only active admissions can be discharged', 1;

        UPDATE Inpatient_Management.Admissions 
        SET DischargeDate = @DischargeDate, Status = 'Discharged'
        WHERE AdmissionID = @AdmissionID;

        UPDATE Inpatient_Management.Beds SET BedStatus = 'Available' WHERE BedID = @BedID;

        PRINT 'Patient discharged successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Discharge_Patient: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetActiveAdmissions
CREATE OR ALTER PROCEDURE Get_Active_Admissions
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            a.AdmissionID,
            a.PatientID,
            a.EncounterID,
            a.AdmittingPhysicianID,
            a.AdmissionDate,
            a.DischargeDate,
            a.AdmittedFrom,
            a.BedID,
            a.AdmissionReason,
            a.Status,
            a.TotalCharges,
            p.FirstName + ' ' + p.LastName AS PatientName,
            p.MRN,
            s.FullName AS PhysicianName,
            b.WardID,
            b.BedNumber
        FROM Inpatient_Management.Admissions a
        INNER JOIN Patient_Management.Patient p ON a.PatientID = p.PatientID
        INNER JOIN Core_system.Staff s ON a.AdmittingPhysicianID = s.StaffID
        INNER JOIN Inpatient_Management.Beds b ON a.BedID = b.BedID
        WHERE a.Status = 'Active'
        ORDER BY a.AdmissionDate DESC;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Active_Admissions: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetAdmissionByID
CREATE OR ALTER PROCEDURE Get_Admission_By_ID 
    @AdmissionID INT 
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @AdmissionID IS NULL
            THROW 50001, 'Admission ID is required', 1;

        SELECT 
            a.AdmissionID,
            a.PatientID,
            a.EncounterID,
            a.AdmittingPhysicianID,
            a.AdmissionDate,
            a.DischargeDate,
            a.AdmittedFrom,
            a.BedID,
            a.AdmissionReason,
            a.Status,
            a.TotalCharges,
            p.FirstName + ' ' + p.LastName AS PatientName,
            p.MRN,
            s.FullName AS PhysicianName,
            b.WardID,
            b.BedNumber
        FROM Inpatient_Management.Admissions a
        INNER JOIN Patient_Management.Patient p ON a.PatientID = p.PatientID
        INNER JOIN Core_system.Staff s ON a.AdmittingPhysicianID = s.StaffID
        INNER JOIN Inpatient_Management.Beds b ON a.BedID = b.BedID
        WHERE a.AdmissionID = @AdmissionID
        ORDER BY a.AdmissionDate DESC;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Admission_By_ID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetPatientAdmissionHistory
CREATE OR ALTER PROCEDURE Get_Patient_Admission_History
    @PatientID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @PatientID IS NULL
            THROW 50001, 'Patient ID is required', 1;

        SELECT 
            a.AdmissionID,
            a.PatientID,
            a.EncounterID,
            a.AdmittingPhysicianID,
            a.AdmissionDate,
            a.DischargeDate,
            a.AdmittedFrom,
            a.BedID,
            a.AdmissionReason,
            a.Status,
            a.TotalCharges,
            p.FirstName + ' ' + p.LastName AS PatientName,
            p.MRN,
            s.FullName AS PhysicianName,
            b.WardID,
            b.BedNumber
        FROM Inpatient_Management.Admissions a
        INNER JOIN Patient_Management.Patient p ON a.PatientID = p.PatientID
        INNER JOIN Core_system.Staff s ON a.AdmittingPhysicianID = s.StaffID
        INNER JOIN Inpatient_Management.Beds b ON a.BedID = b.BedID
        WHERE a.PatientID = @PatientID
        ORDER BY a.AdmissionDate DESC;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Patient_Admission_History: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateAdmission
CREATE OR ALTER PROCEDURE Update_Admission
    @AdmissionID INT,
    @DischargeDate DATETIME2 = NULL,
    @AdmissionDate DATETIME2 = NULL,
    @PatientID INT = NULL,
    @EncounterID INT = NULL,
    @AdmittingPhysicianID INT = NULL,
    @AdmittedFrom NVARCHAR(50) = NULL,
    @BedID INT = NULL,
    @AdmissionReason NVARCHAR(500) = NULL,
    @Status NVARCHAR(100) = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @AdmissionID IS NULL 
            THROW 50001, 'Admission ID is required', 1;

        DECLARE @CurrentBedID INT, @CurrentStatus NVARCHAR(20);
        SELECT @CurrentBedID = BedID, @CurrentStatus = Status 
        FROM Inpatient_Management.Admissions 
        WHERE AdmissionID = @AdmissionID;

        IF @CurrentBedID IS NULL
            THROW 50003, 'Admission not found', 1;

        IF @PatientID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Patient_Management.Patient WHERE PatientID = @PatientID AND IsActive = 1)
            THROW 50003, 'Patient not found or inactive', 1;

        IF @EncounterID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Clinical_Management.Encounters WHERE EncounterID = @EncounterID)
            THROW 50003, 'Encounter not found', 1;

        IF @AdmittingPhysicianID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @AdmittingPhysicianID AND IsActive = 1)
            THROW 50003, 'Admitting physician not found or inactive', 1;

        IF @BedID IS NOT NULL AND @BedID != @CurrentBedID
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE BedID = @BedID AND BedStatus = 'Available')
                THROW 50006, 'New bed not available', 1;

            UPDATE Inpatient_Management.Beds SET BedStatus = 'Available' WHERE BedID = @CurrentBedID;
            UPDATE Inpatient_Management.Beds SET BedStatus = 'Occupied' WHERE BedID = @BedID;
        END

        IF @Status IS NOT NULL AND @Status = 'Discharged' AND @CurrentStatus != 'Discharged'
        BEGIN
            IF @DischargeDate IS NULL
                SET @DischargeDate = GETDATE();
                
            UPDATE Inpatient_Management.Beds SET BedStatus = 'Available' WHERE BedID = COALESCE(@BedID, @CurrentBedID);
        END

        UPDATE Inpatient_Management.Admissions 
        SET AdmissionDate = COALESCE(@AdmissionDate, AdmissionDate),
            DischargeDate = COALESCE(@DischargeDate, DischargeDate),
            PatientID = COALESCE(@PatientID, PatientID),
            EncounterID = COALESCE(@EncounterID, EncounterID),
            AdmittingPhysicianID = COALESCE(@AdmittingPhysicianID, AdmittingPhysicianID),
            AdmittedFrom = COALESCE(@AdmittedFrom, AdmittedFrom),
            AdmissionReason = COALESCE(@AdmissionReason, AdmissionReason),
            BedID = COALESCE(@BedID, BedID),
            Status = COALESCE(@Status, Status)
        WHERE AdmissionID = @AdmissionID;

        PRINT 'Admission updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Admission: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteAdmission
CREATE OR ALTER PROCEDURE Delete_Admission 
    @AdmissionID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @AdmissionID IS NULL 
            THROW 50001, 'Admission ID is required', 1;

        DECLARE @CurrentBedID INT, @CurrentStatus NVARCHAR(60);

        SELECT 
            @CurrentBedID = BedID,
            @CurrentStatus = Status
        FROM Inpatient_Management.Admissions 
        WHERE AdmissionID = @AdmissionID;

        IF @CurrentBedID IS NULL
            THROW 50003, 'Admission not found', 1;

        IF @CurrentStatus = 'Active'
            THROW 50003, 'Cannot delete active admission. Discharge patient first.', 1;

        UPDATE Inpatient_Management.Beds 
        SET BedStatus = 'Available' 
        WHERE BedID = @CurrentBedID;

        DELETE FROM Inpatient_Management.Admissions
        WHERE AdmissionID = @AdmissionID;

        PRINT 'Admission deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Admission: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Ward Procedures
-- =============================================

--usp-CreateWard
CREATE OR ALTER PROCEDURE Create_Ward 
    @WardName NVARCHAR(100) NOT NULL,
    @DepartmentID INT NULL,
    @WardType NVARCHAR(50)
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @WardName IS NULL OR LEN(@WardName) < 1
            THROW 50001, 'Proper Ward name is required', 1;

        IF NOT EXISTS (
            SELECT 1 FROM Core_system.Departments
            WHERE DepartmentID = @DepartmentID
        )
            THROW 50003, 'Department not found', 1;

        IF @WardType NOT IN ('General','Single','Semi-Private','Gold','Diamond','VIP','Maternity')
            THROW 50002, 'Ward type should be only (General, Single, Semi-Private, Gold, Diamond, VIP, Maternity)', 1;

        INSERT INTO Inpatient_Management.Wards(
            WardName,
            DepartmentID,
            WardType,
            IsActive
        )
        VALUES(
            @WardName,
            @DepartmentID,
            @WardType,
            1
        );

        PRINT 'Ward created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Ward: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-UpdateWard
CREATE OR ALTER PROCEDURE Update_Ward
    @WardID INT,
    @WardName NVARCHAR(100) = NULL,
    @DepartmentID INT = NULL,
    @WardType NVARCHAR(50) = NULL,
    @IsActive BIT = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @WardID IS NULL
            THROW 50001, 'Ward ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Wards WHERE WardID = @WardID)
            THROW 50003, 'Ward not found', 1;

        IF @WardName IS NOT NULL AND LEN(@WardName) < 1
            THROW 50003, 'Proper Ward name is required', 1;

        IF @DepartmentID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Core_system.Departments WHERE DepartmentID = @DepartmentID)
            THROW 50003, 'Department not found', 1;

        IF @WardType IS NOT NULL AND @WardType NOT IN ('General','Single','Semi-Private','Gold','Diamond','VIP','Maternity')
            THROW 50005, 'Ward type should be only (General, Single, Semi-Private, Gold, Diamond, VIP, Maternity)', 1;

        UPDATE Inpatient_Management.Wards
        SET WardName = COALESCE(@WardName, WardName),
            DepartmentID = COALESCE(@DepartmentID, DepartmentID),
            WardType = COALESCE(@WardType, WardType),
            IsActive = COALESCE(@IsActive, IsActive)
        WHERE WardID = @WardID;

        PRINT 'Ward updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Ward: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteWard
CREATE OR ALTER PROCEDURE Delete_Ward
    @WardID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @WardID IS NULL
            THROW 50001, 'Ward ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Wards WHERE WardID = @WardID)
            THROW 50003, 'Ward not found', 1;

        IF EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE WardID = @WardID AND BedStatus = 'Occupied')
            THROW 50003, 'Cannot delete ward with occupied beds', 1;

        IF EXISTS (SELECT 1 FROM Inpatient_Management.Admissions a 
                   INNER JOIN Inpatient_Management.Beds b ON a.BedID = b.BedID 
                   WHERE b.WardID = @WardID AND a.Status = 'Active')
            THROW 50004, 'Cannot delete ward with active admissions', 1;

        DELETE FROM Inpatient_Management.Beds WHERE WardID = @WardID;
        DELETE FROM Inpatient_Management.Wards WHERE WardID = @WardID;

        PRINT 'Ward deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Ward: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetWardByID
CREATE OR ALTER PROCEDURE Get_Ward_By_ID
    @WardID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @WardID IS NULL
            THROW 50001, 'Ward ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Wards WHERE WardID = @WardID)
            THROW 50003, 'Ward not found', 1;

        SELECT
            w.WardName,
            w.WardType,
            w.IsActive,
            w.DepartmentID,
            b.BedID,
            b.BedStatus,
            b.BedNumber
        FROM Inpatient_Management.Wards w
        INNER JOIN Inpatient_Management.Beds b ON w.WardID = b.WardID       
        WHERE w.WardID = @WardID
        ORDER BY b.BedNumber; 
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Ward_By_ID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetWardSummary
CREATE OR ALTER PROCEDURE Get_Ward_Summary
    @WardID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT
            w.WardName,
            w.WardType,
            COUNT(B.BedID) AS Total_BedCounts,
            SUM(CASE WHEN b.BedStatus = 'Available' THEN 1 ELSE 0 END) AS AvailableBeds,
            SUM(CASE WHEN B.BedStatus = 'Occupied' THEN 1 ELSE 0 END) AS OccupiedBeds,
            COUNT(A.AdmissionID) AS ActiveAdmissions
        FROM Inpatient_Management.Wards W
        JOIN Inpatient_Management.Beds B ON W.WardID = B.WardID
        LEFT JOIN Inpatient_Management.Admissions A ON A.BedID = B.BedID AND A.Status = 'Active'        
        WHERE W.WardID = @WardID
        GROUP BY w.WardName, w.WardType;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Ward_Summary: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-SearchWard
CREATE OR ALTER PROCEDURE Search_Ward
    @SearchTerm NVARCHAR(80) = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT * FROM Inpatient_Management.Wards W
        WHERE @SearchTerm IS NULL
            OR W.WardName LIKE '%' + @SearchTerm + '%' 
            OR W.WardType LIKE '%' + @SearchTerm + '%'
            OR (TRY_CONVERT(INT, @SearchTerm) IS NOT NULL AND W.WardID = TRY_CONVERT(INT, @SearchTerm));
    END TRY
    BEGIN CATCH
        PRINT 'Error in Search_Ward: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Bed Procedures
-- =============================================

--usp-CreateBed
CREATE OR ALTER PROCEDURE Create_Bed
    @WardID INT,
    @BedNumber NVARCHAR(10)
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @WardID IS NULL OR @BedNumber IS NULL
            THROW 50001, 'Ward ID and Bed Number are required', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Wards WHERE WardID = @WardID AND IsActive = 1)
            THROW 50003, 'Ward not found or inactive', 1;

        DECLARE @WardName NVARCHAR(100);
        SELECT @WardName = WardName FROM Inpatient_Management.Wards WHERE WardID = @WardID;

        DECLARE @FullBedNumber NVARCHAR(20) = UPPER(LEFT(@WardName, 3)) + '-' + @BedNumber;

        IF EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE WardID = @WardID AND BedNumber = @FullBedNumber)
            THROW 50003, 'Bed number already exists in this ward', 1;

        INSERT INTO Inpatient_Management.Beds(
            WardID,
            BedNumber,
            BedStatus
        )
        VALUES(
            @WardID,
            @FullBedNumber,
            'Available'
        );

        PRINT 'Bed created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Bed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO
GO
--usp-UpdateBed
CREATE OR ALTER PROCEDURE Update_Bed
    @BedID INT,
    @WardID INT = NULL,
    @BedNumber NVARCHAR(10) = NULL,
    @BedStatus NVARCHAR(20) = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @BedID IS NULL
            THROW 50001, 'Bed ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE BedID = @BedID)
            THROW 50003, 'Bed not found', 1;

        DECLARE @CurrentWardID INT;
        SELECT @CurrentWardID = WardID FROM Inpatient_Management.Beds WHERE BedID = @BedID;

        IF @WardID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Inpatient_Management.Wards WHERE WardID = @WardID AND IsActive = 1)
            THROW 50003, 'Ward not found or inactive', 1;

        DECLARE @TargetWardID INT = COALESCE(@WardID, @CurrentWardID);
        DECLARE @WardName NVARCHAR(100);
        SELECT @WardName = WardName FROM Inpatient_Management.Wards WHERE WardID = @TargetWardID;

        DECLARE @FullBedNumber NVARCHAR(20);
        IF @BedNumber IS NOT NULL
            SET @FullBedNumber = UPPER(LEFT(@WardName, 3)) + '-' + @BedNumber;

        IF @BedNumber IS NOT NULL AND EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE WardID = @TargetWardID AND BedNumber = @FullBedNumber AND BedID != @BedID)
            THROW 50004, 'Bed number already exists in this ward', 1;

        IF @BedStatus IS NOT NULL AND @BedStatus NOT IN ('Available','Occupied','Cleaning','Blocked','Maintenance')
            THROW 50005, 'Invalid bed status', 1;

        UPDATE Inpatient_Management.Beds
        SET WardID = COALESCE(@WardID, WardID),
            BedNumber = COALESCE(@FullBedNumber, BedNumber),
            BedStatus = COALESCE(@BedStatus, BedStatus)
        WHERE BedID = @BedID;

        PRINT 'Bed updated successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Update_Bed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-DeleteBed
CREATE OR ALTER PROCEDURE Delete_Bed
    @BedID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @BedID IS NULL
            THROW 50001, 'Bed ID is required', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE BedID = @BedID)
            THROW 50003, 'Bed not found', 1;

        IF EXISTS (SELECT 1 FROM Inpatient_Management.Admissions WHERE BedID = @BedID AND Status = 'Active')
            THROW 50003, 'Cannot delete bed with active admission', 1;

        DELETE FROM Inpatient_Management.Beds WHERE BedID = @BedID;

        PRINT 'Bed deleted successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Delete_Bed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetAvailableBeds
CREATE OR ALTER PROCEDURE Get_Available_Beds
    @WardID INT = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            b.BedID,
            b.BedNumber,
            b.BedStatus,
            w.WardName,
            w.WardType
        FROM Inpatient_Management.Beds b
        INNER JOIN Inpatient_Management.Wards w ON b.WardID = w.WardID
        WHERE b.BedStatus = 'Available'
        AND w.IsActive = 1
        AND (@WardID IS NULL OR b.WardID = @WardID)
        ORDER BY w.WardName, b.BedNumber;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Available_Beds: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetBedByID
CREATE OR ALTER PROCEDURE Get_Bed_By_ID
    @BedID INT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @BedID IS NULL
            THROW 50001, 'Bed ID is required', 1;

        SELECT 
            b.BedID,
            b.BedNumber,
            b.BedStatus,
            w.WardName,
            w.WardType,
            a.AdmissionDate,
            a.AdmissionReason,
            a.AdmittedFrom,
            a.Status,
            p.FirstName + ' ' + p.LastName AS PatientName,
            p.MRN,
            DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
            s.FullName,
            s.Position
        FROM Inpatient_Management.Beds b
        INNER JOIN Inpatient_Management.Wards w ON b.WardID = w.WardID
        LEFT JOIN Inpatient_Management.Admissions a ON a.BedID = b.BedID AND a.Status = 'Active'
        LEFT JOIN Patient_Management.Patient p ON p.PatientID = a.PatientID 
        LEFT JOIN Core_system.Staff s ON a.AdmittingPhysicianID = s.StaffID
        WHERE b.BedID = @BedID
            AND w.IsActive = 1;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Bed_By_ID: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- =============================================
-- Bed Transfer Procedures
-- =============================================
GO
--usp-CreateBedTransfer
CREATE OR ALTER PROCEDURE Create_Bed_Transfer
    @AdmissionID INT,
    @FromBedID INT,
    @ToBedID INT,
    @Reason NVARCHAR(200),
    @OrderedBy INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @AdmissionID IS NULL OR @FromBedID IS NULL OR @ToBedID IS NULL OR @OrderedBy IS NULL
            THROW 50001, 'Admission ID, From Bed, To Bed and Ordered By are required', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Admissions WHERE AdmissionID = @AdmissionID AND Status = 'Active')
            THROW 50003, 'Active admission not found', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE BedID = @FromBedID AND BedStatus = 'Occupied')
            THROW 50003, 'From bed is not occupied', 1;

        IF NOT EXISTS (SELECT 1 FROM Inpatient_Management.Beds WHERE BedID = @ToBedID AND BedStatus = 'Available')
            THROW 50004, 'To bed is not available', 1;

        IF NOT EXISTS (SELECT 1 FROM Core_system.Staff WHERE StaffID = @OrderedBy AND IsActive = 1)
            THROW 50003, 'Ordering staff not found or inactive', 1;

        INSERT INTO Inpatient_Management.BedTransfers(
            AdmissionID,
            FromBedID,
            ToBedID,
            Reason,
            OrderedBy
        )
        VALUES(
            @AdmissionID,
            @FromBedID,
            @ToBedID,
            @Reason,
            @OrderedBy
        );

        UPDATE Inpatient_Management.Admissions SET BedID = @ToBedID WHERE AdmissionID = @AdmissionID;
        UPDATE Inpatient_Management.Beds SET BedStatus = 'Available' WHERE BedID = @FromBedID;
        UPDATE Inpatient_Management.Beds SET BedStatus = 'Occupied' WHERE BedID = @ToBedID;

        PRINT 'Bed transfer created successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        PRINT 'Error in Create_Bed_Transfer: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

--usp-GetBedTransfersByAdmission
CREATE OR ALTER PROCEDURE Get_Bed_Transfers_By_Admission
    @AdmissionID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
        IF @AdmissionID IS NULL
            THROW 50001, 'Admission ID is required', 1;

        SELECT 
            bt.TransferID,
            bt.AdmissionID,
            bt.FromBedID,
            bt.ToBedID,
            bt.TransferDate,
            bt.Reason,
            bt.OrderedBy,
            fb.BedNumber AS FromBedNumber,
            tb.BedNumber AS ToBedNumber,
            fw.WardName AS FromWardName,
            tw.WardName AS ToWardName,
            s.FullName AS OrderedByName
        FROM Inpatient_Management.BedTransfers bt
        INNER JOIN Inpatient_Management.Beds fb ON bt.FromBedID = fb.BedID
        INNER JOIN Inpatient_Management.Beds tb ON bt.ToBedID = tb.BedID
        INNER JOIN Inpatient_Management.Wards fw ON fb.WardID = fw.WardID
        INNER JOIN Inpatient_Management.Wards tw ON tb.WardID = tw.WardID
        INNER JOIN Core_system.Staff s ON bt.OrderedBy = s.StaffID
        WHERE bt.AdmissionID = @AdmissionID
        ORDER BY bt.TransferDate DESC;
    END TRY
    BEGIN CATCH
        PRINT 'Error in Get_Bed_Transfers_By_Admission: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO



-- =============================================
-- 1. INSURANCE COMPANIES & PLANS STORED PROCEDURES
-- =============================================

-- usp_CreateInsuranceCompany
CREATE PROCEDURE Finance_Management.usp_CreateInsuranceCompany
    @CompanyName NVARCHAR(200),
    @ContactPerson NVARCHAR(100) = NULL,
    @Phone NVARCHAR(20) = NULL,
    @Email NVARCHAR(100) = NULL,
    @Address NVARCHAR(500) = NULL,
    @CreatedBy INT
AS
BEGIN
    INSERT INTO Finance_Management.InsuranceCompanies 
    (CompanyName, ContactPerson, Phone, Email, Address, CreatedBy)
    VALUES (@CompanyName, @ContactPerson, @Phone, @Email, @Address, @CreatedBy);
    
    SELECT SCOPE_IDENTITY() AS CompanyID;
END
GO

-- usp_UpdateInsuranceCompany
CREATE PROCEDURE Finance_Management.usp_UpdateInsuranceCompany
    @CompanyID INT,
    @CompanyName NVARCHAR(200),
    @ContactPerson NVARCHAR(100) = NULL,
    @Phone NVARCHAR(20) = NULL,
    @Email NVARCHAR(100) = NULL,
    @Address NVARCHAR(500) = NULL,
    @IsActive BIT,
    @UpdatedBy INT
AS
BEGIN
    UPDATE Finance_Management.InsuranceCompanies 
    SET CompanyName = @CompanyName,
        ContactPerson = @ContactPerson,
        Phone = @Phone,
        Email = @Email,
        Address = @Address,
        IsActive = @IsActive,
        UpdatedBy = @UpdatedBy,
        UpdatedDate = GETDATE()
    WHERE CompanyID = @CompanyID;
END
GO

-- usp_GetAllInsuranceCompanies
CREATE PROCEDURE Finance_Management.usp_GetAllInsuranceCompanies
    @IsActive BIT = NULL
AS
BEGIN
    SELECT * FROM Finance_Management.InsuranceCompanies 
    WHERE (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY CompanyName;
END
GO

-- usp_GetInsuranceCompanyByID
CREATE PROCEDURE Finance_Management.usp_GetInsuranceCompanyByID
    @CompanyID INT
AS
BEGIN
    SELECT * FROM Finance_Management.InsuranceCompanies 
    WHERE CompanyID = @CompanyID;
END
GO

-- usp_CreateInsurancePlan
CREATE PROCEDURE Finance_Management.usp_CreateInsurancePlan
    @CompanyID INT,
    @PlanName NVARCHAR(100),
    @PlanCode NVARCHAR(50) = NULL,
    @CoveragePercentage DECIMAL(5,2),
    @DeductibleAmount DECIMAL(10,2),
    @MaxAnnualCoverage DECIMAL(10,2) = NULL,
    @CoPayAmount DECIMAL(10,2),
    @CreatedBy INT
AS
BEGIN
    INSERT INTO Finance_Management.InsurancePlans 
    (CompanyID, PlanName, PlanCode, CoveragePercentage, DeductibleAmount, MaxAnnualCoverage, CoPayAmount, CreatedBy)
    VALUES (@CompanyID, @PlanName, @PlanCode, @CoveragePercentage, @DeductibleAmount, @MaxAnnualCoverage, @CoPayAmount, @CreatedBy);
    
    SELECT SCOPE_IDENTITY() AS PlanID;
END
GO

-- usp_UpdateInsurancePlan
CREATE PROCEDURE Finance_Management.usp_UpdateInsurancePlan
    @PlanID INT,
    @PlanName NVARCHAR(100),
    @PlanCode NVARCHAR(50) = NULL,
    @CoveragePercentage DECIMAL(5,2),
    @DeductibleAmount DECIMAL(10,2),
    @MaxAnnualCoverage DECIMAL(10,2) = NULL,
    @CoPayAmount DECIMAL(10,2),
    @IsActive BIT,
    @UpdatedBy INT
AS
BEGIN
    UPDATE Finance_Management.InsurancePlans 
    SET PlanName = @PlanName,
        PlanCode = @PlanCode,
        CoveragePercentage = @CoveragePercentage,
        DeductibleAmount = @DeductibleAmount,
        MaxAnnualCoverage = @MaxAnnualCoverage,
        CoPayAmount = @CoPayAmount,
        IsActive = @IsActive,
        UpdatedBy = @UpdatedBy,
        UpdatedDate = GETDATE()
    WHERE PlanID = @PlanID;
END
GO

-- usp_GetAllInsurancePlans
CREATE PROCEDURE Finance_Management.usp_GetAllInsurancePlans
    @IsActive BIT = NULL
AS
BEGIN
    SELECT ip.*, ic.CompanyName
    FROM Finance_Management.InsurancePlans ip
    INNER JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    WHERE (@IsActive IS NULL OR ip.IsActive = @IsActive)
    ORDER BY ic.CompanyName, ip.PlanName;
END
GO

-- usp_GetPlansByCompanyID
CREATE PROCEDURE Finance_Management.usp_GetPlansByCompanyID
    @CompanyID INT,
    @IsActive BIT = NULL
AS
BEGIN
    SELECT * FROM Finance_Management.InsurancePlans 
    WHERE CompanyID = @CompanyID 
    AND (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY PlanName;
END
GO

-- =============================================
-- 2. SERVICES CATALOG STORED PROCEDURES
-- =============================================

-- usp_CreateService
CREATE PROCEDURE Finance_Management.usp_CreateService
    @ServiceCode NVARCHAR(20),
    @ServiceName NVARCHAR(200),
    @ServiceCategory NVARCHAR(50) = NULL,
    @Description NVARCHAR(500) = NULL,
    @DepartmentID INT = NULL,
    @StandardPrice DECIMAL(10,2),
    @Cost DECIMAL(10,2) = NULL,
    @IsInsuranceCovered BIT = 1,
    @RequiresPreAuthorization BIT = 0,
    @CreatedBy INT
AS
BEGIN
    INSERT INTO Finance_Management.Services 
    (ServiceCode, ServiceName, ServiceCategory, Description, DepartmentID, StandardPrice, Cost, IsInsuranceCovered, RequiresPreAuthorization, CreatedBy)
    VALUES (@ServiceCode, @ServiceName, @ServiceCategory, @Description, @DepartmentID, @StandardPrice, @Cost, @IsInsuranceCovered, @RequiresPreAuthorization, @CreatedBy);
    
    SELECT SCOPE_IDENTITY() AS ServiceID;
END
GO

-- usp_UpdateService
CREATE PROCEDURE Finance_Management.usp_UpdateService
    @ServiceID INT,
    @ServiceCode NVARCHAR(20),
    @ServiceName NVARCHAR(200),
    @ServiceCategory NVARCHAR(50) = NULL,
    @Description NVARCHAR(500) = NULL,
    @DepartmentID INT = NULL,
    @StandardPrice DECIMAL(10,2),
    @Cost DECIMAL(10,2) = NULL,
    @IsInsuranceCovered BIT = 1,
    @RequiresPreAuthorization BIT = 0,
    @IsActive BIT,
    @UpdatedBy INT
AS
BEGIN
    UPDATE Finance_Management.Services 
    SET ServiceCode = @ServiceCode,
        ServiceName = @ServiceName,
        ServiceCategory = @ServiceCategory,
        Description = @Description,
        DepartmentID = @DepartmentID,
        StandardPrice = @StandardPrice,
        Cost = @Cost,
        IsInsuranceCovered = @IsInsuranceCovered,
        RequiresPreAuthorization = @RequiresPreAuthorization,
        IsActive = @IsActive,
        UpdatedBy = @UpdatedBy,
        UpdatedDate = GETDATE()
    WHERE ServiceID = @ServiceID;
END
GO

-- usp_GetAllServices
CREATE PROCEDURE Finance_Management.usp_GetAllServices
    @IsActive BIT = NULL
AS
BEGIN
    SELECT s.*, d.DepartmentName
    FROM Finance_Management.Services s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    WHERE (@IsActive IS NULL OR s.IsActive = @IsActive)
    ORDER BY s.ServiceCategory, s.ServiceName;
END
GO

-- usp_GetServicesByCategory
CREATE PROCEDURE Finance_Management.usp_GetServicesByCategory
    @ServiceCategory NVARCHAR(50),
    @IsActive BIT = 1
AS
BEGIN
    SELECT * FROM Finance_Management.Services 
    WHERE ServiceCategory = @ServiceCategory 
    AND IsActive = @IsActive
    ORDER BY ServiceName;
END
GO

-- usp_GetServiceByID
CREATE PROCEDURE Finance_Management.usp_GetServiceByID
    @ServiceID INT
AS
BEGIN
    SELECT s.*, d.DepartmentName
    FROM Finance_Management.Services s
    LEFT JOIN Core_system.Departments d ON s.DepartmentID = d.DepartmentID
    WHERE s.ServiceID = @ServiceID;
END
GO

-- =============================================
-- 3. PATIENT INSURANCE STORED PROCEDURES
-- =============================================

-- usp_RegisterPatientInsurance
CREATE PROCEDURE Patient_Management.usp_RegisterPatientInsurance
    @PatientID INT,
    @PlanID INT,
    @PolicyNumber NVARCHAR(100),
    @GroupNumber NVARCHAR(100) = NULL,
    @EffectiveDate DATE,
    @ExpiryDate DATE,
    @IsPrimary BIT = 1,
    @CreatedBy INT
AS
BEGIN
    INSERT INTO Patient_Management.PatientInsurance 
    (PatientID, PlanID, PolicyNumber, GroupNumber, EffectiveDate, ExpiryDate, IsPrimary, CreatedBy)
    VALUES (@PatientID, @PlanID, @PolicyNumber, @GroupNumber, @EffectiveDate, @ExpiryDate, @IsPrimary, @CreatedBy);
    
    SELECT SCOPE_IDENTITY() AS PatientInsuranceID;
END
GO

-- usp_UpdatePatientInsurance
CREATE PROCEDURE Patient_Management.usp_UpdatePatientInsurance
    @PatientInsuranceID INT,
    @PlanID INT,
    @PolicyNumber NVARCHAR(100),
    @GroupNumber NVARCHAR(100) = NULL,
    @EffectiveDate DATE,
    @ExpiryDate DATE,
    @IsPrimary BIT = 1,
    @IsActive BIT,
    @UpdatedBy INT
AS
BEGIN
    UPDATE Patient_Management.PatientInsurance 
    SET PlanID = @PlanID,
        PolicyNumber = @PolicyNumber,
        GroupNumber = @GroupNumber,
        EffectiveDate = @EffectiveDate,
        ExpiryDate = @ExpiryDate,
        IsPrimary = @IsPrimary,
        IsActive = @IsActive,
        UpdatedBy = @UpdatedBy,
        UpdatedDate = GETDATE()
    WHERE PatientInsuranceID = @PatientInsuranceID;
END
GO

-- usp_GetPatientInsurance
CREATE PROCEDURE Patient_Management.usp_GetPatientInsurance
    @PatientID INT
AS
BEGIN
    SELECT pi.*, ip.PlanName, ic.CompanyName, ip.CoveragePercentage, ip.DeductibleAmount, ip.CoPayAmount
    FROM Patient_Management.PatientInsurance pi
    INNER JOIN Finance_Management.InsurancePlans ip ON pi.PlanID = ip.PlanID
    INNER JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    WHERE pi.PatientID = @PatientID
    AND pi.IsActive = 1
    ORDER BY pi.IsPrimary DESC, pi.ExpiryDate DESC;
END
GO

-- usp_VerifyInsuranceCoverage
CREATE PROCEDURE Patient_Management.usp_VerifyInsuranceCoverage
    @PatientID INT
AS
BEGIN
    SELECT 
        pi.PatientInsuranceID,
        pi.PolicyNumber,
        ic.CompanyName,
        ip.PlanName,
        ip.CoveragePercentage,
        ip.DeductibleAmount,
        ip.CoPayAmount,
        CASE 
            WHEN GETDATE() BETWEEN pi.EffectiveDate AND pi.ExpiryDate 
            THEN 'Active' 
            ELSE 'Expired' 
        END AS InsuranceStatus,
        DATEDIFF(DAY, GETDATE(), pi.ExpiryDate) AS DaysUntilExpiry
    FROM Patient_Management.PatientInsurance pi
    INNER JOIN Finance_Management.InsurancePlans ip ON pi.PlanID = ip.PlanID
    INNER JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    WHERE pi.PatientID = @PatientID 
    AND pi.IsActive = 1;
END
GO

-- =============================================
-- 4. INSURANCE VERIFICATION STORED PROCEDURES
-- =============================================

-- usp_LogInsuranceVerification
CREATE PROCEDURE Finance_Management.usp_LogInsuranceVerification
    @PatientID INT,
    @InsurancePlanID INT,
    @VerificationMethod NVARCHAR(50),
    @VerifiedBy INT,
    @IsSuccessful BIT = 1,
    @Notes NVARCHAR(500) = NULL,
    @NextVerificationDate DATE = NULL
AS
BEGIN
    INSERT INTO Finance_Management.InsuranceVerificationLog 
    (PatientID, InsurancePlanID, VerificationMethod, VerifiedBy, IsSuccessful, Notes, NextVerificationDate)
    VALUES (@PatientID, @InsurancePlanID, @VerificationMethod, @VerifiedBy, @IsSuccessful, @Notes, @NextVerificationDate);
    
    SELECT SCOPE_IDENTITY() AS LogID;
END
GO

-- usp_GetVerificationHistory
CREATE PROCEDURE Finance_Management.usp_GetVerificationHistory
    @PatientID INT = NULL,
    @DaysBack INT = 30
AS
BEGIN
    SELECT 
        vl.*,
        p.FirstName + ' ' + p.LastName AS PatientName,
        ic.CompanyName,
        ip.PlanName,
        s.FullName AS VerifiedByName
    FROM Finance_Management.InsuranceVerificationLog vl
    INNER JOIN Patient_Management.Patient p ON vl.PatientID = p.PatientID
    INNER JOIN Finance_Management.InsurancePlans ip ON vl.InsurancePlanID = ip.PlanID
    INNER JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    LEFT JOIN Core_system.Staff s ON vl.VerifiedBy = s.StaffID
    WHERE (@PatientID IS NULL OR vl.PatientID = @PatientID)
    AND vl.VerificationDate >= DATEADD(DAY, -@DaysBack, GETDATE())
    ORDER BY vl.VerificationDate DESC;
END
GO

-- usp_CheckInsuranceValidity
CREATE PROCEDURE Finance_Management.usp_CheckInsuranceValidity
    @PatientID INT
AS
BEGIN
    SELECT 
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM Patient_Management.PatientInsurance 
                WHERE PatientID = @PatientID 
                AND IsActive = 1 
                AND GETDATE() BETWEEN EffectiveDate AND ExpiryDate
            ) THEN 1 
            ELSE 0 
        END AS HasValidInsurance;
END
GO

-- =============================================
-- 5. INVOICES STORED PROCEDURES
-- =============================================

-- usp_CreateInvoice
CREATE PROCEDURE Finance_Management.usp_CreateInvoice
    @PatientID INT,
    @AdmissionID INT = NULL,
    @EncounterID INT = NULL,
    @PhysicianID INT = NULL,
    @InsurancePlanID INT = NULL,
    @SubTotal DECIMAL(10,2) = 0,
    @TaxRate DECIMAL(5,2) = 0,
    @DiscountRate DECIMAL(5,2) = 0,
    @CoPayAmount DECIMAL(10,2) = 0,
    @DeductibleAmount DECIMAL(10,2) = 0,
    @PaymentMethod NVARCHAR(50) = NULL,
    @Notes NVARCHAR(1000) = NULL,
    @CreatedBy INT
AS
BEGIN
    DECLARE @InvoiceNumber NVARCHAR(50);
    DECLARE @TaxAmount DECIMAL(10,2) = @SubTotal * (@TaxRate / 100);
    DECLARE @DiscountAmount DECIMAL(10,2) = @SubTotal * (@DiscountRate / 100);
    DECLARE @TotalAmount DECIMAL(10,2) = @SubTotal + @TaxAmount - @DiscountAmount;
    
    -- Generate invoice number (you might want a more sophisticated method)
    SET @InvoiceNumber = 'INV-' + FORMAT(GETDATE(), 'yyyyMMdd') + '-' + RIGHT('0000' + CAST((SELECT COUNT(*) FROM Finance_Management.Invoices WHERE CAST(InvoiceDate AS DATE) = CAST(GETDATE() AS DATE)) + 1 AS NVARCHAR(4)), 4);
    
    INSERT INTO Finance_Management.Invoices 
    (InvoiceNumber, PatientID, AdmissionID, EncounterID, PhysicianID, InsurancePlanID,
     SubTotal, TaxRate, TaxAmount, DiscountRate, DiscountAmount, TotalAmount,
     CoPayAmount, DeductibleAmount, PaymentMethod, Notes, CreatedBy)
    VALUES 
    (@InvoiceNumber, @PatientID, @AdmissionID, @EncounterID, @PhysicianID, @InsurancePlanID,
     @SubTotal, @TaxRate, @TaxAmount, @DiscountRate, @DiscountAmount, @TotalAmount,
     @CoPayAmount, @DeductibleAmount, @PaymentMethod, @Notes, @CreatedBy);
    
    SELECT SCOPE_IDENTITY() AS InvoiceID, @InvoiceNumber AS InvoiceNumber;
END
GO

-- usp_UpdateInvoice
CREATE PROCEDURE Finance_Management.usp_UpdateInvoice
    @InvoiceID INT,
    @InsurancePlanID INT = NULL,
    @InsuranceCoverageAmount DECIMAL(10,2) = NULL,
    @PatientResponsibilityAmount DECIMAL(10,2) = NULL,
    @InsuranceStatus NVARCHAR(20) = NULL,
    @PaymentStatus NVARCHAR(20) = NULL,
    @Status NVARCHAR(20) = NULL,
    @Notes NVARCHAR(1000) = NULL,
    @UpdatedBy INT
AS
BEGIN
    UPDATE Finance_Management.Invoices 
    SET InsurancePlanID = ISNULL(@InsurancePlanID, InsurancePlanID),
        InsuranceCoverageAmount = ISNULL(@InsuranceCoverageAmount, InsuranceCoverageAmount),
        PatientResponsibilityAmount = ISNULL(@PatientResponsibilityAmount, PatientResponsibilityAmount),
        InsuranceStatus = ISNULL(@InsuranceStatus, InsuranceStatus),
        PaymentStatus = ISNULL(@PaymentStatus, PaymentStatus),
        Status = ISNULL(@Status, Status),
        Notes = ISNULL(@Notes, Notes),
        UpdatedBy = @UpdatedBy,
        UpdatedDate = GETDATE()
    WHERE InvoiceID = @InvoiceID;
END
GO

-- usp_GetInvoiceByID
CREATE PROCEDURE Finance_Management.usp_GetInvoiceByID
    @InvoiceID INT
AS
BEGIN
    SELECT 
        i.*,
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.MRN,
        s.FullName AS PhysicianName,
        ic.CompanyName AS InsuranceCompany,
        ip.PlanName AS InsurancePlan
    FROM Finance_Management.Invoices i
    INNER JOIN Patient_Management.Patient p ON i.PatientID = p.PatientID
    LEFT JOIN Core_system.Staff s ON i.PhysicianID = s.StaffID
    LEFT JOIN Finance_Management.InsurancePlans ip ON i.InsurancePlanID = ip.PlanID
    LEFT JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    WHERE i.InvoiceID = @InvoiceID;
END
GO

-- usp_GetInvoicesByPatient
CREATE PROCEDURE Finance_Management.usp_GetInvoicesByPatient
    @PatientID INT,
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SELECT 
        i.*,
        s.FullName AS PhysicianName,
        ic.CompanyName AS InsuranceCompany
    FROM Finance_Management.Invoices i
    LEFT JOIN Core_system.Staff s ON i.PhysicianID = s.StaffID
    LEFT JOIN Finance_Management.InsurancePlans ip ON i.InsurancePlanID = ip.PlanID
    LEFT JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    WHERE i.PatientID = @PatientID
    AND (@Status IS NULL OR i.Status = @Status)
    ORDER BY i.InvoiceDate DESC;
END
GO

-- usp_GetInvoicesByStatus
CREATE PROCEDURE Finance_Management.usp_GetInvoicesByStatus
    @PaymentStatus NVARCHAR(20) = NULL,
    @InsuranceStatus NVARCHAR(20) = NULL,
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL
AS
BEGIN
    SELECT 
        i.*,
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.MRN,
        s.FullName AS PhysicianName
    FROM Finance_Management.Invoices i
    INNER JOIN Patient_Management.Patient p ON i.PatientID = p.PatientID
    LEFT JOIN Core_system.Staff s ON i.PhysicianID = s.StaffID
    WHERE (@PaymentStatus IS NULL OR i.PaymentStatus = @PaymentStatus)
    AND (@InsuranceStatus IS NULL OR i.InsuranceStatus = @InsuranceStatus)
    AND (@DateFrom IS NULL OR CAST(i.InvoiceDate AS DATE) >= @DateFrom)
    AND (@DateTo IS NULL OR CAST(i.InvoiceDate AS DATE) <= @DateTo)
    ORDER BY i.InvoiceDate DESC;
END
GO

-- usp_CalculateInsuranceCoverage
CREATE PROCEDURE Finance_Management.usp_CalculateInsuranceCoverage
    @InvoiceID INT
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(10,2);
    DECLARE @CoveragePercentage DECIMAL(5,2);
    DECLARE @Deductible DECIMAL(10,2);
    DECLARE @CoPay DECIMAL(10,2);
    DECLARE @InsurancePlanID INT;
    
    -- Get invoice total and insurance details
    SELECT 
        @TotalAmount = i.TotalAmount,
        @InsurancePlanID = i.InsurancePlanID,
        @Deductible = i.DeductibleAmount,
        @CoPay = i.CoPayAmount
    FROM Finance_Management.Invoices i
    WHERE i.InvoiceID = @InvoiceID;
    
    -- Get coverage percentage from insurance plan
    SELECT @CoveragePercentage = CoveragePercentage
    FROM Finance_Management.InsurancePlans
    WHERE PlanID = @InsurancePlanID;
    
    -- Calculate insurance coverage
    DECLARE @AmountAfterDeductible DECIMAL(10,2);
    DECLARE @InsuranceCoverage DECIMAL(10,2);
    DECLARE @PatientResponsibility DECIMAL(10,2);
    
    IF @TotalAmount > @Deductible
        SET @AmountAfterDeductible = @TotalAmount - @Deductible;
    ELSE
        SET @AmountAfterDeductible = 0;
    
    SET @InsuranceCoverage = @AmountAfterDeductible * (@CoveragePercentage / 100);
    SET @PatientResponsibility = @Deductible + (@AmountAfterDeductible * ((100 - @CoveragePercentage) / 100)) + @CoPay;
    
    -- Update the invoice
    UPDATE Finance_Management.Invoices 
    SET InsuranceCoverageAmount = @InsuranceCoverage,
        PatientResponsibilityAmount = @PatientResponsibility
    WHERE InvoiceID = @InvoiceID;
    
    SELECT 
        @InsuranceCoverage AS InsuranceCoverageAmount,
        @PatientResponsibility AS PatientResponsibilityAmount;
END
GO

-- =============================================
-- 6. INVOICE LINES STORED PROCEDURES
-- =============================================

-- usp_AddInvoiceLine
CREATE PROCEDURE Finance_Management.usp_AddInvoiceLine
    @InvoiceID INT,
    @ServiceID INT = NULL,
    @Description NVARCHAR(500),
    @Quantity INT = 1,
    @UnitPrice DECIMAL(10,2),
    @LineDiscountRate DECIMAL(5,2) = 0,
    @CreatedBy INT
AS
BEGIN
    DECLARE @LineDiscountAmount DECIMAL(10,2) = (@Quantity * @UnitPrice) * (@LineDiscountRate / 100);
    
    INSERT INTO Finance_Management.InvoiceLines 
    (InvoiceID, ServiceID, Description, Quantity, UnitPrice, LineDiscountRate, LineDiscountAmount)
    VALUES (@InvoiceID, @ServiceID, @Description, @Quantity, @UnitPrice, @LineDiscountRate, @LineDiscountAmount);
    
    -- Recalculate invoice totals
    EXEC Finance_Management.usp_RecalculateInvoiceTotals @InvoiceID;
    
    SELECT SCOPE_IDENTITY() AS LineID;
END
GO

-- usp_UpdateInvoiceLine
CREATE PROCEDURE Finance_Management.usp_UpdateInvoiceLine
    @LineID INT,
    @Description NVARCHAR(500) = NULL,
    @Quantity INT = NULL,
    @UnitPrice DECIMAL(10,2) = NULL,
    @LineDiscountRate DECIMAL(5,2) = NULL
AS
BEGIN
    UPDATE Finance_Management.InvoiceLines 
    SET Description = ISNULL(@Description, Description),
        Quantity = ISNULL(@Quantity, Quantity),
        UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        LineDiscountRate = ISNULL(@LineDiscountRate, LineDiscountRate),
        LineDiscountAmount = (ISNULL(@Quantity, Quantity) * ISNULL(@UnitPrice, UnitPrice)) * (ISNULL(@LineDiscountRate, LineDiscountRate) / 100)
    WHERE LineID = @LineID;
    
    -- Recalculate invoice totals
    DECLARE @InvoiceID INT;
    SELECT @InvoiceID = InvoiceID FROM Finance_Management.InvoiceLines WHERE LineID = @LineID;
    EXEC Finance_Management.usp_RecalculateInvoiceTotals @InvoiceID;
END
GO

-- usp_GetInvoiceLines
CREATE PROCEDURE Finance_Management.usp_GetInvoiceLines
    @InvoiceID INT
AS
BEGIN
    SELECT 
        il.*,
        s.ServiceCode,
        s.ServiceName
    FROM Finance_Management.InvoiceLines il
    LEFT JOIN Finance_Management.Services s ON il.ServiceID = s.ServiceID
    WHERE il.InvoiceID = @InvoiceID
    ORDER BY il.LineID;
END
GO

-- usp_RecalculateInvoiceTotals
CREATE PROCEDURE Finance_Management.usp_RecalculateInvoiceTotals
    @InvoiceID INT
AS
BEGIN
    DECLARE @SubTotal DECIMAL(10,2);
    DECLARE @TaxRate DECIMAL(5,2);
    DECLARE @DiscountRate DECIMAL(5,2);
    
    -- Get current tax and discount rates
    SELECT @TaxRate = TaxRate, @DiscountRate = DiscountRate
    FROM Finance_Management.Invoices WHERE InvoiceID = @InvoiceID;
    
    -- Calculate new subtotal from line items
    SELECT @SubTotal = SUM(LineTotal)
    FROM Finance_Management.InvoiceLines
    WHERE InvoiceID = @InvoiceID;
    
    -- Calculate tax and discount amounts
    DECLARE @TaxAmount DECIMAL(10,2) = @SubTotal * (@TaxRate / 100);
    DECLARE @DiscountAmount DECIMAL(10,2) = @SubTotal * (@DiscountRate / 100);
    DECLARE @TotalAmount DECIMAL(10,2) = @SubTotal + @TaxAmount - @DiscountAmount;
    
    -- Update the invoice
    UPDATE Finance_Management.Invoices 
    SET SubTotal = @SubTotal,
        TaxAmount = @TaxAmount,
        DiscountAmount = @DiscountAmount,
        TotalAmount = @TotalAmount,
        UpdatedDate = GETDATE()
    WHERE InvoiceID = @InvoiceID;
    
    SELECT @SubTotal AS SubTotal, @TaxAmount AS TaxAmount, @DiscountAmount AS DiscountAmount, @TotalAmount AS TotalAmount;
END
GO

-- =============================================
-- 7. PAYMENTS STORED PROCEDURES
-- =============================================

-- usp_CreatePayment
CREATE PROCEDURE Finance_Management.usp_CreatePayment
    @InvoiceID INT,
    @PaymentMethod NVARCHAR(20),
    @Amount DECIMAL(10,2),
    @ReferenceNumber NVARCHAR(50) = NULL,
    @PaymentType NVARCHAR(20) = 'Patient',
    @Notes NVARCHAR(500) = NULL,
    @ProcessedBy INT
AS
BEGIN
    INSERT INTO Finance_Management.Payments 
    (InvoiceID, PaymentMethod, Amount, ReferenceNumber, PaymentType, Notes, ProcessedBy)
    VALUES (@InvoiceID, @PaymentMethod, @Amount, @ReferenceNumber, @PaymentType, @Notes, @ProcessedBy);
    
    -- Update invoice paid amount and status
    DECLARE @PaidAmount DECIMAL(10,2);
    DECLARE @TotalAmount DECIMAL(10,2);
    
    SELECT @PaidAmount = SUM(Amount) 
    FROM Finance_Management.Payments 
    WHERE InvoiceID = @InvoiceID AND Status = 'Completed';
    
    SELECT @TotalAmount = TotalAmount 
    FROM Finance_Management.Invoices 
    WHERE InvoiceID = @InvoiceID;
    
    DECLARE @PaymentStatus NVARCHAR(20);
    IF @PaidAmount >= @TotalAmount
        SET @PaymentStatus = 'Paid';
    ELSE IF @PaidAmount > 0
        SET @PaymentStatus = 'Partial';
    ELSE
        SET @PaymentStatus = 'Unpaid';
    
    UPDATE Finance_Management.Invoices 
    SET PaidAmount = @PaidAmount,
        PaymentStatus = @PaymentStatus
    WHERE InvoiceID = @InvoiceID;
    
    SELECT SCOPE_IDENTITY() AS PaymentID;
END
GO

-- usp_UpdatePayment
CREATE PROCEDURE Finance_Management.usp_UpdatePayment
    @PaymentID INT,
    @Status NVARCHAR(20),
    @Notes NVARCHAR(500) = NULL,
    @UpdatedBy INT
AS
BEGIN
    UPDATE Finance_Management.Payments 
    SET Status = @Status,
        Notes = ISNULL(@Notes, Notes),
        UpdatedBy = @UpdatedBy,
        UpdatedDate = GETDATE()
    WHERE PaymentID = @PaymentID;
END
GO

-- usp_GetPaymentsByInvoice
CREATE PROCEDURE Finance_Management.usp_GetPaymentsByInvoice
    @InvoiceID INT
AS
BEGIN
    SELECT 
        p.*,
        s.FullName AS ProcessedByName
    FROM Finance_Management.Payments p
    INNER JOIN Core_system.Staff s ON p.ProcessedBy = s.StaffID
    WHERE p.InvoiceID = @InvoiceID
    ORDER BY p.PaymentDate DESC;
END
GO

-- usp_GetPaymentsByDateRange
CREATE PROCEDURE Finance_Management.usp_GetPaymentsByDateRange
    @StartDate DATE,
    @EndDate DATE,
    @PaymentMethod NVARCHAR(20) = NULL
AS
BEGIN
    SELECT 
        p.*,
        i.InvoiceNumber,
        pat.FirstName + ' ' + pat.LastName AS PatientName,
        s.FullName AS ProcessedByName
    FROM Finance_Management.Payments p
    INNER JOIN Finance_Management.Invoices i ON p.InvoiceID = i.InvoiceID
    INNER JOIN Patient_Management.Patient pat ON i.PatientID = pat.PatientID
    INNER JOIN Core_system.Staff s ON p.ProcessedBy = s.StaffID
    WHERE CAST(p.PaymentDate AS DATE) BETWEEN @StartDate AND @EndDate
    AND (@PaymentMethod IS NULL OR p.PaymentMethod = @PaymentMethod)
    AND p.Status = 'Completed'
    ORDER BY p.PaymentDate DESC;
END
GO

-- =============================================
-- 8. INSURANCE CLAIMS STORED PROCEDURES
-- =============================================

-- usp_SubmitInsuranceClaim
CREATE PROCEDURE Finance_Management.usp_SubmitInsuranceClaim
    @InvoiceID INT,
    @ClaimNumber NVARCHAR(100),
    @ClaimAmount DECIMAL(10,2),
    @SubmittedBy INT
AS
BEGIN
    DECLARE @InsurancePlanID INT;
    
    SELECT @InsurancePlanID = InsurancePlanID 
    FROM Finance_Management.Invoices 
    WHERE InvoiceID = @InvoiceID;
    
    INSERT INTO Finance_Management.InsuranceClaims 
    (InvoiceID, InsurancePlanID, ClaimNumber, ClaimAmount, SubmittedBy)
    VALUES (@InvoiceID, @InsurancePlanID, @ClaimNumber, @ClaimAmount, @SubmittedBy);
    
    -- Update invoice insurance status
    UPDATE Finance_Management.Invoices 
    SET InsuranceStatus = 'Submitted',
        InsuranceClaimNumber = @ClaimNumber
    WHERE InvoiceID = @InvoiceID;
    
    SELECT SCOPE_IDENTITY() AS ClaimID;
END
GO

-- usp_UpdateClaimStatus
CREATE PROCEDURE Finance_Management.usp_UpdateClaimStatus
    @ClaimID INT,
    @Status NVARCHAR(20),
    @ApprovedAmount DECIMAL(10,2) = NULL,
    @RejectionReason NVARCHAR(500) = NULL,
    @UpdatedBy INT
AS
BEGIN
    UPDATE Finance_Management.InsuranceClaims 
    SET Status = @Status,
        ApprovedAmount = ISNULL(@ApprovedAmount, ApprovedAmount),
        RejectedAmount = CASE WHEN @Status = 'Rejected' THEN ClaimAmount - ISNULL(@ApprovedAmount, 0) ELSE NULL END,
        RejectionReason = ISNULL(@RejectionReason, RejectionReason),
        ApprovedDate = CASE WHEN @Status IN ('Approved', 'Partially Approved', 'Paid') THEN GETDATE() ELSE ApprovedDate END,
        UpdatedBy = @UpdatedBy,
        UpdatedDate = GETDATE()
    WHERE ClaimID = @ClaimID;
    
    -- Update invoice insurance status
    DECLARE @InvoiceID INT;
    SELECT @InvoiceID = InvoiceID FROM Finance_Management.InsuranceClaims WHERE ClaimID = @ClaimID;
    
    UPDATE Finance_Management.Invoices 
    SET InsuranceStatus = @Status
    WHERE InvoiceID = @InvoiceID;
END
GO

-- usp_GetClaimsByStatus
CREATE PROCEDURE Finance_Management.usp_GetClaimsByStatus
    @Status NVARCHAR(20) = NULL,
    @DaysBack INT = 30
AS
BEGIN
    SELECT 
        c.*,
        i.InvoiceNumber,
        i.TotalAmount,
        p.FirstName + ' ' + p.LastName AS PatientName,
        ic.CompanyName AS InsuranceCompany,
        ip.PlanName AS InsurancePlan
    FROM Finance_Management.InsuranceClaims c
    INNER JOIN Finance_Management.Invoices i ON c.InvoiceID = i.InvoiceID
    INNER JOIN Patient_Management.Patient p ON i.PatientID = p.PatientID
    INNER JOIN Finance_Management.InsurancePlans ip ON c.InsurancePlanID = ip.PlanID
    INNER JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    WHERE (@Status IS NULL OR c.Status = @Status)
    AND c.SubmittedDate >= DATEADD(DAY, -@DaysBack, GETDATE())
    ORDER BY c.SubmittedDate DESC;
END
GO

-- usp_RecordInsurancePayment
CREATE PROCEDURE Finance_Management.usp_RecordInsurancePayment
    @ClaimID INT,
    @PaymentAmount DECIMAL(10,2),
    @ReferenceNumber NVARCHAR(100) = NULL,
    @Notes NVARCHAR(500) = NULL
AS
BEGIN
    INSERT INTO Finance_Management.InsurancePayments 
    (ClaimID, PaymentAmount, ReferenceNumber, Notes)
    VALUES (@ClaimID, @PaymentAmount, @ReferenceNumber, @Notes);
    
    -- Update claim status to Paid if full amount received
    DECLARE @TotalPaid DECIMAL(10,2);
    DECLARE @ClaimAmount DECIMAL(10,2);
    
    SELECT @TotalPaid = SUM(PaymentAmount) 
    FROM Finance_Management.InsurancePayments 
    WHERE ClaimID = @ClaimID;
    
    SELECT @ClaimAmount = ClaimAmount 
    FROM Finance_Management.InsuranceClaims 
    WHERE ClaimID = @ClaimID;
    
    IF @TotalPaid >= @ClaimAmount
    BEGIN
        UPDATE Finance_Management.InsuranceClaims 
        SET Status = 'Paid',
            PaymentDate = GETDATE()
        WHERE ClaimID = @ClaimID;
        
        -- Update invoice insurance status
        DECLARE @InvoiceID INT;
        SELECT @InvoiceID = InvoiceID FROM Finance_Management.InsuranceClaims WHERE ClaimID = @ClaimID;
        
        UPDATE Finance_Management.Invoices 
        SET InsuranceStatus = 'Paid'
        WHERE InvoiceID = @InvoiceID;
    END
    
    SELECT SCOPE_IDENTITY() AS InsurancePaymentID;
END
GO

-- =============================================
-- 9. REPORTS & ANALYTICS STORED PROCEDURES
-- =============================================

-- usp_GetRevenueReport
CREATE PROCEDURE Finance_Management.usp_GetRevenueReport
    @StartDate DATE,
    @EndDate DATE,
    @GroupBy NVARCHAR(20) = 'Daily' -- Daily, Weekly, Monthly
AS
BEGIN
    IF @GroupBy = 'Daily'
    BEGIN
        SELECT 
            CAST(i.InvoiceDate AS DATE) AS Period,
            COUNT(*) AS InvoiceCount,
            SUM(i.TotalAmount) AS TotalRevenue,
            SUM(i.PaidAmount) AS TotalCollected,
            SUM(i.BalanceAmount) AS Outstanding
        FROM Finance_Management.Invoices i
        WHERE CAST(i.InvoiceDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY CAST(i.InvoiceDate AS DATE)
        ORDER BY Period;
    END
    ELSE IF @GroupBy = 'Weekly'
    BEGIN
        SELECT 
            DATEPART(YEAR, i.InvoiceDate) AS Year,
            DATEPART(WEEK, i.InvoiceDate) AS Week,
            COUNT(*) AS InvoiceCount,
            SUM(i.TotalAmount) AS TotalRevenue,
            SUM(i.PaidAmount) AS TotalCollected,
            SUM(i.BalanceAmount) AS Outstanding
        FROM Finance_Management.Invoices i
        WHERE CAST(i.InvoiceDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY DATEPART(YEAR, i.InvoiceDate), DATEPART(WEEK, i.InvoiceDate)
        ORDER BY Year, Week;
    END
    ELSE IF @GroupBy = 'Monthly'
    BEGIN
        SELECT 
            YEAR(i.InvoiceDate) AS Year,
            MONTH(i.InvoiceDate) AS Month,
            COUNT(*) AS InvoiceCount,
            SUM(i.TotalAmount) AS TotalRevenue,
            SUM(i.PaidAmount) AS TotalCollected,
            SUM(i.BalanceAmount) AS Outstanding
        FROM Finance_Management.Invoices i
        WHERE CAST(i.InvoiceDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
        ORDER BY Year, Month;
    END
END
GO

-- usp_GetOutstandingInvoices
CREATE PROCEDURE Finance_Management.usp_GetOutstandingInvoices
    @DaysOverdue INT = NULL
AS
BEGIN
    SELECT 
        i.InvoiceNumber,
        i.InvoiceDate,
        i.DueDate,
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.MRN,
        i.TotalAmount,
        i.PaidAmount,
        i.BalanceAmount,
        i.PaymentStatus,
        DATEDIFF(DAY, i.DueDate, GETDATE()) AS DaysOverdue
    FROM Finance_Management.Invoices i
    INNER JOIN Patient_Management.Patient p ON i.PatientID = p.PatientID
    WHERE i.PaymentStatus IN ('Unpaid', 'Partial')
    AND i.BalanceAmount > 0
    AND (@DaysOverdue IS NULL OR DATEDIFF(DAY, i.DueDate, GETDATE()) >= @DaysOverdue)
    ORDER BY DaysOverdue DESC, i.BalanceAmount DESC;
END
GO

-- usp_GetInsuranceClaimsReport
CREATE PROCEDURE Finance_Management.usp_GetInsuranceClaimsReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT 
        ic.CompanyName AS InsuranceCompany,
        COUNT(*) AS TotalClaims,
        SUM(c.ClaimAmount) AS TotalClaimed,
        SUM(ISNULL(c.ApprovedAmount, 0)) AS TotalApproved,
        SUM(ISNULL(ip.PaymentAmount, 0)) AS TotalPaid,
        AVG(DATEDIFF(DAY, c.SubmittedDate, ISNULL(c.PaymentDate, GETDATE()))) AS AvgProcessingDays
    FROM Finance_Management.InsuranceClaims c
    INNER JOIN Finance_Management.InsurancePlans ip ON c.InsurancePlanID = ip.PlanID
    INNER JOIN Finance_Management.InsuranceCompanies ic ON ip.CompanyID = ic.CompanyID
    LEFT JOIN Finance_Management.InsurancePayments ipay ON c.ClaimID = ipay.ClaimID
    WHERE CAST(c.SubmittedDate AS DATE) BETWEEN @StartDate AND @EndDate
    GROUP BY ic.CompanyName
    ORDER BY TotalClaimed DESC;
END
GO

-- usp_GetPatientBillingSummary
CREATE PROCEDURE Finance_Management.usp_GetPatientBillingSummary
    @PatientID INT
AS
BEGIN
    SELECT 
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.MRN,
        COUNT(i.InvoiceID) AS TotalInvoices,
        SUM(i.TotalAmount) AS TotalBilled,
        SUM(i.PaidAmount) AS TotalPaid,
        SUM(i.BalanceAmount) AS TotalOutstanding,
        MAX(i.InvoiceDate) AS LastInvoiceDate
    FROM Patient_Management.Patient p
    LEFT JOIN Finance_Management.Invoices i ON p.PatientID = i.PatientID
    WHERE p.PatientID = @PatientID
    GROUP BY p.PatientID, p.FirstName, p.LastName, p.MRN;
END
GO