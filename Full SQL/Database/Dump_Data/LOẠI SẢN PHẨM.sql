USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROC dumpDL_LOAISANPHAM
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- 1. Khởi tạo bảng chứa danh sách tên loại sản phẩm (có ID tự tăng để lặp)
    -- =========================================================================
    DECLARE @ListTenLSP TABLE (ID INT IDENTITY(1,1), TenLSP NVARCHAR(50));
    
    INSERT INTO @ListTenLSP (TenLSP)
    VALUES 
        (N'Cà phê'), 
        (N'Nước ép'), 
        (N'Trà trái cây'), 
        (N'Trà sữa'), 
        (N'Đá xay'), 
        (N'Matcha'), 
        (N'Sữa chua'), 
        (N'Cacao'), 
        (N'Bánh');

    -- Khai báo các biến theo đúng phân tích
    DECLARE @count INT = 1;
    DECLARE @max INT = 9;
    DECLARE @maLSP CHAR(10);
    DECLARE @tenLSP NVARCHAR(50);

    -- =========================================================================
    -- 2. Vòng lặp từ 1 đến @max (9) để tạo dữ liệu
    -- =========================================================================
    WHILE @count <= @max
    BEGIN
        -- Tạo mã định dạng LSP + số thứ tự (Đảm bảo 2 chữ số: LSP01, LSP02...)
        SET @maLSP = 'LSP' + RIGHT('00' + CAST(@count AS VARCHAR), 2);

        -- Lấy tên loại sản phẩm tương ứng với vòng lặp hiện tại
        SELECT @tenLSP = TenLSP FROM @ListTenLSP WHERE ID = @count;

        -- =====================================================================
        -- 3. Xử lý ngoại lệ và chèn dữ liệu
        -- =====================================================================
        BEGIN TRY
            INSERT INTO LOAISANPHAM (MaLSP, TenLSP)
            VALUES (@maLSP, @tenLSP);
        END TRY
        BEGIN CATCH
            -- Bắt lỗi trùng khóa (MaLSP) hoặc các lỗi khác
            PRINT N'LỖI CHÈN TẠI MÃ ' + @maLSP + ': ' + ERROR_MESSAGE();
        END CATCH

        -- Tăng biến đếm (Luôn tăng để tránh lặp vô hạn nếu có 1 dòng bị lỗi)
        SET @count = @count + 1;
    END

    PRINT N'Đã hoàn thành dump ' + CAST(@max AS NVARCHAR) + N' bản ghi vào bảng LOAISANPHAM!';
END
GO

-- =============================================================================
-- CÁCH CHẠY THỬ (TESTING)
-- =============================================================================
-- TRUNCATE TABLE LOAISANPHAM; -- Mở comment dòng này nếu cần xóa dữ liệu cũ

-- Thực thi thủ tục
EXEC dumpDL_LOAISANPHAM;

-- Kiểm tra lại dữ liệu
SELECT * FROM LOAISANPHAM;