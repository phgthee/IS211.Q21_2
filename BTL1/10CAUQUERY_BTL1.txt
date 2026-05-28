-- Query 1:
-- Tại cửa hàng chính (CH1), role: Giám đốc (Director)
-- Top 5 nhân viên bán nhiều nhất trên toàn bộ hệ thống 3 chi nhánh.
SELECT MaNhanVien, SUM(TongTien) AS DoanhThu
FROM (
    SELECT MaNhanVien, TongTien FROM HoaDon

    UNION ALL

    SELECT MaNhanVien, TongTien 
    FROM CH2.HoaDon@GiamDoc12Link

    UNION ALL

    SELECT MaNhanVien, TongTien 
    FROM CH3.HoaDon@GiamDoc13Link
)
GROUP BY MaNhanVien
ORDER BY DoanhThu DESC
FETCH FIRST 5 ROWS WITH TIES;

--------------------------------------------------
-- Query 2
-- Tại cửa hàng chính (CH1), role: Giám đốc (Director)
-- Tìm chi nhánh có tổng số lượng hóa đơn lớn nhất trong toàn bộ hệ thống.
WITH TongHD AS (
    SELECT MaCuaHang, COUNT(*) AS SL
    FROM (
        SELECT MaCuaHang FROM HoaDon
        UNION ALL
        SELECT MaCuaHang FROM CH2.HoaDon@GiamDoc12Link
        UNION ALL
        SELECT MaCuaHang FROM CH3.HoaDon@GiamDoc13Link
    )
    GROUP BY MaCuaHang
)
SELECT MaCuaHang, SL
FROM TongHD
WHERE SL = (SELECT MAX(SL) FROM TongHD);

---------------------------------------------------
--Query 3
//Tìm sản phẩm có doanh thu cao nhất trong từng chi nhánh
SELECT *
FROM (
    SELECT MaCuaHang,
           MaSanPham,
           SUM(ThanhTien) AS DoanhThu,
           RANK() OVER (
               PARTITION BY MaCuaHang 
               ORDER BY SUM(ThanhTien) DESC
           ) rnk
    FROM (
        SELECT H.MaCuaHang, CT.MaSanPham, CT.ThanhTien
        FROM HoaDon H JOIN ChiTietHoaDon CT ON H.MaHoaDon = CT.MaHoaDon

        UNION ALL

        SELECT H.MaCuaHang, CT.MaSanPham, CT.ThanhTien
        FROM CH2.HoaDon@GiamDoc12Link H
        JOIN CH2.ChiTietHoaDon@GiamDoc12Link CT 
        ON H.MaHoaDon = CT.MaHoaDon

        UNION ALL

        SELECT H.MaCuaHang, CT.MaSanPham, CT.ThanhTien
        FROM CH3.HoaDon@GiamDoc13Link H
        JOIN CH3.ChiTietHoaDon@GiamDoc13Link CT 
        ON H.MaHoaDon = CT.MaHoaDon
    )
    GROUP BY MaCuaHang, MaSanPham
)
WHERE rnk = 1;

--------------------------------------------------------
-- Query 4
-- Tìm khách hàng có tổng chi tiêu cao hơn trung bình của chính chi nhánh họ mua nhiều nhất
WITH TongKH AS (
    SELECT MaKhachHang, MaCuaHang, SUM(TongTien) AS TongChi
    FROM (
        SELECT MaKhachHang, MaCuaHang, TongTien 
        FROM HoaDon
        WHERE MaKhachHang IS NOT NULL

        UNION ALL

        SELECT MaKhachHang, MaCuaHang, TongTien 
        FROM CH2.HoaDon@GiamDoc12Link
        WHERE MaKhachHang IS NOT NULL

        UNION ALL

        SELECT MaKhachHang, MaCuaHang, TongTien 
        FROM CH3.HoaDon@GiamDoc13Link
        WHERE MaKhachHang IS NOT NULL
    )
    GROUP BY MaKhachHang, MaCuaHang
),

MaxCN AS (
    SELECT MaKhachHang,
           MaCuaHang,
           TongChi,
           DENSE_RANK() OVER (
               PARTITION BY MaKhachHang 
               ORDER BY TongChi DESC
           ) AS rnk
    FROM TongKH
),

AvgCN AS (
    SELECT MaCuaHang, AVG(TongChi) AS AvgChi
    FROM TongKH
    GROUP BY MaCuaHang
)

SELECT M.MaKhachHang,
       M.MaCuaHang,
       M.TongChi,
       A.AvgChi
FROM MaxCN M
JOIN AvgCN A 
    ON M.MaCuaHang = A.MaCuaHang
WHERE M.rnk = 1
  AND M.TongChi > A.AvgChi;

---------------------------------------------------------------------
--Query 5:
-- Danh sách khách hàng VIP toàn hệ thống
-- Tại chi nhánh 2, role: NhanVien
-- Liệt kê các khách hàng có tổng giá trị mua hàng trên 20 triệu đồng tính trên toàn bộ 3 chi nhánh.
SELECT 
    kh.MaKhachHang, 
    kh.HoTen, 
    kh.SDT,
    SUM(hd_global.TongTien) AS TongGiaTriMuaHang
FROM (
    -- Gom dữ liệu khách hàng (giả sử bảng này nhân bản hoặc truy vấn từ site gốc)
    SELECT MaKhachHang, HoTen, SDT FROM KhachHang@LINK_TT
) kh
JOIN (
    -- Gom tất cả hóa đơn từ 3 chi nhánh về một tập dữ liệu ảo
    SELECT MaKhachHang, TongTien FROM HoaDon@LINK_TT
    UNION ALL
    SELECT MaKhachHang, TongTien FROM HoaDon@LINK_CN1
    UNION ALL
    SELECT MaKhachHang, TongTien FROM HoaDon -- Tại Site này (Chi nhánh 2)
) hd_global ON kh.MaKhachHang = hd_global.MaKhachHang
GROUP BY 
    kh.MaKhachHang, 
    kh.HoTen, 
    kh.SDT
HAVING 
    SUM(hd_global.TongTien) > 20000000 -- Điều kiện VIP > 20 triệu
ORDER BY 
    TongGiaTriMuaHang DESC;

------------------------------------------------------------
-- Query 6:
-- Tại cửa hàng 2, role: QuanLyKho
-- Thống kê tổng số lượng tồn kho của từng sản phẩm tại cả 3 chi nhánh.
SELECT 
    sp.MaSanPham, 
    sp.TenSanPham, 
    SUM(tk_global.SoLuong) AS TongTonKhoToanHeThong
FROM 
    CH2.SANPHAM sp
JOIN (
    SELECT 
        MaSanPham, 
        (SoLuongTrenKe + SoLuongTrongKho) AS SoLuong 
    FROM CH2.TONKHO_CUAHANG
    UNION ALL
    SELECT 
        MaSanPham, 
        (SoLuongTrenKe + SoLuongTrongKho) AS SoLuong 
    FROM CH1.TONKHO_CUAHANG@QuanLyKho21Link
    UNION ALL
    SELECT 
        MaSanPham, 
        (SoLuongTrenKe + SoLuongTrongKho) AS SoLuong 
    FROM CH3.TONKHO_CUAHANG@QuanLyKho23Link
) tk_global ON sp.MaSanPham = tk_global.MaSanPham
GROUP BY 
    sp.MaSanPham, 
    sp.TenSanPham
ORDER BY 
    TongTonKhoToanHeThong DESC;

------------------------------------------------------------
--Query 7:
-- Tại chi nhánh 2, role: NhanVien
-- Liệt kê các hóa đơn trong tháng 12/2025 có tổng tiền lớn hơn mức trung bình của từng chi nhánh.
WITH AllInvoices AS (
    SELECT 'Cửa hàng 1' AS TenCH, MaHoaDon, MaKhachHang, TongTien, NgayTao
    FROM CH1.HOADON@NhanVien21Link
    WHERE NgayTao >= TO_DATE('2025-12-01', 'YYYY-MM-DD') 
      AND NgayTao < TO_DATE('2026-01-01', 'YYYY-MM-DD')
    
    UNION ALL
    
    SELECT 'Cửa hàng 2' AS TenCH, MaHoaDon, MaKhachHang, TongTien, NgayTao
    FROM CH2.HOADON
    WHERE NgayTao >= TO_DATE('2025-12-01', 'YYYY-MM-DD') 
      AND NgayTao < TO_DATE('2026-01-01', 'YYYY-MM-DD')
    
    UNION ALL
    
    SELECT 'Cửa hàng 3' AS TenCH, MaHoaDon, MaKhachHang, TongTien, NgayTao
    FROM CH3.HOADON@NhanVien23Link
    WHERE NgayTao >= TO_DATE('2025-12-01', 'YYYY-MM-DD') 
      AND NgayTao < TO_DATE('2026-01-01', 'YYYY-MM-DD')
),
BranchAverages AS (
    SELECT TenCH, AVG(TongTien) AS MucTrungBinh
    FROM AllInvoices
    GROUP BY TenCH
)
SELECT 
    i.TenCH, 
    i.MaHoaDon, 
    i.MaKhachHang, 
    i.TongTien, 
    ROUND(a.MucTrungBinh, 2) AS TrungBinhCuaChiNhanh,
    i.NgayTao
FROM AllInvoices i
JOIN BranchAverages a ON i.TenCH = a.TenCH
WHERE i.TongTien > a.MucTrungBinh
ORDER BY i.TenCH, i.TongTien DESC;


------------------------------------------------------------
-- Query 8: Tại cửa hàng chính (CH3), role: Cửa hàng trưởng
-- lấy top 10 nhân viên có doanh thu cao nhất trên toàn bộ 3 chi nhánh (CH1, CH2, CH3) trong năm 2025,

SELECT * FROM (
    SELECT 
        MANHANVIEN, 
        MACUAHANG, 
        SUM(TONGTIEN) AS TongDoanhThu,
        RANK() OVER (ORDER BY SUM(TONGTIEN) DESC) AS XepHang
    FROM (
        -- Tại CH3 (Cục bộ)
        SELECT MANHANVIEN, MACUAHANG, TONGTIEN, NGAYTAO FROM HOADON
        UNION ALL
        -- Tại CH1 (Sửa Schema BTL1. cho bảng ở xa)
        SELECT MANHANVIEN, MACUAHANG, TONGTIEN, NGAYTAO FROM CH1.HOADON@NHANVIEN31LINK
        UNION ALL
        -- Tại CH2
        SELECT MANHANVIEN, MACUAHANG, TONGTIEN, NGAYTAO FROM CH2.HOADON@NHANVIEN32LINK
    )
    WHERE EXTRACT(YEAR FROM NGAYTAO) = 2025
    GROUP BY MANHANVIEN, MACUAHANG
)
WHERE XepHang <= 10;

SELECT * FROM (
    SELECT MANHANVIEN, MACUAHANG, SUM(TONGTIEN) AS DoanhThu,
           RANK() OVER (ORDER BY SUM(TONGTIEN) DESC) AS Hang
    FROM (
        -- Tại CH3 (Cục bộ)
        SELECT MANHANVIEN, MACUAHANG, TONGTIEN, NGAYTAO FROM HOADON
        UNION ALL
        -- Tại CH1 (Dùng Owner CH1)
        SELECT MANHANVIEN, MACUAHANG, TONGTIEN, NGAYTAO FROM CH1.HOADON@NHANVIEN31LINK
        UNION ALL
        -- Tại CH2 (Dùng Owner CH2)
        SELECT MANHANVIEN, MACUAHANG, TONGTIEN, NGAYTAO FROM CH2.HOADON@NHANVIEN32LINK
    )
    WHERE EXTRACT(YEAR FROM NGAYTAO) = 2026
    GROUP BY MANHANVIEN, MACUAHANG
) WHERE Hang <= 10;


------------------------------------------------------------
-- Query 9: 
-- Thống kê số lượng giao dịch theo phương thức thanh toán của từng cửa hàng.

SELECT MACUAHANG, PHUONGTHUCTHANHTOAN, COUNT(*) AS SoGiaoDich
FROM (
    SELECT MACUAHANG, PHUONGTHUCTHANHTOAN FROM HOADON
    UNION ALL
    SELECT MACUAHANG, PHUONGTHUCTHANHTOAN FROM CH1.HOADON@NHANVIEN31LINK
    UNION ALL
    SELECT MACUAHANG, PHUONGTHUCTHANHTOAN FROM CH2.HOADON@NHANVIEN32LINK
)
GROUP BY MACUAHANG, PHUONGTHUCTHANHTOAN;


------------------------------------------------------------
-- Query 10
-- Tại CH3, role QuanLyKho, tìm các sản phẩm sắp hết trên kệ nhưng còn hàng trong kho và đối chiếu tồn kho với CH1, CH2 để hỗ trợ điều phối hàng hóa.
SELECT 
    local.MASANPHAM,
    sp.TENSANPHAM,
    local.SOLUONGTRENKE AS Tren_Ke,
    local.SOLUONGTRONGKHO AS Trong_Kho,
    -- Tính tổng để đối soát với các chi nhánh khác
    (local.SOLUONGTRENKE + local.SOLUONGTRONGKHO) AS Tong_CH3,
    ch1.Tong_CH1,
    ch2.Tong_CH2
FROM TONKHO_CUAHANG local
JOIN SANPHAM sp ON local.MASANPHAM = sp.MASANPHAM
-- Lấy tổng tồn kho từ CH1 (Dùng công thức cộng trực tiếp)
LEFT JOIN (
    SELECT MASANPHAM, (SOLUONGTRENKE + SOLUONGTRONGKHO) AS Tong_CH1
    FROM CH1.TONKHO_CUAHANG@QuanLyKho31Link
) ch1 ON local.MASANPHAM = ch1.MASANPHAM
-- Lấy tổng tồn kho từ CH2
LEFT JOIN (
    SELECT MASANPHAM, (SOLUONGTRENKE + SOLUONGTRONGKHO) AS Tong_CH2
    FROM CH2.TONKHO_CUAHANG@QuanLyKho32Link
) ch2 ON local.MASANPHAM = ch2.MASANPHAM
WHERE local.MACUAHANG = 'CH3'
  AND local.SOLUONGTRENKE < 5  -- Kệ sắp trống
  AND local.SOLUONGTRONGKHO > 0 -- Nhưng kho vẫn còn hàng để châm
ORDER BY local.SOLUONGTRENKE ASC;
