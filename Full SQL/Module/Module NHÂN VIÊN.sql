/*
=======================================================================
* Tên module: sp_ThemNhanVien
* Chức năng : Thêm nhân viên mới. Kiểm tra trùng lặp Mã NV, SĐT và STK.
* Bảng tác động: NHANVIEN
=======================================================================
*/
USE QLY_CONGCAFFE
GO
CREATE OR ALTER PROCEDURE sp_ThemNhanVien (
    @MaNV CHAR(10),
    @TenNV NVARCHAR(50),
    @GioiTinh NVARCHAR(3),
    @NgaySinhNV DATETIME,
    @STK NVARCHAR(50), -- Đã sửa lại cho khớp với bảng (NVARCHAR(50))
    @SDTNV CHAR(10),
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    -- Kiểm tra dữ liệu bắt buộc không được để trống
    IF @MaNV IS NULL OR @TenNV IS NULL
    BEGIN
        SET @thongBao = N'Lỗi: Mã nhân viên và Tên nhân viên không được để trống!';
        RETURN;
    END

    BEGIN TRY
        -- 1. Kiểm tra trùng lặp Khóa chính và các cột UNIQUE
        IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaNV)
        BEGIN
            SET @thongBao = N'Lỗi: Mã nhân viên này đã tồn tại trong hệ thống!';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM NHANVIEN WHERE SDTNV = @SDTNV)
        BEGIN
            SET @thongBao = N'Lỗi: Số điện thoại này đã được đăng ký cho nhân viên khác!';
            RETURN;
        END

        IF @STK IS NOT NULL AND EXISTS (SELECT 1 FROM NHANVIEN WHERE STK = @STK)
        BEGIN
            SET @thongBao = N'Lỗi: Số tài khoản này đã tồn tại trong hệ thống!';
            RETURN;
        END

        -- 2. Tiến hành thêm dữ liệu
        BEGIN TRANSACTION;
        
        INSERT INTO NHANVIEN (MaNV, TenNV, GioiTinh, NgaySinhNV, STK, SDTNV)
        VALUES (@MaNV, @TenNV, @GioiTinh, @NgaySinhNV, @STK, @SDTNV);

        COMMIT TRANSACTION;
        SET @thongBao = N'Thêm nhân viên thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        -- Bắt các lỗi ràng buộc CHECK từ database (tuổi, định dạng sđt, giới tính...)
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--===============================================================================================
--===============================================================================================

/*
=======================================================================
* Tên module: sp_SuaNhanVien
* Chức năng : Cập nhật thông tin nhân viên. Loại trừ kiểm tra trùng lặp 
* thông tin với chính bản thân nhân viên đó. Đồng bộ cấu trúc OUTPUT.
* Bảng tác động: NHANVIEN
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_SuaNhanVien (
    @MaNV CHAR(10),
    @TenNV NVARCHAR(50),
    @GioiTinh NVARCHAR(3),
    @NgaySinhNV DATETIME,
    @STK NVARCHAR(50), -- Đồng bộ kiểu dữ liệu với bảng
    @SDTNV CHAR(10),
    @thongBao NVARCHAR(500) OUTPUT, -- Đồng bộ kiến trúc trả về
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    BEGIN TRY
        -- 1. Kiểm tra nhân viên có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaNV)
        BEGIN
            SET @thongBao = N'Lỗi: Không tìm thấy nhân viên cần sửa!';
            RETURN;
        END

        -- 2. Kiểm tra trùng lặp (Loại trừ chính nhân viên đang sửa)
        IF EXISTS (SELECT 1 FROM NHANVIEN WHERE SDTNV = @SDTNV AND MaNV <> @MaNV)
        BEGIN
            SET @thongBao = N'Lỗi: Số điện thoại này đã được đăng ký cho nhân viên khác!';
            RETURN;
        END

        IF @STK IS NOT NULL AND EXISTS (SELECT 1 FROM NHANVIEN WHERE STK = @STK AND MaNV <> @MaNV)
        BEGIN
            SET @thongBao = N'Lỗi: Số tài khoản này đã được đăng ký cho nhân viên khác!';
            RETURN;
        END

        -- 3. Tiến hành cập nhật
        BEGIN TRANSACTION;
        
        UPDATE NHANVIEN
        SET TenNV = @TenNV,
            GioiTinh = @GioiTinh,
            NgaySinhNV = @NgaySinhNV,
            STK = @STK,
            SDTNV = @SDTNV
        WHERE MaNV = @MaNV;

        COMMIT TRANSACTION;
        SET @thongBao = N'Cập nhật thông tin nhân viên thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi xảy ra và giao dịch đang mở thì Rollback
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--============================================================================================
--============================================================================================

/*
=======================================================================
* Tên module: sp_XoaNhanVien
* Chức năng : Xóa nhân viên khỏi hệ thống. Ngăn chặn xóa nếu nhân viên 
* đã có lịch sử lập Hóa Đơn Bán hoặc Hóa Đơn Nhập.
* Bảng tác động: NHANVIEN, HOADON_BAN, HOADON_NHAP
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_XoaNhanVien (
    @MaNV CHAR(10),
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    BEGIN TRY
        -- 1. Kiểm tra nhân viên có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaNV)
        BEGIN
            SET @thongBao = N'Lỗi: Không tìm thấy nhân viên cần xóa!';
            RETURN;
        END

        -- 2. Kiểm tra Khóa ngoại: Nhân viên đã lập Hóa đơn bán chưa?
        IF EXISTS (SELECT 1 FROM HOADON_BAN WHERE MaNV = @MaNV)
        BEGIN
            SET @thongBao = N'Từ chối Xóa: Nhân viên này đã từng lập Hóa Đơn Bán. Xóa sẽ làm hỏng dữ liệu doanh thu!';
            RETURN;
        END

        -- 3. Kiểm tra Khóa ngoại: Nhân viên đã lập Hóa đơn nhập kho chưa?
        IF EXISTS (SELECT 1 FROM HOADON_NHAP WHERE MaNV = @MaNV)
        BEGIN
            SET @thongBao = N'Từ chối Xóa: Nhân viên này đã từng lập Hóa Đơn Nhập Kho. Xóa sẽ làm hỏng dữ liệu kho!';
            RETURN;
        END

        -- 4. Nếu vượt qua tất cả bài kiểm tra, tiến hành xóa
        BEGIN TRANSACTION;
        
        DELETE FROM NHANVIEN WHERE MaNV = @MaNV;

        COMMIT TRANSACTION;
        SET @thongBao = N'Xóa nhân viên thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        -- Rollback nếu có lỗi xảy ra trong quá trình DELETE
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO