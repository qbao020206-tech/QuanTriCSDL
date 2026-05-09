/*
=======================================================================
* Tên module : sp_XoaHoaDonNhap
* Chức năng  : Xóa hóa đơn nhập và toàn bộ chi tiết hóa đơn nhập liên quan.
*              Áp dụng nguyên tắc xóa bảng con (CTHD) trước, bảng cha (Hóa đơn) sau.
* Bảng tác động: HOADON_NHAP, CTHD_NHAP
=======================================================================
*/
USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROCEDURE sp_XoaHoaDonNhap
(
    @MaHD_NH CHAR(10),
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    -- Đồng bộ mức độ cô lập giao dịch
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    SET @thongBao = N'';
    SET @check = 0;

    -- 1. Validate đầu vào
    IF @MaHD_NH IS NULL OR LTRIM(RTRIM(@MaHD_NH)) = ''
    BEGIN
        SET @thongBao = N'Mã hóa đơn nhập không được để trống!';
        RETURN;
    END

    -- 2. Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM HOADON_NHAP WHERE MaHD_NH = @MaHD_NH)
    BEGIN
        SET @thongBao = N'Hóa đơn nhập không tồn tại hoặc đã bị xóa!';
        RETURN;
    END

    -- 3. Bắt đầu giao dịch xóa
    BEGIN TRANSACTION;
    BEGIN TRY
        -- XÓA CON TRƯỚC: Xóa toàn bộ chi tiết nguyên vật liệu thuộc hóa đơn này
        DELETE FROM CTHD_NHAP
        WHERE MaHD_NH = @MaHD_NH;

        -- XÓA CHA SAU: Xóa vỏ hóa đơn nhập
        DELETE FROM HOADON_NHAP
        WHERE MaHD_NH = @MaHD_NH;

        COMMIT TRANSACTION;
        SET @thongBao = N'Xóa hóa đơn nhập và toàn bộ chi tiết thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        -- Kiểm tra an toàn trước khi Rollback
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @thongBao = N'Lỗi hệ thống khi xóa hóa đơn nhập: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

/*
=======================================================================
* Tên module : sp_XoaChiTietHoaDonNhap
* Chức năng  : Xóa một dòng chi tiết nguyên vật liệu khỏi hóa đơn nhập 
*              và tự động tính lại tổng tiền cho vỏ hóa đơn.
* Bảng tác động: CTHD_NHAP, HOADON_NHAP
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_XoaChiTietHoaDonNhap
(
    @MaHD_NH CHAR(10),
    @MaNVL CHAR(6), -- Đã sửa lại thành CHAR(6) cho khớp bảng NVL
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    SET @thongBao = N'';
    SET @check = 0;

    -- 1. Validate dữ liệu đầu vào
    IF @MaHD_NH IS NULL OR LTRIM(RTRIM(@MaHD_NH)) = ''
    BEGIN
        SET @thongBao = N'Lỗi: Mã hóa đơn nhập không được để trống!';
        RETURN;
    END

    IF @MaNVL IS NULL OR LTRIM(RTRIM(@MaNVL)) = ''
    BEGIN
        SET @thongBao = N'Lỗi: Mã nguyên vật liệu không được để trống!';
        RETURN;
    END

    -- 2. Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM HOADON_NHAP WHERE MaHD_NH = @MaHD_NH)
    BEGIN
        SET @thongBao = N'Lỗi: Hóa đơn nhập không tồn tại!';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM CTHD_NHAP WHERE MaHD_NH = @MaHD_NH AND MaNVL = @MaNVL)
    BEGIN
        SET @thongBao = N'Lỗi: Chi tiết nguyên vật liệu này không có trong hóa đơn!';
        RETURN;
    END

    -- 3. Tiến hành Xóa và Cập nhật
    BEGIN TRANSACTION;
    BEGIN TRY
        -- BƯỚC 1: Xóa dòng chi tiết
        DELETE FROM CTHD_NHAP
        WHERE MaHD_NH = @MaHD_NH AND MaNVL = @MaNVL;

        -- BƯỚC 2: Tính lại Tổng tiền cho vỏ hóa đơn (Tính trên cột ThanhTien)
        UPDATE HOADON_NHAP
        SET TongTien = ISNULL(
            (
                SELECT SUM(ThanhTien) 
                FROM CTHD_NHAP
                WHERE MaHD_NH = @MaHD_NH
            ), 0 -- Nếu xóa hết sạch chi tiết thì SUM ra NULL, ISNULL sẽ gán về 0
        )
        WHERE MaHD_NH = @MaHD_NH;

        COMMIT TRANSACTION;
        SET @thongBao = N'Xóa chi tiết nhập thành công và đã cập nhật lại tổng tiền!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @thongBao = N'Lỗi hệ thống khi xóa chi tiết hóa đơn nhập: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO
/*
=======================================================================
* Tên module : sp_XoaHoaDonBan
* Chức năng  : Xóa hóa đơn bán và toàn bộ chi tiết hóa đơn.
*              Đồng thời trả lại trạng thái Bàn về 'Trống'.
* Bảng tác động: HOADON_BAN, CTHD_BAN, VITRI
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_XoaHoaDonBan
(
    @MaBill CHAR(20), -- Đã đồng bộ lên CHAR(20)
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    SET @thongBao = N'';
    SET @check = 0;

    -- 1. Validate đầu vào
    IF @MaBill IS NULL OR LTRIM(RTRIM(@MaBill)) = ''
    BEGIN
        SET @thongBao = N'Mã hóa đơn bán không được để trống!';
        RETURN;
    END

    -- 2. Kiểm tra tồn tại và lấy MSBAN để lát nữa trả lại trạng thái bàn
    DECLARE @MSBan_Tam CHAR(10);
    
    SELECT @MSBan_Tam = MSBAN 
    FROM HOADON_BAN 
    WHERE MaBILL = @MaBill;

    IF @MSBan_Tam IS NULL
    BEGIN
        SET @thongBao = N'Hóa đơn bán không tồn tại hoặc đã bị xóa trước đó!';
        RETURN;
    END

    -- 3. Bắt đầu giao dịch
    BEGIN TRANSACTION;
    BEGIN TRY
        -- BƯỚC 1: Xóa con trước (Chi tiết hóa đơn)
        DELETE FROM CTHD_BAN
        WHERE MaBILL = @MaBill;

        -- BƯỚC 2: Xóa cha sau (Vỏ hóa đơn)
        DELETE FROM HOADON_BAN
        WHERE MaBILL = @MaBill;

        -- BƯỚC 3: Trả lại trạng thái bàn về 'Trống'
        UPDATE VITRI 
        SET TrangThai = N'Trống' 
        WHERE MSBAN = @MSBan_Tam;

        COMMIT TRANSACTION;
        SET @thongBao = N'Hủy hóa đơn thành công! Bàn đã được trả về trạng thái Trống.';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @thongBao = N'Lỗi hệ thống khi xóa hóa đơn bán: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

/*
=======================================================================
* Tên module: sp_ThemCTHD_Ban
* Chức năng : Thêm món vào Hóa đơn bán. Tính thành tiền tự động qua 
*             Computed Column và CỘNG DỒN Tổng Tiền cho vỏ hóa đơn.
* Bảng tác động: CTHD_BAN, HOADON_BAN
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_XoaChiTietHoaDonBan
(
    @MaBill CHAR(20), -- Đã sửa thành CHAR(20) cho khớp bảng HOADON_BAN
    @MaSP CHAR(20),   -- Đã sửa thành CHAR(20) cho khớp bảng SANPHAM
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    SET @thongBao = N'';
    SET @check = 0;

    -- 1. Validate dữ liệu đầu vào
    IF @MaBill IS NULL OR LTRIM(RTRIM(@MaBill)) = ''
    BEGIN
        SET @thongBao = N'Lỗi: Mã hóa đơn bán không được để trống!';
        RETURN;
    END

    IF @MaSP IS NULL OR LTRIM(RTRIM(@MaSP)) = ''
    BEGIN
        SET @thongBao = N'Lỗi: Mã sản phẩm không được để trống!';
        RETURN;
    END

    -- 2. Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM HOADON_BAN WHERE MaBILL = @MaBill)
    BEGIN
        SET @thongBao = N'Lỗi: Hóa đơn bán không tồn tại!';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM CTHD_BAN WHERE MaBILL = @MaBill AND MaSP = @MaSP)
    BEGIN
        SET @thongBao = N'Lỗi: Sản phẩm này không có trong hóa đơn bán!';
        RETURN;
    END

    -- 3. Tiến hành Xóa và Cập nhật Tổng tiền
    BEGIN TRANSACTION;
    BEGIN TRY
        -- BƯỚC 1: Xóa dòng chi tiết món ăn/đồ uống
        DELETE FROM CTHD_BAN
        WHERE MaBILL = @MaBill AND MaSP = @MaSP;

        -- BƯỚC 2: Tính lại Tổng tiền cho vỏ hóa đơn (Tính trên cột Computed Column ThanhTien)
        UPDATE HOADON_BAN
        SET TongTien = ISNULL(
            (
                SELECT SUM(ThanhTien)
                FROM CTHD_BAN
                WHERE MaBILL = @MaBill
            ), 0 -- Nếu khách hủy món cuối cùng (bill trống), Tổng tiền trả về 0
        )
        WHERE MaBILL = @MaBill;

        COMMIT TRANSACTION;
        SET @thongBao = N'Xóa món khỏi hóa đơn thành công và đã cập nhật lại tổng tiền!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        -- Bắt lỗi an toàn
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @thongBao = N'Lỗi hệ thống khi xóa chi tiết hóa đơn bán: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

