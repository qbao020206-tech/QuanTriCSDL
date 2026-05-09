/*
=======================================================================
* Tên module: sp_ThemSanPham
* Chức năng : Thêm sản phẩm mới vào menu. Kiểm tra tính hợp lệ của Giá bán
* và ràng buộc khóa ngoại với bảng LOAISANPHAM. Đồng bộ biến OUTPUT.
* Bảng tác động: SANPHAM
=======================================================================
*/

USE QLY_CONGCAFFE;
GO
a
CREATE OR ALTER PROCEDURE sp_ThemSanPham (
    @MaSP CHAR(20),        -- Đã đồng bộ CHAR(20)
    @TenSP NVARCHAR(50),   -- Đã đồng bộ NVARCHAR(50)
    @GiaSP MONEY,          -- Đã đồng bộ MONEY
    @MaLSP VARCHAR(10),    -- Đã đồng bộ VARCHAR(10)
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    -- 1. Kiểm tra dữ liệu bắt buộc (NOT NULL)
    IF @MaSP IS NULL OR @TenSP IS NULL OR @GiaSP IS NULL
    BEGIN
        SET @thongBao = N'Lỗi: Mã sản phẩm, Tên sản phẩm và Giá bán không được để trống!';
        RETURN;
    END

    BEGIN TRY
        -- 2. Kiểm tra trùng Mã Sản Phẩm (Khóa chính)
        IF EXISTS (SELECT 1 FROM SANPHAM WHERE MaSP = @MaSP)
        BEGIN
            SET @thongBao = N'Lỗi: Mã sản phẩm này đã tồn tại trong menu!';
            RETURN;
        END

        -- 3. Kiểm tra Giá bán phải lớn hơn hoặc bằng 0
        IF @GiaSP < 0
        BEGIN
            SET @thongBao = N'Lỗi: Giá bán sản phẩm không được là số âm!';
            RETURN;
        END

        -- 4. Kiểm tra Mã Loại Sản Phẩm có tồn tại không (Khóa ngoại)
        IF @MaLSP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM LOAISANPHAM WHERE MaLSP = @MaLSP)
        BEGIN
            SET @thongBao = N'Lỗi: Mã Loại Sản Phẩm không tồn tại trong hệ thống. Vui lòng kiểm tra lại danh mục!';
            RETURN;
        END

        -- 5. Tiến hành thêm mới vào bảng
        BEGIN TRANSACTION;
        
        INSERT INTO SANPHAM (MaSP, TenSP, GiaSP, MaLSP)
        VALUES (@MaSP, @TenSP, @GiaSP, @MaLSP);

        COMMIT TRANSACTION;
        SET @thongBao = N'Thêm sản phẩm mới vào Menu thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO


--==================================================================================
--=================================================================================
/*
=======================================================================
* Tên module: sp_SuaSanPham
* Chức năng : Cập nhật thông tin (Tên, Giá, Loại) của sản phẩm đã có.
*             Cho phép truyền NULL nếu không muốn thay đổi cột đó.
* Bảng tác động: SANPHAM
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_SuaSanPham (
    @MaSP CHAR(20),             -- Đồng bộ CHAR(20)
    @TenSP NVARCHAR(50) = NULL, -- Đồng bộ NVARCHAR(50), gán mặc định NULL
    @GiaSP MONEY = NULL,        -- Đồng bộ MONEY, gán mặc định NULL
    @MaLSP VARCHAR(10) = NULL,  -- Đồng bộ VARCHAR(10), gán mặc định NULL
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    BEGIN TRY
        -- 1. Kiểm tra xem có truyền tham số nào vào để sửa không
        IF @TenSP IS NULL AND @GiaSP IS NULL AND @MaLSP IS NULL
        BEGIN
            SET @thongBao = N'Lỗi: Không có thông tin mới nào được truyền vào để cập nhật!';
            RETURN;
        END

        -- 2. Kiểm tra Sản phẩm có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM SANPHAM WHERE MaSP = @MaSP)
        BEGIN
            SET @thongBao = N'Lỗi: Không tìm thấy sản phẩm cần cập nhật!';
            RETURN;
        END

        -- 3. Kiểm tra Giá bán (nếu có truyền vào cập nhật)
        IF @GiaSP IS NOT NULL AND @GiaSP < 0
        BEGIN
            SET @thongBao = N'Lỗi: Giá bán sản phẩm không được là số âm!';
            RETURN;
        END

        -- 4. Kiểm tra Loại sản phẩm (Khóa ngoại, nếu có thay đổi)
        IF @MaLSP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM LOAISANPHAM WHERE MaLSP = @MaLSP)
        BEGIN
            SET @thongBao = N'Lỗi: Mã Loại Sản Phẩm không hợp lệ hoặc không tồn tại!';
            RETURN;
        END

        -- 5. Tiến hành cập nhật
        BEGIN TRANSACTION;
        
        -- Dùng ISNULL để giữ lại giá trị cũ nếu tham số truyền vào là NULL
        UPDATE SANPHAM
        SET TenSP = ISNULL(@TenSP, TenSP),
            GiaSP = ISNULL(@GiaSP, GiaSP),
            MaLSP = ISNULL(@MaLSP, MaLSP)
        WHERE MaSP = @MaSP;

        COMMIT TRANSACTION;
        SET @thongBao = N'Cập nhật thông tin sản phẩm thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--==================================================================================
--=================================================================================

/*
=======================================================================
* Tên module: sp_XoaSanPham
* Chức năng : Xóa sản phẩm khỏi hệ thống. Ngăn chặn xóa nếu sản phẩm 
* đã phát sinh giao dịch trong Chi tiết Hóa Đơn Bán.
* Bảng tác động: SANPHAM, CTHD_BAN
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_XoaSanPham (
    @MaSP CHAR(20), -- Đồng bộ kiểu dữ liệu CHAR(20)
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET @thongBao = N'';
    SET @check = 0;

    BEGIN TRY
        -- 1. Kiểm tra Sản phẩm có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM SANPHAM WHERE MaSP = @MaSP)
        BEGIN
            SET @thongBao = N'Lỗi: Không tìm thấy sản phẩm cần xóa!';
            RETURN;
        END

        -- 2. Kiểm tra Khóa ngoại (Sản phẩm này đã từng được bán chưa?)
        IF EXISTS (SELECT 1 FROM CTHD_BAN WHERE MaSP = @MaSP)
        BEGIN
            SET @thongBao = N'Từ chối Xóa: Sản phẩm này đã phát sinh giao dịch bán hàng trong quá khứ. Việc xóa sẽ làm hỏng dữ liệu doanh thu. Thay vào đó, hãy ẩn sản phẩm này trên phần mềm!';
            RETURN;
        END

        -- 3. Tiến hành xóa nếu sản phẩm chưa từng được bán
        BEGIN TRANSACTION;
        
        DELETE FROM SANPHAM WHERE MaSP = @MaSP;

        COMMIT TRANSACTION;
        SET @thongBao = N'Xóa sản phẩm thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO