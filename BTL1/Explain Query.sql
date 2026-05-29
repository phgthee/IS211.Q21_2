-- Câu truy vấn ban đầu
-- Lấy thông tin sản phẩm, hóa đơn, khách hàng và tồn kho cho các hóa đơn có tổng tiền từ 100.000 đến 1.000.000 trong tháng 01/2025 do nhân viên tên “Linh” lập.
SELECT DISTINCT
 SP.MaSanPham,
 SP.TenSanPham,
 SP.GiaBan,
 QLK.SoLuongTrongKho,
 HD.MaHoaDon,
 HD.NgayTao,
 HD.TongTien,
 HD.PhuongThucThanhToan,
 NV.HoTen AS TenNhanVien,
 KH.HoTen AS TenKhachHang
FROM CH1.ChiTietHoaDon@NhanVien21Link CTHD
JOIN CH1.HoaDon@NhanVien21Link HD ON CTHD.MaHoaDon = HD.MaHoaDon
JOIN CH1.NhanVien@NhanVien21Link NV ON HD.MaNhanVien = NV.MaNhanVien
JOIN CH1.KhachHang@NhanVien21Link KH ON HD.MaKhachHang =
KH.MaKhachHang
JOIN SanPham SP ON CTHD.MaSanPham = SP.MaSanPham
JOIN CH1.TonKho_CuaHang@NhanVien21Link QLK ON SP.MaSanPham =
QLK.MaSanPham
WHERE
 NV.HoTen LIKE '% Linh'
 AND HD.TongTien BETWEEN 100000 AND 1000000
 AND HD.PhuongThucThanhToan = 'CHUYENKHOAN'
 AND HD.NgayTao >= TO_DATE('01/01/2025', 'DD/MM/YYYY')
 AND HD.NgayTao < TO_DATE('01/02/2025', 'DD/MM/YYYY')

-----------------------------------------------------------------------
-- Thực hiện EXPLAIN câu truy vấn chưa tối ưu
-- 1. Bật thống kê thời gian thực trong Oracle để lấy số liệu chi tiết
ALTER SESSION SET statistics_level = ALL;
-- 2. Yêu cầu phân tích kế hoạch thực thi (Explain Plan)
EXPLAIN PLAN FOR
SELECT DISTINCT
 SP.MaSanPham,
 SP.TenSanPham,
 SP.GiaBan,
 QLK.SoLuongTrongKho,
 HD.MaHoaDon,
 HD.NgayTao,
 HD.TongTien,
 HD.PhuongThucThanhToan,
 HD.PhuongThucThanhToan,
 NV.HoTen AS TenNhanVien,
 KH.HoTen AS TenKhachHang
FROM CH1.ChiTietHoaDon@NhanVien21Link CTHD
JOIN CH1.HoaDon@NhanVien21Link HD ON CTHD.MaHoaDon = HD.MaHoaDon
JOIN CH1.NhanVien@NhanVien21Link NV ON HD.MaNhanVien = NV.MaNhanVien
JOIN CH1.KhachHang@NhanVien21Link KH ON HD.MaKhachHang = KH.MaKhachHang
JOIN SanPham SP ON CTHD.MaSanPham = SP.MaSanPham
JOIN CH1.TonKho_CuaHang@NhanVien21Link QLK ON SP.MaSanPham =
QLK.MaSanPham
WHERE
 NV.HoTen LIKE '% Linh'
 AND HD.TongTien BETWEEN 100000 AND 1000000
 AND HD.PhuongThucThanhToan = 'CHUYENKHOAN'
 AND HD.NgayTao >= TO_DATE('01/01/2025', 'DD/MM/YYYY')
 AND HD.NgayTao < TO_DATE('01/02/2025', 'DD/MM/YYYY')
 AND QLK.SoLuongTrongKho > 20
 AND KH.DiemTichLuy >= 4500;

------------------------------------------------------------------------------------
-- Thực hiện EXPLAIN câu truy vấn đã tối ưu
ALTER SESSION SET statistics_level = ALL;
EXPLAIN PLAN FOR
SELECT DISTINCT
 SP.MaSanPham,
 SP.TenSanPham,
 SP.GiaBan,
 R.SoLuongTrongKho,
 R.MaHoaDon,
 R.NgayTao,
 R.TongTien,
 R.PhuongThucThanhToan,
 R.TenNhanVien,
 R.TenKhachHang
FROM
 (
 SELECT /*+ NO_MERGE */
CTHD.MaSanPham,
 QLK.SoLuongTrongKho,
 HD.MaHoaDon,
 HD.NgayTao,
 HD.TongTien,
 HD.PhuongThucThanhToan,
 NV.HoTen AS TenNhanVien,
 KH.HoTen AS TenKhachHang
 FROM
 CH1.HoaDon@NhanVien21Link HD
 JOIN CH1.ChiTietHoaDon@NhanVien21Link CTHD ON HD.MaHoaDon =
CTHD.MaHoaDon
 JOIN CH1.NhanVien@NhanVien21Link NV ON HD.MaNhanVien =
NV.MaNhanVien
JOIN CH1.KhachHang@NhanVien21Link KH ON HD.MaKhachHang =
KH.MaKhachHang
 JOIN CH1.TONKHO_CUAHANG@NhanVien21Link QLK ON
CTHD.MaSanPham = QLK.MaSanPham -- Thay đổi điều kiện Join vật lý tại Site xa
 WHERE
 NV.HoTen LIKE '% Linh'
 AND KH.DiemTichLuy >= 4500
 AND HD.PhuongThucThanhToan = 'CHUYENKHOAN'
 AND HD.TongTien BETWEEN 100000 AND 1000000
 AND HD.NgayTao >= DATE '2025-01-01'
 AND HD.NgayTao < DATE '2025-02-01'
 AND QLK.SoLuong > 20
 ) R
JOIN SanPham SP
 ON R.MaSanPham = SP.MaSanPham;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
