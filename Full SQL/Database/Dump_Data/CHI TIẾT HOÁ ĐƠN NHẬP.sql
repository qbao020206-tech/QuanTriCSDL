CREATE OR ALTER PROCEDURE dumpDL_CTHD_NHAP
    @max INT = 1000000 -- Cấu hình tạo 100.000 bản ghi chi tiết
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- 1. Khởi tạo các biến môi trường và nạp Cache cho bảng Master
    -- =========================================================================
    
    -- Cache Hóa Đơn Nhập (Cần lấy cả MaHD_NH và NgayLap để tính HSD)
    DECLARE @ListHDN TABLE (ID INT IDENTITY(1,1), MaHD_NH CHAR(10), NgayLap DATETIME);
    INSERT INTO @ListHDN (MaHD_NH, NgayLap) SELECT MaHD_NH, NgayLap FROM HOADON_NHAP;
    DECLARE @TongHDN INT = @@ROWCOUNT;

    -- Cache Nguyên Vật Liệu (Lấy mã và đơn giá)
    DECLARE @ListNVL TABLE (ID INT IDENTITY(1,1), MaNVL CHAR(10), DonGia DECIMAL(18,2));
    INSERT INTO @ListNVL (MaNVL, DonGia) SELECT MaNVL, DonGia FROM NVL;
    DECLARE @TongNVL INT = @@ROWCOUNT;

    -- Kiểm tra an toàn
    IF (@TongHDN = 0 OR @TongNVL = 0)
    BEGIN
        PRINT N'LỖI: Bảng HOADON_NHAP hoặc NVL chưa có dữ liệu. Không thể tạo chi tiết!';
        RETURN;
    END

    -- Khai báo biến lặp và biến lưu dữ liệu dòng
    DECLARE @i INT = 1;
    DECLARE @MaHD_NH CHAR(10);
    DECLARE @MaNVL CHAR(10);
    DECLARE @NgayLap DATETIME;
    DECLARE @DonGiaNVL DECIMAL(18,2);
    DECLARE @SoLuong INT;
    DECLARE @HSD DATETIME;
    DECLARE @NgayThem INT;

    -- Biến Failsafe chống lặp vô hạn (Trường hợp dữ liệu master quá ít)
    DECLARE @failsafe INT = 0; 
    DECLARE @maxFailsafe INT = @max * 5;

    -- =========================================================================
    -- 2. Vòng lặp tạo dữ liệu chi tiết hóa đơn nhập
    -- =========================================================================
    WHILE @i <= @max
    BEGIN
        -- Chống kẹt vòng lặp
        SET @failsafe = @failsafe + 1;
        IF @failsafe > @maxFailsafe 
        BEGIN
            PRINT N'CẢNH BÁO: Hết tổ hợp ghép Hóa đơn & NVL hợp lệ. Dừng vòng lặp sớm!';
            BREAK;
        END

        -- Trích xuất ngẫu nhiên 1 bản ghi từ bảng HOADON_NHAP -> Gán MaHD_NH và NgayLap
        SELECT @MaHD_NH = MaHD_NH, @NgayLap = NgayLap 
        FROM @ListHDN 
        WHERE ID = (ABS(CHECKSUM(NEWID())) % @TongHDN) + 1;

        -- Trích xuất ngẫu nhiên 1 bản ghi từ bảng NVL -> Gán MaNVL và DonGiaNVL
        SELECT @MaNVL = MaNVL, @DonGiaNVL = DonGia 
        FROM @ListNVL 
        WHERE ID = (ABS(CHECKSUM(NEWID())) % @TongNVL) + 1;

        -- Sinh số lượng nhập: Từ 1 đến 100
        SET @SoLuong = (ABS(CHECKSUM(NEWID())) % 100) + 1;

        -- Sinh Hạn sử dụng (HSD): Cộng thêm từ 30 đến 365 ngày so với NgayLap
        SET @NgayThem = 30 + (ABS(CHECKSUM(NEWID())) % 336); -- 336 = 365 - 30 + 1
SET @HSD = DATEADD(DAY, @NgayThem, @NgayLap);

        -- =====================================================================
        -- 3. Xử lý ngoại lệ và Thực thi chèn dữ liệu
        -- =====================================================================
        BEGIN TRY
            -- CHÚ Ý: Cột ThanhTien tự động tính nên không được đưa vào INSERT
            INSERT INTO CTHD_NHAP (MaHD_NH, MaNVL, SoLuong, DonGiaNVL, HSD)
            VALUES (@MaHD_NH, @MaNVL, @SoLuong, @DonGiaNVL, @HSD);

            -- Tăng biến đếm nếu chèn thành công
            SET @i = @i + 1;
        END TRY
        BEGIN CATCH
            -- Bắt lỗi trùng khóa chính kép (MaHD_NH, MaNVL).
            -- Nếu gặp lỗi, lệnh CATCH sẽ bỏ qua, không tăng @i, và lặp lại bước chọn dữ liệu mới.
            CONTINUE;
        END CATCH
    END

    -- Báo cáo kết quả
    DECLARE @DaTao INT = @i - 1;
    PRINT N'Đã hoàn tất dump ' + CAST(@DaTao AS NVARCHAR) + N' bản ghi vào bảng CTHD_NHAP!';
END
GO

-- =============================================================================
-- CÁCH CHẠY THỬ VÀ KIỂM TRA
-- =============================================================================
-- TRUNCATE TABLE CTHD_NHAP; -- Mở comment nếu muốn chạy lại từ đầu bằng data sạch

-- Thực thi thủ tục 100.000 dòng (Mất khoảng vài giây)
EXEC dumpDL_CTHD_NHAP @max = 100000;