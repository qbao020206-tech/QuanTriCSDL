

USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROC dumpDL_NVL
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- 1. Khởi tạo dữ liệu mẫu và biến đếm
    -- =========================================================================
    -- Tạo cấu trúc lưu trữ tạm chứa sẵn danh sách dữ liệu thực tế (Đã bỏ DonGia)
    DECLARE @TempData TABLE (
        ID INT IDENTITY(1,1), -- Dùng để trích xuất tuần tự
        TenNVL NVARCHAR(100),
        DVT NVARCHAR(10)
    );

    -- Chèn 30 nguyên vật liệu phổ biến cho quán cafe / trà sữa (Chỉ còn Tên và DVT)
    INSERT INTO @TempData (TenNVL, DVT)
    VALUES 
        (N'Cà phê Robusta', N'Kg'),
        (N'Cà phê Arabica', N'Kg'),
        (N'Trà đen', N'Kg'),
        (N'Trà Oolong', N'Kg'),
        (N'Trà lài (nhài)', N'Kg'),
        (N'Sữa đặc', N'Hộp'),
        (N'Sữa tươi không đường', N'Lít'),
        (N'Kem béo Rich''s', N'Hộp'),
        (N'Đường cát trắng', N'Kg'),
        (N'Đường nước', N'Can'),
        (N'Bột Cacao', N'Kg'),
        (N'Bột Matcha', N'Kg'),
        (N'Bột béo', N'Kg'),
        (N'Trân châu đen', N'Kg'),
        (N'Trân châu trắng 3Q', N'Kg'),
        (N'Syrup Đào', N'Chai'),
        (N'Syrup Vải', N'Chai'),
        (N'Syrup Dâu', N'Chai'),
        (N'Sinh tố Xoài', N'Chai'),
        (N'Đào ngâm', N'Hộp'),
        (N'Vải ngâm', N'Hộp'),
        (N'Sữa chua', N'Hộp'),
        (N'Nước cốt dừa', N'Lon'),
        (N'Mật ong', N'Lít'),
        (N'Chanh dây tươi', N'Kg'),
        (N'Tắc (Quất) tươi', N'Kg'),
        (N'Cà phê chồn', N'Kg'),
        (N'Kem Base', N'Hộp'),
        (N'Cốt trà bí đao', N'Lít'),
        (N'Hạt chia', N'Kg');

    -- Khai báo biến
    DECLARE @count INT = 1; 
    DECLARE @max INT; 
    SELECT @max = COUNT(*) FROM @TempData; -- Tổng số lượng NVL trong danh sách mẫu (30 loại)

    DECLARE @maNVL CHAR(10);
    DECLARE @tenNVL NVARCHAR(100);
    DECLARE @dvt NVARCHAR(10);

    -- =========================================================================
    -- 2. Vòng lặp WHILE từ 1 đến @max để tạo dữ liệu
    -- =========================================================================
    WHILE @count <= @max
    BEGIN
        -- Xử lý Mã NVL: Định dạng 'NVL' + 3 chữ số (VD: NVL001, NVL002...)
        SET @maNVL = 'NVL' + RIGHT('000' + CAST(@count AS VARCHAR), 3);

        -- Trích xuất tuần tự 1 dòng dữ liệu từ danh sách chuẩn bị sẵn
        SELECT 
            @tenNVL = TenNVL, 
            @dvt = DVT
        FROM @TempData 
        WHERE ID = @count;

        -- =====================================================================
        -- Thực thi chèn và Xử lý ngoại lệ
        -- =====================================================================
        BEGIN TRY
            -- Câu lệnh INSERT đã được loại bỏ DonGia
            INSERT INTO NVL (MaNVL, TenNVL, DVT)
            VALUES (@maNVL, @tenNVL, @dvt);
        END TRY
        BEGIN CATCH
            -- In thông báo lỗi nếu trùng khóa chính (PK) hoặc vi phạm constraint
            PRINT N'LỖI CHÈN TẠI MÃ ' + @maNVL + ': ' + ERROR_MESSAGE();
        END CATCH

        -- Tăng biến đếm lên 1 sau mỗi lần chèn (để vòng lặp tiếp tục và Mã NVL tịnh tiến)
        SET @count = @count + 1;
    END

    PRINT N'Đã hoàn thành dump ' + CAST(@max AS NVARCHAR) + N' bản ghi vào bảng NVL!';
END
GO

-- =============================================================================
-- CÁCH CHẠY THỬ (TESTING)
-- =============================================================================
-- Đảm bảo bạn đã chạy lệnh ALTER TABLE DROP COLUMN ở trên trước khi EXEC.

-- Xóa dữ liệu cũ nếu cần thiết trước khi dump lại (Bỏ comment nếu dùng)
-- DELETE FROM NVL; 

-- Thực thi thủ tục
EXEC dumpDL_NVL;

-- Kiểm tra lại dữ liệu
SELECT * FROM NVL;
-- =============================================================================
-- CÁCH CHẠY THỬ (TESTING)
-- =============================================================================
-- TRUNCATE TABLE NVL; -- Xóa dữ liệu cũ nếu cần

-- Thực thi thủ tục
EXEC dumpDL_NVL;

-- Kiểm tra lại dữ liệu
SELECT * FROM NVL;

