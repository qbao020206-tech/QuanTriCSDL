/*
=======================================================================
* Tên module: sp_ThemNCC
* Chức năng : Thêm hồ sơ Nhà cung cấp mới. Đảm bảo Mã NCC và SĐT 
* là duy nhất. Đồng bộ chuẩn OUTPUT và TRANSACTION.
* Bảng tác động: NCC
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_ThemNCC (
    @MaNCC CHAR(6),
    @TenNCC NVARCHAR(100),
    @DiaChiNCC NVARCHAR(150),
    @SDTNCC VARCHAR(10),
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    -- 0. Kiểm tra dữ liệu bắt buộc (NOT NULL)
    IF @MaNCC IS NULL OR @TenNCC IS NULL OR @DiaChiNCC IS NULL OR @SDTNCC IS NULL
    BEGIN
        SET @thongBao = N'Lỗi: Tất cả các thông tin của Nhà cung cấp đều bắt buộc, không được để trống!';
        RETURN;
    END

    BEGIN TRY
        -- 1. Kiểm tra trùng lặp Khóa chính (Mã NCC)
        IF EXISTS (SELECT 1 FROM NCC WHERE MaNCC = @MaNCC)
        BEGIN
            SET @thongBao = N'Lỗi: Mã Nhà cung cấp này đã tồn tại trong hệ thống!';
            RETURN;
        END

        -- 2. Kiểm tra trùng lặp Số điện thoại (Ràng buộc UNIQUE)
        IF EXISTS (SELECT 1 FROM NCC WHERE SDTNCC = @SDTNCC)
        BEGIN
            SET @thongBao = N'Lỗi: Số điện thoại này đã được đăng ký cho một Nhà cung cấp khác!';
            RETURN;
        END

        -- 3. Tiến hành thêm dữ liệu
        BEGIN TRANSACTION;
        
        INSERT INTO NCC (MaNCC, TenNCC, DiaChiNCC, SDTNCC)
        VALUES (@MaNCC, @TenNCC, @DiaChiNCC, @SDTNCC);

        COMMIT TRANSACTION;
        SET @thongBao = N'Thêm Nhà cung cấp mới thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        -- Bắt các lỗi ràng buộc CHECK từ database (như chứa chữ cái trong SĐT)
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--=======================================================================================
--============================================================================================
/*
=======================================================================
* Tên module: sp_SuaNCC
* Chức năng : Cập nhật thông tin Nhà cung cấp. Loại trừ kiểm tra trùng lặp 
*             SĐT với chính NCC đó. Hỗ trợ cập nhật một phần (Partial Update).
* Bảng tác động: NCC
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_SuaNCC (
    @MaNCC CHAR(6),
    @TenNCC NVARCHAR(100) = NULL,
    @DiaChiNCC NVARCHAR(150) = NULL,
    @SDTNCC VARCHAR(10) = NULL,
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    BEGIN TRY
        -- 1. Kiểm tra xem có thông tin nào được truyền vào để sửa không
        IF @TenNCC IS NULL AND @DiaChiNCC IS NULL AND @SDTNCC IS NULL
        BEGIN
            SET @thongBao = N'Lỗi: Không có thông tin mới nào được truyền vào để cập nhật!';
            RETURN;
        END

        -- 2. Kiểm tra Nhà cung cấp có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM NCC WHERE MaNCC = @MaNCC)
        BEGIN
            SET @thongBao = N'Lỗi: Không tìm thấy Nhà cung cấp cần cập nhật!';
            RETURN;
        END

        -- 3. Kiểm tra trùng lặp Số điện thoại (Chỉ kiểm tra nếu có truyền SĐT mới vào)
        IF @SDTNCC IS NOT NULL AND EXISTS (SELECT 1 FROM NCC WHERE SDTNCC = @SDTNCC AND MaNCC <> @MaNCC)
        BEGIN
            SET @thongBao = N'Lỗi: Số điện thoại cập nhật đã thuộc về một đối tác khác!';
            RETURN;
        END

        -- 4. Tiến hành cập nhật
        BEGIN TRANSACTION;
        
        UPDATE NCC
        SET TenNCC = ISNULL(@TenNCC, TenNCC),
            DiaChiNCC = ISNULL(@DiaChiNCC, DiaChiNCC),
            SDTNCC = ISNULL(@SDTNCC, SDTNCC)
        WHERE MaNCC = @MaNCC;

        COMMIT TRANSACTION;
        SET @thongBao = N'Cập nhật thông tin Nhà cung cấp thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--======================================================
--=============================================================

/*
=======================================================================
* Tên module: sp_XoaNCC
* Chức năng : Xóa vật lý Nhà cung cấp. Bảo vệ dữ liệu kế toán bằng cách
*             chặn xóa đối với những nhà cung cấp đã có lịch sử nhập hàng.
* Bảng tác động: NCC, HOADON_NHAP
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_XoaNCC (
    @MaNCC CHAR(6),
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    BEGIN TRY
        -- 1. Kiểm tra Nhà cung cấp có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM NCC WHERE MaNCC = @MaNCC)
        BEGIN
            SET @thongBao = N'Lỗi: Không tìm thấy Nhà cung cấp cần xóa!';
            RETURN;
        END

        -- 2. Kiểm tra Khóa ngoại (Đã từng nhập hàng của đối tác này chưa?)
        IF EXISTS (SELECT 1 FROM HOADON_NHAP WHERE MaNCC = @MaNCC)
        BEGIN
            SET @thongBao = N'Từ chối Xóa: Hệ thống đã ghi nhận lịch sử nhập kho từ đối tác này. Xóa sẽ làm mất dữ liệu công nợ và chi phí. Vui lòng ngưng hợp tác thay vì xóa!';
            RETURN;
        END

        -- 3. Tiến hành xóa nếu chưa từng có giao dịch
        BEGIN TRANSACTION;
        
        DELETE FROM NCC WHERE MaNCC = @MaNCC;

        COMMIT TRANSACTION;
        SET @thongBao = N'Xóa Nhà cung cấp thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        -- Rollback nếu có lỗi bất ngờ trong lúc DELETE
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO