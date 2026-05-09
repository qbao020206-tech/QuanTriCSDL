USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROCEDURE dumpDL_NCC
    @SoLuong INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- 1. Khởi tạo các bảng, biến để lưu trữ dữ liệu nguồn
    -- =========================================================================
    DECLARE @phanDauTen TABLE (PhanDau NVARCHAR(50));
    DECLARE @phanCuoiTen TABLE (PhanCuoi NVARCHAR(50));
    DECLARE @linhVucHoatDong TABLE (LinhVuc NVARCHAR(50));
    DECLARE @loaiHinhCongTy TABLE (LoaiHinh NVARCHAR(50));
    DECLARE @duong TABLE (TenDuong NVARCHAR(100));
    DECLARE @dauSoDienThoai TABLE (DauSo VARCHAR(3));

    -- Đổ dữ liệu mẫu cho các thành phần tạo Tên Công Ty
    INSERT INTO @loaiHinhCongTy VALUES (N'Công ty TNHH'), (N'Công ty Cổ phần');
    
    INSERT INTO @phanDauTen VALUES 
        (N'Đại'), (N'Tân'), (N'Hòa'), (N'Thịnh'), (N'Vạn'), (N'Bình'), (N'Long'), 
        (N'Tiến'), (N'An'), (N'Hoàng'), (N'Phú'), (N'Minh'), (N'Vĩnh'), (N'Nhật'), 
        (N'Kim'), (N'Bảo'), (N'Hữu'), (N'Thái'), (N'Duy'), (N'Việt'), (N'Thế'), 
        (N'Hải'), (N'Phong'), (N'Quốc'), (N'Nam'), (N'Trường'), (N'Thảo'), (N'Khôi');

    INSERT INTO @phanCuoiTen VALUES 
        (N'Phát'), (N'An'), (N'Gia'), (N'Long'), (N'Đạt'), (N'Minh'), (N'Việt'), 
        (N'Khánh'), (N'Bảo'), (N'Thành'), (N'Quang'), (N'Khang'), (N'Hưng'), (N'Lộc'), 
        (N'Thịnh'), (N'Vượng'), (N'Châu'), (N'Phương'), (N'Hải'), (N'Hiệp'), (N'Thắng');

    INSERT INTO @linhVucHoatDong VALUES 
        (N'Thương mại'), (N'Thương mại & Xuất nhập khẩu'), (N'Dịch vụ'), 
        (N'Công nghệ'), (N'Sản xuất'), (N'Dịch vụ & Sản xuất');

    -- Đổ dữ liệu mẫu cho Đầu số điện thoại
    INSERT INTO @dauSoDienThoai VALUES 
        ('032'), ('033'), ('034'), ('035'), ('036'), ('037'), ('038'), ('039'), 
        ('086'), ('096'), ('097'), ('098'), ('070'), ('079'), ('089'), ('090'), ('093');

    -- Đổ dữ liệu mẫu cho Tên đường
    INSERT INTO @duong VALUES 
        (N'Nguyễn Văn Linh'), (N'Phan Châu Trinh'), (N'Bạch Đằng'), (N'Trần Phú'), 
        (N'Lê Duẩn'), (N'Hùng Vương'), (N'Nguyễn Hữu Thọ'), (N'Hàm Nghi'), 
        (N'Lê Hồng Phong'), (N'Núi Thành'), (N'Võ Văn Kiệt'), (N'Phạm Văn Đồng'), 
        (N'Châu Thị Vĩnh Tế'), (N'Tôn Thất Thiệp'), (N'Nguyễn Tất Thành'), (N'Lê Độ');

    -- =========================================================================
    -- 2. Khai báo biến xử lý vòng lặp
    -- =========================================================================
    DECLARE @STT INT = 1;
    DECLARE @maNCC CHAR(6);
    DECLARE @tenNCC NVARCHAR(100);
    DECLARE @diaChiNCC NVARCHAR(150);
    DECLARE @sdtNCC VARCHAR(10);

    -- Biến tạm để ghép chuỗi
    DECLARE @loaiHinh NVARCHAR(50), @phanDau NVARCHAR(50), @phanCuoi NVARCHAR(50), @linhVuc NVARCHAR(50);
    DECLARE @tenDuong NVARCHAR(100), @quan NVARCHAR(50), @soNha INT;
    DECLARE @dauSo VARCHAR(3);

    -- =========================================================================
    -- 3. Vòng lặp sinh dữ liệu
    -- =========================================================================
    WHILE @STT <= @SoLuong
    BEGIN
        -- Sinh Mã NCC: Dạng 'NCC' + 3 số (Để phù hợp với constraint CHAR(6) của DDL)
        SET @maNCC = 'NCC' + RIGHT('000' + CAST(@STT AS VARCHAR), 3);

        -- Random Tên Công Ty
        SELECT TOP 1 @loaiHinh = LoaiHinh FROM @loaiHinhCongTy ORDER BY NEWID();
        SELECT TOP 1 @phanDau = PhanDau FROM @phanDauTen ORDER BY NEWID();
        SELECT TOP 1 @phanCuoi = PhanCuoi FROM @phanCuoiTen ORDER BY NEWID();
        SELECT TOP 1 @linhVuc = LinhVuc FROM @linhVucHoatDong ORDER BY NEWID();
        SET @tenNCC = @loaiHinh + ' ' + @phanDau + ' ' + @phanCuoi + ' ' + @linhVuc;

        -- Random Địa chỉ
        SELECT TOP 1 @tenDuong = TenDuong FROM @duong ORDER BY NEWID();
        
        -- Xác định Quận dựa theo Tên đường bằng CASE WHEN
        SET @quan = CASE 
            WHEN @tenDuong IN (N'Nguyễn Văn Linh', N'Phan Châu Trinh', N'Bạch Đằng', N'Trần Phú', N'Lê Duẩn', N'Hùng Vương', N'Nguyễn Hữu Thọ', N'Hàm Nghi', N'Lê Hồng Phong', N'Núi Thành') THEN N'Hải Châu'
            WHEN @tenDuong IN (N'Võ Văn Kiệt', N'Phạm Văn Đồng', N'Châu Thị Vĩnh Tế', N'Tôn Thất Thiệp') THEN N'Sơn Trà'
            WHEN @tenDuong IN (N'Nguyễn Tất Thành', N'Lê Độ') THEN N'Thanh Khê'
            ELSE N'Hải Châu' -- Mặc định phòng hờ
        END;

        SET @soNha = ABS(CHECKSUM(NEWID())) % 999 + 1;
        SET @diaChiNCC = N'Số ' + CAST(@soNha AS NVARCHAR) + N', Đường ' + @tenDuong + N', Quận ' + @quan + N', Đà Nẵng';

        -- Random Số điện thoại
        SELECT TOP 1 @dauSo = DauSo FROM @dauSoDienThoai ORDER BY NEWID();
        SET @sdtNCC = @dauSo + RIGHT('0000000' + CAST(ABS(CHECKSUM(NEWID())) % 10000000 AS VARCHAR), 7);

        -- =====================================================================
        -- 4. Xử lý ngoại lệ và Insert dữ liệu
        -- =====================================================================
        BEGIN TRY
            INSERT INTO NCC (MaNCC, TenNCC, DiaChiNCC, SDTNCC)
            VALUES (@maNCC, @tenNCC, @diaChiNCC, @sdtNCC);

            -- Nếu Insert thành công, không vướng ràng buộc UNIQUE (SDTNCC) thì mới tăng biến đếm
            SET @STT = @STT + 1;
        END TRY
        BEGIN CATCH
            -- Nếu bị lỗi (chủ yếu là trùng số điện thoại do ràng buộc UNIQUE), 
            -- vòng lặp sẽ bỏ qua không tăng biến @STT, tiếp tục random lại ở vòng sau.
            PRINT N'BỎ QUA DO LỖI HOẶC TRÙNG SĐT TẠI MÃ ' + @maNCC + ': ' + ERROR_MESSAGE();
        END CATCH
    END

    PRINT N'Đã hoàn thành dump ' + CAST(@SoLuong AS NVARCHAR) + N' bản ghi vào bảng NCC!';
END
GO

-- =============================================================================
-- CÁCH CHẠY THỬ (TESTING)
-- =============================================================================
-- TRUNCATE TABLE NCC; -- Xóa dữ liệu cũ nếu cần

-- Thực thi thủ tục
EXEC dumpDL_NCC @SoLuong = 200;

-- Kiểm tra lại dữ liệu
SELECT  * FROM NCC;
SELECT COUNT(*) AS TongSoNCC FROM NCC;