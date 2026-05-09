USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROC dumpDL_SANPHAM
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- 1. Khởi tạo dữ liệu nguồn & biến đếm
    -- =========================================================================
    -- Lưu ý: Điều kiện tiên quyết là bảng LOAISANPHAM đã có dữ liệu từ LSP01 -> LSP09

    -- Khởi tạo biến đếm
    DECLARE @count INT = 1;

    -- Tạo một cấu trúc lưu trữ tạm (Table Variable) chứa danh sách sản phẩm đã phân loại
    DECLARE @TempSP TABLE (
        ID INT IDENTITY(1,1), -- Số thứ tự dùng để trích xuất trong vòng lặp
        TenSP NVARCHAR(30),
        GiaSP DECIMAL(10,2),
        MaLSP CHAR(10)
    );

    -- Chèn dữ liệu menu mẫu (Map đúng với MaLSP từ LSP01 đến LSP09)
    INSERT INTO @TempSP (TenSP, GiaSP, MaLSP)
    VALUES 
        -- Nhóm LSP01: Cà phê
        (N'Cà phê đen đá', 25000, 'LSP01'),
        (N'Cà phê sữa đá', 29000, 'LSP01'),
        (N'Bạc xỉu', 35000, 'LSP01'),
        (N'Cà phê cốt dừa', 45000, 'LSP01'),
        (N'Cà phê muối', 39000, 'LSP01'),

        -- Nhóm LSP02: Nước ép
        (N'Nước ép cam', 40000, 'LSP02'),
        (N'Nước ép dưa hấu', 35000, 'LSP02'),
        (N'Nước ép thơm', 35000, 'LSP02'),
        (N'Nước ép ổi', 35000, 'LSP02'),

        -- Nhóm LSP03: Trà trái cây
        (N'Trà đào cam sả', 45000, 'LSP03'),
        (N'Trà vải nhiệt đới', 45000, 'LSP03'),
        (N'Trà dâu tằm', 40000, 'LSP03'),
        (N'Trà chanh dây tuyết', 39000, 'LSP03'),

        -- Nhóm LSP04: Trà sữa
        (N'Trà sữa truyền thống', 35000, 'LSP04'),
        (N'Trà sữa Oolong nướng', 40000, 'LSP04'),
        (N'Trà sữa Thái xanh', 35000, 'LSP04'),
        (N'Hồng trà macchiato', 42000, 'LSP04'),

        -- Nhóm LSP05: Đá xay
        (N'Cà phê đá xay', 49000, 'LSP05'),
        (N'Caramel đá xay', 55000, 'LSP05'),
        (N'Việt quất đá xay', 55000, 'LSP05'),

        -- Nhóm LSP06: Matcha
        (N'Matcha đá xay', 55000, 'LSP06'),
        (N'Matcha latte', 45000, 'LSP06'),

        -- Nhóm LSP07: Sữa chua
        (N'Sữa chua đá', 25000, 'LSP07'),
        (N'Sữa chua việt quất', 35000, 'LSP07'),
        (N'Sữa chua hạt đác', 39000, 'LSP07'),

        -- Nhóm LSP08: Cacao
        (N'Cacao nóng', 35000, 'LSP08'),
        (N'Cacao sữa đá', 35000, 'LSP08'),

        -- Nhóm LSP09: Bánh
        (N'Bánh sừng bò', 30000, 'LSP09'),
        (N'Bánh Tiramisu', 45000, 'LSP09'),
        (N'Bánh bông lan trứng muối', 50000, 'LSP09'),
        (N'Bánh phô mai nướng', 40000, 'LSP09');

    -- Đặt biến @max = Tổng số dòng trong dữ liệu tạm
    DECLARE @max INT;
    SELECT @max = COUNT(*) FROM @TempSP;

    -- =========================================================================
    -- 2. Vòng lặp WHILE từ 1 đến @max để tạo dữ liệu
    -- =========================================================================
    -- Khai báo các biến tạm trong vòng lặp
    DECLARE @maSP CHAR(10);
    DECLARE @tenSP NVARCHAR(30);
    DECLARE @giaSP DECIMAL(10,2);
    DECLARE @maLSP CHAR(10);

    WHILE @count <= @max
    BEGIN
        -- Tạo mã sản phẩm tự động: 'SP' + 3 số (Ví dụ: SP001, SP015...)
        SET @maSP = 'SP' + RIGHT('000' + CAST(@count AS VARCHAR), 3);

        -- Đọc lần lượt 1 dòng từ @TempSP và gán vào các biến
        SELECT 
            @tenSP = TenSP, 
            @giaSP = GiaSP, 
            @maLSP = MaLSP
        FROM @TempSP 
        WHERE ID = @count;

        -- =====================================================================
        -- 3. Xử lý ngoại lệ và Thực thi chèn
        -- =====================================================================
        BEGIN TRY
            INSERT INTO SANPHAM (MaSP, TenSP, GiaSP, MaLSP)
            VALUES (@maSP, @tenSP, @giaSP, @maLSP);
        END TRY
        BEGIN CATCH
            -- Bắt lỗi nếu MaLSP không hợp lệ (vi phạm khóa ngoại FK_SP_LSP) hoặc lỗi khác
            PRINT N'LỖI CHÈN TẠI MÃ ' + @maSP + ': ' + ERROR_MESSAGE();
        END CATCH

        -- Tăng biến đếm
        SET @count = @count + 1;
    END

    PRINT N'Đã hoàn thành dump ' + CAST(@max AS NVARCHAR) + N' bản ghi vào bảng SANPHAM!';
END
GO

-- =============================================================================
-- CÁCH CHẠY THỬ (TESTING)
-- =============================================================================
-- TRUNCATE TABLE SANPHAM; -- Bỏ comment dòng này để xóa dữ liệu cũ nếu muốn chạy lại từ đầu

-- Thực thi Procedure
EXEC dumpDL_SANPHAM;

-- Kiểm tra lại dữ liệu
SELECT * FROM SANPHAM;