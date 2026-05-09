/*
=======================================================================
* Tên module: sp_ThemHoaDonNhap
* Chức năng : Tạo vỏ hóa đơn nhập hàng. Tự động sinh mã HDN và gán 
*             Tổng tiền mặc định = 0. Trả về Mã HDN vừa tạo.
* Bảng tác động: HOADON_NHAP
=======================================================================
*/
USE QLY_CONGCAFFE
GO
CREATE OR ALTER PROCEDURE sp_ThemHoaDonNhap (
    @MaNV CHAR(10),
    @MaNCC CHAR(6), -- Đã sửa lại cho khớp với bảng NCC (CHAR 6)
    @NgayLap DATETIME,
    @PTThanhToan CHAR(10),
    @ThueVAT DECIMAL(5,2) = 0.1,
    @MaHD_NH_Out CHAR(10) OUTPUT, -- Biến trả về mã HĐ vừa tạo để dùng cho CTHD
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

        -- 1. Kiểm tra Khóa ngoại
        IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaNV)
        BEGIN 
            SET @thongBao = N'Lỗi: Nhân viên không tồn tại trong hệ thống!'; 
            ROLLBACK TRAN; 
            RETURN; 
        END

        IF NOT EXISTS (SELECT 1 FROM NCC WHERE MaNCC = @MaNCC)
        BEGIN 
            SET @thongBao = N'Lỗi: Nhà cung cấp không tồn tại!'; 
            ROLLBACK TRAN; 
            RETURN; 
        END

        -- 2. Kiểm tra tính hợp lệ của Ngày lập
        IF @NgayLap > GETDATE()
        BEGIN 
            SET @thongBao = N'Lỗi: Ngày lập hóa đơn không được vượt quá thời gian hiện tại!'; 
            ROLLBACK TRAN; 
            RETURN; 
        END

        -- 3. Phát sinh mã Hóa đơn tự động (HDN + 7 số)
        DECLARE @max_ma CHAR(10);
        SELECT @max_ma = MAX(MaHD_NH) FROM HOADON_NHAP;
        
        SET @max_ma = ISNULL(RIGHT(@max_ma, 7), '0000000');
        SET @MaHD_NH_Out = 'HDN' + RIGHT('0000000' + CAST(CAST(@max_ma AS INT) + 1 AS VARCHAR), 7);

        -- 4. Thêm "Vỏ" hóa đơn vào CSDL (Tổng tiền tạm gán = 0)
        INSERT INTO HOADON_NHAP (MaHD_NH, MaNV, MaNCC, NgayLap, PTThanhToan, TongTien, ThueVAT)
        VALUES (@MaHD_NH_Out, @MaNV, @MaNCC, @NgayLap, @PTThanhToan, 0, @ThueVAT);

        COMMIT TRANSACTION;
        SET @thongBao = N'Tạo vỏ hóa đơn nhập thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        -- Bắt lỗi an toàn
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        SET @thongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--========================================================
--==========================================================
/*
=======================================================================
* Tên module: sp_ThemCTHD_Nhap
* Chức năng : Thêm chi tiết mặt hàng vào hóa đơn nhập. Tính thành tiền,
*             Cộng dồn Tổng Tiền cho vỏ hóa đơn.
* Bảng tác động: CTHD_NHAP, HOADON_NHAP
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_ThemCTHD_Nhap (
    @MaHD_NH CHAR(10),
    @MaNVL CHAR(6), 
    @SoLuong INT,
    @DonGiaNVL DECIMAL(18,2), -- Đã khớp với bảng CTHD_NHAP
    @HSD DATETIME,
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

        IF NOT EXISTS (SELECT 1 FROM HOADON_NHAP WHERE MaHD_NH = @MaHD_NH)
        BEGIN SET @thongBao = N'Lỗi: Hóa đơn nhập không tồn tại!'; ROLLBACK TRAN; RETURN; END

        IF NOT EXISTS (SELECT 1 FROM NVL WHERE MaNVL = @MaNVL)
        BEGIN SET @thongBao = N'Lỗi: Nguyên vật liệu không tồn tại!'; ROLLBACK TRAN; RETURN; END

        IF EXISTS (SELECT 1 FROM CTHD_NHAP WHERE MaHD_NH = @MaHD_NH AND MaNVL = @MaNVL)
        BEGIN SET @thongBao = N'Lỗi: Nguyên vật liệu đã có trong hóa đơn!'; ROLLBACK TRAN; RETURN; END

        IF @SoLuong <= 0 OR @DonGiaNVL < 0
        BEGIN SET @thongBao = N'Lỗi: Số lượng/Đơn giá không hợp lệ!'; ROLLBACK TRAN; RETURN; END

        -- FIX LỖI 271: Chèn DonGiaNVL, để CSDL tự tính ThanhTien
        INSERT INTO CTHD_NHAP (MaHD_NH, MaNVL, SoLuong, DonGiaNVL, HSD)
        VALUES (@MaHD_NH, @MaNVL, @SoLuong, @DonGiaNVL, @HSD);

        -- Tính tay biến này để cộng dồn lên vỏ hóa đơn cha
        DECLARE @ThanhTien DECIMAL(18,2) = @SoLuong * @DonGiaNVL;
        UPDATE HOADON_NHAP
        SET TongTien = TongTien + @ThanhTien
        WHERE MaHD_NH = @MaHD_NH;

        COMMIT TRANSACTION;
        SET @thongBao = N'Thêm chi tiết nhập thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @thongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--===================================================================
--===================================================================

/*
=======================================================================
* Tên module: sp_ThemHoaDonBan
* Chức năng : Tạo vỏ hóa đơn bán hàng (Mở bàn). Tự động sinh mã Bill 
*             (dài 18 ký tự) và cập nhật trạng thái bàn thành 'Có khách'.
*             Chặn mở Bill nếu bàn đang không trống.
* Bảng tác động: HOADON_BAN, VITRI
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_ThemHoaDonBan (
    @PTThanhToan NVARCHAR(50),
    @TGBAN DATETIME,
    @MaKH CHAR(10) = NULL,
    @MaNV CHAR(10),
    @MSBAN CHAR(10),
    @MaBill_Out CHAR(20) OUTPUT, -- Đã sửa thành CHAR(20) cho khớp DB
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

        -- 1. Kiểm tra Khóa ngoại và Ràng buộc thời gian
        IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MaNV = @MaNV)
        BEGIN SET @thongBao = N'Lỗi: Nhân viên không tồn tại!'; ROLLBACK TRAN; RETURN; END

        IF @MaKH IS NOT NULL AND NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MaKH = @MaKH)
        BEGIN SET @thongBao = N'Lỗi: Khách hàng không tồn tại!'; ROLLBACK TRAN; RETURN; END

        IF NOT EXISTS (SELECT 1 FROM VITRI WHERE MSBAN = @MSBAN)
        BEGIN SET @thongBao = N'Lỗi: Mã số bàn không tồn tại trong sơ đồ quán!'; ROLLBACK TRAN; RETURN; END

        IF @TGBAN > GETDATE()
        BEGIN SET @thongBao = N'Lỗi: Thời gian bán không được ở tương lai!'; ROLLBACK TRAN; RETURN; END

        -- 2. Kiểm tra trạng thái bàn (Phải là 'Trống' mới được mở Bill)
        -- Lưu ý: Trong các script trước, chúng ta dùng N'Trống', N'Đang có', N'Đã đặt'
        IF EXISTS (SELECT 1 FROM VITRI WHERE MSBAN = @MSBAN AND TrangThai <> N'Trống')
        BEGIN SET @thongBao = N'Từ chối: Bàn này hiện đang có khách hoặc đã được đặt trước!'; ROLLBACK TRAN; RETURN; END

        -- 3. Phát sinh mã Bill tự động (Đảm bảo >= 18 ký tự theo chuẩn CHECK CONSTRAINT)
        -- Công thức: 'HDB' (3 ký tự) + 15 số = 18 ký tự
        DECLARE @max_ma CHAR(20);
        SELECT @max_ma = MAX(MaBILL) FROM HOADON_BAN;
        
        -- Cắt lấy 15 ký tự số cuối cùng (Dùng BIGINT vì số quá lớn)
        SET @max_ma = ISNULL(RIGHT(@max_ma, 15), '000000000000000');
        SET @MaBill_Out = 'HDB' + RIGHT('000000000000000' + CAST(CAST(@max_ma AS BIGINT) + 1 AS VARCHAR), 15);

        -- 4. Insert vỏ hóa đơn bán (Gán tạm TongTien = 0)
        INSERT INTO HOADON_BAN (MaBILL, TongTien, PTThanhToan, TGBAN, MaKH, MaNV, MSBAN)
        VALUES (@MaBill_Out, 0, @PTThanhToan, @TGBAN, @MaKH, @MaNV, @MSBAN);

        -- 5. Cập nhật trạng thái bàn sang "Có khách"
        UPDATE VITRI SET TrangThai = N'Có khách' WHERE MSBAN = @MSBAN;

        COMMIT TRANSACTION;
        SET @thongBao = N'Mở bàn và tạo vỏ hóa đơn bán thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @thongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO

--=============================================
--=================================================

/*
=======================================================================
* Tên module: sp_ThemCTHD_Ban
* Chức năng : Thêm món vào Hóa đơn bán. Tính thành tiền tự động qua 
*             Computed Column và CỘNG DỒN Tổng Tiền cho vỏ hóa đơn.
* Bảng tác động: CTHD_BAN, HOADON_BAN
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_ThemCTHD_Ban (
    @MaBill CHAR(20),
    @MaSP CHAR(20),
    @SoLuong INT,
    @DonGiaSP MONEY, -- FIX LỖI 207: Trả lại tên chuẩn DonGiaSP
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

        IF NOT EXISTS (SELECT 1 FROM HOADON_BAN WHERE MaBILL = @MaBill)
        BEGIN SET @thongBao = N'Lỗi: Hóa đơn bán không tồn tại!'; ROLLBACK TRAN; RETURN; END

        IF NOT EXISTS (SELECT 1 FROM SANPHAM WHERE MaSP = @MaSP)
        BEGIN SET @thongBao = N'Lỗi: Sản phẩm không tồn tại!'; ROLLBACK TRAN; RETURN; END

        IF EXISTS (SELECT 1 FROM CTHD_BAN WHERE MaBILL = @MaBill AND MaSP = @MaSP)
        BEGIN SET @thongBao = N'Lỗi: Món này đã có trong Bill!'; ROLLBACK TRAN; RETURN; END

        IF @SoLuong <= 0 OR @DonGiaSP < 0
        BEGIN SET @thongBao = N'Lỗi: Số lượng/Giá bán không hợp lệ!'; ROLLBACK TRAN; RETURN; END

        -- FIX LỖI 207: Sửa lại tên cột DonGiaSP
        INSERT INTO CTHD_BAN (MaBILL, MaSP, SoLuong, DonGiaSP)
        VALUES (@MaBill, @MaSP, @SoLuong, @DonGiaSP);

        -- Cộng dồn tiền lên vỏ hóa đơn
        -- Lưu ý nhỏ: Sơ đồ ERD của bạn ghi là cột TongCong, nếu lệnh này báo lỗi tên cột TongTien, 
        -- bạn hãy đổi chữ TongTien dưới đây thành TongCong nhé!
        UPDATE HOADON_BAN
        SET TongTien = TongTien + (@SoLuong * @DonGiaSP) 
        WHERE MaBILL = @MaBill;

        COMMIT TRANSACTION;
        SET @thongBao = N'Đã thêm món vào hóa đơn thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @thongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO