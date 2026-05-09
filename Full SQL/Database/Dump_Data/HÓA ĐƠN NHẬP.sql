USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROCEDURE dumpDL_HOADON_NHAP
    @max INT = 1000000 -- Đặt tham số để dễ dàng thay đổi, mặc định 50.000 theo phân tích
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- 1. Khởi tạo các biến môi trường và nạp bộ nhớ đệm (Cache) cho Foreign Key
    -- =========================================================================
    DECLARE @ngayBD DATETIME = '2023-01-01';
    DECLARE @ngayKT DATETIME = GETDATE();
    DECLARE @count INT = 1;

    -- Biến tạm lưu trữ chi tiết dòng
    DECLARE @MaHD_NH CHAR(10);
    DECLARE @MaNV CHAR(10);
    DECLARE @MaNCC CHAR(6);
    DECLARE @NgayLap DATETIME;
    DECLARE @PTThanhToan CHAR(10);
    DECLARE @ThueVAT DECIMAL(5,2);
    DECLARE @TongTien DECIMAL(18,2) = 0; -- Mặc định bằng 0 theo thuật toán

    -- TỐI ƯU HIỆU NĂNG: Nạp danh sách Nhân viên vào biến bảng có đánh ID
    DECLARE @ListNV TABLE (ID INT IDENTITY(1,1), MaNV CHAR(10));
    INSERT INTO @ListNV (MaNV) SELECT MaNV FROM NHANVIEN;
    DECLARE @TongSoNV INT = @@ROWCOUNT;

    -- TỐI ƯU HIỆU NĂNG: Nạp danh sách NCC vào biến bảng có đánh ID
    DECLARE @ListNCC TABLE (ID INT IDENTITY(1,1), MaNCC CHAR(6));
    INSERT INTO @ListNCC (MaNCC) SELECT MaNCC FROM NCC;
    DECLARE @TongSoNCC INT = @@ROWCOUNT;

    -- Kiểm tra an toàn: Đảm bảo bảng NHANVIEN và NCC đã có dữ liệu
    IF (@TongSoNV = 0 OR @TongSoNCC = 0)
    BEGIN
        PRINT N'LỖI: Bảng NHANVIEN hoặc NCC chưa có dữ liệu. Không thể tạo hóa đơn!';
        RETURN;
    END

    -- Biến hỗ trợ random
    DECLARE @RandomNVID INT;
    DECLARE @RandomNCCID INT;
    DECLARE @TotalSeconds INT = DATEDIFF(SECOND, @ngayBD, @ngayKT);

    -- =========================================================================
    -- 2. Vòng lặp tạo dữ liệu hóa đơn nhập
    -- =========================================================================
    WHILE @count <= @max
    BEGIN
        -- Tạo Mã hóa đơn: 'HDN' + 7 chữ số (Ví dụ: HDN0000001, HDN0000002...)
        SET @MaHD_NH = 'HDN' + RIGHT('0000000' + CAST(@count AS VARCHAR), 7);

        -- Tạo ngày lập ngẫu nhiên từ @ngayBD đến @ngayKT (Random đến từng giây)
        SET @NgayLap = DATEADD(SECOND, ABS(CHECKSUM(NEWID())) % @TotalSeconds, @ngayBD);

        -- Lấy ngẫu nhiên 1 Nhân viên cực nhanh dựa trên ID
        SET @RandomNVID = (ABS(CHECKSUM(NEWID())) % @TongSoNV) + 1;
        SELECT @MaNV = MaNV FROM @ListNV WHERE ID = @RandomNVID;

        -- Lấy ngẫu nhiên 1 Nhà cung cấp cực nhanh dựa trên ID
        SET @RandomNCCID = (ABS(CHECKSUM(NEWID())) % @TongSoNCC) + 1;
        SELECT @MaNCC = MaNCC FROM @ListNCC WHERE ID = @RandomNCCID;

        -- Phương thức thanh toán: Random TM hoặc CK
        IF (ABS(CHECKSUM(NEWID())) % 2 = 0)
            SET @PTThanhToan = 'TM';
        ELSE
            SET @PTThanhToan = 'CK';

        -- Thuế VAT: Random 0.08 (8%) hoặc 0.10 (10%)
        IF (ABS(CHECKSUM(NEWID())) % 2 = 0)
            SET @ThueVAT = 0.08;
        ELSE
            SET @ThueVAT = 0.10;

        -- =====================================================================
        -- 3. Xử lý ngoại lệ và Thực thi chèn dữ liệu
        -- =====================================================================
        BEGIN TRY
            INSERT INTO HOADON_NHAP (MaHD_NH, MaNV, MaNCC, NgayLap, PTThanhToan, TongTien, ThueVAT)
            VALUES (@MaHD_NH, @MaNV, @MaNCC, @NgayLap, @PTThanhToan, @TongTien, @ThueVAT);
            
            -- Chỉ tăng biến đếm nếu insert thành công (nếu xảy ra lỗi trùng mã HDN sẽ thử lại)
            SET @count = @count + 1;
        END TRY
        BEGIN CATCH
            -- In ra thông báo lỗi chi tiết
            PRINT N'LỖI CHÈN TẠI MÃ ' + @MaHD_NH + ': ' + ERROR_MESSAGE();
            -- Ép tăng biến đếm để vòng lặp không bị kẹt vô hạn nếu lỗi logic cứng
            SET @count = @count + 1;
        END CATCH
    END

    PRINT N'Đã hoàn tất dump ' + CAST(@max AS NVARCHAR) + N' bản ghi vào bảng HOADON_NHAP!';
END
GO

-- =============================================================================
-- CÁCH CHẠY THỬ (TESTING)
-- =============================================================================
-- Xóa dữ liệu cũ nếu muốn làm lại từ đầu (Bỏ comment nếu cần)
-- TRUNCATE TABLE HOADON_NHAP; 
-- Hoặc DELETE FROM HOADON_NHAP; nếu có khóa ngoại ràng buộc ở bảng CTHD

-- Thực thi Procedure tạo 50.000 dòng
EXEC dumpDL_HOADON_NHAP @max = 50000;

-- Kiểm tra kết quả
SELECT COUNT(*) AS TongSoHoaDonNhap FROM HOADON_NHAP;
SELECT TOP 20 * FROM HOADON_NHAP ORDER BY NgayLap DESC;