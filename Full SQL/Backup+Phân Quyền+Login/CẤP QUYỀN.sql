USE QLY_CONGCAFFE;
GO
GRANT EXECUTE ON dbo.sp_ThemSanPham TO staff_role;
GRANT EXECUTE ON dbo.sp_SuaSanPham TO staff_role;
GRANT EXECUTE ON dbo.sp_XoaSanPham TO staff_role;
GO

USE master;
GO
SELECT name, DB_NAME() as [Database_Hien_Tai]
FROM sys.procedures 
WHERE name IN ('sp_ThemSanPham', 'sp_SuaSanPham', 'sp_XoaSanPham');

USE master;
GO
DROP PROCEDURE IF EXISTS dbo.sp_ThemSanPham;
DROP PROCEDURE IF EXISTS dbo.sp_SuaSanPham;
DROP PROCEDURE IF EXISTS dbo.sp_XoaSanPham;
GO


USE QLY_CONGCAFFE;
GO

-- 1. Cấp quyền thực thi module Thêm Nhà Cung Cấp
GRANT EXECUTE ON dbo.sp_ThemNCC TO staff_role;

-- 2. Cấp quyền thực thi module Sửa Nhà Cung Cấp
GRANT EXECUTE ON dbo.sp_SuaNCC TO staff_role;

-- 3. Cấp quyền thực thi module Xóa Nhà Cung Cấp
GRANT EXECUTE ON dbo.sp_XoaNCC TO staff_role;
GO

-- Đảm bảo đứng đúng vị trí
USE QLY_CONGCAFFE;
GO

-- 1. Cấp quyền thực thi cho module Thêm nguyên vật liệu
GRANT EXECUTE ON dbo.sp_ThemNVL TO staff_role;

-- 2. Cấp quyền thực thi cho module Sửa nguyên vật liệu
GRANT EXECUTE ON dbo.sp_SuaNVL TO staff_role;

-- 3. Cấp quyền thực thi cho module Xóa nguyên vật liệu
GRANT EXECUTE ON dbo.sp_XoaNVL TO staff_role;
GO


USE QLY_CONGCAFFE;
GO

-- 1. Cấp quyền cho nghiệp vụ NHẬP HÀNG
GRANT EXECUTE ON dbo.sp_ThemHoaDonNhap TO staff_role;
GRANT EXECUTE ON dbo.sp_ThemCTHD_Nhap TO staff_role;

-- 2. Cấp quyền cho nghiệp vụ BÁN HÀNG
GRANT EXECUTE ON dbo.sp_ThemHoaDonBan TO staff_role;
GRANT EXECUTE ON dbo.sp_ThemCTHD_Ban TO staff_role;
GO

USE master;
GO

-- Xóa các thủ tục đang nằm sai chỗ
DROP PROCEDURE IF EXISTS dbo.sp_ThemHoaDonNhap;
DROP PROCEDURE IF EXISTS dbo.sp_ThemCTHD_Nhap;
DROP PROCEDURE IF EXISTS dbo.sp_ThemHoaDonBan;
DROP PROCEDURE IF EXISTS dbo.sp_ThemCTHD_Ban;
GO

-- Đảm bảo đang đứng đúng Database của quán cafe
USE QLY_CONGCAFFE;
GO

-- Từ chối quyền thực thi module Thống kê doanh thu cho nhóm nhân viên (staff_role)
DENY EXECUTE ON dbo.sp_ThongKeDoanhThu_TungSanPham TO staff_role;
GO


-- Đảm bảo đang đứng đúng Database QLY_CONGCAFFE
USE QLY_CONGCAFFE;
GO

-- 1. Cấp quyền Xóa Hóa đơn Bán và Chi tiết Hóa đơn Bán
GRANT EXECUTE ON dbo.sp_XoaHoaDonBan TO staff_role;
GRANT EXECUTE ON dbo.sp_XoaChiTietHoaDonBan TO staff_role;

-- 2. Cấp quyền Xóa Hóa đơn Nhập và Chi tiết Hóa đơn Nhập
GRANT EXECUTE ON dbo.sp_XoaHoaDonNhap TO staff_role;
GRANT EXECUTE ON dbo.sp_XoaChiTietHoaDonNhap TO staff_role;
GO

USE QLY_CONGCAFFE;
GO
SELECT name FROM sys.procedures 
WHERE name IN ('sp_XoaHoaDonBan', 'sp_XoaChiTietHoaDonBan', 'sp_XoaChiTietHoaDonNhap');