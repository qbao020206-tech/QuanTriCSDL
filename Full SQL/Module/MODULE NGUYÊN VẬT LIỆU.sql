CREATE OR ALTER PROCEDURE sp_ThemNVL(
    @MaNVL CHAR(6),
    @TenNVL NVARCHAR(100),
    @DVT NVARCHAR(10),
    @thongbao NVARCHAR(300) OUTPUT,
    @ret_val BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET NOCOUNT ON;
    SET @ret_val = 0; SET @thongbao = N'';
 
    BEGIN TRY
        BEGIN TRANSACTION;
        -- 1. Kiểm tra trống
        IF @MaNVL IS NULL OR LTRIM(RTRIM(@MaNVL)) = '' OR @TenNVL IS NULL OR LTRIM(RTRIM(@TenNVL)) = ''
        BEGIN
            SET @thongbao = N'Lỗi: Mã và Tên nguyên vật liệu không được để trống!';
            ROLLBACK TRANSACTION; RETURN;
        END
        -- 2. Kiểm tra trùng
        IF EXISTS (SELECT 1 FROM NVL WHERE MaNVL = @MaNVL)
        BEGIN
            SET @thongbao = N'Lỗi: Mã Nguyên vật liệu đã tồn tại!';
            ROLLBACK TRANSACTION; RETURN;
        END
        -- 3. Insert (Chỉ dùng 3 cột theo sơ đồ)
        INSERT INTO NVL (MaNVL, TenNVL, DVT)
        VALUES (@MaNVL, @TenNVL, @DVT);
 
        COMMIT TRANSACTION;
        SET @thongbao = N'Thêm nguyên vật liệu mới thành công!';
        SET @ret_val = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @thongbao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        SET @ret_val = 0;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE sp_SuaNVL (
    @MaNVL CHAR(6),
    @TenNVL NVARCHAR(100) = NULL,
    @DVT NVARCHAR(10) = NULL,
    @thongbao NVARCHAR(500) OUTPUT,
    @ret_val BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET NOCOUNT ON;
    SET @ret_val = 0; SET @thongbao = N'';

    BEGIN TRY
        BEGIN TRANSACTION;
        -- 1. Kiểm tra tồn tại
        IF NOT EXISTS (SELECT 1 FROM NVL WHERE MaNVL = @MaNVL)
        BEGIN
            SET @thongbao = N'Lỗi: Không tìm thấy Nguyên vật liệu cần cập nhật!';
            ROLLBACK TRANSACTION; RETURN;
        END
        -- 2. Cập nhật linh hoạt (Bỏ DonGia)
        UPDATE NVL
        SET TenNVL = ISNULL(@TenNVL, TenNVL),
            DVT = ISNULL(@DVT, DVT)
        WHERE MaNVL = @MaNVL;

        COMMIT TRANSACTION;
        SET @thongbao = N'Cập nhật thông tin Nguyên vật liệu thành công!';
        SET @ret_val = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @thongbao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        SET @ret_val = 0;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_SuaNVL (
    @MaNVL CHAR(6),
    @TenNVL NVARCHAR(100) = NULL,
    @DVT NVARCHAR(10) = NULL,
    @thongbao NVARCHAR(500) OUTPUT,
    @ret_val BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET NOCOUNT ON;
    SET @ret_val = 0; SET @thongbao = N'';

    BEGIN TRY
        BEGIN TRANSACTION;
        -- 1. Kiểm tra tồn tại
        IF NOT EXISTS (SELECT 1 FROM NVL WHERE MaNVL = @MaNVL)
        BEGIN
            SET @thongbao = N'Lỗi: Không tìm thấy Nguyên vật liệu cần cập nhật!';
            ROLLBACK TRANSACTION; RETURN;
        END
        -- 2. Cập nhật linh hoạt (Bỏ DonGia)
        UPDATE NVL
        SET TenNVL = ISNULL(@TenNVL, TenNVL),
            DVT = ISNULL(@DVT, DVT)
        WHERE MaNVL = @MaNVL;

        COMMIT TRANSACTION;
        SET @thongbao = N'Cập nhật thông tin Nguyên vật liệu thành công!';
        SET @ret_val = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @thongbao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        SET @ret_val = 0;
    END CATCH
END;
GO