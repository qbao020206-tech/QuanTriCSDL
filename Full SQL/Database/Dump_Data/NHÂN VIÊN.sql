USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROC dumpDL_NHANVIEN
    @SoLuong INT = 1000000 -- Đặt số lượng bạn muốn test
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Khởi tạo các bảng biến để lưu dữ liệu nguồn
    DECLARE @hoNV TABLE (ho NVARCHAR(50));
    DECLARE @tenLotNV TABLE (tenLot NVARCHAR(50));
    DECLARE @tenNV TABLE (ten NVARCHAR(50));
    -- Thêm cột id để lát nữa chia đều đầu số điện thoại
    DECLARE @dau_SDT TABLE (id INT IDENTITY(1,1), dauSo VARCHAR(3)); 

    -- Thêm dữ liệu mẫu
    INSERT INTO @hoNV VALUES (N'Nguyễn'), (N'Trần'), (N'Lê'), (N'Phạm'), (N'Hoàng'), (N'Vũ'), (N'Huỳnh'), (N'Phan'), (N'Dương'), (N'Đoàn');
    INSERT INTO @tenLotNV VALUES (N'Văn'), (N'Khánh'), (N'Ngọc'), (N'Thanh'), (N'Bảo'), (N'Minh'), (N'Xuân'), (N'Thị'), (N'Hữu'), (N'Gia');
    INSERT INTO @tenNV VALUES (N'Nam'), (N'Lan'), (N'Tú'), (N'Khoa'), (N'Phương'), (N'Anh'), (N'Ngân'), (N'Nhi'), (N'Tuấn'), (N'Linh');
    INSERT INTO @dau_SDT (dauSo) VALUES ('032'), ('033'), ('034'), ('035'), ('036'), ('037'), ('038'), ('039'), ('086'), ('096'), ('097'), ('098'), ('070'), ('079'), ('090'), ('093');

    -- 2. Khai báo các biến xử lý
    DECLARE @i INT = 1;
    DECLARE @maNV CHAR(10);
    DECLARE @hoTen NVARCHAR(50);
    DECLARE @ho NVARCHAR(50), @tenLot NVARCHAR(50), @ten NVARCHAR(50);
    DECLARE @gioiTinh NVARCHAR(3);
    DECLARE @SDT CHAR(10);
    DECLARE @dauSo VARCHAR(3);
    DECLARE @STK NVARCHAR(50);
    DECLARE @ngaySinh DATETIME;
    DECLARE @soNgayRandom INT;

    -- 3. Tạo vòng lặp sinh dữ liệu
    WHILE @i <= @SoLuong
    BEGIN
        SET @maNV = 'NV' + RIGHT('00000000' + CAST(@i AS VARCHAR), 8);

        SELECT TOP 1 @ho = ho FROM @hoNV ORDER BY NEWID();
        SELECT TOP 1 @tenLot = tenLot FROM @tenLotNV ORDER BY NEWID();
        SELECT TOP 1 @ten = ten FROM @tenNV ORDER BY NEWID();
        SET @hoTen = @ho + ' ' + @tenLot + ' ' + @ten;

        IF (ABS(CHECKSUM(NEWID())) % 2 = 0) SET @gioiTinh = N'Nam'; ELSE SET @gioiTinh = N'Nữ';

        SET @soNgayRandom = ABS(CHECKSUM(NEWID())) % 13514;
        SET @ngaySinh = DATEADD(DAY, @soNgayRandom, '1970-01-01');

        -- ==========================================
        -- THUẬT TOÁN MỚI: CHỐNG TRÙNG LẶP TUYỆT ĐỐI
        -- ==========================================
        
        -- Số điện thoại: Phân bổ đều qua 16 đầu số và dùng biến @i làm đuôi số
        SELECT @dauSo = dauSo FROM @dau_SDT WHERE id = ((@i % 16) + 1);
        SET @SDT = @dauSo + RIGHT('0000000' + CAST((@i / 16) + 1000000 AS VARCHAR), 7);

        -- Số tài khoản: Sinh 1 số random 3 chữ số làm đầu + ghép trực tiếp biến @i làm đuôi
        SET @STK = CAST(ABS(CHECKSUM(NEWID())) % 900 + 100 AS VARCHAR) + RIGHT('000000000' + CAST(@i AS VARCHAR), 9);

        BEGIN TRY
            INSERT INTO NHANVIEN (MaNV, TenNV, GioiTinh, NgaySinhNV, STK, SDTNV)
            VALUES (@maNV, @hoTen, @gioiTinh, @ngaySinh, @STK, @SDT);

            -- Chỉ tăng đếm khi thành công
            SET @i = @i + 1; 
        END TRY
        BEGIN CATCH
            -- Xóa lệnh tăng @i ở đây. Nếu gặp lỗi nó sẽ tự động thử lại ở cùng 1 giá trị @i.
        END CATCH
    END

    PRINT N'Đã hoàn thành dump ' + CAST(@SoLuong AS NVARCHAR) + N' bản ghi Nhân Viên!';
END
GO

-- ==========================================
-- CÁCH CHẠY THỬ (TESTING)
-- ==========================================
-- Xóa dữ liệu cũ (nếu có) trước khi test
-- TRUNCATE TABLE NHANVIEN; 

-- Chạy thủ tục với 200 dòng mặc định
EXEC dumpDL_NHANVIEN;

-- Kiểm tra kết quả
SELECT  * FROM NHANVIEN;
SELECT COUNT(*) AS TongSoNhanVien FROM NHANVIEN;

TRUNCATE TABLE NHANVIEN

DELETE FROM NHANVIEN;