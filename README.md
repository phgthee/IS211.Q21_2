# 🗄️ Cơ Sở Dữ Liệu Phân Tán – BTL1 & BTL2

> Môn học: Cơ Sở Dữ Liệu Phân Tán  
> Khoa Hệ Thống Thông Tin – Trường Đại học Công nghệ Thông tin, ĐHQG TP.HCM

---

## Cấu trúc Repository

```
├── BTL1/          # Oracle RDBMS Distributed Database
├── BTL2/          # Neo4j NoSQL Distributed Database
└── Dataset/       # Dữ liệu dùng chung cho cả 2 bài
```

---

## Dataset

Dataset được dùng chung cho cả hai bài tập lớn, mô phỏng hệ thống bán lẻ của chuỗi cửa hàng gồm **3 chi nhánh phân tán** tại 3 địa điểm khác nhau.

| Bảng | Mô tả |
|---|---|
| `NhanVien` | Thông tin nhân viên tại từng chi nhánh |
| `KhachHang` | Thông tin khách hàng |
| `SanPham` | Danh mục và thông tin sản phẩm |
| `DanhMucSanPham` | Phân loại sản phẩm theo danh mục |
| `Kho` | Thông tin kho hàng tại từng chi nhánh |
| `TonKho` | Tình trạng tồn kho theo sản phẩm và chi nhánh |
| `HoaDon` | Thông tin hóa đơn bán hàng |
| `ChiTietHoaDon` | Chi tiết sản phẩm trong từng hóa đơn |

---

## BTL1 – Cơ Sở Dữ Liệu Phân Tán trên Oracle RDBMS

### Tổng quan
Thiết kế và triển khai hệ thống CSDL phân tán trên **Oracle RDBMS**, kết nối qua **Radmin VPN** trên tối thiểu 3 máy ảo.

### Nội dung thực hiện

- **Phân mảnh dữ liệu:** Triển khai phân mảnh ngang, dọc và hỗn hợp trên các bảng dữ liệu.
- **Nhân bản:** Cài đặt ít nhất một bảng nhân bản giữa các máy.
- **Truy vấn phân tán:** Thực thi 10 câu truy vấn phân tán bao gồm UNION, INTERSECT, MINUS, GROUP BY, HAVING, SUM, AVG.
- **Hàm & Thủ tục:** Xây dựng function và stored procedure trong môi trường phân tán.
- **Ràng buộc toàn vẹn:** Cài đặt và kiểm thử ràng buộc tham chiếu và nghiệp vụ (RBTV).
- **Mức cô lập giao dịch:** Minh họa các mức Read Uncommitted, Read Committed, Repeatable Read, Serializable.
- **Tối ưu hóa truy vấn:** Phân tích và cải thiện hiệu năng truy vấn bằng EXPLAIN PLAN.
- **Indexing *(Bonus)*:** Nghiên cứu và triển khai các loại index trong Oracle, đo lường hiệu năng.

---

## BTL2 – Cơ Sở Dữ Liệu Phân Tán trên NoSQL (Neo4j)

### Tổng quan
Thiết kế và triển khai hệ thống CSDL đồ thị phân tán trên **Neo4j**, kết nối đa máy qua **Radmin VPN**, tương tác dữ liệu thông qua **Python**.

### Nội dung thực hiện

- **Tổng quan NoSQL & Neo4j:** Lịch sử, kiến trúc, các loại NoSQL, khái niệm Graph Database, ngôn ngữ truy vấn Cypher.
- **Cài đặt & cấu hình:** Triển khai Neo4j trên nhiều máy, kết nối qua Radmin VPN và Remote Connection.
- **Nhập dữ liệu:** Nhập dữ liệu từ file CSV thông qua Python (`pandas` + `py2neo`); xử lý file lớn bằng chunking.
- **Truy vấn phân tán:** Thực thi các câu truy vấn Cypher kết nối đồng thời vào nhiều instance, tổng hợp kết quả ở tầng ứng dụng.
- **Thao tác CRUD:** Thực hiện Create, Read, Update, Delete trên môi trường đa máy.
- **Replication *(Bonus)*:** Tìm hiểu cơ chế nhân bản trong Neo4j; trong phạm vi đồ án triển khai ở mức Remote Connection do giới hạn của Community Edition.

---

## Công nghệ sử dụng

| | BTL1 | BTL2 |
|---|---|---|
| **Database** | Oracle RDBMS | Neo4j (Community Edition) |
| **Kết nối mạng** | Radmin VPN | Radmin VPN |
| **Ngôn ngữ** | SQL / PL-SQL | Python (pandas, py2neo) |
| **Truy vấn** | SQL | Cypher |

---

## Thành viên nhóm

| MSSV | Họ và tên |
|---|---|
| 22521460 | Nguyễn Lê Phương Thy |
| 22521455 | Hoàng Dương Ngọc Thuỷ |
| 23521512 | Trần Hữu Thịnh |

---

## Giảng viên hướng dẫn

Trợ giảng thực hành: **KS. Nguyễn Minh Nhựt**  
Môn: Cơ Sở Dữ Liệu Phân Tán – Khoa Hệ Thống Thông Tin, UIT
