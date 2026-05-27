BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ChiTietHoaDon CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE HoaDon CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE TonKho_CuaHang CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Kho CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE NhanVien CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE SanPham CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DanhMuc_SanPham CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE KhachHang CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE CuaHang CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/
CREATE TABLE DanhMuc_SanPham (
    MaDanhMuc VARCHAR2(20) PRIMARY KEY,
    TenDanhMuc NVARCHAR2(255)
);

CREATE TABLE CuaHang (
    MaCuaHang VARCHAR2(20) PRIMARY KEY,
    TenCuaHang NVARCHAR2(255),
    DiaChi NVARCHAR2(500),
    SDT VARCHAR2(20)
);

CREATE TABLE KhachHang (
    MaKhachHang VARCHAR2(20) PRIMARY KEY,
    SDT VARCHAR2(20) UNIQUE,
    HoTen NVARCHAR2(255),
    NgaySinh DATE,
    GioiTinh NVARCHAR2(10),
    DiaChi NVARCHAR2(500),
    DiemTichLuy NUMBER DEFAULT 0
);

CREATE TABLE SanPham (
    MaSanPham VARCHAR2(50) PRIMARY KEY,
    TenSanPham NVARCHAR2(255),
    DVT VARCHAR2(50),
    MaDanhMuc VARCHAR2(20),
    GiaBan NUMBER(19),
    GiaVon NUMBER(19),
    CONSTRAINT fk_sp_danhmuc FOREIGN KEY (MaDanhMuc) REFERENCES DanhMuc_SanPham(MaDanhMuc)
);

CREATE TABLE Kho (
    MaKho VARCHAR2(20) PRIMARY KEY,
    MaSanPham VARCHAR2(50),
    SoLuong NUMBER,
    ViTri VARCHAR2(255),
    NgayCapNhat TIMESTAMP,
    CONSTRAINT fk_kho_sanpham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
);

CREATE TABLE TonKho_CuaHang (
    MaCuaHang VARCHAR2(20),
    MaSanPham VARCHAR2(50),
    SoLuongTrenKe NUMBER DEFAULT 0,
    SoLuongTrongKho NUMBER DEFAULT 0,
    NgayCapNhat TIMESTAMP,
    PRIMARY KEY (MaCuaHang, MaSanPham),
    CONSTRAINT fk_tk_cuahang FOREIGN KEY (MaCuaHang) REFERENCES CuaHang(MaCuaHang),
    CONSTRAINT fk_tk_sanpham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
);

CREATE TABLE NhanVien (
    MaNhanVien VARCHAR2(20) PRIMARY KEY,
    MaCuaHang VARCHAR2(20),
    HoTen NVARCHAR2(255),
    GioiTinh NVARCHAR2(10),
    NgaySinh DATE,
    ChucVu NVARCHAR2(100),
    NgayVaoLam DATE,
    Luong NUMBER,
    CONSTRAINT fk_nv_cuahang FOREIGN KEY (MaCuaHang) REFERENCES CuaHang(MaCuaHang)
);

CREATE TABLE HoaDon (
    MaHoaDon VARCHAR2(20) PRIMARY KEY,
    MaCuaHang VARCHAR2(20),
    MaNhanVien VARCHAR2(20),
    MaKhachHang VARCHAR2(20),
    TongTien NUMBER(19,4),
    NgayTao TIMESTAMP,
    PhuongThucThanhToan NVARCHAR2(50),
    CONSTRAINT fk_hd_cuahang FOREIGN KEY (MaCuaHang) REFERENCES CuaHang(MaCuaHang),
    CONSTRAINT fk_hd_nhanvien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien),
    CONSTRAINT fk_hd_khachhang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang)
);

CREATE TABLE ChiTietHoaDon (
    MaHoaDon VARCHAR2(20),
    MaSanPham VARCHAR2(50),
    SoLuong NUMBER,
    DonGia NUMBER(19),
    ThanhTien NUMBER(19),
    PRIMARY KEY (MaHoaDon, MaSanPham),
    CONSTRAINT fk_cthd_hoadon FOREIGN KEY (MaHoaDon) REFERENCES HoaDon(MaHoaDon),
    CONSTRAINT fk_cthd_sanpham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
);
COMMIT;