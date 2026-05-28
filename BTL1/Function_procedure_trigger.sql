-- Function tính tổng doanh thu của một nhân viên theo tháng và năm, 
-- kiểm tra tính hợp lệ của tháng và xác minh nhân viên tồn tại trên cả 3 chi nhánh trước khi tổng hợp dữ liệu hóa đơn phân tán.
create or replace NONEDITIONABLE FUNCTION fn_tong_doanh_thu_nv (
    p_ma_nhan_vien IN VARCHAR2,
    p_thang        IN NUMBER,
    p_nam          IN NUMBER
)
RETURN NUMBER
IS
    v_tong_doanh_thu NUMBER := 0;
    v_start_date     DATE;
    v_end_date       DATE;
    v_dem            NUMBER := 0;

BEGIN

    -- 1. KIỂM TRA THÁNG
    IF p_thang < 1 OR p_thang > 12 THEN

        RAISE_APPLICATION_ERROR(
            -20002,
            'Tháng không hợp lệ'
        );

    END IF;

    -- 2. KIỂM TRA NHÂN VIÊN TỒN TẠI
    SELECT COUNT(*)
    INTO v_dem
    FROM (
        -- CH1
        SELECT MaNhanVien
        FROM NhanVien
        WHERE MaNhanVien = p_ma_nhan_vien

        UNION

        -- CH2
        SELECT MaNhanVien
        FROM CH2.NhanVien@GiamDoc12Link
        WHERE MaNhanVien = p_ma_nhan_vien

        UNION

        -- CH3
        SELECT MaNhanVien
        FROM CH3.NhanVien@GiamDoc13Link
        WHERE MaNhanVien = p_ma_nhan_vien
    );

    IF v_dem = 0 THEN

        RAISE_APPLICATION_ERROR(
            -20003,
            'Nhân viên không tồn tại: ' || p_ma_nhan_vien
        );

    END IF;

    -- 3. TÍNH KHOẢNG NGÀY
    v_start_date :=
        TO_DATE(
            p_nam || '-' || p_thang || '-01',
            'YYYY-MM-DD'
        );

    v_end_date :=
        ADD_MONTHS(v_start_date, 1);

    -- 4. TÍNH TỔNG DOANH THU
    SELECT NVL(SUM(TongTien), 0)
    INTO v_tong_doanh_thu
    FROM (

        -- CH1
        SELECT TongTien
        FROM HoaDon
        WHERE MaNhanVien = p_ma_nhan_vien
          AND NgayTao >= v_start_date
          AND NgayTao < v_end_date

        UNION ALL

        -- CH2
        SELECT TongTien
        FROM CH2.HoaDon@GiamDoc12Link
        WHERE MaNhanVien = p_ma_nhan_vien
          AND NgayTao >= v_start_date
          AND NgayTao < v_end_date

        UNION ALL

        -- CH3
        SELECT TongTien
        FROM CH3.HoaDon@GiamDoc13Link
        WHERE MaNhanVien = p_ma_nhan_vien
          AND NgayTao >= v_start_date
          AND NgayTao < v_end_date
    );

    RETURN v_tong_doanh_thu;

EXCEPTION

    WHEN OTHERS THEN

        RAISE_APPLICATION_ERROR(
            -20001,
            'Có lỗi khi tính doanh thu: ' || SQLERRM
        );

END;

----------------------------------------------------------------
-- Procedure thực hiện điều chuyển sản phẩm giữa các chi nhánh, kiểm tra tồn kho nguồn, cập nhật giảm/tăng số lượng tại kho nguồn và kho đích 
-- thông qua database link để đảm bảo đồng bộ dữ liệu phân tán.
create or replace NONEDITIONABLE PROCEDURE SP_DIEU_CHUYEN_KHO (
    p_MaSP           VARCHAR2,
    p_TuChiNhanH     VARCHAR2, -- CH1 / CH2 / CH3
    p_DenChiNhanH    VARCHAR2,
    p_SoLuong        NUMBER
)
AS
    v_TonKhoNguon NUMBER := 0;
    v_Dem NUMBER := 0;

    v_LinkNguon VARCHAR2(50);
    v_LinkDich  VARCHAR2(50);

    v_IsNguonLocal BOOLEAN := FALSE;
    v_IsDichLocal  BOOLEAN := FALSE;
BEGIN

    -- 1. KI?M TRA S?N PH?M
    SELECT COUNT(*)
    INTO v_Dem
    FROM SANPHAM
    WHERE MASANPHAM = p_MaSP;

    IF v_Dem = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'S?n ph?m không t?n t?i: ' || p_MaSP
        );
    END IF;

    -- 2. KI?M TRA CHI NHÁNH NGU?N
    IF p_TuChiNhanH = 'CH2' THEN

        v_LinkNguon := 'QuanLyKho12Link';
        v_IsNguonLocal := FALSE;

    ELSIF p_TuChiNhanH = 'CH3' THEN

        v_LinkNguon := 'QuanLyKho13Link';
        v_IsNguonLocal := FALSE;

    ELSIF p_TuChiNhanH = 'CH1' THEN

        v_IsNguonLocal := TRUE;

    ELSE

        RAISE_APPLICATION_ERROR(
            -20004,
            'Chi nhánh ngu?n không h?p l?'
        );

    END IF;

    -- 3. L?Y T?N KHO NGU?N
    IF v_IsNguonLocal THEN

        SELECT SoLuongTrongKho
        INTO v_TonKhoNguon
        FROM CH1.TonKho_CuaHang
        WHERE MaSanPham = p_MaSP
          AND MaCuaHang = p_TuChiNhanH
        FOR UPDATE;

    ELSE

        EXECUTE IMMEDIATE '
            SELECT SoLuongTrongKho
            FROM CH3.TonKho_CuaHang@' || v_LinkNguon || '
            WHERE MaSanPham = :1
              AND MaCuaHang = :2'
        INTO v_TonKhoNguon
        USING p_MaSP, p_TuChiNhanH;

    END IF;

    -- 4. KI?M TRA T?N KHO
    IF v_TonKhoNguon < p_SoLuong THEN

        RAISE_APPLICATION_ERROR(
            -20002,
            'Không ?? t?n kho t?i ' || p_TuChiNhanH
        );

    END IF;

    -- 5. TR? KHO NGU?N
    IF v_IsNguonLocal THEN

        UPDATE CH1.TonKho_CuaHang
        SET SoLuongTrongKho =
            SoLuongTrongKho - p_SoLuong
        WHERE MaSanPham = p_MaSP
          AND MaCuaHang = p_TuChiNhanH;

    ELSE

        EXECUTE IMMEDIATE '
            UPDATE CH3.TonKho_CuaHang@' || v_LinkNguon || '
            SET SoLuongTrongKho =
                SoLuongTrongKho - :1
            WHERE MaSanPham = :2
              AND MaCuaHang = :3'
        USING p_SoLuong,
              p_MaSP,
              p_TuChiNhanH;

    END IF;

    -- 6. KI?M TRA CHI NHÁNH ?ÍCH
    IF p_DenChiNhanH = 'CH1' THEN

        v_IsDichLocal := TRUE;

    ELSIF p_DenChiNhanH = 'CH2' THEN

        v_LinkDich := 'QuanLyKho12Link';

    ELSIF p_DenChiNhanH = 'CH3' THEN

        v_LinkDich := 'QuanLyKho13Link';

    ELSE

        RAISE_APPLICATION_ERROR(
            -20005,
            'Chi nhánh ?ích không h?p l?'
        );

    END IF;

    -- 7. C?NG KHO ?ÍCH
    IF v_IsDichLocal THEN

        MERGE INTO CH1.TonKho_CuaHang t
        USING (
            SELECT p_MaSP AS MaSP
            FROM dual
        ) s
        ON (
            t.MaSanPham = s.MaSP
            AND t.MaCuaHang = p_DenChiNhanH
        )

        WHEN MATCHED THEN
            UPDATE SET
                SoLuongTrongKho =
                    SoLuongTrongKho + p_SoLuong

        WHEN NOT MATCHED THEN
            INSERT (
                MaCuaHang,
                MaSanPham,
                SoLuongTrongKho
            )
            VALUES (
                p_DenChiNhanH,
                p_MaSP,
                p_SoLuong
            );

    ELSE

        EXECUTE IMMEDIATE '
            MERGE INTO CH3.TonKho_CuaHang@' || v_LinkDich || ' t
            USING (
                SELECT :1 AS MaSP,
                       :2 AS MaCH,
                       :3 AS SL
                FROM dual
            ) s
            ON (
                t.MaSanPham = s.MaSP
                AND t.MaCuaHang = s.MaCH
            )

            WHEN MATCHED THEN
                UPDATE SET
                    SoLuongTrongKho =
                        SoLuongTrongKho + s.SL

            WHEN NOT MATCHED THEN
                INSERT (
                    MaCuaHang,
                    MaSanPham,
                    SoLuongTrongKho
                )
                VALUES (
                    s.MaCH,
                    s.MaSP,
                    s.SL
                )'
        USING p_MaSP,
              p_DenChiNhanH,
              p_SoLuong;

    END IF;

    -- 8. COMMIT
    COMMIT;

    DBMS_OUTPUT.PUT_LINE(
        'Thành công: chuy?n '
        || p_SoLuong
        || ' s?n ph?m '
        || p_MaSP
        || ' t? '
        || p_TuChiNhanH
        || ' sang '
        || p_DenChiNhanH
    );

