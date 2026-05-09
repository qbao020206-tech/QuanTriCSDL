USE QLY_CONGCAFFE;
GO
CREATE OR ALTER PROCEDURE dumpDL_KHACHHANG
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tuDienTen TABLE (khoaTen NVARCHAR(10), giaTriTen NVARCHAR(MAX));
    DECLARE @quan TABLE (quan NVARCHAR(50));
    DECLARE @dauSo TABLE (dauSo NVARCHAR(10));

    INSERT INTO @dauSo VALUES 
    ('032'),('033'),('034'),('035'),('036'),('037'),('038'),
    ('039'),('086'),('096'),('097'),('098'),('070'),('076'),('077'),
    ('078'),('079'),('089'),('090'),('093'),('081'),('082'),('083'),
    ('084'),('085'),('088'),('091'),('094');

    INSERT INTO @tuDienTen VALUES
    (N'Họ', N'Nguyễn,Phan,Lê,Văn,Phạm,Phùng,Đinh,Trần,Mai,Chu,Sử,Khổng,Hoàng,Huỳnh,Vũ,Đặng,Nông,Ứng,Phí,Lương,Lại,Ma,Đào,Lữ,Vương,Đổng,Trịnh,Mẫn,Võ,Bùi,Dương,Ngô,Hồ,Lý,Tôn,Sầm,Ông,Triệu,Quách'),
    (N'Tên Đệm', N'Văn,Thị,Duy,Đình,Khánh,Minh,Đức,Công,Bảo,Hoài,Gia,Mai,Ngọc,Thu,Vân,Vỹ,Như,Quỳnh,Thảo,Thanh'),
    (N'Tên', N'Anh,Vy,Thủy,Mai,Đan,Phụng,Thư,Thụy,Hưng,Vũ,Trúc,Lan,Mạnh,Nam,Phúc,Công,Duy,Ý,Tuyết,Hiến,An,Hoàng,Ngân,Tam,Nhiên,Hương,Hoa,Mỹ,Thiệu,Nghi,Tú,Sâm,Bắc,Tây,Đông');

    INSERT INTO @quan VALUES
    (N'Hải Châu'), (N'Sơn Trà'), (N'Ngũ Hành Sơn'), (N'Thanh Khê'),
    (N'Hòa Vang'), (N'Cẩm Lệ'), (N'Liên Chiểu');

    DECLARE 
        @count INT = 1,
        @max INT = 1000000, 
        @ngayBD DATE = '1970-01-01',
        @ngayKT DATE = '2006-12-31',
        @daysDiff INT;

    SET @daysDiff = DATEDIFF(DAY, @ngayBD, @ngayKT);

    WHILE @count <= @max
    BEGIN
        DECLARE 
            @maKH CHAR(10), -- Sửa lại thành CHAR(10)
            @tenKH NVARCHAR(50),
            @sdt_KH CHAR(10),
            @ngaySinh DATE,
            @dchi_KH NVARCHAR(100),
            @ho NVARCHAR(20),
            @tenDem NVARCHAR(20),
            @ten NVARCHAR(20),
            @tenQuan NVARCHAR(50),
            @duong NVARCHAR(50);

        -- Sửa lại 8 số 0 để chuỗi KH + 8 số = 10 ký tự
        SET @maKH = 'KH' + RIGHT('00000000' + CAST(@count AS VARCHAR), 8); 

        SET @ho = (SELECT TOP 1 VALUE FROM STRING_SPLIT((SELECT giaTriTen FROM @tuDienTen WHERE khoaTen = N'Họ'), ',') ORDER BY NEWID());
        SET @tenDem = (SELECT TOP 1 VALUE FROM STRING_SPLIT((SELECT giaTriTen FROM @tuDienTen WHERE khoaTen = N'Tên Đệm'), ',') ORDER BY NEWID());
        SET @ten = (SELECT TOP 1 VALUE FROM STRING_SPLIT((SELECT giaTriTen FROM @tuDienTen WHERE khoaTen = N'Tên'), ',') ORDER BY NEWID());

        SET @tenKH = @ho + ' ' + @tenDem + ' ' + @ten;

        SET @sdt_KH = (SELECT TOP 1 dauSo FROM @dauSo ORDER BY NEWID())
                      + RIGHT(CAST(CAST(RAND() * 9000000 + 1000000 AS INT) AS VARCHAR), 7);

        SET @ngaySinh = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % @daysDiff, @ngayBD);

        SELECT TOP 1 @tenQuan = quan FROM @quan ORDER BY NEWID();

        SET @duong =
            CASE    
                WHEN @tenQuan = N'Hải Châu' THEN (SELECT TOP 1 duong FROM (VALUES 
                (N'Cao Thắng'), (N'Lê Đình Lý'), (N'Hùng Vương'), (N'Lê Lợi'), (N'3.2'), (N'Nguyễn Chí Thanh'), 
                (N'Phan Châu Trinh'), (N'Tiểu La'), (N'2.9'), (N'Quang Trung'), (N'Đống Đa'), (N'Nguyễn Du'), 
                (N'Lý Tự Trọng'), (N'Hoàng Diệu'), (N'Ông Ích Khiêm'), (N'Nguyễn Hoàng'), (N'Thái Phiên'), (N'Lê Hồng Phong'), 
                (N'Hoàng Văn Thụ'), (N'Yên Bái'), (N'Trưng Nữ Vương'), (N'Ngô Gia Tự'), (N'Triệu Nữ Vương'), 
                (N'Pasteur'), (N'Lê Đình Dương'), (N'Nguyễn Văn Linh'), (N'Lê Thanh Nghị'), (N'Xô Viết Nghệ Tĩnh'),
                (N'Trần Phú'), (N'Bạch Đằng')) AS tenDuong (duong) ORDER BY NEWID())
                ELSE N'Nguyễn Văn Linh'
            END

        SET @dchi_KH =
            N'Số ' + CAST(ROUND(RAND() * 999, 0) AS NVARCHAR(10)) +
            N', Đường ' + @duong +
            N', ' + @tenQuan +
            N', Đà Nẵng';

        BEGIN TRY
            INSERT INTO KHACHHANG (MaKH, TenKH, SDTKH, NgaySinhKH, DiaChiKH)
            VALUES (@maKH, @tenKH, @sdt_KH, @ngaySinh, @dchi_KH);

            SET @count = @count + 1;
        END TRY
        BEGIN CATCH
            PRINT N'Lỗi tại dòng ' + CAST(@count AS VARCHAR) + N': ' + ERROR_MESSAGE();
            SET @count = @count + 1; 
        END CATCH
    END
