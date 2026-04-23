-- 1. Phân tích và đề xuất giải pháp:
-- Với 2 triệu bản ghi, việc thay đổi kiểu dữ liệu (Data type) là một thao tác Metadata Change nặng nề. Chúng ta có 2 hướng tiếp cận chính: 

-- Giải pháp 1: Sử dụng Online DDL
-- Sử dụng tính năng có sẵn của MySQL để thay đổi trực tiếp cấu trúc bảng mà vẫn cho phép đọc/ghi dữ liệu.
-- Cơ chế: MySQL cố gắng thực hiện thay đổi mà không cần tạo bảng tạm nếu có thể, hoặc cho phép các lệnh INSERT/UPDATE chạy song song.
-- Câu lệnh minh họa: 
ALTER TABLE USERS 
MODIFY COLUMN Phone VARCHAR(15) NOT NULL, 
ALGORITHM=INPLACE,
LOCK=NONE;

-- Giải pháp 2: Sử dụng giải pháp bảng tạm
-- Tạo 1 cột mới với kiểu dữ liệu mong muốn, chuyển dữ liệu dần dần, sau đó đổi tên cột. 
-- Cơ chế: Tránh việc khóa bảng chính quá lâu bằng cách thực hiện thay đổi trên thực thể mới.
-- Các bước: 1. Thêm cột phone_new (VARCHAR).
--           2. Update dữ liệu từ phone sang phone_new (có xử lý thêm số 0).
--           3. Xóa cột cũ và đổi tên cột mới.

-- 2. So sánh và lựa chọn: 
-- Tiêu chí               Giải pháp 1: Online DDL                      Giải pháp 2: Shadow Copy
-- Độ phức tạp            Thấp (1 câu lệnh)                            Cao (Nhiều bước, cần trigger)
-- Khả năng ghi dữ liệu   Có thể bị chặn nếu không hỗ trợ ALGORITHM    Không bị chặn
-- Rủi ro                 Cao: Đổi từ INT sang VARCHAR thường yêu cầu  Thấp: Kiểm soát được tốc độ chuyển đổi dữ liệu.
--                        rebuild lại bảng hoàn toàn. Lock bảng lâu 
--                        sẽ làm sập app.
-- Tính toàn vẹn          Tự động xử lý                                Dễ sai sót trong quá trình sync dữ liệu

-- Lựa chọn: Mặc dù Giải pháp 2 an toàn nhất cho dữ liệu cực lớn (Big Data), nhưng với 2 triệu bản ghi (mức độ vừa phải) 
-- và yêu cầu "1 câu lệnh DDL duy nhất", chúng ta sẽ tối ưu Giải pháp 1 bằng cách ép MySQL sử dụng cơ chế Online DDL tối ưu nhất.

-- 3. Chốt giải pháp và thực thi
-- Để giải quyết dứt điểm vấn đề mà không làm sập ứng dụng (vẫn cho phép người dùng đăng nhập/đăng ký trong lúc chạy), ta sử dụng
-- câu lệnh ALTER TABLE kèm theo các chỉ thị về ALGORITHM và LOCK.