EXCEPTION

    WHEN OTHERS THEN

        ROLLBACK;

        RAISE_APPLICATION_ERROR(
            -20003,
            SQLERRM
        );

END;

----------------------------------------------------------------
-- Trigger tự động cập nhật tồn kho khi có thao tác thêm, sửa hoặc xóa chi tiết hóa đơn, bao gồm hoàn kho dữ liệu cũ và trừ kho dữ liệu mới 
-- nhằm đảm bảo số lượng tồn luôn chính xác.
create or replace NONEDITIONABLE TRIGGER TRG_CT_HOADON_CAPNHATKHO
FOR INSERT OR UPDATE OR DELETE ON CHITIETHOADON
COMPOUND TRIGGER

    ------------------------------------------------------------------
    -- KHAI BÁO KIỂU DỮ LIỆU
    ------------------------------------------------------------------
    TYPE t_masp IS TABLE OF CHITIETHOADON.MASANPHAM%TYPE INDEX BY PLS_INTEGER;
    TYPE t_mahd IS TABLE OF CHITIETHOADON.MAHOADON%TYPE INDEX BY PLS_INTEGER;
    TYPE t_sl IS TABLE OF CHITIETHOADON.SOLUONG%TYPE INDEX BY PLS_INTEGER;

    ------------------------------------------------------------------
    -- MẢNG DỮ LIỆU MỚI
    ------------------------------------------------------------------
    arr_new_masp t_masp;
    arr_new_mahd t_mahd;
    arr_new_sl   t_sl;

    ------------------------------------------------------------------
    -- MẢNG DỮ LIỆU CŨ
    ------------------------------------------------------------------
    arr_old_masp t_masp;
    arr_old_mahd t_mahd;
    arr_old_sl   t_sl;

    ------------------------------------------------------------------
    -- RESET DỮ LIỆU
    ------------------------------------------------------------------
    BEFORE STATEMENT IS
    BEGIN
        arr_new_masp.DELETE;
        arr_new_mahd.DELETE;
        arr_new_sl.DELETE;

        arr_old_masp.DELETE;
        arr_old_mahd.DELETE;
        arr_old_sl.DELETE;
    END BEFORE STATEMENT;

    ------------------------------------------------------------------
    -- LƯU DỮ LIỆU TẠM
    ------------------------------------------------------------------
    AFTER EACH ROW IS
    BEGIN
        --------------------------------------------------------------
        -- INSERT / UPDATE
        --------------------------------------------------------------
        IF INSERTING OR UPDATING THEN
            arr_new_masp(arr_new_masp.COUNT + 1) := :NEW.MASANPHAM;
            arr_new_mahd(arr_new_mahd.COUNT + 1) := :NEW.MAHOADON;
            arr_new_sl(arr_new_sl.COUNT + 1)     := :NEW.SOLUONG;
        END IF;

        --------------------------------------------------------------
        -- DELETE / UPDATE
        --------------------------------------------------------------
        IF DELETING OR UPDATING THEN
            arr_old_masp(arr_old_masp.COUNT + 1) := :OLD.MASANPHAM;
            arr_old_mahd(arr_old_mahd.COUNT + 1) := :OLD.MAHOADON;
            arr_old_sl(arr_old_sl.COUNT + 1)     := :OLD.SOLUONG;
        END IF;
    END AFTER EACH ROW;

    ------------------------------------------------------------------
    -- XỬ LÝ KHO
    ------------------------------------------------------------------
    AFTER STATEMENT IS
        v_maCH              HOADON.MACUAHANG%TYPE;

        v_slTrenKe          TONKHO_CUAHANG.SOLUONGTRENKE%TYPE;
        v_slTrongKho        TONKHO_CUAHANG.SOLUONGTRONGKHO%TYPE;

        v_canTru            NUMBER;
        v_conThieu          NUMBER;
    BEGIN
------------------------------------------------------------------
        -- 1. HOÀN KHO CHO DỮ LIỆU CŨ
        ------------------------------------------------------------------
        FOR i IN 1 .. arr_old_masp.COUNT LOOP
            BEGIN
                SELECT MACUAHANG
                INTO v_maCH
                FROM HOADON
                WHERE MAHOADON = arr_old_mahd(i);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20002,
                        'Không tìm thấy hóa đơn: ' || arr_old_mahd(i)
                    );
            END;

            --------------------------------------------------------------
            -- HOÀN HÀNG LẠI LÊN KỆ
            --------------------------------------------------------------
            UPDATE TONKHO_CUAHANG
            SET SOLUONGTRENKE = SOLUONGTRENKE + arr_old_sl(i)
            WHERE MASANPHAM = arr_old_masp(i)
              AND MACUAHANG = v_maCH;

            IF SQL%ROWCOUNT = 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20003,
                    'Không tìm thấy thông tin tồn kho của sản phẩm ' || arr_old_masp(i)
                );
            END IF;
        END LOOP;

        ------------------------------------------------------------------
        -- 2. TRỪ KHO CHO DỮ LIỆU MỚI
        ------------------------------------------------------------------
        FOR i IN 1 .. arr_new_masp.COUNT LOOP

            --------------------------------------------------------------
            -- VALIDATE SỐ LƯỢNG
            --------------------------------------------------------------
            IF arr_new_sl(i) <= 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20004,
                    'Số lượng phải lớn hơn 0'
                );
            END IF;

            --------------------------------------------------------------
            -- LẤY MÃ CỬA HÀNG
            --------------------------------------------------------------
            BEGIN
                SELECT MACUAHANG
                INTO v_maCH
                FROM HOADON
                WHERE MAHOADON = arr_new_mahd(i);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20005,
                        'Không tìm thấy hóa đơn: ' || arr_new_mahd(i)
                    );
            END;

            --------------------------------------------------------------
            -- KHÓA DÒNG TỒN KHO
            --------------------------------------------------------------
            BEGIN
                SELECT SOLUONGTRENKE,
                       SOLUONGTRONGKHO
                INTO v_slTrenKe,
                     v_slTrongKho
                FROM TONKHO_CUAHANG
                WHERE MASANPHAM = arr_new_masp(i)
                  AND MACUAHANG = v_maCH
FOR UPDATE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20006,
                        'Không tồn tại dữ liệu tồn kho của sản phẩm ' || arr_new_masp(i)
                    );
            END;

            v_canTru := arr_new_sl(i);

            --------------------------------------------------------------
            -- KIỂM TRA TỔNG TỒN
            --------------------------------------------------------------
            IF (v_slTrenKe + v_slTrongKho) < v_canTru THEN
                RAISE_APPLICATION_ERROR(
                    -20001,
                    'Không đủ tồn kho cho sản phẩm: ' || arr_new_masp(i)
                );
            END IF;

            --------------------------------------------------------------
            -- ĐỦ HÀNG TRÊN KỆ
            --------------------------------------------------------------
            IF v_slTrenKe >= v_canTru THEN
                UPDATE TONKHO_CUAHANG
                SET SOLUONGTRENKE = SOLUONGTRENKE - v_canTru
                WHERE MASANPHAM = arr_new_masp(i)
                  AND MACUAHANG = v_maCH;

            --------------------------------------------------------------
            -- KHÔNG ĐỦ HÀNG TRÊN KỆ
            --------------------------------------------------------------
            ELSE
                v_conThieu := v_canTru - v_slTrenKe;

                UPDATE TONKHO_CUAHANG
                SET SOLUONGTRENKE = 0,
                    SOLUONGTRONGKHO = SOLUONGTRONGKHO - v_conThieu
                WHERE MASANPHAM = arr_new_masp(i)
                  AND MACUAHANG = v_maCH;
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END TRG_CT_HOADON_CAPNHATKHO;
