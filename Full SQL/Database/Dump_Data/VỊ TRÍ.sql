USE QLY_CONGCAFFE;
GO
-- 1. Khởi tạo các biến kiểm soát
DECLARE @max INT = 30;           -- Tổng số bàn cần tạo
DECLARE @count INT = 1;          -- Biến đếm vòng lặp tổng
DECLARE @countA INT = 1;         -- Đếm số thứ tự bàn khu Ngoài sân (A)
DECLARE @countB INT = 1;         -- Đếm số thứ tự bàn khu Tầng 1 (B)
DECLARE @countC INT = 1;         -- Đếm số thứ tự bàn khu Tầng 2 (C)

-- Các biến chứa dữ liệu để Insert
DECLARE @msBan CHAR(10);
DECLARE @kvBan NVARCHAR(10);
DECLARE @trangThai NVARCHAR(10) = N'Trống'; 
DECLARE @randomKhu INT; 

-- 2. Vòng lặp tạo dữ liệu
WHILE @count <= @max
BEGIN
    BEGIN TRY
        -- Random ngẫu nhiên từ 1 đến 3 để chọn khu vực
        SET @randomKhu = ABS(CHECKSUM(NEWID())) % 3 + 1; 

        -- Xử lý logic tiền tố (Prefix) theo từng khu vực
        IF @randomKhu = 1
        BEGIN
            SET @kvBan = N'Ngoài sân';
            -- Format: A + 000 + số thứ tự -> lấy 3 số cuối (VD: countA=1 -> A001)
            SET @msBan = 'A' + RIGHT('000' + CAST(@countA AS VARCHAR(3)), 3);
            SET @countA = @countA + 1; -- Tăng số thứ tự cho bàn Ngoài sân tiếp theo
        END
        ELSE IF @randomKhu = 2
        BEGIN
            SET @kvBan = N'Tầng 1';
            SET @msBan = 'B' + RIGHT('000' + CAST(@countB AS VARCHAR(3)), 3);
            SET @countB = @countB + 1; -- Tăng số thứ tự cho bàn Tầng 1 tiếp theo
        END
        ELSE IF @randomKhu = 3
        BEGIN
            SET @kvBan = N'Tầng 2';
            SET @msBan = 'C' + RIGHT('000' + CAST(@countC AS VARCHAR(3)), 3);
            SET @countC = @countC + 1; -- Tăng số thứ tự cho bàn Tầng 2 tiếp theo
        END

        -- Thực hiện chèn dữ liệu
        INSERT INTO VITRI (MSBan, KVBan, TrangThai)
        VALUES (@msBan, @kvBan, @trangThai);

        -- Tăng biến đếm tổng
        SET @count = @count + 1;
    END TRY
    
    -- 3. Bắt và hiển thị lỗi nếu có
    BEGIN CATCH
        PRINT N'❌ Lỗi tại vòng lặp thứ ' + CAST(@count AS NVARCHAR(10));
        PRINT N'Mã bàn đang cố gắng chèn: ' + ISNULL(@msBan, 'Unknown');
        PRINT N'Chi tiết lỗi: ' + ERROR_MESSAGE();
        
        -- Vẫn tăng biến đếm tổng để vòng lặp không bị kẹt vô hạn
        SET @count = @count + 1; 
    END CATCH
END;
GO

-- Kiểm tra lại dữ liệu đã sinh
SELECT * FROM VITRI;


DELETE FROM VITRI;