END
EXEC dumpDL_KHACHHANG;

  -- Dòng này là mở bảng ra để xe
  SELECT * FROM KHACHHANG;
  SELECT * FROM NHANVIEN
  USE QLY_CONGCAFFE;
GO

DECLARE @tuDienTen TABLE (khoaTen NVARCHAR(10), giaTriTen NVARCHAR(MAX));
DECLARE @quan TABLE (quan NVARCHAR(50));
DECLARE @dauSo TABLE (dauSo NVARCHAR(10));

INSERT INTO @dauSo VALUES 
('032'),('033'),('034'),('035'),('036'),('037'),('038'),
('039'),('086'),('096'),('097'),('098'),('070'),('076'),('077'),
('078'),('079'),('089'),('090'),('093'),('081'),('082'),('083'),
('084'),('085'),('088'),('091'),('094');

INSERT INTO @quan VALUES 
(N'Hải Châu'), (N'Sơn Trà'), (N'Ngũ Hành Sơn'), (N'Thanh Khê'),
(N'Hòa Vang'), (N'Cẩm Lệ'), (N'Liên Chiểu');

-- Biến để chạy vòng lặp cập nhật
DECLARE @maKH CHAR(10);
DECLARE @tenQuan NVARCHAR(50), @duong NVARCHAR(50), @dchi_KH NVARCHAR(100), @sdt_KH CHAR(10);

-- Sử dụng CURSOR để quét qua các dòng đang bị NULL dữ liệu
DECLARE kh_cursor CURSOR FOR 
SELECT MaKH FROM KHACHHANG WHERE SDTKH IS NULL OR DiaChiKH IS NULL;

OPEN kh_cursor;
FETCH NEXT FROM kh_cursor INTO @maKH;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 1. Sinh số điện thoại ngẫu nhiên
    SET @sdt_KH = (SELECT TOP 1 dauSo FROM @dauSo ORDER BY NEWID()) 
                  + RIGHT(CAST(CAST(RAND() * 9000000 + 1000000 AS INT) AS VARCHAR), 7);

    -- 2. Sinh địa chỉ ngẫu nhiên
    SELECT TOP 1 @tenQuan = quan FROM @quan ORDER BY NEWID();
    
    SET @duong = CASE    
        WHEN @tenQuan = N'Hải Châu' THEN (SELECT TOP 1 duong FROM (VALUES 
        (N'Cao Thắng'), (N'Lê Đình Lý'), (N'Hùng Vương'), (N'Lê Lợi'), (N'Nguyễn Chí Thanh'), 
        (N'Phan Châu Trinh'), (N'Bạch Đằng'), (N'Trần Phú'), (N'Quang Trung')) AS tenDuong(duong) ORDER BY NEWID())
        ELSE N'Nguyễn Văn Linh'
    END

    SET @dchi_KH = N'Số ' + CAST(ABS(CHECKSUM(NEWID())) % 999 + 1 AS NVARCHAR(10)) +
                   N', Đường ' + @duong + N', ' + @tenQuan + N', Đà Nẵng';

    -- 3. Cập nhật vào bảng
    UPDATE KHACHHANG 
    SET SDTKH = @sdt_KH, 
        DiaChiKH = @dchi_KH
    WHERE MaKH = @maKH;

    FETCH NEXT FROM kh_cursor INTO @maKH;
END

CLOSE kh_cursor;
DEALLOCATE kh_cursor;
GO

-- Kiểm tra kết quả
SELECT TOP 100 * FROM KHACHHANG;

