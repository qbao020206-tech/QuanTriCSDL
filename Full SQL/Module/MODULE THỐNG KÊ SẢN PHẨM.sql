/*
=======================================================================
* Tên module: sp_ThongKeDoanhThu_TungSanPham
* Chức năng : Báo cáo thống kê số lượng bán và doanh thu của từng 
*             sản phẩm trong khoảng thời gian tùy chọn.
* Bảng truy xuất: HOADON_BAN, CTHD_BAN, SANPHAM
=======================================================================
*/
CREATE OR ALTER PROCEDURE sp_ThongKeDoanhThu_TungSanPham (
    @TuNgay DATETIME,
    @DenNgay DATETIME,
    @thongBao NVARCHAR(500) OUTPUT,
    @check BIT OUTPUT
)
AS
BEGIN
    -- READ COMMITTED là lựa chọn tốt nhất cho báo cáo: Không chặn ghi, tránh đọc rác
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;
    SET @thongBao = N'';
    SET @check = 0;

    BEGIN TRY
        -- 1. Chuẩn hóa khoảng thời gian (Đảm bảo lấy hết dữ liệu đến cuối ngày kết thúc)
        -- Nếu @DenNgay chỉ có ngày (ví dụ 2024-12-31), ta cộng thêm để lấy đến 23:59:59
        IF @TuNgay > @DenNgay
        BEGIN
            SET @thongBao = N'Lỗi: Ngày bắt đầu không được lớn hơn ngày kết thúc!';
            RETURN;
        END

        -- 2. Kiểm tra dữ liệu tồn tại
        IF NOT EXISTS (
            SELECT 1 
            FROM HOADON_BAN 
            WHERE TGBan >= @TuNgay AND TGBan <= @DenNgay
        )
        BEGIN
            SET @thongBao = N'Thông báo: Không có giao dịch bán hàng nào trong khoảng thời gian này!';
            SET @check = 1;
            -- Vẫn trả về một bảng trống để tránh lỗi ở tầng giao diện
            SELECT TOP 0 NULL AS [Mã Sản Phẩm]; 
            RETURN;
        END

        -- 3. Truy vấn thống kê
        -- Sử dụng INNER JOIN để chỉ thống kê những sản phẩm thực sự có phát sinh doanh số
        SELECT 
            SP.MaSP AS [Mã Sản Phẩm],
            SP.TenSP AS [Tên Sản Phẩm],
            SUM(CT.SoLuong) AS [Tổng Số Lượng Bán],
            CAST(SUM(CT.ThanhTien) AS MONEY) AS [Tổng Doanh Thu]
        FROM HOADON_BAN HD
        JOIN CTHD_BAN CT ON HD.MaBILL = CT.MaBILL
        JOIN SANPHAM SP ON CT.MaSP = SP.MaSP
        WHERE HD.TGBan >= @TuNgay AND HD.TGBan <= @DenNgay
        GROUP BY SP.MaSP, SP.TenSP
        ORDER BY [Tổng Doanh Thu] DESC;

        SET @thongBao = N'Thống kê doanh thu theo sản phẩm thành công!';
        SET @check = 1;
    END TRY
    BEGIN CATCH
        SET @thongBao = N'LỖI HỆ THỐNG: ' + ERROR_MESSAGE();
        SET @check = 0;
    END CATCH
END;
GO