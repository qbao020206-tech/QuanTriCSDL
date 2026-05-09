CREATE OR ALTER PROCEDURE dumpDL_CTHD_BAN
    @max INT = 150000 -- Tổng số lượng chi tiết hóa đơn cần tạo theo thiết kế
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- 1. Khởi tạo các biến môi trường và nạp Cache cho bảng Master
    -- =========================================================================
    
    -- Cache Hóa Đơn Bán (Lấy danh sách mã hóa đơn đã tồn tại)
    DECLARE @ListHDB TABLE (ID INT IDENTITY(1,1), MaBILL CHAR(10));
    INSERT INTO @ListHDB (MaBILL) SELECT MaBILL FROM HOADON_BAN;
    DECLARE @TongHDB INT = @@ROWCOUNT;

    -- Cache Sản Phẩm (Lấy danh mục mã sản phẩm VÀ Giá bán tương ứng)
    DECLARE @ListSP TABLE (ID INT IDENTITY(1,1), MaSP CHAR(10), GiaSP DECIMAL(10,2));
    INSERT INTO @ListSP (MaSP, GiaSP) SELECT MaSP, GiaSP FROM SANPHAM;
    DECLARE @TongSP INT = @@ROWCOUNT;

    -- Kiểm tra an toàn: Đảm bảo bảng Hóa đơn và Sản phẩm đã có dữ liệu
    IF (@TongHDB = 0 OR @TongSP = 0)
    BEGIN
        PRINT N'LỖI: Bảng HOADON_BAN hoặc SANPHAM chưa có dữ liệu. Hãy chạy dumpDL cho 2 bảng này trước!';
        RETURN;
    END

    -- Khai báo biến đếm và các biến lưu trữ chi tiết dòng
    DECLARE @i INT = 1;
    DECLARE @maHDB CHAR(10);
    DECLARE @maSP CHAR(10);
    DECLARE @soLuong INT;
    DECLARE @giaBan DECIMAL(18,2);

    -- Biến Failsafe chống lặp vô hạn (Trường hợp số lượng Hóa Đơn quá ít, không đủ tổ hợp ghép)
    DECLARE @failsafe INT = 0; 
    DECLARE @maxFailsafe INT = @max * 5;

    -- =========================================================================
    -- 2. Vòng lặp tạo dữ liệu chi tiết hóa đơn
    -- =========================================================================
    WHILE @i <= @max
    BEGIN
        -- Tăng biến an toàn để phòng kẹt lặp vô hạn
        SET @failsafe = @failsafe + 1;
        IF @failsafe > @maxFailsafe 
        BEGIN
            PRINT N'CẢNH BÁO: Hết tổ hợp ghép Hóa đơn & Sản phẩm hợp lệ. Dừng vòng lặp sớm!';
            BREAK;
        END

        -- Chọn ngẫu nhiên 1 mã hóa đơn từ Cache
        SELECT @maHDB = MaBILL FROM @ListHDB WHERE ID = (ABS(CHECKSUM(NEWID())) % @TongHDB) + 1;

        -- Chọn ngẫu nhiên 1 mã sản phẩm và Giá bán tương ứng từ Cache
        SELECT @maSP = MaSP, @giaBan = GiaSP FROM @ListSP WHERE ID = (ABS(CHECKSUM(NEWID())) % @TongSP) + 1;

        -- Sinh số lượng ngẫu nhiên từ 1 đến 10
        SET @soLuong = (ABS(CHECKSUM(NEWID())) % 10) + 1;

        -- =====================================================================
        -- 3. Xử lý ngoại lệ và Thực thi lệnh chèn
        -- =====================================================================
        BEGIN TRY
-- CHÚ Ý: Không đưa cột ThanhTien vào lệnh INSERT vì đây là Computed Column
            INSERT INTO CTHD_BAN (MaBILL, MaSP, SoLuong, DonGiaSP)
            VALUES (@maHDB, @maSP, @soLuong, @giaBan);

            -- Chỉ tăng biến đếm khi insert thành công (Bỏ qua các bản ghi bị lỗi Duplicate PK)
            SET @i = @i + 1;
        END TRY
        BEGIN CATCH
            -- Nếu lỗi (thường là lỗi 2627: Vi phạm khóa chính / Duplicate PK do random trúng món đã có trong Bill)
            -- Hệ thống sẽ âm thầm bỏ qua (không tăng @i) và lặp lại để tìm tổ hợp mới.
            CONTINUE;
        END CATCH
    END

    -- Tính toán tổng số lượng thực tế đã tạo
    DECLARE @SoLuongDaTao INT = @i - 1;
    PRINT N'Đã hoàn tất dump ' + CAST(@SoLuongDaTao AS NVARCHAR) + N' bản ghi vào bảng CTHD_BAN!';
END
GO

-- =============================================================================
-- CÁCH CHẠY THỬ VÀ KIỂM TRA
-- =============================================================================
-- TRUNCATE TABLE CTHD_BAN; -- (Mở comment nếu muốn xóa dữ liệu cũ làm lại từ đầu)

-- Thực thi thủ tục (Sẽ mất khoảng vài giây cho 150.000 dòng)
EXEC dumpDL_CTHD_BAN @max = 150000;

-- 1. Kiểm tra tổng số lượng đã chèn
SELECT COUNT(*) AS TongSoChiTietHD FROM CTHD_BAN;