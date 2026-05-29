-- Câu truy vấn ban đầu chưa tối ưu
-- Thống kê các hóa đơn có tổng tiền >= 500.000 được chuyển khoản ngày 01/01/2025 và đếm số lượng sản phẩm trong từng hóa đơn.
SELECT
 HD.MaHoaDon,
 HD.NgayTao,
 HD.PhuongThucThanhToan,
 HD.TongTien,
 COUNT(CTHD.MaSanPham) AS SoLuongMonGiaoDich
FROM HoaDon@NhanVien21LinkHD
JOIN ChiTietHoaDon@NhanVien21LinkCTHD ON HD.MaHoaDon
CTHD.MaHoaDon
WHERE
 TRUNC(HD.NgayTao) = TO_DATE('01/01/2025', 'DD/MM/YYYY')
 AND HD.PhuongThucThanhToan = 'Chuyển khoản'
 AND HD.TongTien >= 500000
GROUP BY
 HD.MaHoaDon, HD.NgayTao, HD.PhuongThucThanhToan, HD.TongTien;

-------------------------------------------------------------------
-- Thực hiện EXPLAIN câu truy vấn ban đầu
-- 1. Bật thống kê thời gian thực trong Oracle để lấy số liệu chi tiết
ALTER SESSION SET statistics_level = ALL;
-- 2. Yêu cầu phân tích kế hoạch thực thi (Explain Plan)
EXPLAIN PLAN FOR
SELECT
 HD.MaHoaDon,
 HD.NgayTao,
 HD.PhuongThucThanhToan,
 HD.TongTien,
 COUNT(CTHD.MaSanPham) AS SoLuongMonGiaoDich
FROM
 HoaDon@NhanVien21LinkHD
JOIN
 ChiTietHoaDon@NhanVien21LinkCTHD
 ON HD.MaHoaDon = CTHD.MaHoaDon
WHERE
 TRUNC(HD.NgayTao) = TO_DATE('01/01/2025', 'DD/MM/YYYY')
 AND HD.PhuongThucThanhToan = 'Chuyển khoản'
 AND HD.TongTien >= 500000
GROUP BY
 HD.MaHoaDon,
 HD.NgayTao,
 HD.PhuongThucThanhToan,
 HD.TongTien;

-----------------------------------------------------------
-- Thực hiện indexing
-- 1. Tạo B-Tree Index cho cột Ngày Tạo (Dữ liệu có độ phân tán cao)
CREATE INDEX idex_hoadon_ngaytao ON HoaDon(NgayTao);
-- 2. Tạo B-Tree Index cho cột Tổng Tiền (Dùng để tối ưu phép so sánh >= 500000)
CREATE INDEX idex_hoadon_tongtien ON HoaDon(TongTien);
-- 3. Tạo Bitmap Index cho Phương thức thanh toán (Dữ liệu có độ phân tán thấp: Tiền
mặt/Chuyển khoản)
CREATE BITMAP INDEX bidex_hoadon_pttt ON HoaDon(PhuongThucThanhToan);
-- 4. Tạo Composite Index (Index phức hợp) trên bảng Chi tiết hóa đơn để tối ưu phép
JOIN
CREATE INDEX idex_cthd_mahoadon ON ChiTietHoaDon(MaHoaDon,
MaSanPham)
