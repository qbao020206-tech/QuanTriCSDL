/*
=======================================================================
* Tên module: sp_ThemKhachHang
* Chức năng : Thêm khách hàng mới, tự động phát sinh mã, kiểm tra ràng buộc.
* Bảng tác động: KHACHHANG
=======================================================================
*/
USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROCEDURE sp_ThemKhachHang (
    @TenKH NVARCHAR(50),
    @NgaySinhKH DATETIME,
    @DiaChiKH NVARCHAR(100),
    @SDTKH VARCHAR(10),
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    -- Thiết lập mức cô lập giao dịch cao nhất để tránh đụng độ dữ liệu
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    -- 1. Kiểm tra dữ liệu rỗng
    IF @TenKH IS NULL OR @SDTKH IS NULL OR @DiaChiKH IS NULL
    BEGIN
        SET @thongBao = N'Tên, địa chỉ và số điện thoại khách hàng không được để trống!';
        RETURN;
    END

    -- 2. Kiểm tra định dạng số điện thoại (Phải đúng 10 số, không chứa ký tự chữ)
    IF LEN(@SDTKH) <> 10 OR @SDTKH LIKE '%[^0-9]%'
    BEGIN
        SET @thongBao = N'Số điện thoại không hợp lệ (phải đúng 10 chữ số)!';
        RETURN;
    END

    -- 3. Kiểm tra ngày sinh hợp lệ (Phải nhỏ hơn ngày hiện tại)
    IF @NgaySinhKH >= GETDATE()
    BEGIN
        SET @thongBao = N'Ngày sinh không hợp lệ!';
        RETURN;
    END

    -- 4. Kiểm tra số điện thoại đã tồn tại chưa (So sánh trực tiếp nguyên bản)
    IF EXISTS (SELECT 1 FROM KHACHHANG WHERE SDTKH = @SDTKH)
    BEGIN
        SET @thongBao = N'Số điện thoại đã tồn tại trong hệ thống!';
        RETURN;
    END

    BEGIN TRANSACTION
    BEGIN TRY
        -- 5. Phát sinh mã khách hàng tự động (Định dạng: KH + 8 số = 10 ký tự)
        DECLARE @max_maKH CHAR(10), @new_maKH CHAR(10);
        SELECT @max_maKH = MAX(MaKH) FROM KHACHHANG;
        
        -- Nếu chưa có dữ liệu, gán gốc là 00000000, có rồi thì cắt 8 số cuối
        SET @max_maKH = ISNULL(RIGHT(@max_maKH, 8), '00000000');
        
        -- Cộng thêm 1 vào mã lớn nhất hiện tại
        SET @new_maKH = 'KH' + RIGHT('00000000' + CAST(CAST(@max_maKH AS INT) + 1 AS VARCHAR), 8);

        -- 6. Thực hiện Insert dữ liệu vào bảng
        INSERT INTO KHACHHANG (MaKH, TenKH, NgaySinhKH, DiaChiKH, SDTKH)
        VALUES (@new_maKH, @TenKH, @NgaySinhKH, @DiaChiKH, @SDTKH);

        COMMIT TRANSACTION;
        SET @thongBao = N'Thêm khách hàng thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @thongBao = N'Lỗi khi thêm khách hàng: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO


--=========================================================================================================================================
--=========================================================================================================================================

/*
=======================================================================
* Tên module: sp_SuaKhachHang
* Chức năng : Cập nhật thông tin khách hàng. Cho phép truyền NULL nếu không đổi.
* Bảng tác động: KHACHHANG
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_SuaKhachHang (
    @MaKH CHAR(10),
    @TenKH NVARCHAR(50) = NULL,
    @NgaySinhKH DATETIME = NULL,
    @DiaChiKH NVARCHAR(100) = NULL,
    @SDTKH VARCHAR(10) = NULL,
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;
    BEGIN TRY
        SET @thongBao = N'';
        SET @check = 0;

        -- 1. Kiểm tra xem người dùng có truyền tham số nào vào không
        IF @TenKH IS NULL AND @NgaySinhKH IS NULL AND @DiaChiKH IS NULL AND @SDTKH IS NULL
        BEGIN
            SET @thongBao = N'Không có thông tin mới nào được truyền vào để cập nhật!';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Kiểm tra khách hàng tồn tại (Bỏ check TrangThai vì bảng không có)
        IF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MaKH = @MaKH)
        BEGIN
            SET @thongBao = N'Khách hàng không tồn tại trong hệ thống!';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Kiểm tra ngày sinh (nếu có truyền vào)
        IF @NgaySinhKH IS NOT NULL AND @NgaySinhKH >= GETDATE()
        BEGIN
            SET @thongBao = N'Ngày sinh cập nhật không hợp lệ (Không được ở tương lai)!';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 4. Kiểm tra SĐT (nếu có truyền vào)
        IF @SDTKH IS NOT NULL 
        BEGIN
            -- Kiểm tra định dạng 10 số
            IF LEN(@SDTKH) <> 10 OR @SDTKH LIKE '%[^0-9]%'
            BEGIN
                SET @thongBao = N'Số điện thoại không hợp lệ (Phải đúng 10 chữ số)!';
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Kiểm tra SĐT có bị trùng với khách khác không
            IF EXISTS (SELECT 1 FROM KHACHHANG WHERE SDTKH = @SDTKH AND MaKH != @MaKH)
            BEGIN
                SET @thongBao = N'Số điện thoại cập nhật đã bị trùng với một khách hàng khác!';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- 5. Thực hiện UPDATE gộp 1 lần (Tối ưu hiệu năng)
        -- ISNULL(@ThamSo, Cột_Cũ) sẽ giữ nguyên dữ liệu cũ nếu tham số truyền vào là NULL
        UPDATE KHACHHANG 
        SET 
            TenKH = ISNULL(@TenKH, TenKH),
            NgaySinhKH = ISNULL(@NgaySinhKH, NgaySinhKH),
            DiaChiKH = ISNULL(@DiaChiKH, DiaChiKH),
            SDTKH = ISNULL(@SDTKH, SDTKH)
        WHERE MaKH = @MaKH;

        COMMIT TRANSACTION;
        SET @thongBao = N'Cập nhật thông tin khách hàng thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @thongBao = N'LỖI: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--================================================================================
--=====================================================================================
/*
=======================================================================
* Tên module: sp_XoaKhachHang
* Chức năng : Thực hiện xóa cứng (Hard Delete) khách hàng. 
*             Ngăn chặn xóa nếu khách hàng đã có lịch sử mua hàng.
* Bảng tác động: KHACHHANG, HOADON_BAN
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_XoaKhachHang (
    @MaKH CHAR(10), 
    @thongBao NVARCHAR(500) OUTPUT, 
    @check BIT OUTPUT
)
AS
BEGIN
    -- Thiết lập mức cô lập giao dịch đồng bộ với các module khác
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    -- Kiểm tra dữ liệu truyền vào
    IF @MaKH IS NULL
    BEGIN
        SET @thongBao = N'Lỗi: Mã khách hàng không được để trống!';
        RETURN;
    END

    BEGIN TRY
        -- 1. Kiểm tra khách hàng có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MaKH = @MaKH)
        BEGIN
            SET @thongBao = N'Lỗi: Khách hàng không tồn tại hoặc đã bị xóa trước đó!';
            RETURN;
        END

        -- 2. Kiểm tra lịch sử mua hàng (Khóa ngoại)
        IF EXISTS (SELECT 1 FROM HOADON_BAN WHERE MaKH = @MaKH)
        BEGIN
            SET @thongBao = N'Từ chối Xóa: Khách hàng này đã có lịch sử mua hàng. Xóa sẽ làm hỏng dữ liệu doanh thu!';
            RETURN;
        END

        -- 3. Thực hiện xóa cứng nếu vượt qua kiểm tra
        BEGIN TRANSACTION;
        
        DELETE FROM KHACHHANG WHERE MaKH = @MaKH;

        COMMIT TRANSACTION;
        SET @thongBao = N'Đã xóa khách hàng thành công!';
        SET @check = 1;
        
    END TRY
    BEGIN CATCH
        -- Rollback nếu có lỗi trong quá trình thực thi lệnh DELETE
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO