--	TẠO LOGIN CHO QUẢN LÝ	
--Bước 1: Tạo login
CREATE LOGIN store_manager  
WITH PASSWORD ='Nhom1012345#',	-- Mật khẩu của Login
	 CHECK_POLICY=ON,			-- Kiểm tra chính sách mật khẩu (bao gồm độ dài và tính phức tạp)
	 CHECK_EXPIRATION=ON;		-- Mật khẩu sẽ hết hạn sau một thời gian nhất định

--Bước 2: Sử dụng ALTER LOGIN để thiết lập MUST_CHANGE
ALTER LOGIN store_manager 
WITH PASSWORD= 'Nhom1012345#' MUST_CHANGE;		--Yêu cầu người dùng thay đổi mật khẩu khi đăng nhập lần đầu


--TẠO LOGIN CHO NHÂN VIÊN
--Bước 1: Tạo login
CREATE LOGIN staff_user1
WITH PASSWORD ='Nhom1012345#',	-- Mật khẩu của Login
	 CHECK_POLICY=ON,			-- Kiểm tra chính sách mật khẩu (bao gồm độ dài và tính phức tạp)
	 CHECK_EXPIRATION=ON;		-- Mật khẩu sẽ hết hạn sau một thời gian nhất định
--Bước 2: Sử dụng ALTER LOGIN để thiết lập MUST_CHANGE
ALTER LOGIN staff_user1
WITH PASSWORD= 'Nhom1012345#' MUST_CHANGE;		--Yêu cầu người dùng thay đổi mật khẩu khi đăng nhập lần đầu

--Bước 1: Tạo login
CREATE LOGIN staff_user2
WITH PASSWORD ='Nhom1012345#',	-- Mật khẩu của Login
	 CHECK_POLICY=ON,			-- Kiểm tra chính sách mật khẩu (bao gồm độ dài và tính phức tạp)
	 CHECK_EXPIRATION=ON;		-- Mật khẩu sẽ hết hạn sau một thời gian nhất định

--Bước 2: Sử dụng ALTER LOGIN để thiết lập MUST_CHANGE
ALTER LOGIN staff_user2
WITH PASSWORD= 'Nhom1012345#' MUST_CHANGE;		--Yêu cầu người dùng thay đổi mật khẩu khi đăng nhập lần đầu

-- Chạy lệnh này để reset lại mật khẩu và gỡ bỏ cờ MUST_CHANGE cho cả 3 tài khoản
ALTER LOGIN store_manager WITH PASSWORD = 'Nhom1012345#';
ALTER LOGIN staff_user1 WITH PASSWORD = 'Nhom1012345#';
ALTER LOGIN staff_user2 WITH PASSWORD = 'Nhom1012345#';


-- TẠO USER
--Tạo user cho store_manager 
USE QLY_CONGCAFFE
CREATE USER store_manager FOR LOGIN store_manager
--Tạo user cho staff_user1 
USE QLY_CONGCAFFE
CREATE USER staff_user1 FOR LOGIN  staff_user1
--Tạo user cho staff_user2
USE QLY_CONGCAFFE
CREATE USER staff_user2 FOR LOGIN  staff_user2

-- Cấp quyền SELECT (xem dữ liệu) trên View HOADON_NHAP_VIEW cho nhóm staff_role
GRANT SELECT ON HOADON_NHAP_VIEW TO staff_role;
GO

-- Cấp quyền XEM danh sách sản phẩm cho nhân viên
GRANT SELECT ON dbo.SANPHAM TO staff_role;

-- CẤM nhân viên Thêm, Sửa, Xóa sản phẩm
DENY INSERT, UPDATE, DELETE ON dbo.SANPHAM TO staff_role;
GO

-- Cấp quyền XEM bảng Loại Sản Phẩm cho nhân viên
GRANT SELECT ON dbo.LOAISANPHAM TO staff_role;

-- CẤM nhân viên Thêm, Sửa, Xóa Loại Sản Phẩm
DENY INSERT, UPDATE, DELETE ON dbo.LOAISANPHAM TO staff_role;
GO

-- Cấp quyền XEM bảng Vị Trí cho nhân viên
GRANT SELECT ON dbo.VITRI TO staff_role;

-- CẤM nhân viên Thêm, Sửa, Xóa trong bảng Vị Trí
DENY INSERT, UPDATE, DELETE ON dbo.VITRI TO staff_role;
GO


-- Cấp quyền XEM, THÊM và SỬA thông tin Khách Hàng cho nhân viên
GRANT SELECT, INSERT, UPDATE ON dbo.KHACHHANG TO staff_role;

-- CẤM nhân viên XÓA thông tin Khách Hàng
DENY DELETE ON dbo.KHACHHANG TO staff_role;
GO


-- Cấp quyền XEM và THÊM chi tiết món cho nhân viên
GRANT SELECT, INSERT ON dbo.CTHD_BAN TO staff_role;

-- CẤM nhân viên tự ý SỬA hoặc XÓA chi tiết món đã order
DENY UPDATE, DELETE ON dbo.CTHD_BAN TO staff_role;
GO

-- Cấp quyền XEM và TẠO hóa đơn bán mới cho nhân viên
GRANT SELECT, INSERT ON dbo.HOADON_BAN TO staff_role;
GO

-- Cấp quyền XEM và THÊM chi tiết hóa đơn bán cho nhân viên
GRANT SELECT, INSERT ON dbo.CTHD_BAN TO staff_role;

-- CẤM nhân viên tự ý SỬA hoặc XÓA chi tiết hóa đơn bán
DENY UPDATE, DELETE ON dbo.CTHD_BAN TO staff_role;
GO

-- Cấp quyền XEM dữ liệu trên bảng gốc HOADON_NHAP
GRANT SELECT ON dbo.HOADON_NHAP TO staff_role;

-- CẤM nhân viên Thêm, Sửa, Xóa trực tiếp trên bảng này
DENY INSERT, UPDATE, DELETE ON dbo.HOADON_NHAP TO staff_role;
GO

-- Cấp quyền XEM dữ liệu từ View cho nhân viên
GRANT SELECT ON dbo.HOADON_NHAP_VIEW TO staff_role;

-- CẤM nhân viên Thêm, Sửa, Xóa thông qua View này
DENY INSERT, UPDATE, DELETE ON dbo.HOADON_NHAP_VIEW TO staff_role;
GO

-- Chỉ cho phép nhóm staff_role xem dữ liệu bảng gốc HOADON_NHAP
GRANT SELECT ON dbo.HOADON_NHAP TO staff_role;

-- Cấm các thao tác thay đổi dữ liệu trên bảng gốc này
DENY INSERT, UPDATE, DELETE ON dbo.HOADON_NHAP TO staff_role;
GO


-- Cấm tuyệt đối các quyền xem, thêm, sửa, xóa trên bảng gốc CTHD_NHAP cho nhóm staff_role
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.CTHD_NHAP TO staff_role;
GO

-- Cấm tuyệt đối các quyền xem, thêm, sửa, xóa trên bảng NVL cho nhóm staff_role
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.NVL TO staff_role;
GO

-- Từ chối các quyền xem, thêm, sửa, xóa trên bảng Nhà cung cấp cho nhóm staff_role
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.NCC TO staff_role;
GO


-- Từ chối tất cả các quyền truy vấn và thay đổi dữ liệu trên bảng NHANVIEN cho nhóm staff_role
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.NHANVIEN TO staff_role;
GO

-- 1. Cấp quyền thực thi module Thêm Khách hàng
GRANT EXECUTE ON dbo.sp_ThemKhachHang TO staff_role;

-- 2. Cấp quyền thực thi module Sửa Khách hàng
GRANT EXECUTE ON dbo.sp_SuaKhachHang TO staff_role;

-- 3. Cấp quyền thực thi module Xóa Khách hàng
GRANT EXECUTE ON dbo.sp_XoaKhachHang TO staff_role;
GO


USE QLY_CONGCAFFE;
GO

-- 1. Cấp quyền thực thi module Thêm Nhân viên
GRANT EXECUTE ON dbo.sp_ThemNhanVien TO staff_role;

-- 2. Cấp quyền thực thi module Sửa Nhân viên
GRANT EXECUTE ON dbo.sp_SuaNhanVien TO staff_role;

-- 3. Cấp quyền thực thi module Xóa Nhân viên
GRANT EXECUTE ON dbo.sp_XoaNhanVien TO staff_role;
GO


USE QLY_CONGCAFFE; -- Nhảy vào đúng "nhà" của mình
GO

-- Sau đó mới chạy các lệnh GRANT
GRANT EXECUTE ON dbo.sp_ThemSanPham TO staff_role;
GRANT EXECUTE ON dbo.sp_SuaSanPham TO staff_role;
GRANT EXECUTE ON dbo.sp_XoaSanPham TO staff_role;
GO