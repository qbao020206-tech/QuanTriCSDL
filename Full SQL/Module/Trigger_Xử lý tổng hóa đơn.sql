USE QLY_CONGCAFFE;
GO

-- Xóa trigger cũ nếu đã tồn tại để tạo lại cái mới cho chắc chắn
IF OBJECT_ID('trg_CapNhatTongTien_HDBan', 'TR') IS NOT NULL
    DROP TRIGGER trg_CapNhatTongTien_HDBan;
GO

-- Tạo Trigger gắn vào bảng CTHD_BAN
CREATE TRIGGER trg_CapNhatTongTien_HDBan
ON CTHD_BAN
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Lệnh này sẽ tự động chạy ngầm mỗi khi bạn thêm, sửa, xóa CTHD_BAN
    UPDATE HD
    SET HD.TongTien = (
        SELECT ISNULL(SUM(ThanhTien), 0) 
        FROM CTHD_BAN CT 
        WHERE CT.MaBILL = HD.MaBILL
    )
    FROM HOADON_BAN HD
    -- Chỉ tính toán lại cho đúng cái Hóa Đơn vừa bị tác động
    WHERE HD.MaBILL IN (
        SELECT MaBILL FROM inserted 
        UNION 
        SELECT MaBILL FROM deleted
    );
END;
GO

-- Lệnh này sẽ quét quá khứ, cộng dồn toàn bộ bảng chi tiết và cập nhật lên hóa đơn
UPDATE HD
SET HD.TongTien = ISNULL(CT.TongThanhTien, 0)
FROM HOADON_BAN HD
LEFT JOIN (
    SELECT MaBILL, SUM(ThanhTien) AS TongThanhTien 
    FROM CTHD_BAN 
    GROUP BY MaBILL
) CT ON HD.MaBILL = CT.MaBILL;

PRINT N'Đã cập nhật lại Tổng Tiền cho toàn bộ hóa đơn cũ!';

--===============================================================================================================

CREATE OR ALTER TRIGGER trg_CapNhatTongTien_HDNhap
ON CTHD_NHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Tự động cập nhật lại TongTien mỗi khi CTHD_NHAP có thay đổi
    UPDATE HN
    SET HN.TongTien = (
        SELECT ISNULL(SUM(ThanhTien), 0) 
        FROM CTHD_NHAP CT 
        WHERE CT.MaHD_NH = HN.MaHD_NH
    ) * (1 + HN.ThueVAT)
    FROM HOADON_NHAP HN
    -- Chỉ cập nhật đúng cái Hóa đơn vừa bị tác động
    WHERE HN.MaHD_NH IN (
        SELECT MaHD_NH FROM inserted 
        UNION 
        SELECT MaHD_NH FROM deleted
    );
END;
GO



UPDATE HN
SET HN.TongTien = ISNULL(CT.TongThanhTien, 0) * (1 + HN.ThueVAT) 
-- Nếu logic của bạn Tổng tiền KHÔNG bao gồm VAT, hãy bỏ cụm "* (1 + HN.ThueVAT)" đi nhé.
FROM HOADON_NHAP HN
LEFT JOIN (
    SELECT MaHD_NH, SUM(ThanhTien) AS TongThanhTien 
    FROM CTHD_NHAP 
    GROUP BY MaHD_NH
) CT ON HN.MaHD_NH = CT.MaHD_NH;

PRINT N'Đã cập nhật lại Tổng Tiền cho toàn bộ Hóa Đơn Nhập!';

--========================================================
